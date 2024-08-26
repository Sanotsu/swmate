// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../apis/text_to_image/aliyun_tti_apis.dart';
import '../../../../common/llm_spec/cus_llm_model.dart';
import '../../../../common/llm_spec/cus_llm_spec.dart';
import '../../../../models/text_to_image/aliyun_tti_req.dart';
import '../../../../models/text_to_image/aliyun_tti_resp.dart';
import '../../_componets/prompt_input.dart';
import '../../_helper/constants.dart';
import '../../_ig_screen_parts/size_and_num_selector.dart';
import 'base_ig_screen_state.dart';

class AliyunWordArtScreen extends StatefulWidget {
  const AliyunWordArtScreen({super.key});

  @override
  State<AliyunWordArtScreen> createState() => _AliyunWordArtScreenState();
}

class _AliyunWordArtScreenState extends BaseIGScreenState<AliyunWordArtScreen> {
  // 艺术字体选中的字体名称和样式索引
  String selectedStyle = "";
  String selectedFontName = "";

  ///
  /// 用户输入的提示词
  ///
  final _textContentController = TextEditingController();

  // 用于创作的文字(暂时不使用参考图了)
  String textContent = "";

  // 基类初始话成功了，还要子类也初始化成功，才能渲染页面
  bool isWordArtInited = false;
  Timer? _timer;
  double _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    wordArtInit();
  }

  // 等待父类初始化，父类初始化完了，才初始化子类，直到超时取消
  wordArtInit() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds += 0.1;
      });

      if (isInited) {
        selectedSize = WordArt_outputImageRatioList.first;
        selectedStyle = getInitialStyle();
        selectedFontName = getInitialFontName();

        if (!mounted) return;
        setState(() {
          isWordArtInited = true;
        });

        _timer?.cancel();
      }

      if (_elapsedSeconds >= 60) {
        _timer?.cancel();
      }
    });
  }

  /// 锦书创意文字支持的尺寸
  @override
  List<String> getSizeList() {
    return WordArt_outputImageRatioList;
  }

  /// 锦书创意文字默认的尺寸
  @override
  String getInitialSize() {
    return WordArt_outputImageRatioList.first;
  }

  /// 锦书创意文字支持的自定义字体名称列表
  List<String> getFontNameList() {
    if (selectedModelSpec.cusLlm == CusLLM.aliyun_Wordart_Texture_TTI_WORD) {
      return WordArt_Texture_FontNameMap.keys.toList();
    }

    if (selectedModelSpec.cusLlm == CusLLM.aliyun_Wordart_Surnames_TTI_WORD) {
      return WordArt_Surnames_FontNameMap.keys.toList();
    }

    return WordArt_Texture_FontNameMap.keys.toList();
  }

  /// 锦书创意文字默认的字体
  String getInitialFontName() {
    if (selectedModelSpec.cusLlm == CusLLM.aliyun_Wordart_Texture_TTI_WORD) {
      return WordArt_Texture_FontNameMap.keys.toList().first;
    }

    if (selectedModelSpec.cusLlm == CusLLM.aliyun_Wordart_Surnames_TTI_WORD) {
      return WordArt_Surnames_FontNameMap.keys.toList().first;
    }

    return WordArt_Texture_FontNameMap.keys.toList().first;
  }

  /// 锦书创意文字支持的预设样式(自定义样式和模型预设样式)
  List<String> getStyleList() {
    if (selectedModelSpec.cusLlm == CusLLM.aliyun_Wordart_Texture_TTI_WORD) {
      return WordArt_Texture_StyleMap.keys.toList();
    }

    if (selectedModelSpec.cusLlm == CusLLM.aliyun_Wordart_Surnames_TTI_WORD) {
      return WordArt_Surnames_StyleMap.keys.toList();
    }

    // 文字变形不需要样式
    return [];
  }

  /// 锦书创意文字默认的样式
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
    return '';
  }

  /// 是否是自定义样式
  /// 百家姓自定义样式的话，不允许传prompt；其他两个自定义也必传
  bool isDiyStyle() {
    if (selectedModelSpec.cusLlm == CusLLM.aliyun_Wordart_Surnames_TTI_WORD) {
      return ['自定义'].contains(selectedStyle);
    }

    // 文字变形默认prompt必传的
    return true;
  }

  /// 是否可以点击生成按钮
  /// 文字纹理、文字变形、百家姓可以点击生成按钮的条件各不相同
  @override
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

  /// 锦书创意文字默认的平台(其实也只有阿里云)
  @override
  ApiPlatform getInitialPlatform() {
    return ApiPlatform.aliyun;
  }

  /// 锦书创意文字支持的模型类型
  @override
  LLModelType getModelType() {
    return LLModelType.tti_word;
  }

  /// 平台和模型切换后的回调
  @override
  cpModelChangedCB(ApiPlatform? cp, CusLLMSpec? llmSpec) {
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
  }

  // 锦书都是提交job查询job状态，所以这个重载返回null，供基类条件判断
  @override
  Future<List<String>?>? getDirectImageGenerationResult() => null;

  // 锦书创意文字页面的标题
  @override
  String getAppBarTitle() {
    return '创意文字';
  }

  // 锦书创意文字历史记录页面的标签关键字
  @override
  String getHistoryLabel() {
    return '创意文字';
  }

  /// (阿里云锦书)提交文生图任务
  @override
  Future<AliyunTtiResp> commitImageGenerationJob() async {
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

    return commitAliyunWordartJob(
      selectedModelSpec.model,
      input,
      parameters,
      type: selectedModelSpec.cusLlm == CusLLM.aliyun_Wordart_Texture_TTI_WORD
          ? "texture"
          : selectedModelSpec.cusLlm == CusLLM.aliyun_Wordart_Semantic_TTI_WORD
              ? "semantic"
              : "surnames",
    );
  }

  /// 构建配置区域
  @override
  List<Widget> buildConfigArea() {
    return [
      ...super.buildConfigArea(),
      if (isInited && isWordArtInited)
        Container(
          height: 32.sp,
          margin: EdgeInsets.fromLTRB(5.sp, 5.sp, 5.sp, 0),
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

      /// 正向、反向提示词
      if (isInited && isWordArtInited)
        Column(
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
                controller: promptController,
                isRequired: true,
                onChanged: (text) {
                  setState(() {
                    prompt = text.trim();
                  });
                },
              ),
          ],
        )
    ];
  }
}
