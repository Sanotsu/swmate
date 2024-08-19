// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import '../../../../apis/text_to_image/aliyun_wanx_apis.dart';
import '../../../../apis/text_to_image/silicon_flow_tti_apis.dart';
import '../../../../apis/text_to_image/xfyun_tti_aps.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/llm_spec/cus_llm_spec.dart';

import '../../../../common/utils/db_tools/db_helper.dart';
import '../../../../common/utils/tools.dart';
import '../../../../models/text_to_image/aliyun_tti_req.dart';
import '../../../../models/text_to_image/aliyun_tti_resp.dart';
import '../../../../models/text_to_image/com_tti_req.dart';
import '../../../../models/text_to_image/com_tti_resp.dart';
import '../../../../models/text_to_image/com_tti_state.dart';
import '../../../../services/cus_get_storage.dart';
import '../../_componets/cus_platform_and_llm_row.dart';
import '../../_componets/prompt_input.dart';
import '../../_tti_screen_parts/style_grid_selector.dart';
import '../../_tti_screen_parts/tti_button_row_area.dart';
import '../../_helper/constants.dart';
import '../../_componets/loading_overlay.dart';
import '../../_tti_screen_parts/size_and_num_selector.dart';
import 'tti_history_screen.dart';

class CommonTTIScreen extends StatefulWidget {
  const CommonTTIScreen({super.key});

  @override
  State<CommonTTIScreen> createState() => _CommonTTIScreenState();
}

