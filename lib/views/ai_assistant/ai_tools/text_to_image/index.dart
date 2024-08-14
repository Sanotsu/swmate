// ignore_for_file: avoid_print, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../apis/text_to_image/silicon_flow_tti_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/llm_spec/cus_llm_spec.dart';
import '../../../../models/text_to_image/com_tti_req.dart';
import '../../../../services/cus_get_storage.dart';
import '../../_chat_screen_parts/chat_plat_and_llm_area.dart';

var ImageSizeList = [
  "512x512",
  "512x1024",
  '768x512',
  '768x1024',
  '1024x576',
  '576x1024',
];
var ImageNumList = [1, 2, 3, 4];

class Text2ImageScreen extends StatefulWidget {
  const Text2ImageScreen({super.key});

  @override
  State createState() => _Text2ImageScreenState();
}

class _Text2ImageScreenState extends State<Text2ImageScreen>
    with WidgetsBindingObserver {
  /// 级联选择效果：云平台-模型名
  ApiPlatform selectedPlatform = ApiPlatform.siliconCloud;

  // 被选中的模型信息
  CusLLMSpec selectedModelSpec = CusLLM_SPEC_LIST.where((spec) =>
      spec.platform == ApiPlatform.siliconCloud &&
      spec.modelType == LLModelType.tti).toList().first;

  final _promptController = TextEditingController();
  final _negativePromptController = TextEditingController();

  // 描述画面的提示词信息。支持中英文，长度不超过500个字符，超过部分会自动截断。
  String prompt = "";
  // 画面中不想出现的内容描述词信息。支持中英文，长度不超过500个字符，超过部分会自动截断。
  String negativePrompt = "";
  // 被选中的生成尺寸
  String selectedSize = ImageSizeList.first;
  // 被选中的生成数量
  int selectedNum = ImageNumList.first;

  // 是否正在生成图片
  bool isGenImage = false;

  // 最后生成的图片地址
  List<String> rstImageUrls = [];

  // 添加一个overlay，在生成图片时，禁止用户的其他操作
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _removeLoadingOverlay();
    }
  }

  /// 添加遮罩
  void _showLoadingOverlay() {
    OverlayState? overlayState = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.8),
          child: const Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                Text("图片生成中……"),
                Text("请勿退出当前页面"),
              ],
            ),
          ),
        );
      },
    );
    overlayState.insert(_overlayEntry!);
  }

  /// 移除遮罩
  void _removeLoadingOverlay() {
    _overlayEntry?.remove();
    setState(() {
      _overlayEntry = null;
    });
  }

  /// 构建用于下拉的平台列表(根据上层传入的值)
  List<DropdownMenuItem<ApiPlatform?>> buildCloudPlatforms() {
    // 2024-08-14 目前只有sf平台有免费文生图模型
    return ApiPlatform.values
        .where((e) => e == ApiPlatform.siliconCloud)
        .map((e) {
      return DropdownMenuItem<ApiPlatform?>(
        value: e,
        alignment: AlignmentDirectional.center,
        child: Text(
          CP_NAME_MAP[e]!,
          style: const TextStyle(color: Colors.blue),
        ),
      );
    }).toList();
  }

  /// 当切换了云平台时，要同步切换选中的大模型
  onCloudPlatformChanged(ApiPlatform? value) {
    // 如果平台被切换，则更新当前的平台为选中的平台，且重置模型为符合该平台的模型的第一个
    if (value != selectedPlatform) {
      // 更新被选中的平台为当前选中平台
      selectedPlatform = value ?? ApiPlatform.siliconCloud;

      setState(() {
        // 切换平台后，修改选中的模型为该平台第一个
        selectedModelSpec = CusLLM_SPEC_LIST.where((spec) =>
            spec.platform == selectedPlatform &&
            spec.modelType == LLModelType.tti).toList().first;
      });
    }
  }

  /// 选定了云平台后，要构建用于下拉选择的该平台的大模型列表
  List<DropdownMenuItem<CusLLMSpec>> buildPlatformLLMs() {
    // 用于下拉的模型首先需要是对话模型
    return CusLLM_SPEC_LIST.where((spec) =>
            spec.platform == selectedPlatform &&
            spec.modelType == LLModelType.tti)
        .map((e) => DropdownMenuItem<CusLLMSpec>(
              value: e,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                e.name,
                style: const TextStyle(color: Colors.blue),
              ),
            ))
        .toList();
  }

  /// 获取文生图的数据
  getText2ImageData() async {
    // 如果在生成中，就不要继续生成了
    if (isGenImage) {
      return;
    }

    setState(() {
      isGenImage = true;
      _showLoadingOverlay();
    });

    // 查看现在读取的内容
    print("正向词 $prompt");
    print("消极词 $negativePrompt");
    print("尺寸 $selectedSize");
    print("选择的平台 $selectedPlatform");
    print("选择的模型 $selectedModelSpec");

    // 获取图片生成结果
    var a = ComTtiReq.sdLighting(
      prompt: prompt,
      negativePrompt: negativePrompt,
      imageSize: selectedSize,
      batchSize: selectedNum,
    );

    var result = await getSFTtiResp(a, selectedModelSpec.model);

    if (result.error != null) {
      EasyLoading.showError("服务器报错:\n${result.error!}");
      // 移除遮罩
      if (!mounted) return;
      setState(() {
        isGenImage = false;
        _removeLoadingOverlay();
      });
    } else {
      // 任务处理完成之后，放到结果列表中显示
      List<String> imageUrls = [];

      if (result.images != null) {
        for (var e in result.images!) {
          imageUrls.add(e.url);
          await MyGetStorage().setText2ImageUrl(e.url);
        }
      }

      // 移除遮罩
      if (!mounted) return;
      setState(() {
        rstImageUrls = imageUrls;
        isGenImage = false;
        _removeLoadingOverlay();
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文本生图(SF平台)'),
        actions: [
          IconButton(
            onPressed: () {
              var list = MyGetStorage().getText2ImageUrl();

              // 点击了指定文生图记录，弹窗显示缩略图
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    // title: Text(
                    //   "文生图历史记录(原始宽高比)",
                    //   style: TextStyle(fontSize: 15.sp),
                    // ),
                    title: RichText(
                      // 应用文本缩放因子
                      textScaler: MediaQuery.of(context).textScaler,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "文生图历史记录\n",
                            style: TextStyle(
                              fontSize: 20.sp,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: "只有图片地址，没有保留参数",
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    content: SizedBox(
                      height: 300.sp,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 直接预览
                            Text(
                              "直接预览(原始宽高比)",
                              style: TextStyle(fontSize: 15.sp),
                            ),
                            Wrap(
                              spacing: 5.sp,
                              runSpacing: 5.sp,
                              children: buildImageList("默认", list, context),
                            ),

                            SizedBox(height: 20.sp),
                            // 点击按钮去浏览器下载查看
                            Text(
                              "点击按钮去浏览器下载查看",
                              style: TextStyle(fontSize: 15.sp),
                            ),

                            Wrap(
                              spacing: 5.sp,
                              children: List.generate(
                                list.length,
                                (index) => ElevatedButton(
                                  // 尽量弹窗中一排4个按钮
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size(52, 26.sp),
                                    padding: EdgeInsets.all(0.sp),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.sp),
                                    ),
                                  ),
                                  // 假设url一定存在的
                                  onPressed: () => _launchUrl(list[index]),
                                  child: Text(
                                    '图片${index + 1}',
                                    style: TextStyle(fontSize: 12.sp),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        child: const Text("确定"),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        // 允许子控件（如TextField）接收点击事件
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // 点击空白处可以移除焦点，关闭键盘
          FocusScope.of(context).unfocus();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// 执行按钮
            Padding(
              padding: EdgeInsets.all(5.sp),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "文生图配置",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  buildText2ImageButtonArea(),
                ],
              ),
            ),

            /// 文生图配置折叠栏
            Expanded(flex: 2, child: buildConfigArea()),

            const Divider(),
            Padding(
              padding: EdgeInsets.all(5.sp),
              child: Text(
                "生成的图片(点击查看、长按保存)",
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
            ),

            /// 文生图的结果
            buildImageResult(),
            SizedBox(height: 10.sp),
          ],
        ),
      ),
    );
  }

  /// 构建可切换云平台和模型的行
  _buildPlatAndModelRow() {
    return Container(
      color: Colors.grey[300],
      child: Padding(
        padding: EdgeInsets.only(left: 10.sp),
        child: PlatAndLlmRow(
          selectedPlatform: selectedPlatform,
          onPlatformChanged: onCloudPlatformChanged,
          selectedModelSpec: selectedModelSpec,
          onModelSpecChanged: (val) {
            setState(() {
              selectedModelSpec = val!;
            });
          },
          buildPlatformList: buildCloudPlatforms,
          buildModelSpecList: buildPlatformLLMs,
        ),
      ),
    );
  }

  ///
  _buildSizeAndNumArea() {
    return SizedBox(
      height: 32.sp,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(width: 5.sp),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1.0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // const Icon(Icons.aspect_ratio),
                  const Text("尺寸"),
                  DropdownButton<String?>(
                    value: selectedSize,
                    underline: Container(),
                    alignment: AlignmentDirectional.center,
                    menuMaxHeight: 300.sp,
                    items: ImageSizeList.map((e) => DropdownMenuItem<String>(
                          value: e,
                          alignment: AlignmentDirectional.center,
                          child: Text(
                            e,
                            style: const TextStyle(color: Colors.blue),
                          ),
                        )).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedSize = val;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1.0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // const Icon(Icons.numbers_rounded),
                  const Text("数量"),
                  DropdownButton<int?>(
                    value: selectedNum,
                    underline: Container(),
                    alignment: AlignmentDirectional.center,
                    menuMaxHeight: 300.sp,
                    items: ImageNumList.map((e) => DropdownMenuItem<int>(
                          value: e,
                          alignment: AlignmentDirectional.center,
                          child: Text(
                            e.toString(),
                            style: const TextStyle(color: Colors.blue),
                          ),
                        )).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedNum = val;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建文生图配置和执行按钮
  buildText2ImageButtonArea() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            // 处理编辑按钮的点击事件
            setState(() {
              prompt = "";
              negativePrompt = "";
              _promptController.text = "";
              _negativePromptController.text = "";
              selectedSize = ImageSizeList.first;
              selectedNum = ImageNumList.first;
            });
          },
          child: const Text("还原配置"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: Size(72, 36.sp),
            padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 5.sp),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.sp),
            ),
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue,
          ),
          onPressed: prompt.isNotEmpty
              ? () async {
                  FocusScope.of(context).unfocus();

                  // 实际请求
                  await getText2ImageData();
                }
              : null,
          child: const Text(
            "生成图片",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// 构建文生图的配置折叠栏
  buildConfigArea() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 平台和模型选择
          _buildPlatAndModelRow(),

          /// 画风、尺寸、张数选择
          _buildSizeAndNumArea(),

          /// 正向提示词
          _buildPromptHint(),

          /// 消极提示词
          _buildNegativePromptHint(),
        ],
      ),
    );
  }

  /// 构建生成的图片区域
  buildImageResult() {
    return SizedBox(
      // 最多4张图片，每张占0.24宽度，高度就预留0.5宽度。在外层Column最下面留点空即可
      height: 0.5.sw,
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (rstImageUrls.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 0.25.sw),
                child: buildNetworkImageViewGrid(
                  // ？？？2024-08-14 SF平台限时免费的没有样式
                  "默认",
                  rstImageUrls,
                  context,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 正向提示词输入框
  _buildPromptHint() {
    return Padding(
      padding: EdgeInsets.all(5.sp),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("正向提示词(不可为空)", style: TextStyle(color: Colors.green)),
          TextField(
            controller: _promptController,
            decoration: InputDecoration(
              hintText: '描述画面的提示词信息。支持中英文，不超过500个字符。\n比如：“一只展翅翱翔的狸花猫”',
              hintStyle: TextStyle(fontSize: 12.sp),
              border: const OutlineInputBorder(), // 添加边框
            ),
            maxLines: 5,
            minLines: 3,
            onChanged: (String? text) {
              if (text != null) {
                setState(() {
                  prompt = text.trim();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  /// 反向提示词输入框
  _buildNegativePromptHint() {
    return Padding(
      padding: EdgeInsets.all(5.sp),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("反向提示词(可以不填)"),
          TextField(
            controller: _negativePromptController,
            decoration: InputDecoration(
              hintText:
                  '画面中不想出现的内容描述词信息。通过指定用户不想看到的内容来优化模型输出，使模型产生更有针对性和理想的结果。',
              hintStyle: TextStyle(fontSize: 12.sp),
              border: const OutlineInputBorder(), // 添加边框
            ),
            maxLines: 5,
            minLines: 3,
            onChanged: (String? text) {
              if (text != null) {
                setState(() {
                  negativePrompt = text.trim();
                });
              }
            },
          ),
        ],
      ),
    );
  }
}
