// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cus_brief_llm_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CusBriefLLMSpec _$CusBriefLLMSpecFromJson(Map<String, dynamic> json) =>
    CusBriefLLMSpec(
      $enumDecode(_$ApiPlatformEnumMap, json['platform']),
      json['model'] as String,
      $enumDecode(_$LLModelTypeEnumMap, json['modelType']),
      name: json['name'] as String?,
      isFree: json['isFree'] as bool?,
      inputPrice: (json['inputPrice'] as num?)?.toDouble(),
      outputPrice: (json['outputPrice'] as num?)?.toDouble(),
      costPer: (json['costPer'] as num?)?.toDouble(),
      contextLength: (json['contextLength'] as num?)?.toInt(),
      cusLlmSpecId: json['cusLlmSpecId'] as String,
      gmtRelease: json['gmtRelease'] == null
          ? null
          : DateTime.parse(json['gmtRelease'] as String),
      gmtCreate: json['gmtCreate'] == null
          ? null
          : DateTime.parse(json['gmtCreate'] as String),
      isBuiltin: json['isBuiltin'] as bool? ?? false,
    );

Map<String, dynamic> _$CusBriefLLMSpecToJson(CusBriefLLMSpec instance) =>
    <String, dynamic>{
      'cusLlmSpecId': instance.cusLlmSpecId,
      'platform': _$ApiPlatformEnumMap[instance.platform]!,
      'model': instance.model,
      'modelType': _$LLModelTypeEnumMap[instance.modelType]!,
      'name': instance.name,
      'isFree': instance.isFree,
      'inputPrice': instance.inputPrice,
      'outputPrice': instance.outputPrice,
      'costPer': instance.costPer,
      'contextLength': instance.contextLength,
      'gmtRelease': instance.gmtRelease?.toIso8601String(),
      'gmtCreate': instance.gmtCreate?.toIso8601String(),
      'isBuiltin': instance.isBuiltin,
    };

const _$ApiPlatformEnumMap = {
  ApiPlatform.aliyun: 'aliyun',
  ApiPlatform.baidu: 'baidu',
  ApiPlatform.tencent: 'tencent',
  ApiPlatform.deepseek: 'deepseek',
  ApiPlatform.lingyiwanwu: 'lingyiwanwu',
  ApiPlatform.zhipu: 'zhipu',
  ApiPlatform.siliconCloud: 'siliconCloud',
  ApiPlatform.infini: 'infini',
  ApiPlatform.volcengine: 'volcengine',
  ApiPlatform.volcesBot: 'volcesBot',
};

const _$LLModelTypeEnumMap = {
  LLModelType.cc: 'cc',
  LLModelType.vision: 'vision',
  LLModelType.reasoner: 'reasoner',
  LLModelType.tti: 'tti',
  LLModelType.iti: 'iti',
  LLModelType.image: 'image',
  LLModelType.ttv: 'ttv',
  LLModelType.itv: 'itv',
  LLModelType.video: 'video',
  LLModelType.audio: 'audio',
  LLModelType.asr: 'asr',
  LLModelType.tts: 'tts',
  LLModelType.omni: 'omni',
};