class _CommonTTIScreenState extends State<CommonTTIScreen>
    with WidgetsBindingObserver {
  ///
  /// 统一显示的平台、模型、生成数量、生成尺寸的变量
  /// 在init时需要重新设置
  ///
  // 所有支持文生图的模型列表(用于下拉的平台和该平台拥有的模型列表也从这里来)
  var llmSpecList = CusLLM_SPEC_LIST.where(
    (spec) => spec.modelType == LLModelType.tti,
  ).toList();

  // 级联选择效果：云平台-模型名
  late ApiPlatform selectedPlatform;

  // 被选中的模型信息
  late CusLLMSpec selectedModelSpec;

  // 被选中的生成尺寸
  String selectedSize = SF_ImageSizeList.first;
  // 被选中的生成数量
  int selectedNum = ImageNumList.first;

// 阿里云有选择的样式编号
  int _selectedStyleIndex = 0;

  ///
  /// 用户输入的提示词
  ///
  final _promptController = TextEditingController();
  final _negativePromptController = TextEditingController();

  // 描述画面的提示词信息。支持中英文，长度不超过500个字符，超过部分会自动截断。
  String prompt = "";
  // 画面中不想出现的内容描述词信息。支持中英文，长度不超过500个字符，超过部分会自动截断。
  String negativePrompt = "";

  ///
  /// 一些tti任务调用中或者结束后的操作
  ///
  // 是否正在生成图片
  bool isGenImage = false;

  // 最后生成的图片地址
  List<String> rstImageUrls = [];

  final DBHelper dbHelper = DBHelper();
  // 最近对话需要的记录历史对话的变量
  List<LlmTtiResult> text2ImageHistory = [];

  @override
  void initState() {
    super.initState();

    // 文生图，初始化固定为sf，模型就每次进来都随机
    selectedPlatform = ApiPlatform.siliconCloud;
    // 2024-07-14 同样的，选中的平台后也随机选择一个模型
    List<CusLLMSpec> models = CusLLM_SPEC_LIST.where((spec) =>
        spec.platform == selectedPlatform &&
        spec.modelType == LLModelType.tti).toList();
    selectedModelSpec = models[Random().nextInt(models.length)];

    // 不同模型支持的尺寸列表不一样，也要更新
    getSizeList();
    selectedSize = getInitialSize();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("当前页面状态--$state");

    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      LoadingOverlay.hide();
    }
  }

  /// 获取文生图的数据
  Future<void> getText2ImageData() async {
    if (isGenImage) {
      return;
    }

    setState(() {
      isGenImage = true;
      // 开始获取图片后，添加遮罩
      LoadingOverlay.show(context);
    });

    print("选择的平台 $selectedPlatform");
    print("选择的模型 ${selectedModelSpec.toRawJson()}");
    print("尺寸 $selectedSize");
    print("张数 $selectedNum");
    print("正向词 $prompt");
    print("消极词 $negativePrompt");
    print("样式(不一样有) <${WANX_StyleMap.values.toList()[_selectedStyleIndex]}>");

    // 请求得到的图片结果
    List<String> imageUrls = [];
    // 如果是阿里云平台
    if (selectedPlatform == ApiPlatform.aliyun) {
      var input = AliyunTtiInput(
        prompt: prompt,
        negativePrompt: negativePrompt,
      );

      var parameters = AliyunTtiParameter(
        style: "<${WANX_StyleMap.values.toList()[_selectedStyleIndex]}>",
        size: selectedSize,
        n: selectedNum,
      );

      // 提交文生图任务
      var jobResp = await commitAliyunText2ImgJob(input, parameters);

      if (!mounted) return;
      if (jobResp.code != null) {
        setState(() {
          isGenImage = false;
          LoadingOverlay.hide();
        });
        return commonExceptionDialog(
          context,
          "发生异常",
          "生成图片出错:${jobResp.message}",
        );
      }

      // 查询文生图任务状态
      var taskId = jobResp.output.taskId;
      AliyunTtiResp? result = await timedText2ImageJobStatus(taskId);

      if (!mounted) return;
      if (result?.code != null) {
        setState(() {
          isGenImage = false;
          LoadingOverlay.hide();
        });

        return commonExceptionDialog(
          context,
          "发生异常",
          "查询文本生图任务进度报错:${jobResp.message}",
        );
      }

      // 得到图片结构，存入变量
      var a = result?.output.results;
      if (a != null && a.isNotEmpty) {
        for (var e in a) {
          if (e.url != null) imageUrls.add(e.url!);
        }
      }
    } else if (selectedPlatform == ApiPlatform.siliconCloud) {
      var a = ComTtiReq.sdLighting(
        prompt: prompt,
        negativePrompt: negativePrompt,
        imageSize: selectedSize,
        batchSize: selectedNum,
      );

      ComTtiResp result = await getSFTtiResp(a, selectedModelSpec.model);

      if (!mounted) return;
      if (result.error != null) {
        EasyLoading.showError("服务器报错:\n${result.error!}");
        setState(() {
          isGenImage = false;
          LoadingOverlay.hide();
        });
      } else {
        if (result.images != null) {
          for (var e in result.images!) {
            imageUrls.add(e.url);
            await MyGetStorage().setText2ImageUrl(e.url);
          }
        }
      }
    } else {
      var result = await getXfyunTtiResp(selectedSize, prompt);
      print(result.toRawJson());

      if (!mounted) return;
      if (result.header?.code != null && result.header?.code != 0) {
        EasyLoading.showError("服务器报错:\n${result.header?.message}");
        setState(() {
          isGenImage = false;
          LoadingOverlay.hide();
        });
      } else {
        var cont = result.payload?.choices?.text?.first.content;
        if (cont != null) {
          var file = await saveTtiBase64ImageToLocal(cont, prefix: "xfyun_");
          print(file);
          imageUrls.add(file.path);
        } else {
          EasyLoading.showError("图片数据为空:\n${result.header?.message}");
          setState(() {
            isGenImage = false;
            LoadingOverlay.hide();
          });
        }
      }
    }

    // 正确获得文生图结果之后，将生成记录保存
    await dbHelper.insertTextToImageResultList([
      LlmTtiResult(
        requestId: const Uuid().v4(),
        prompt: prompt,
        negativePrompt: negativePrompt,
        style: selectedPlatform == ApiPlatform.aliyun
            ? "<${WANX_StyleMap.values.toList()[_selectedStyleIndex]}>"
            : '默认',
        imageUrls: imageUrls,
        gmtCreate: DateTime.now(),
        llmSpec: selectedModelSpec,
      )
    ]);

    if (!mounted) return;
    setState(() {
      rstImageUrls = imageUrls;
      isGenImage = false;
      LoadingOverlay.hide();
    });
  }

  // 查询阿里云文生图任务的状态
  Future<AliyunTtiResp?> timedText2ImageJobStatus(String taskId) async {
    bool isMaxWaitTimeExceeded = false;

    const maxWaitDuration = Duration(minutes: 10);

    Timer timer = Timer(maxWaitDuration, () {
      setState(() {
        isGenImage = false;
        LoadingOverlay.hide();
      });

      EasyLoading.showError(
        "生成图片超时，请稍候重试！",
        duration: const Duration(seconds: 10),
      );

      isMaxWaitTimeExceeded = true;

      print('文生图任务处理耗时，状态查询终止。');
    });

    bool isRequestSuccessful = false;
    while (!isRequestSuccessful && !isMaxWaitTimeExceeded) {
      try {
        var result = await getAliyunText2ImgJobResult(taskId);

        var boolFlag = result.output.taskStatus == "SUCCEEDED" ||
            result.output.taskStatus == "FAILED";

        if (boolFlag) {
          isRequestSuccessful = true;
          print('文生图任务处理完成!');
          timer.cancel();

          return result;
        } else {
          print('文生图任务还在处理中，请稍候重试……');
          await Future.delayed(const Duration(seconds: 5));
        }
      } catch (e) {
        print('发生异常: $e');
        await Future.delayed(const Duration(seconds: 5));
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文本生图'),
        actions: [
          // TextButton(
          //   onPressed: () async {
          //     var a = await getXfyunTtiResp("512x512", "性感美女，全身照");

          //     var cont = a.payload?.choices?.text?.first.content;
          //     if (cont != null) {
          //       var file = await saveTtiBase64ImageToLocal(
          //         cont,
          //         prefix: "xfyun_",
          //       );
          //       print(file);
          //     }

          //     print(a.toRawJson());
          //   },
          //   child: const Text("测试"),
          // ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TtiHistoryScreen(),
                ),
              ).then((value) {
                unfocusHandle();
              });
            },
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      // 设为false，会被遮住一部分，反向词输入框没了
      // 但如果为true，键盘挤压，加上下方固定的图片行，输入框的位置就很小了(16:9的手机屏的话)
      // resizeToAvoidBottomInset: false,
      body: GestureDetector(
        // 允许子控件（如TextField）接收点击事件
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // 点击空白处可以移除焦点，关闭键盘
          unfocusHandle();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// 执行按钮(固定在上方，配置和生成结果可以滚动)
            buildTtiButtonArea(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    /// 文生图配置折叠栏
                    ...buildConfigArea(),

                    /// 文生图的结果
                    if (rstImageUrls.isNotEmpty) ...buildImageResult(),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // 点击删除历史记录的按钮时执行
  void onDelete(LlmTtiResult e) async {
    // 先删除
    await dbHelper.deleteTextToImageResultById(e.requestId);

    // 然后重新查询并更新
    var b = await dbHelper.queryTextToImageResultList();
    setState(() {
      text2ImageHistory = b;
    });
  }

  List<String> getSizeList() {
    if (selectedPlatform == ApiPlatform.siliconCloud) {
      return SF_ImageSizeList;
    }

    if (selectedPlatform == ApiPlatform.xfyun) {
      return XFYUN_ImageSizeList;
    }

    if (selectedPlatform == ApiPlatform.aliyun) {
      return ALIYUN_ImageSizeList;
    }

    // 没有匹配上的，都返回siliconCloud的配置
    return SF_ImageSizeList;
  }

  String getInitialSize() {
    if (selectedPlatform == ApiPlatform.siliconCloud) {
      return SF_ImageSizeList.first;
    }

    if (selectedPlatform == ApiPlatform.xfyun) {
      return XFYUN_ImageSizeList.first;
    }

    if (selectedPlatform == ApiPlatform.aliyun) {
      return ALIYUN_ImageSizeList.first;
    }

    // 没有匹配上的，都返回siliconCloud的配置
    return SF_ImageSizeList.first;
  }

  ///
  /// 页面布局从上往下
  ///
  /// 构建文生图配置和执行按钮区域
  Widget buildTtiButtonArea() {
    return Text2ImageButtonArea(
      title: "文生图配置",
      onReset: () {
        unfocusHandle();
        setState(() {
          prompt = "";
          negativePrompt = "";
          _promptController.text = "";
          _negativePromptController.text = "";
          selectedSize = getInitialSize();
          selectedNum = ImageNumList.first;
        });
      },
      onGenerate: () async {
        unfocusHandle();
        await getText2ImageData();
      },
      canGenerate: prompt.isNotEmpty,
    );
  }

  /// 构建文生图的配置区域
  List<Widget> buildConfigArea() {
    return [
      /// 平台和模型选择
      CusPlatformAndLlmRow(
        initialPlatform: selectedPlatform,
        initialModelSpec: selectedModelSpec,
        llmSpecList: llmSpecList,
        targetModelType: LLModelType.tti,
        showToggleSwitch: false,
        onPlatformOrModelChanged: (ApiPlatform? cp, CusLLMSpec? llmSpec) {
          setState(() {
            selectedPlatform = cp!;
            selectedModelSpec = llmSpec!;
            // 模型可供输出的图片尺寸列表也要更新
            getSizeList();
            selectedSize = getInitialSize();
          });
        },
      ),

      /// 尺寸、张数选择
      SizeAndNumArea(
        selectedSize: selectedSize,
        selectedNum: selectedNum,
        sizeList: getSizeList(),
        numList: ImageNumList,
        onSizeChanged: (val) {
          setState(() {
            selectedSize = val;
          });
        },
        onNumChanged: (val) {
          setState(() {
            selectedNum = val;
          });
        },
      ),

      /// 画风、尺寸、张数选择
      if (selectedModelSpec.cusLlm == CusLLM.aliyun_Wanx_v1_TTI)
        Center(
          child: SizedBox(
            width: 0.8.sw,
            child: StyleGrid(
              imageUrls: WANX_StyleImageList,
              labels: WANX_StyleMap.keys.toList(),
              subLabels: WANX_StyleMap.values.toList(),
              selectedIndex: _selectedStyleIndex,
              onTap: (index) {
                setState(() {
                  _selectedStyleIndex =
                      _selectedStyleIndex == index ? -1 : index;
                });
              },
            ),
          ),
        ),

      /// 正向、反向提示词
      Padding(
        padding: EdgeInsets.all(5.sp),
        child: Column(
          children: [
            PromptInput(
              label: "正向提示词",
              hintText: '描述画面的提示词信息。支持中英文，不超过500个字符。\n比如：“一只展翅翱翔的狸花猫”',
              controller: _promptController,
              onChanged: (text) {
                setState(() {
                  prompt = text.trim();
                });
              },
              isRequired: true,
            ),
            PromptInput(
              label: "反向提示词",
              hintText:
                  '画面中不想出现的内容描述词信息。通过指定用户不想看到的内容来优化模型输出，使模型产生更有针对性和理想的结果。',
              controller: _negativePromptController,
              onChanged: (text) {
                setState(() {
                  negativePrompt = text.trim();
                });
              },
            ),
          ],
        ),
      )
    ];
  }

  /// 构建生成的图片区域
  List<Widget> buildImageResult() {
    return [
      const Divider(),

      /// 文生图结果提示行
      Padding(
        padding: EdgeInsets.all(5.sp),
        child: Text(
          "生成的图片(点击查看、长按保存)",
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
      ),

      /// 图片放一行，最多只有4张
      SizedBox(
        // 最多4张图片，放在一排就好(高度即四分之一的宽度左右)。在最下面留点空即可
        height: 0.25.sw + 5.sp,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.sp),
                child: buildNetworkImageViewGrid(
                  context,
                  rstImageUrls,
                  crossAxisCount: 4,
                  // 模型名有空格或斜线，等后续更新spec，用name来
                  prefix: selectedPlatform.name,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }
}
