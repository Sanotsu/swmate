import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

import '../../../common/llm_spec/constant_llm_enum.dart';

part 'video_generation_request.g.dart';

@JsonSerializable(explicitToJson: true)
class VideoGenerationRequest {
  final String model;
  final String prompt;

  /// 阿里云特有参数: model input parameters
  final AliyunVideoInput? input;
  final AliyunVideoParameter? parameters;

  /// 智谱AI特有参数: model prompt quality with_audio image_url size fps request_id user_id
  // 输出模式，默认为 "speed"。 "quality"：质量优先，生成质量高。 "speed"：速度优先，生成时间更快，质量相对降低。
  final String? quality;
  // 是否生成 AI 音效。默认值: False（不生成音效）。
  @JsonKey(name: 'with_audio')
  final bool? withAudio;
  // 支持通过URL或Base64编码 【image_url和prompt二选一或者同时传入】
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  // 分辨率选项：720x480、1024x1024、1280x960、960x1280、1920x1080、1080x1920、2048x1080、3840x2160
  final String? size;
  // 视频帧率（FPS），可选值为 30 或 60。默认值: 30。
  final int? fps;
  // 由用户端传参，需保证唯一性；用于区分每次请求的唯一标识，用户端不传时平台会默认生成。
  @JsonKey(name: 'request_id')
  final String? requestId;
  // 终端用户的唯一ID，协助平台对终端用户的违规行为、生成违法及不良信息或其他滥用行为进行干预。
  // ID长度要求：最少6个字符，最多128个字符。
  @JsonKey(name: 'user_id')
  final String? userId;

  // 硅基流动特有参数 2025-02-19
  // Lightricks/LTX-Video: model prompt seed image
  // tencent/HunyuanVideo: model prompt seed
  // genmo/mochi-1-preview: model prompt seed guidance_scale
  // 这个参考图暂时只能是url
  final String? image;
  final int? seed;
  @JsonKey(name: 'guidance_scale')
  final double? guidanceScale;

  VideoGenerationRequest({
    required this.model,
    required this.prompt,
    this.quality,
    this.withAudio,
    this.imageUrl,
    this.size,
    this.fps,
    this.requestId,
    this.userId,
    this.image,
    this.seed,
    this.guidanceScale,
    this.input,
    this.parameters,
  });

  // 从字符串转
  factory VideoGenerationRequest.fromRawJson(String str) =>
      VideoGenerationRequest.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory VideoGenerationRequest.fromJson(Map<String, dynamic> json) =>
      _$VideoGenerationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$VideoGenerationRequestToJson(this);

  Map<String, dynamic> toRequestBody(ApiPlatform platform) {
    // 基础请求体
    final Map<String, dynamic> base = {
      'model': model,
      'prompt': prompt,
    };

    switch (platform) {
      case ApiPlatform.siliconCloud:
        return {
          ...base,
          if (image != null) 'image': image,
          if (seed != null) 'seed': seed,
          if (guidanceScale != null) 'guidance_scale': guidanceScale,
        };

      case ApiPlatform.aliyun:
        var inputJson = {};
        inputJson['prompt'] = prompt;
        if (imageUrl != null) {
          inputJson['img_url'] = imageUrl;
        }
        return {
          // 阿里云的输入参数是单独的
          'model': model,
          // "input": AliyunVideoInput(prompt: prompt, imgUrl: imageUrl).toJson(),
          "input": inputJson,
          "parameters": AliyunVideoParameter(size: size, seed: seed).toJson(),
          if (input != null) 'input': input?.toJson(),
          if (parameters != null) 'parameters': parameters?.toJson(),
        };

      case ApiPlatform.zhipu:
        return {
          ...base,
          if (withAudio != null) 'with_audio': withAudio,
          if (imageUrl != null) 'image_url': imageUrl,
          if (requestId != null) 'request_id': requestId,
          if (userId != null) 'user_id': userId,
          // cogvideox-flash：不支持quality 、size 、fps 参数设置
          if (quality != null) 'quality': quality,
          if (size != null) 'size': size,
          if (fps != null) 'fps': fps,
        };

      default:
        return base;
    }
  }
}

@JsonSerializable(explicitToJson: true)
class AliyunVideoInput {
  /// 如果是文生视频，prompt为必填；如果是图生视频，img_url为必填。
  /// 前端可根据是否传入参考图来区分使用的模型
  ///
  // 文本提示词。支持中英文，长度不超过800个字符
  final String? prompt;
  // 生成视频时所使用的第一帧图像的URL。
  @JsonKey(name: 'img_url')
  final String? imgUrl;

  AliyunVideoInput({
    required this.prompt,
    this.imgUrl,
  });

  factory AliyunVideoInput.fromJson(Map<String, dynamic> json) =>
      _$AliyunVideoInputFromJson(json);

  Map<String, dynamic> toJson() => _$AliyunVideoInputToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AliyunVideoParameter {
  // 文生成视频的分辨率。默认值1280*720。其中，1280代表宽度，720代表高度。
  // 【图生视频没看到这个参数】
  // 目前支持5档分辨率选择：1280*720、960*960、720*1280、1088*832、 832*1088。
  final String? size;
  // 生成视频的时长，默认为5，单位为秒。2025-02-19 目前仅支持5秒固定时长生成。
  final int? duration;
  // 是否开启prompt智能改写。开启后使用大模型对输入prompt进行智能改写。对于较短的prompt生成效果提升明显，但会增加耗时。
  @JsonKey(name: 'prompt_extend')
  final bool? promptExtend;
  // 生成视频的高度。默认值720。
  final int? seed;

  AliyunVideoParameter({
    this.size,
    this.seed,
    this.duration = 5,
    this.promptExtend = true,
  });

  factory AliyunVideoParameter.fromJson(Map<String, dynamic> json) =>
      _$AliyunVideoParameterFromJson(json);

  Map<String, dynamic> toJson() => _$AliyunVideoParameterToJson(this);
}
