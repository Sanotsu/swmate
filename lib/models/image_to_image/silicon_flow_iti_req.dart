import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'silicon_flow_iti_req.g.dart';

///
/// 【以 siliconflow 的入参为基准的响应类】
///
/// siliconflowTtiResp => siliconflow image to image request
///
/// 图生图和文生图的结果是一样的，就不重复了
///
@JsonSerializable(explicitToJson: true)
class SiliconflowItiReq {
  @JsonKey(name: 'prompt')
  String prompt;

  @JsonKey(name: 'negative_prompt')
  String? negativePrompt;

  @JsonKey(name: 'image')
  String? image;

  @JsonKey(name: 'image_size')
  String? imageSize;

  @JsonKey(name: 'batch_size')
  int? batchSize;

  @JsonKey(name: 'num_inference_steps')
  int? numInferenceSteps;

  @JsonKey(name: 'guidance_scale')
  double? guidanceScale;

  @JsonKey(name: 'seed')
  int? seed;

  @JsonKey(name: 'style_name')
  String? styleName;

  @JsonKey(name: 'controlnet_conditioning_scale')
  double? controlnetConditioningScale;

  @JsonKey(name: 'ip_adapter_scale')
  double? ipAdapterScale;

  @JsonKey(name: 'enhance_face_region')
  bool? enhanceFaceRegion;

  @JsonKey(name: 'face_image')
  String? faceImage;

  @JsonKey(name: 'pose_image')
  String? poseImage;

  @JsonKey(name: 'style_strengh_radio')
  int? styleStrenghRadio;

  @JsonKey(name: 'reference_style_image')
  String? referenceStyleImage;

  @JsonKey(name: 'room_image')
  String? roomImage;

  SiliconflowItiReq({
    required this.prompt,
    required this.image,
    required this.imageSize,
    required this.batchSize,
    this.numInferenceSteps,
    this.guidanceScale,
    this.negativePrompt,
    this.seed,
    this.controlnetConditioningScale,
    this.enhanceFaceRegion,
    this.faceImage,
    this.ipAdapterScale,
    this.poseImage,
    this.referenceStyleImage,
    this.roomImage,
    this.styleName,
    this.styleStrenghRadio,
  });

  // Stable Diffusion XL
  // Stable Diffusion 2.1
  // Stable Diffusion XL Lighting
  SiliconflowItiReq.sd({
    required this.prompt,
    this.negativePrompt,
    required this.image,
    required this.imageSize,
    required this.batchSize,
    this.seed,
    this.numInferenceSteps = 20,
    this.guidanceScale = 7.5,
  });

  SiliconflowItiReq.instantID({
    required this.faceImage,
    required this.poseImage,
    required this.prompt,
    this.negativePrompt,
    required this.styleName,
    this.seed,
    this.numInferenceSteps = 20,
    this.guidanceScale = 5,
    this.controlnetConditioningScale = 0.8,
    this.ipAdapterScale = 0.8,
    this.enhanceFaceRegion = true,
  });

  SiliconflowItiReq.photoMaker({
    required this.prompt,
    this.negativePrompt,
    required this.image,
    required this.imageSize,
    required this.styleName,
    required this.batchSize,
    this.seed,
    this.numInferenceSteps = 20,
    this.guidanceScale = 5,
    this.styleStrenghRadio = 20,
  });

  /// 2024-08-23 sf文档里有，但价格表里面没说是暂时限量免费
  SiliconflowItiReq.decorationDesign({
    required this.batchSize,
    this.controlnetConditioningScale = 0.52,
    this.guidanceScale = 7,
    required this.imageSize,
    this.ipAdapterScale = 0.95,
    required this.prompt,
    this.negativePrompt,
    this.numInferenceSteps = 20,
    required this.referenceStyleImage,
    required this.roomImage,
    this.seed,
  });

  // 从字符串转
  factory SiliconflowItiReq.fromRawJson(String str) =>
      SiliconflowItiReq.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory SiliconflowItiReq.fromJson(Map<String, dynamic> srcJson) =>
      _$SiliconflowItiReqFromJson(srcJson);

  Map<String, dynamic> toFullJson() => _$SiliconflowItiReqToJson(this);

  // 自定义tojson方法，参数为null的就不加到json中
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    json['prompt'] = prompt;
    if (negativePrompt != null) json['negative_prompt'] = negativePrompt;
    if (image != null) json['image'] = image;
    if (imageSize != null) json['image_size'] = imageSize;
    if (batchSize != null) json['batch_size'] = batchSize;
    if (numInferenceSteps != null) {
      json['num_inference_steps'] = numInferenceSteps;
    }
    if (guidanceScale != null) json['guidance_scale'] = guidanceScale;
    if (seed != null) json['seed'] = seed;
    if (controlnetConditioningScale != null) {
      json['controlnet_conditioning_scale'] = controlnetConditioningScale;
    }
    if (enhanceFaceRegion != null) {
      json['enhance_face_region'] = enhanceFaceRegion;
    }
    if (faceImage != null) json['face_image'] = faceImage;
    if (ipAdapterScale != null) json['ip_adapter_scale'] = ipAdapterScale;
    if (poseImage != null) json['pose_image'] = poseImage;
    if (referenceStyleImage != null) {
      json['reference_style_image'] = referenceStyleImage;
    }
    if (roomImage != null) json['room_image'] = roomImage;
    if (styleName != null) json['style_name'] = styleName;
    if (styleStrenghRadio != null) {
      json['style_strengh_radio'] = styleStrenghRadio;
    }

    return json;
  }
}
