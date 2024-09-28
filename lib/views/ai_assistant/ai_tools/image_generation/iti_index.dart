import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../apis/image_to_image/silicon_flow_iti_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/llm_spec/cus_llm_model.dart';
import '../../../../common/llm_spec/cus_llm_spec.dart';
import '../../../../common/utils/tools.dart';
import '../../../../models/image_to_image/silicon_flow_iti_req.dart';
import '../../../../models/text_to_image/aliyun_tti_resp.dart';
import '../../../../models/text_to_image/silicon_flow_ig_resp.dart';
import '../../../../services/cus_get_storage.dart';
import '../../_componets/loading_overlay.dart';
import '../../_componets/prompt_input.dart';
import '../../_helper/constants.dart';

import 'base_ig_screen_state.dart';

///
/// sf平台中图生图页面(还没有其他平台免费的图生图，阿里云图片要先上传oss，不能传base64,所以先不用)
/// 和图生图的有十分相识，所以继承图生图页面base页面
///
class CommonITIScreen extends StatefulWidget {
  // 可供挑选的模型列表
  final List<CusLLMSpec> llmSpecList;
  // 可供挑选的预设系统角色
  final List<CusSysRoleSpec> cusSysRoleSpecs;

  const CommonITIScreen({
    super.key,
    required this.llmSpecList,
    required this.cusSysRoleSpecs,
  });

  @override
  State<CommonITIScreen> createState() => _CommonITIScreenState();
}

class _CommonITIScreenState extends BaseIGScreenState<CommonITIScreen> {
  // 选择的图片文件
  File? selectedImage;
  // 如果是InstantID 需要传2个图片:face 和 pose
  File? selectedFaceImage;
  File? selectedPoseImage;

  /// 图生图各个平台支持的尺寸
  @override
  List<String> getSizeList() {
    return SF_ITISizeList;
  }

  /// 不同模型有的可能有默认的样式
  @override
  List<String> getStyleList() {
    // 文字变形不需要样式
    return [];
  }

  /// 图生图支持的模型类型
  @override
  LLModelType getModelType() {
    return LLModelType.iti;
  }

  /// 平台和模型切换后的回调
  @override
  cpModelChangedCB(ApiPlatform? cp, CusLLMSpec? llmSpec) {
    super.cpModelChangedCB(cp, llmSpec);
  }

  // 图生图页面的标题
  @override
  String getAppBarTitle() {
    return '图片生图';
  }

  // 图生图历史记录页面的标签关键字
  @override
  String getHistoryLabel() {
    return '图片生图';
  }

  @override
  resetConfig() {
    super.resetConfig();
    setState(() {
      selectedImage = null;
      selectedFaceImage = null;
      selectedPoseImage = null;
    });
  }

  /// 是否可以点击生成按钮
  /// 总得来说图片和提示词不可为空，样式、尺寸等有默认值时不会为空的
  @override
  bool isCanGenerate() {
    // 创意文字为空，则肯定不能点击生成按钮
    if (prompt.isEmpty) {
      return false;
    }

    // 文字变形默认prompt必传的
    return prompt.isNotEmpty;
  }

  /// 提交图生图任务(暂无)
  @override
  Future<AliyunTtiResp?> commitImageGenerationJob() async {
    return null;
  }

  /// (sf平台)获取图生图直接是返回的结果
  @override
  Future<List<String>?>? getDirectImageGenerationResult() async {
    // 请求得到的图片结果
    List<String> imageUrls = [];

    // 图片转为base64
    String? imageBase64String = await getImageBase64String(selectedImage);

    // 不同的模型参数不完全相同，默认就是SD这样必要的参数
    SiliconflowItiReq a = SiliconflowItiReq.sd(
      prompt: prompt,
      negativePrompt: negativePrompt,
      image: imageBase64String,
      imageSize: selectedSize,
      batchSize: selectedNum,
      numInferenceSteps: inferenceStepsValue.toInt(),
      guidanceScale: guidanceScaleValue,
    );

    SiliconFlowIGResp result =
        await getSFImageToImageResp(a, selectedModelSpec.model);

    if (!mounted) return null;
    if (result.error != null || result.code != null) {
      setState(() {
        isGenImage = false;
        LoadingOverlay.hide();
      });
      commonHintDialog(
        context,
        "错误提醒",
        "API调用报错:\n${result.error ?? result.message}",
      );
    } else {
      if (result.images != null) {
        for (var e in result.images!) {
          imageUrls.add(e.url);
          await MyGetStorage().setImageGenerationUrl(e.url);
        }
      }
    }

    return imageUrls;
  }

  /// 构建配置区域
  @override
  List<Widget> buildConfigArea({bool? isOnlySize}) {
    return [
      ...super.buildConfigArea(),

      /// 尺寸、张数选择

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
