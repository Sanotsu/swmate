// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aliyun_wanx_req.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AliyunWanxReq _$AliyunWanxReqFromJson(Map<String, dynamic> json) =>
    AliyunWanxReq(
      model: json['model'] as String,
      input: WanxInput.fromJson(json['input'] as Map<String, dynamic>),
      parameters: json['parameters'] == null
          ? null
          : WanxParameter.fromJson(json['parameters'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AliyunWanxReqToJson(AliyunWanxReq instance) =>
    <String, dynamic>{
      'model': instance.model,
      'input': instance.input.toJson(),
      'parameters': instance.parameters?.toJson(),
    };

WanxInput _$WanxInputFromJson(Map<String, dynamic> json) => WanxInput(
      prompt: json['prompt'] as String,
      negativePrompt: json['negative_prompt'] as String?,
      refImg: json['ref_img'] as String?,
    );

Map<String, dynamic> _$WanxInputToJson(WanxInput instance) => <String, dynamic>{
      'prompt': instance.prompt,
      'negative_prompt': instance.negativePrompt,
      'ref_img': instance.refImg,
    };

WanxParameter _$WanxParameterFromJson(Map<String, dynamic> json) =>
    WanxParameter(
      style: json['style'] as String?,
      size: json['size'] as String?,
      n: (json['n'] as num?)?.toInt(),
      seed: (json['seed'] as num?)?.toInt(),
      strength: (json['strength'] as num?)?.toDouble(),
      refMode: json['ref_mode'] as String?,
    );

Map<String, dynamic> _$WanxParameterToJson(WanxParameter instance) =>
    <String, dynamic>{
      'style': instance.style,
      'size': instance.size,
      'n': instance.n,
      'seed': instance.seed,
      'strength': instance.strength,
      'ref_mode': instance.refMode,
    };
