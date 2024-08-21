// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import '../../../../apis/text_to_image/aliyun_tti_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/llm_spec/cus_llm_spec.dart';

import '../../../../common/utils/db_tools/db_helper.dart';
import '../../../../models/text_to_image/aliyun_tti_req.dart';
import '../../../../models/text_to_image/aliyun_tti_resp.dart';
import '../../../../models/text_to_image/com_tti_state.dart';
import '../../_componets/cus_platform_and_llm_row.dart';
import '../../_componets/prompt_input.dart';
import '../../_tti_screen_parts/tti_button_row_area.dart';
import '../../_helper/constants.dart';
import '../../_componets/loading_overlay.dart';
import '../../_tti_screen_parts/size_and_num_selector.dart';
import '../../_tti_screen_parts/tti_history_screen.dart';

class AliyunWordArtScreen extends StatefulWidget {
  const AliyunWordArtScreen({super.key});

  @override
  State<AliyunWordArtScreen> createState() => _AliyunWordArtScreenState();
}

class _AliyunWordArtScreenState extends State<AliyunWordArtScreen>
    with WidgetsBindingObserver {
  ///
  /// 统一显示的平台、模型、生成数量、生成尺寸的变量
  /// 在init时需要重新设置
  ///
  // 所有支持文生图的模型列表(用于下拉的平台和该平台拥有的模型列表也从这里来)
  var llmSpecList = CusLLM_SPEC_LIST.where(
    (spec) => spec.modelType == LLModelType.tti_word,
  ).toList();

  // 级联选择效果：云平台-模型名
  late ApiPlatform selectedPlatform;

  // 被选中的模型信息
  late CusLLMSpec selectedModelSpec;

  // 被选中的生成尺寸
  String selectedSize = WordArt_outputImageRatioList.first;
  // 被选中的生成数量
  int selectedNum = ImageNumList.first;

  // 艺术字体选中的字体名称和样式索引
  String selectedStyle = "";
  String selectedFontName = "";

  ///
  /// 用户输入的提示词
  ///
  final _textContentController = TextEditingController();
  final _promptController = TextEditingController();

  // 用于创作的文字(暂时不使用参考图了)
  String textContent = "";
  // 描述画面的提示词信息。支持中英文，长度不超过500个字符，超过部分会自动截断。
  String prompt = "";

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
    selectedPlatform = ApiPlatform.aliyun;
    // 2024-07-14 同样的，选中的平台后也随机选择一个模型
    List<CusLLMSpec> models = CusLLM_SPEC_LIST.where((spec) =>
        spec.platform == selectedPlatform &&
        spec.modelType == LLModelType.tti_word).toList();
    selectedModelSpec = models[Random().nextInt(models.length)];

    // 不同模型支持的尺寸列表不一样，也要更新
    getSizeList();
    selectedSize = getInitialSize();

    // 文字纹理和百家姓都有预设样式和自定义样式，当选中了自定义样式时，可以选择自选字体
    // 为了简单一点，默认选中预设的样式
    getStyleList();
    selectedStyle = getInitialStyle();

    // 如果是自定义样式，则需要获取字体列表
    getFontNameList();
    selectedFontName = getInitialFontName();

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
    print("样式(不一样有) <$selectedStyle>");

    // 请求得到的图片结果
    List<String> imageUrls = [];

    AliyunTtiInput input;
    AliyunTtiParameter parameters;
    // 文字纹理
    if (selectedModelSpec.cusLlm == CusLLM.aliyun_Wordart_Texture_TTI_WORD) {
      input = AliyunTtiInput.wordArtTexture(
        // 自定义样式和预设都必须提供prompt
        prompt: prompt,
        text: AliyunTtiText.wordArtTexture(
          textContent: textContent,
          fontName: WordArt_Texture_FontNameMap[selectedFontName],
        ),
        textureStyle: WordArt_Texture_StyleMap[selectedStyle],
      );

      parameters = AliyunTtiParameter.wordArtTexture(
        n: selectedNum,
      );
    } else if (selectedModelSpec.cusLlm ==
        CusLLM.aliyun_Wordart_Surnames_TTI_WORD) {
      // 百家姓生成
      input = AliyunTtiInput.wordArtSurnames(
        surname: textContent,
        // 只有时自定义样式时，才允许提供prompt；预设样式不允许提供prompt
        prompt: isDiyStyle() ? prompt : null,
        // 如果样式不是diy，则不能提供text了
        style: WordArt_Surnames_StyleMap[selectedStyle],
        text: WordArt_Surnames_StyleMap[selectedStyle] == 'diy'
            ? AliyunTtiText.wordArtSurnames(
                fontName: WordArt_Surnames_FontNameMap[selectedFontName],
              )
            : null,
      );

      print("百家姓的input ${input.toRawJson()}");

      parameters = AliyunTtiParameter.wordArtSurnames(
        n: selectedNum,
      );
    } else {
      // 文字变形
      input = AliyunTtiInput.wordArtSemantic(
        prompt: prompt,
        text: textContent,
      );

      parameters = AliyunTtiParameter.wordArtSemantic(
        fontName: WordArt_Texture_FontNameMap[selectedFontName],
        n: selectedNum,
      );
    }

    // 提交文生图任务
    var jobResp = await commitAliyunWordartJob(
      selectedModelSpec.model,
      input,
      parameters,
      type: selectedModelSpec.cusLlm == CusLLM.aliyun_Wordart_Texture_TTI_WORD
          ? "texture"
          : selectedModelSpec.cusLlm == CusLLM.aliyun_Wordart_Semantic_TTI_WORD
              ? "semantic"
              : "surnames",
    );

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
        if (e.pngUrl != null) imageUrls.add(e.pngUrl!);
        // 2024-08-21 svg的预览报错？？？
        // if (e.svgUrl != null) imageUrls.add(e.svgUrl!);
      }
    }

    // 正确获得文生图结果之后，将生成记录保存
    await dbHelper.insertTextToImageResultList([
      LlmTtiResult(
        requestId: const Uuid().v4(),
        prompt: "[$textContent] $prompt",
        negativePrompt: "",
        style:
            selectedPlatform == ApiPlatform.aliyun ? "<$selectedStyle>" : '默认',
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
        title: const Text('创意文字'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TtiHistoryScreen(
                    lable: '创意文字',
                    modelType: LLModelType.tti_word,
                  ),
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

  List<String> getFontNameList() {
    if (selectedModelSpec.cusLlm == CusLLM.aliyun_Wordart_Texture_TTI_WORD) {
      return WordArt_Texture_FontNameMap.keys.toList();
    }

    if (selectedModelSpec.cusLlm == CusLLM.aliyun_Wordart_Surnames_TTI_WORD) {
      return WordArt_Surnames_FontNameMap.keys.toList();
    }

    return WordArt_Texture_FontNameMap.keys.toList();
  }

  String getInitialFontName() {
    if (selectedModelSpec.cusLlm == CusLLM.aliyun_Wordart_Texture_TTI_WORD) {
      return WordArt_Texture_FontNameMap.keys.toList().first;
    }

    if (selectedModelSpec.cusLlm == CusLLM.aliyun_Wordart_Surnames_TTI_WORD) {
      return WordArt_Surnames_FontNameMap.keys.toList().first;
    }

    return WordArt_Texture_FontNameMap.keys.toList().first;
  }

  List<String> getStyleList() {
    if (selectedModelSpec.cusLlm == CusLLM.aliyun_Wordart_Texture_TTI_WORD) {
      return WordArt_Texture_StyleMap.keys.toList();
    }

    if (selectedModelSpec.cusLlm == CusLLM.aliyun_Wordart_Surnames_TTI_WORD) {
      return WordArt_Surnames_StyleMap.keys.toList();
    }

    // 文字变形不需要样式
    // return WordArt_Texture_StyleMap.keys.toList();
    return [];
  }

  String getInitialStyle() {
    if (selectedModelSpec.cusLlm == CusLLM.aliyun_Wordart_Texture_TTI_WORD) {
      // 默认选中第4个(因为前面3个时自定义样式，可以传参考图、字体等内容)
      return WordArt_Texture_StyleMap.keys.toList()[3];
    }

    if (selectedModelSpec.cusLlm == CusLLM.aliyun_Wordart_Surnames_TTI_WORD) {
      // 同上
      return WordArt_Surnames_StyleMap.keys.toList()[2];
    }

    // 文字变形不需要样式
    // return WordArt_Texture_StyleMap.keys.toList().first;
    return '';
  }

  List<String> getSizeList() {
    return WordArt_outputImageRatioList;
  }

  String getInitialSize() {
    return WordArt_outputImageRatioList.first;
  }

  /// 文字纹理和百家姓生成，在选中了“预设风格”时，
  /// 不支持输入提示词（input.prompt）和字体类型（input.text.ttf_url和input.text.font_name）
  /// 则不显示prompt输入框和字体选择框
  bool isDiyStyle() {
    // 如果是文字纹理，自定义样式和预设都必须提供prompt
    // if (selectedModelSpec.cusLlm == CusLLM.aliyun_Wordart_Texture_TTI_WORD) {
    //   return ['立体材质', '场景融合', '光影特效'].contains(selectedStyle);
    // }
    if (selectedModelSpec.cusLlm == CusLLM.aliyun_Wordart_Surnames_TTI_WORD) {
      return ['自定义'].contains(selectedStyle);
    }

    // 文字变形默认prompt必传的
    return true;
  }

  bool isCanGenerate() {
    // 创意文字为空，则肯定不能点击生成按钮
    if (textContent.isEmpty) {
      return false;
    }

    // 如果是文字纹理，自定义样式和预设都必须提供prompt
    if (selectedModelSpec.cusLlm == CusLLM.aliyun_Wordart_Texture_TTI_WORD) {
      return prompt.isNotEmpty;
    }

    // 如果是百家姓，且是“自定义风格，那么提示词不能为空;其他预设风格，则prompt输入了也无效
    if (selectedModelSpec.cusLlm == CusLLM.aliyun_Wordart_Surnames_TTI_WORD) {
      if (['自定义'].contains(selectedStyle)) {
        return prompt.isNotEmpty;
      } else {
        return true;
      }
    }

    // 文字变形默认prompt必传的
    return prompt.isNotEmpty;
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
          _promptController.text = "";
          _textContentController.text = "";
          selectedSize = getInitialSize();
          selectedNum = ImageNumList.first;
        });
      },
      onGenerate: () async {
        unfocusHandle();
        await getText2ImageData();
      },
      canGenerate: isCanGenerate(),
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
        targetModelType: LLModelType.tti_word,
        showToggleSwitch: false,
        onPlatformOrModelChanged: (ApiPlatform? cp, CusLLMSpec? llmSpec) {
          setState(() {
            selectedPlatform = cp!;
            selectedModelSpec = llmSpec!;
            // 模型可供输出的图片尺寸列表、样式、预选字体也要更新
            getSizeList();
            selectedSize = getInitialSize();

            getStyleList();
            selectedStyle = getInitialStyle();

            getFontNameList();
            selectedFontName = getInitialFontName();

            isDiyStyle();
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
      SizedBox(height: 5.sp),

      SizedBox(
        height: 32.sp,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.sp),
          child: Row(
            children: [
              // 文字变形不支持样式
              if (selectedModelSpec.cusLlm !=
                  CusLLM.aliyun_Wordart_Semantic_TTI_WORD)
                Expanded(
                  child: SizeAndNumSelector(
                    label: "样式",
                    selectedValue: selectedStyle,
                    items: getStyleList(),
                    onChanged: (val) {
                      setState(() {
                        selectedStyle = val;
                        isDiyStyle();
                      });
                    },
                    itemToString: (item) => item.toString(),
                  ),
                ),
              if (isDiyStyle() &&
                  selectedModelSpec.cusLlm !=
                      CusLLM.aliyun_Wordart_Semantic_TTI_WORD)
                SizedBox(width: 5.sp),
              if (isDiyStyle())
                Expanded(
                  child: SizeAndNumSelector(
                    label: "字体",
                    // 只有时文字纹理时，自定义时，字体太大显示不佳需要缩小，其他其他不需要
                    labelSize: (selectedModelSpec.cusLlm ==
                            CusLLM.aliyun_Wordart_Texture_TTI_WORD)
                        ? 12.sp
                        : 15.sp,
                    selectedValue: selectedFontName,
                    items: getFontNameList(),
                    onChanged: (val) {
                      setState(() {
                        selectedFontName = val;
                      });
                    },
                    itemToString: (item) => item.toString(),
                  ),
                ),
            ],
          ),
        ),
      ),

      /// 正向、反向提示词
      Padding(
        padding: EdgeInsets.all(5.sp),
        child: Column(
          children: [
            PromptInput(
              label: "创意文字",
              hintText: selectedModelSpec.cusLlm ==
                      CusLLM.aliyun_Wordart_Texture_TTI_WORD
                  ? '需要创作的艺术字，支持1-6个字符'
                  : selectedModelSpec.cusLlm ==
                          CusLLM.aliyun_Wordart_Surnames_TTI_WORD
                      ? '需要创作的姓氏，支持1-2个字符。例如‘杨’、‘诸葛’'
                      : "需要创作的艺术字",
              controller: _textContentController,
              isRequired: true,
              onChanged: (text) {
                setState(() {
                  textContent = text.trim();
                });
              },
            ),
            if (isDiyStyle())
              PromptInput(
                label: "正向提示词",
                hintText: selectedModelSpec.cusLlm ==
                        CusLLM.aliyun_Wordart_Surnames_TTI_WORD
                    ? '期望图片创意样式的描述提示词，长度小于1000。\n比如：“古风，山水画”'
                    : selectedModelSpec.cusLlm ==
                            CusLLM.aliyun_Wordart_Texture_TTI_WORD
                        ? "期望文字纹理创意样式的描述提示词，长度小于200。\n比如“水果，蔬菜”"
                        : "期望文字变形创意样式的描述提示词，长度小于200。\n比如“春暖花开、山峦叠嶂、漓江蜿蜒、岩石奇秀”",
                controller: _promptController,
                isRequired: true,
                onChanged: (text) {
                  setState(() {
                    prompt = text.trim();
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
