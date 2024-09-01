// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:swmate/apis/text_to_image/zhipuai_tti_apis.dart';
import 'package:uuid/uuid.dart';

import '../../../../apis/text_to_image/aliyun_tti_apis.dart';
import '../../../../apis/text_to_image/silicon_flow_tti_apis.dart';
import '../../../../apis/text_to_image/xfyun_tti_aps.dart';
import '../../../../common/llm_spec/cus_llm_model.dart';
import '../../../../common/llm_spec/cus_llm_spec.dart';
import '../../../../common/utils/tools.dart';
import '../../../../models/text_to_image/aliyun_tti_req.dart';
import '../../../../models/text_to_image/aliyun_tti_resp.dart';
import '../../../../models/text_to_image/silicon_flow_tti_req.dart';
import '../../../../models/text_to_image/silicon_flow_ig_resp.dart';
import '../../../../models/text_to_image/zhipu_tti_req.dart';
import '../../../../services/cus_get_storage.dart';
import '../../_componets/loading_overlay.dart';
import '../../_componets/prompt_input.dart';
import '../../_helper/constants.dart';
import '../../_ig_screen_parts/style_grid_selector.dart';
import 'base_ig_screen_state.dart';

class CommonTTIScreen extends StatefulWidget {
  // 可供挑选的模型列表
  final List<CusLLMSpec> llmSpecList;
  // 可供挑选的预设系统角色
  final List<CusSysRoleSpec> cusSysRoleSpecs;

  const CommonTTIScreen({
    super.key,
    required this.llmSpecList,
    required this.cusSysRoleSpecs,
  });

  @override
  State<CommonTTIScreen> createState() => _CommonTTIScreenState();
}

class _CommonTTIScreenState extends BaseIGScreenState<CommonTTIScreen> {
  /// 文生图各个平台支持的尺寸
  @override
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
    if (selectedPlatform == ApiPlatform.zhipu) {
      return ZHIPU_CogViewSizeList;
    }

