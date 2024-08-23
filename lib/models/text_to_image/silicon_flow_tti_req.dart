import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'silicon_flow_tti_req.g.dart';

///
/// 【以 siliconflow 的入参为基准的响应类】
///
/// siliconflowTtiResp => siliconflow text to image request
///
@JsonSerializable(explicitToJson: true)
class SiliconFlowTtiReq {
  // Flux.1-schnell 只有这4个
  @JsonKey(name: 'prompt')
  String prompt;

  @JsonKey(name: 'image_size')
  String imageSize;

  @JsonKey(name: 'num_inference_steps')
  int numInferenceSteps;

  @JsonKey(name: 'seed')
  int? seed;

  /// Stable Diffusion 3
  // 反向提示
  @JsonKey(name: 'negative_prompt')
  String? negativePrompt;

  // 一次性生成的图片数量
  @JsonKey(name: 'batch_size')
  int? batchSize;

  @JsonKey(name: 'guidance_scale')
  double? guidanceScale;

  SiliconFlowTtiReq({
    required this.prompt,
    required this.imageSize,
    required this.numInferenceSteps,
    required this.seed,
    this.batchSize = 1,
  });

  //  Flux.1-schnell 必须的栏位
  SiliconFlowTtiReq.flux1schnell({
    required this.prompt,
    required this.imageSize,
    this.seed,
    required this.numInferenceSteps,
  })  : negativePrompt = null,
        batchSize = null,
        guidanceScale = null;

  // 模型类、默认numInferenceSteps 和 guidanceScale
  // Stable Diffusion 3              [1,100](20)   [0,100](7.5)
  // Stable Diffusion XL             [1,100](20)   [0,100](7.5)
  // Stable Diffusion 2.1            [1,100](20)   [0,100](7.5)
  // Stable Diffusion Turbo          [1,10](6)   [0,2](1)
  // Stable Diffusion XL Turbo       [1,10](6)   [0,2](1)
  // Stable Diffusion XL Lighting    [1,4](4)    [0,2](1)
  // 必须的栏位（区分不同默认值，因为范围不同）
  // 正统的sd，就带X
  SiliconFlowTtiReq.sdX({
    required this.prompt,
    this.negativePrompt,
    // Defaults to 512x512 (512x1024、768x512、768x1024、1024x576、576x1024)
    required this.imageSize,
    // 1 to 4, Defaults to 1
    required this.batchSize,
    // 0 to 9999999999
    this.seed,
    // 这两个不同的sd默认值不一样
    this.numInferenceSteps = 20,
    this.guidanceScale = 7.5,
  });

  // 轻量的sd，就带Turbo
  SiliconFlowTtiReq.sdTurbo({
    required this.prompt,
    this.negativePrompt,
    // Defaults to 512x512 (512x1024、768x512、768x1024、1024x576、576x1024)
    required this.imageSize,
    // 1 to 4, Defaults to 1
    required this.batchSize,
    // 0 to 9999999999
    this.seed,
    // 这两个不同的sd默认值不一样
    this.numInferenceSteps = 6,
    this.guidanceScale = 1,
  });

  // 更轻量的sd，就带Lighting
  SiliconFlowTtiReq.sdLighting({
    required this.prompt,
    this.negativePrompt,
    // Defaults to 512x512 (512x1024、768x512、7768x1024、1024x576、576x1024)
    required this.imageSize,
    // 1 to 4, Defaults to 1
    required this.batchSize,
    // 0 to 9999999999
    this.seed,
    // 这两个不同的sd默认值不一样
    this.numInferenceSteps = 4,
    this.guidanceScale = 1,
  });

  // 从字符串转
  factory SiliconFlowTtiReq.fromRawJson(String str) =>
      SiliconFlowTtiReq.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory SiliconFlowTtiReq.fromJson(Map<String, dynamic> srcJson) =>
      _$SiliconFlowTtiReqFromJson(srcJson);

  Map<String, dynamic> toFullJson() => _$SiliconFlowTtiReqToJson(this);

  // 自定义tojson方法，参数为null的就不加到json中
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    json['prompt'] = prompt;
    if (negativePrompt != null) json['negative_prompt'] = negativePrompt;
    json['image_size'] = imageSize;
    if (batchSize != null) json['batch_size'] = batchSize;
    if (seed != null) json['seed'] = seed;
    json['num_inference_steps'] = numInferenceSteps;
    if (guidanceScale != null) json['guidance_scale'] = guidanceScale;

    return json;
  }
}
