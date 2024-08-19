// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aliyun_tti_req.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AliyunTtiReq _$AliyunTtiReqFromJson(Map<String, dynamic> json) => AliyunTtiReq(
      model: json['model'] as String,
      input: AliyunTtiInput.fromJson(json['input'] as Map<String, dynamic>),
      parameters: json['parameters'] == null
          ? null
          : AliyunTtiParameter.fromJson(
              json['parameters'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AliyunTtiReqToJson(AliyunTtiReq instance) =>
    <String, dynamic>{
      'model': instance.model,
      'input': instance.input.toJson(),
      'parameters': instance.parameters?.toJson(),
    };

AliyunTtiInput _$AliyunTtiInputFromJson(Map<String, dynamic> json) =>
    AliyunTtiInput(
      prompt: json['prompt'] as String,
      negativePrompt: json['negative_prompt'] as String?,
      refImg: json['ref_img'] as String?,
    );

Map<String, dynamic> _$AliyunTtiInputToJson(AliyunTtiInput instance) =>
    <String, dynamic>{
      'prompt': instance.prompt,
      'negative_prompt': instance.negativePrompt,
      'ref_img': instance.refImg,
    };

AliyunTtiParameter _$AliyunTtiParameterFromJson(Map<String, dynamic> json) =>
    AliyunTtiParameter(
      style: json['style'] as String?,
      size: json['size'] as String?,
      n: (json['n'] as num?)?.toInt(),
      seed: (json['seed'] as num?)?.toInt(),
      strength: (json['strength'] as num?)?.toDouble(),
      refMode: json['ref_mode'] as String?,
      steps: json['steps'] as String?,
    );

Map<String, dynamic> _$AliyunTtiParameterToJson(AliyunTtiParameter instance) =>
    <String, dynamic>{
      'style': instance.style,
      'size': instance.size,
      'n': instance.n,
      'seed': instance.seed,
      'strength': instance.strength,
      'ref_mode': instance.refMode,
      'steps': instance.steps,
    };
