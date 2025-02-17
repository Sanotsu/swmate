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
      json['name'] as String,
      json['isFree'] as bool,
      inputPrice: (json['inputPrice'] as num?)?.toDouble(),
      outputPrice: (json['outputPrice'] as num?)?.toDouble(),
      costPer: (json['costPer'] as num?)?.toDouble(),
      contextLength: (json['contextLength'] as num?)?.toInt(),
      cusLlmSpecId: json['cusLlmSpecId'] as String?,
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
  ApiPlatform.baidu: 'baidu',
  ApiPlatform.tencent: 'tencent',
  ApiPlatform.aliyun: 'aliyun',
  ApiPlatform.siliconCloud: 'siliconCloud',
  ApiPlatform.lingyiwanwu: 'lingyiwanwu',
  ApiPlatform.xfyun: 'xfyun',
  ApiPlatform.zhipu: 'zhipu',
  ApiPlatform.infini: 'infini',
};

const _$LLModelTypeEnumMap = {
  LLModelType.cc: 'cc',
  LLModelType.vision: 'vision',
  LLModelType.tti: 'tti',
  LLModelType.tti_word: 'tti_word',
  LLModelType.iti: 'iti',
  LLModelType.ttv: 'ttv',
  LLModelType.voice: 'voice',
};
