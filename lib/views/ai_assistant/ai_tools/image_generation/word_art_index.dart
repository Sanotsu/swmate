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
  // 可供挑选的模型列表
  final List<CusLLMSpec> llmSpecList;
  // 可供挑选的预设系统角色
  final List<CusSysRoleSpec> cusSysRoleSpecs;

  const AliyunWordArtScreen({
    super.key,
    required this.llmSpecList,
    required this.cusSysRoleSpecs,
  });

  @override
  State<AliyunWordArtScreen> createState() => _AliyunWordArtScreenState();
}

class _AliyunWordArtScreenState extends BaseIGScreenState<AliyunWordArtScreen> {
  // 艺术字体选中的字体名称和样式索引
  String selectedFontName = "";

  // 用于创作的文字控制器
  final _textContentController = TextEditingController();
  // 用于创作的文字(暂时不使用参考图了)
  String textContent = "";

  @override
  void initState() {
    super.initState();

    setState(() {
      selectedFontName = getInitialFontName();
    });
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
  @override
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

  // 创意文字不需要高级选项
  @override
  bool isShowAdvancedOptions() => false;

  /// 锦书创意文字支持的模型类型
  @override
  LLModelType getModelType() {
    return LLModelType.tti_word;
  }

  /// 平台和模型切换后的回调
  @override
  cpModelChangedCB(ApiPlatform? cp, CusLLMSpec? llmSpec) {
    super.cpModelChangedCB(cp, llmSpec);
    setState(() {
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

      /// 2024-09-04
      /// 图片纹理和百家姓生成都没有指定的尺寸，就文字变形可选{"1280x720", "720x1280", "1024x1024"}
      /// 所以锦书就不显示尺寸下拉框，只显示张数张数选择
      SizedBox(
        height: 32.sp,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(width: 5.sp),
            Expanded(
              child: SizeAndNumSelector(
                label: "数量",
                selectedValue: selectedNum,
                items: ImageNumList,
                onChanged: (val) => setState(() => selectedNum = val),
                itemToString: (item) => item.toString(),
              ),
            ),
            SizedBox(width: 5.sp),
          ],
        ),
      ),

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
