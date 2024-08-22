// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../apis/text_to_image/aliyun_tti_apis.dart';
import '../../../../apis/text_to_image/silicon_flow_tti_apis.dart';
import '../../../../apis/text_to_image/xfyun_tti_aps.dart';
import '../../../../common/llm_spec/cus_llm_spec.dart';
import '../../../../common/utils/tools.dart';
import '../../../../models/text_to_image/aliyun_tti_req.dart';
import '../../../../models/text_to_image/aliyun_tti_resp.dart';
import '../../../../models/text_to_image/com_tti_req.dart';
import '../../../../models/text_to_image/com_tti_resp.dart';
import '../../../../services/cus_get_storage.dart';
import '../../_componets/loading_overlay.dart';
import '../../_componets/prompt_input.dart';
import '../../_helper/constants.dart';
import '../../_tti_screen_parts/style_grid_selector.dart';
import 'base_tti_screen_state.dart';

class CommonTTIScreen extends StatefulWidget {
  const CommonTTIScreen({super.key});

  @override
  State<CommonTTIScreen> createState() => _CommonTTIScreenState();
}

class _CommonTTIScreenState extends BaseTTIScreenState<CommonTTIScreen> {
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

    // 没有匹配上的，都返回siliconCloud的配置
    return SF_ImageSizeList;
  }

  /// 文生图各个平台的默认尺寸
  @override
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

  /// 文生图默认选中的平台(sf限时免费的)
  @override
  ApiPlatform getInitialPlatform() {
    return ApiPlatform.siliconCloud;
  }

  /// 文生图支持的模型类型
  @override
  LLModelType getModelType() {
    return LLModelType.tti;
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
    });
  }

  // 文生图页面的标题
  @override
  String getAppBarTitle() {
    return '文本444生图';
  }

  // 文生图历史记录页面的标签关键字
  @override
  String getHistoryLabel() {
    return '文本生图';
  }

  /// (阿里云平台)提交文生图任务
  @override
  Future<AliyunTtiResp?> commitText2ImgJob() async {
    if (selectedPlatform == ApiPlatform.aliyun) {
      var input = AliyunTtiInput(
        prompt: prompt,
        negativePrompt: negativePrompt,
      );

      var parameters = AliyunTtiParameter(
        style: "<${WANX_StyleMap.values.toList()[selectedStyleIndex]}>",
        size: selectedSize,
        n: selectedNum,
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
  @override
  Future<List<String>?>? getDirectTTIResult() async {
    // 请求得到的图片结果
    List<String> imageUrls = [];

    if (selectedPlatform == ApiPlatform.siliconCloud) {
      var a = ComTtiReq.sdLighting(
        prompt: prompt,
        negativePrompt: negativePrompt,
        imageSize: selectedSize,
        batchSize: selectedNum,
      );

      ComTtiResp result = await getSFTtiResp(a, selectedModelSpec.model);

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
            await MyGetStorage().setText2ImageUrl(e.url);
          }
        }
      }
    } else {
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
    }
    return imageUrls;
  }

  /// 构建配置区域
  @override
  List<Widget> buildConfigArea() {
    return [
      // 平台模型选中和尺寸张数选择结构大体一样的，放在基类
      ...super.buildConfigArea(),

      /// 画风选择
      if (selectedModelSpec.cusLlm == CusLLM.aliyun_Wanx_v1_TTI)
        Center(
          child: SizedBox(
            width: 0.8.sw,
            child: StyleGrid(
              imageUrls: WANX_StyleImageList,
              labels: WANX_StyleMap.keys.toList(),
              subLabels: WANX_StyleMap.values.toList(),
              selectedIndex: selectedStyleIndex,
              onTap: (index) {
                setState(() {
                  selectedStyleIndex = selectedStyleIndex == index ? -1 : index;
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
              hintText:
                  '画面中不想出现的内容描述词信息。通过指定用户不想看到的内容来优化模型输出，使模型产生更有针对性和理想的结果。',
              controller: negativePromptController,
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
}
