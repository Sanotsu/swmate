// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../apis/image_to_image/silicon_flow_iti_apis.dart';
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
import '../../_ig_screen_parts/image_pick_and_view_area.dart';
import '../../_ig_screen_parts/size_and_num_selector.dart';
import 'base_ig_screen_state.dart';

///
/// sf平台中图生图页面(还没有其他平台免费的图生图，阿里云图片要先上传oss，不能传base64,所以先不用)
/// 和图生图的有十分相识，所以继承图生图页面base页面
///
class CommonITIScreen extends StatefulWidget {
  const CommonITIScreen({super.key});

  @override
  State<CommonITIScreen> createState() => _CommonITIScreenState();
}

class _CommonITIScreenState extends BaseIGScreenState<CommonITIScreen> {
  // 选择的图片文件
  File? selectedImage;
  // 如果是InstantID 需要传2个图片:face 和 pose
  File? selectedFaceImage;
  File? selectedPoseImage;

  // 被选中的风格
  String selectedStyle = "";

  // 基类初始话成功了，还要子类也初始化成功，才能渲染页面
  bool isItiInited = false;
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    itiInit();
  }

  // 等待父类初始化，父类初始化完了，才初始化子类，直到超时取消
  itiInit() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
      });

      if (isInited) {
        selectedSize = getInitialSize();
        selectedStyle = getInitialStyle();

        if (!mounted) return;
        setState(() {
          isItiInited = true;
        });
        _timer?.cancel();
      }

      if (_elapsedSeconds >= 60) {
        _timer?.cancel();
      }
    });
  }

  /// 图生图各个平台支持的尺寸
  @override
  List<String> getSizeList() {
    return SF_ITISizeList;
  }

  /// 图生图各个平台的默认尺寸
  @override
  String getInitialSize() {
    return SF_ITISizeList.first;
  }

  /// 不同模型有的可能有默认的样式
  List<String> getStyleList() {
    if (selectedModelSpec.cusLlm == CusLLM.siliconCloud_PhotoMaker_ITI) {
      return PhotoMaker_StyleMap.keys.toList();
    }

    if (selectedModelSpec.cusLlm == CusLLM.siliconCloud_InstantID_ITI) {
      return InstantID_StyleMap.keys.toList();
    }

    // 文字变形不需要样式
    return [];
  }

  /// 不同模型有的可能有默认的样式
  String getInitialStyle() {
    if (selectedModelSpec.cusLlm == CusLLM.siliconCloud_PhotoMaker_ITI) {
      return PhotoMaker_StyleMap.keys.toList().first;
    }

    if (selectedModelSpec.cusLlm == CusLLM.siliconCloud_InstantID_ITI) {
      return InstantID_StyleMap.keys.toList().first;
    }

    // 文字变形不需要样式
    return '';
  }

  /// 图生图默认选中的平台(sf限时免费的)
  @override
  ApiPlatform getInitialPlatform() {
    return ApiPlatform.siliconCloud;
  }

  /// 图生图支持的模型类型
  @override
  LLModelType getModelType() {
    return LLModelType.iti;
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
    });
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

    // 如果是文字纹理，自定义样式和预设都必须提供prompt
    if (selectedModelSpec.cusLlm != CusLLM.siliconCloud_InstantID_ITI) {
      return selectedImage != null;
    }

    // 如果是百家姓，且是“自定义风格，那么提示词不能为空;其他预设风格，则prompt输入了也无效
    if (selectedModelSpec.cusLlm == CusLLM.siliconCloud_InstantID_ITI) {
      return selectedFaceImage != null && selectedPoseImage != null;
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
    // var tempBase64Str = base64Encode((await selectedImage!.readAsBytes()));
    // String? imageBase64String = "data:image/png;base64,$tempBase64Str";

    String? imageBase64String = await getImageBase64String(selectedImage);
    String? faceImageBase64String =
        await getImageBase64String(selectedFaceImage);
    String? poseImageBase64String =
        await getImageBase64String(selectedPoseImage);

    // 不同的模型参数不完全相同
    SiliconflowItiReq a;

    if (selectedModelSpec.cusLlm == CusLLM.siliconCloud_PhotoMaker_ITI) {
      a = SiliconflowItiReq.photoMaker(
        prompt: prompt,
        negativePrompt: negativePrompt,
        image: imageBase64String,
        imageSize: selectedSize,
        batchSize: selectedNum,
        styleName: PhotoMaker_StyleMap[selectedStyle],
      );
    } else if (selectedModelSpec.cusLlm ==
            CusLLM.siliconCloud_StableDiffusionXL_ITI ||
        selectedModelSpec.cusLlm ==
            CusLLM.siliconCloud_StableDiffusion2p1_ITI ||
        selectedModelSpec.cusLlm ==
            CusLLM.siliconCloud_StableDiffusionXL_Lighting_ITI) {
      a = SiliconflowItiReq.sd(
        prompt: prompt,
        negativePrompt: negativePrompt,
        image: imageBase64String,
        imageSize: selectedSize,
        batchSize: selectedNum,
        numInferenceSteps: selectedModelSpec.cusLlm ==
                CusLLM.siliconCloud_StableDiffusionXL_Lighting_ITI
            ? 4
            : 20,
        guidanceScale: selectedModelSpec.cusLlm ==
                CusLLM.siliconCloud_StableDiffusionXL_Lighting_ITI
            ? 1
            : 7.5,
      );
    } else if (selectedModelSpec.cusLlm == CusLLM.siliconCloud_InstantID_ITI) {
      a = SiliconflowItiReq.instantID(
        faceImage: faceImageBase64String,
        poseImage: poseImageBase64String,
        prompt: prompt,
        negativePrompt: negativePrompt,
        styleName: InstantID_StyleMap[selectedStyle],
      );
    } else {
      // 默认就是SD这样必要的参数
      a = SiliconflowItiReq.sd(
        prompt: prompt,
        negativePrompt: negativePrompt,
        image: imageBase64String,
        imageSize: selectedSize,
        batchSize: selectedNum,
      );
    }

    SiliconFlowIGResp result =
        await getSFImageToImageResp(a, selectedModelSpec.model);

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

    return imageUrls;
  }

  /// 构建配置区域
  @override
  List<Widget> buildConfigArea() {
    return [
      // 平台模型选中和尺寸张数选择结构大体一样的，放在基类
      ...super.buildConfigArea(),

      if (isInited &&
          isItiInited &&
          (selectedModelSpec.cusLlm == CusLLM.siliconCloud_PhotoMaker_ITI ||
              selectedModelSpec.cusLlm == CusLLM.siliconCloud_InstantID_ITI))
        Container(
          margin: EdgeInsets.fromLTRB(5.sp, 5.sp, 5.sp, 0),
          height: 32.sp,
          child: Row(
            children: [
              Expanded(
                child: SizeAndNumSelector(
                  label: "样式",
                  selectedValue: selectedStyle,
                  items: getStyleList(),
                  onChanged: (val) {
                    setState(() {
                      selectedStyle = val;
                    });
                  },
                  itemToString: (item) => item.toString(),
                ),
              ),
            ],
          ),
        ),

      // ？？？2024-08-23 实测腾讯的photoMaker会报500错误，无法解决
      // 正常的图生图，只需要一个参考图
      if (isInited &&
          isItiInited &&
          selectedModelSpec.cusLlm != CusLLM.siliconCloud_InstantID_ITI)
        SizedBox(
          height: 100.sp,
          child: ImagePickAndViewArea(
            imageSelectedHandle: _pickImage,
            imageClearHandle: () => setState(() => selectedImage = null),
            selectedImage: selectedImage,
          ),
        ),

      // InstantID 需要传两个图片，和其他的不一样
      if (isInited &&
          isItiInited &&
          selectedModelSpec.cusLlm == CusLLM.siliconCloud_InstantID_ITI)
        SizedBox(
          height: 100.sp,
          child: Row(
            children: [
              Expanded(
                child: ImagePickAndViewArea(
                  imageSelectedHandle: _pickFaceImage,
                  imageClearHandle: () =>
                      setState(() => selectedFaceImage = null),
                  selectedImage: selectedFaceImage,
                  imagePlaceholder: "【脸部】参考图",
                ),
              ),
              Expanded(
                child: ImagePickAndViewArea(
                  imageSelectedHandle: _pickPoseImage,
                  imageClearHandle: () =>
                      setState(() => selectedPoseImage = null),
                  selectedImage: selectedPoseImage,
                  imagePlaceholder: "【姿势】参考图",
                ),
              ),
            ],
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
          PromptInput(
            label: "反向提示词",
            hintText: '画面中不想出现的内容描述词信息。通过指定用户不想看到的内容来优化模型输出，使模型产生更有针对性和理想的结果。',
            controller: negativePromptController,
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

  /// 选择图片来源
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    print("选中的图片---------$pickedFile");

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickFaceImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    print("选中的Face图片---------$pickedFile");

    if (pickedFile != null) {
      setState(() => selectedFaceImage = File(pickedFile.path));
    }
  }

  Future<void> _pickPoseImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    print("选中的Pose图片---------$pickedFile");

    if (pickedFile != null) {
      setState(() => selectedPoseImage = File(pickedFile.path));
    }
  }
}