    // 没有匹配上的，都返回siliconCloud的配置
    return SF_ImageSizeList;
  }

  /// 不同模型有的可能有默认的样式
  @override
  List<String> getStyleList() {
    if (selectedPlatform == ApiPlatform.aliyun) {
      return WANX_StyleMap.keys.toList();
    }

    // 文字变形不需要样式
    return [];
  }

  /// 文生图支持的模型类型
  @override
  LLModelType getModelType() {
    return LLModelType.tti;
  }

  /// 平台和模型切换后的回调
  @override
  cpModelChangedCB(ApiPlatform? cp, CusLLMSpec? llmSpec) {
    super.cpModelChangedCB(cp, llmSpec);
  }

  // 文生图页面的标题
  @override
  String getAppBarTitle() {
    return '文本生图';
  }

  // 文生图历史记录页面的标签关键字
  @override
  String getHistoryLabel() {
    return '文本生图';
  }

  /// (阿里云平台)提交文生图任务
  @override
  Future<AliyunTtiResp?> commitImageGenerationJob() async {
    if (selectedPlatform == ApiPlatform.aliyun) {
      var input = AliyunTtiInput(
        prompt: prompt,
        negativePrompt: negativePrompt,
      );

      // 2024-08-28 除了万相，其他也行？？？
      var parameters = AliyunTtiParameter(
        style: "<${WANX_StyleMap[selectedStyle]}>",
        size: selectedSize,
        n: selectedNum,
        seed: int.tryParse(seedController.text),
        steps: inferenceStepsValue.toInt(),
        guidance: guidanceScaleValue,
      );

      return commitAliyunText2ImgJob(
        selectedModelSpec.model,
        input,
        parameters,
      );
    } else {
      // sf、讯飞直接生成tti结果，所以单独处理
      return null;
    }
  }

  /// (讯飞、sf平台)获取文生图直接是返回的结果
  /// 2024-90-01 智谱cogview也可以是直接的结果
  @override
  Future<List<String>?>? getDirectImageGenerationResult() async {
    // 请求得到的图片结果
    List<String> imageUrls = [];

    if (selectedPlatform == ApiPlatform.siliconCloud) {
      SiliconFlowTtiReq a = SiliconFlowTtiReq.sdX(
        prompt: prompt,
        negativePrompt: negativePrompt,
        imageSize: selectedSize,
        batchSize: selectedNum,
        seed: int.tryParse(seedController.text),
        numInferenceSteps: inferenceStepsValue.toInt(),
        guidanceScale: guidanceScaleValue,
      );

      SiliconFlowIGResp result = await getSFTtiResp(a, selectedModelSpec.model);

      if (!mounted) return null;
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
            await MyGetStorage().setImageGenerationUrl(e.url);
          }
        }
      }
    } else if (selectedPlatform == ApiPlatform.xfyun) {
      var result = await getXfyunTtiResp(selectedSize, prompt);
      print(result.toRawJson());

      if (!mounted) return null;
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
    } else if (selectedPlatform == ApiPlatform.zhipu) {
      CogViewReq a = CogViewReq(
        model: selectedModelSpec.model,
        prompt: prompt,
        size: selectedSize,
        userId: const Uuid().v4(),
      );

      var result = await getZhipuTtiResp(a);
      print(result.toRawJson());

      if (!mounted) return null;
      if (result.error?.code != null) {
        EasyLoading.showError("服务器报错:\n${result.error?.message}");
        setState(() {
          isGenImage = false;
          LoadingOverlay.hide();
        });
      } else {
        // 目前数组中只包含一张图片。
        var cont = (result.data != null && result.data!.isNotEmpty)
            ? result.data?.first.url
            : null;
        if (cont != null) {
          print("xxxxxxxxxxxxxxxxxxxxxxxxx$cont");

          imageUrls.add(cont);
        } else {
          EasyLoading.showError("图片数据为空:\n${result.error?.message}");
          setState(() {
            isGenImage = false;
            LoadingOverlay.hide();
          });
        }
      }
    }
    return imageUrls;
  }

  /// 构建配置区域
  @override
  List<Widget> buildConfigArea({bool? isOnlySize}) {
    return [
      // 平台模型选中和尺寸张数选择结构大体一样的，放在基类
      ...super.buildConfigArea(),

      /// 画风选择
      if (selectedModelSpec.cusLlm == CusLLM.aliyun_Wanx_v1_TTI)
        Center(
          child: SizedBox(
            width: 0.8.sw,
            child: StyleGrid(
              crossAxisCount: 5,
              imageUrls: WANX_StyleImageList,
              labels: WANX_StyleMap.keys.toList(),
              subLabels: WANX_StyleMap.values.toList(),
              selectedIndex: WANX_StyleMap.keys.toList().indexOf(selectedStyle),
              onTap: (index) {
                setState(() {
                  selectedStyle = WANX_StyleMap.keys.toList()[index];
                });
              },
            ),
          ),
        ),

      /// 正向、反向提示词
      Column(
        children: [
          PromptInput(
            label: "正向提示词",
            hintText: '描述画面的提示词信息。不超过500个字符\n(部分模型只支持英文)。\n比如：“一只展翅翱翔的狸花猫”',
            controller: promptController,
            onChanged: (text) {
              setState(() {
                prompt = text.trim();
              });
            },
            isRequired: true,
          ),
          // 2024-09-01 之前的其他不知道，但智谱的文生图这个肯定没用
          if (selectedPlatform != ApiPlatform.zhipu)
            PromptInput(
              label: "反向提示词",
              hintText: '画面中不想出现的内容描述词信息。通过指定用户不想看到的内容来优化输出，使模型产生更有针对性和理想的结果。',
              controller: negativePromptController,
              maxLines: 2,
              minLines: 1,
              onChanged: (text) {
                setState(() {
                  negativePrompt = text.trim();
                });
              },
            ),
        ],
      ),
    ];
  }
}
