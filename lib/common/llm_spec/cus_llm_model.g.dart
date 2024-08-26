// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cus_llm_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CusLLMSpec _$CusLLMSpecFromJson(Map<String, dynamic> json) => CusLLMSpec(
      $enumDecode(_$ApiPlatformEnumMap, json['platform']),
      $enumDecode(_$CusLLMEnumMap, json['cusLlm']),
      json['model'] as String,
      json['name'] as String,
      (json['contextLength'] as num?)?.toInt(),
      json['isFree'] as bool,
      (json['inputPrice'] as num?)?.toDouble(),
      (json['outputPrice'] as num?)?.toDouble(),
      cusLlmSpecId: json['cusLlmSpecId'] as String?,
      isQuote: json['isQuote'] as bool? ?? false,
      feature: json['feature'] as String?,
      useCase: json['useCase'] as String?,
      modelType: $enumDecodeNullable(_$LLModelTypeEnumMap, json['modelType']) ??
          LLModelType.cc,
      gmtCreate: json['gmtCreate'] == null
          ? null
          : DateTime.parse(json['gmtCreate'] as String),
      costPer: (json['costPer'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$CusLLMSpecToJson(CusLLMSpec instance) =>
    <String, dynamic>{
      'cusLlmSpecId': instance.cusLlmSpecId,
      'platform': _$ApiPlatformEnumMap[instance.platform]!,
      'model': instance.model,
      'cusLlm': _$CusLLMEnumMap[instance.cusLlm]!,
      'name': instance.name,
      'contextLength': instance.contextLength,
      'isFree': instance.isFree,
      'inputPrice': instance.inputPrice,
      'outputPrice': instance.outputPrice,
      'isQuote': instance.isQuote,
      'feature': instance.feature,
      'useCase': instance.useCase,
      'modelType': _$LLModelTypeEnumMap[instance.modelType]!,
      'costPer': instance.costPer,
      'gmtCreate': instance.gmtCreate?.toIso8601String(),
    };

const _$ApiPlatformEnumMap = {
  ApiPlatform.baidu: 'baidu',
  ApiPlatform.tencent: 'tencent',
  ApiPlatform.aliyun: 'aliyun',
  ApiPlatform.siliconCloud: 'siliconCloud',
  ApiPlatform.lingyiwanwu: 'lingyiwanwu',
  ApiPlatform.xfyun: 'xfyun',
};

const _$CusLLMEnumMap = {
  CusLLM.baidu_Ernie_Speed_8K: 'baidu_Ernie_Speed_8K',
  CusLLM.baidu_Ernie_Speed_128K: 'baidu_Ernie_Speed_128K',
  CusLLM.baidu_Ernie_Lite_8K: 'baidu_Ernie_Lite_8K',
  CusLLM.baidu_Ernie_Tiny_8K: 'baidu_Ernie_Tiny_8K',
  CusLLM.baidu_Yi_34B_Chat_4K: 'baidu_Yi_34B_Chat_4K',
  CusLLM.baidu_Fuyu_8B: 'baidu_Fuyu_8B',
  CusLLM.tencent_Hunyuan_Lite: 'tencent_Hunyuan_Lite',
  CusLLM.xfyun_Spark_Lite: 'xfyun_Spark_Lite',
  CusLLM.xfyun_TTI: 'xfyun_TTI',
  CusLLM.aliyun_Wanx_v1_TTI: 'aliyun_Wanx_v1_TTI',
  CusLLM.aliyun_Flux_Merged_TTI: 'aliyun_Flux_Merged_TTI',
  CusLLM.aliyun_Flux_Schnell_TTI: 'aliyun_Flux_Schnell_TTI',
  CusLLM.aliyun_Flux_Dev_TTI: 'aliyun_Flux_Dev_TTI',
  CusLLM.aliyun_Wordart_Texture_TTI_WORD: 'aliyun_Wordart_Texture_TTI_WORD',
  CusLLM.aliyun_Wordart_Semantic_TTI_WORD: 'aliyun_Wordart_Semantic_TTI_WORD',
  CusLLM.aliyun_Wordart_Surnames_TTI_WORD: 'aliyun_Wordart_Surnames_TTI_WORD',
  CusLLM.YiLarge: 'YiLarge',
  CusLLM.YiMedium: 'YiMedium',
  CusLLM.YiVision: 'YiVision',
  CusLLM.YiMedium200k: 'YiMedium200k',
  CusLLM.YiSpark: 'YiSpark',
  CusLLM.YiLargeRag: 'YiLargeRag',
  CusLLM.YiLargeTurbo: 'YiLargeTurbo',
  CusLLM.siliconCloud_Qwen2_7B_Instruct: 'siliconCloud_Qwen2_7B_Instruct',
  CusLLM.siliconCloud_Qwen2_1p5B_Instruct: 'siliconCloud_Qwen2_1p5B_Instruct',
  CusLLM.siliconCloud_Qwen1p5_7B_Chat: 'siliconCloud_Qwen1p5_7B_Chat',
  CusLLM.siliconCloud_GLM4_9B_Chat: 'siliconCloud_GLM4_9B_Chat',
  CusLLM.siliconCloud_ChatGLM3_6B: 'siliconCloud_ChatGLM3_6B',
  CusLLM.siliconCloud_Yi1p5_9B_Chat_16K: 'siliconCloud_Yi1p5_9B_Chat_16K',
  CusLLM.siliconCloud_Yi1p5_6B_Chat: 'siliconCloud_Yi1p5_6B_Chat',
  CusLLM.siliconCloud_GEMMA2_9B_Instruct: 'siliconCloud_GEMMA2_9B_Instruct',
  CusLLM.siliconCloud_InternLM2p5_7B_Chat: 'siliconCloud_InternLM2p5_7B_Chat',
  CusLLM.siliconCloud_LLAMA3_8B_Instruct: 'siliconCloud_LLAMA3_8B_Instruct',
  CusLLM.siliconCloud_LLAMA3p1_8B_Instruct: 'siliconCloud_LLAMA3p1_8B_Instruct',
  CusLLM.siliconCloud_Mistral_7B_Instruct_v0p2:
      'siliconCloud_Mistral_7B_Instruct_v0p2',
  CusLLM.siliconCloud_Flux1_Schnell_TTI: 'siliconCloud_Flux1_Schnell_TTI',
  CusLLM.siliconCloud_StableDiffusion3_TTI: 'siliconCloud_StableDiffusion3_TTI',
  CusLLM.siliconCloud_StableDiffusionXL_TTI:
      'siliconCloud_StableDiffusionXL_TTI',
  CusLLM.siliconCloud_StableDiffusion2p1_TTI:
      'siliconCloud_StableDiffusion2p1_TTI',
  CusLLM.siliconCloud_StableDiffusion_Turbo_TTI:
      'siliconCloud_StableDiffusion_Turbo_TTI',
  CusLLM.siliconCloud_StableDiffusionXL_Turbo_TTI:
      'siliconCloud_StableDiffusionXL_Turbo_TTI',
  CusLLM.siliconCloud_StableDiffusionXL_Lighting_TTI:
      'siliconCloud_StableDiffusionXL_Lighting_TTI',
  CusLLM.siliconCloud_PhotoMaker_ITI: 'siliconCloud_PhotoMaker_ITI',
  CusLLM.siliconCloud_InstantID_ITI: 'siliconCloud_InstantID_ITI',
  CusLLM.siliconCloud_StableDiffusionXL_ITI:
      'siliconCloud_StableDiffusionXL_ITI',
  CusLLM.siliconCloud_StableDiffusion2p1_ITI:
      'siliconCloud_StableDiffusion2p1_ITI',
  CusLLM.siliconCloud_StableDiffusionXL_Lighting_ITI:
      'siliconCloud_StableDiffusionXL_Lighting_ITI',
};

const _$LLModelTypeEnumMap = {
  LLModelType.cc: 'cc',
  LLModelType.vision: 'vision',
  LLModelType.tti: 'tti',
  LLModelType.tti_word: 'tti_word',
  LLModelType.iti: 'iti',
};

CusSysRoleSpec _$CusSysRoleSpecFromJson(Map<String, dynamic> json) =>
    CusSysRoleSpec(
      label: json['label'] as String,
      name: $enumDecodeNullable(_$CusSysRoleEnumMap, json['name']),
      hintInfo: json['hintInfo'] as String? ?? "",
      systemPrompt: json['systemPrompt'] as String,
      sysRoleType:
          $enumDecodeNullable(_$LLModelTypeEnumMap, json['sysRoleType']) ??
              LLModelType.vision,
    )
      ..cusSysRoleSpecId = json['cusSysRoleSpecId'] as String?
      ..subtitle = json['subtitle'] as String?
      ..imageUrl = json['imageUrl'] as String?
      ..gmtCreate = json['gmtCreate'] == null
          ? null
          : DateTime.parse(json['gmtCreate'] as String);

Map<String, dynamic> _$CusSysRoleSpecToJson(CusSysRoleSpec instance) =>
    <String, dynamic>{
      'cusSysRoleSpecId': instance.cusSysRoleSpecId,
      'label': instance.label,
      'subtitle': instance.subtitle,
      'name': _$CusSysRoleEnumMap[instance.name],
      'hintInfo': instance.hintInfo,
      'systemPrompt': instance.systemPrompt,
      'imageUrl': instance.imageUrl,
      'sysRoleType': _$LLModelTypeEnumMap[instance.sysRoleType],
      'gmtCreate': instance.gmtCreate?.toIso8601String(),
    };

const _$CusSysRoleEnumMap = {
  CusSysRole.doc_translator: 'doc_translator',
  CusSysRole.doc_summarizer: 'doc_summarizer',
  CusSysRole.doc_analyzer: 'doc_analyzer',
  CusSysRole.img_translator: 'img_translator',
  CusSysRole.img_summarizer: 'img_summarizer',
  CusSysRole.img_analyzer: 'img_analyzer',
};