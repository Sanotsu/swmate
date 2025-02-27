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
  ApiPlatform.zhipu: 'zhipu',
  ApiPlatform.infini: 'infini',
};

const _$CusLLMEnumMap = {
  CusLLM.baidu_Ernie_Speed_8K: 'baidu_Ernie_Speed_8K',
  CusLLM.baidu_Ernie_Speed_128K: 'baidu_Ernie_Speed_128K',
  CusLLM.baidu_Ernie_Lite_8K: 'baidu_Ernie_Lite_8K',
  CusLLM.baidu_Ernie_Tiny_8K: 'baidu_Ernie_Tiny_8K',
  CusLLM.baidu_Yi_34B_Chat_4K: 'baidu_Yi_34B_Chat_4K',
  CusLLM.baidu_Fuyu_8B: 'baidu_Fuyu_8B',
  CusLLM.baidu_ERNIE4p0_8K: 'baidu_ERNIE4p0_8K',
  CusLLM.baidu_ERNIE4p0_Turbo_8K: 'baidu_ERNIE4p0_Turbo_8K',
  CusLLM.baidu_ERNIE3p5_8K: 'baidu_ERNIE3p5_8K',
  CusLLM.baidu_ERNIE3p5_128K: 'baidu_ERNIE3p5_128K',
  CusLLM.baidu_ERNIE_Novel_8K: 'baidu_ERNIE_Novel_8K',
  CusLLM.tencent_Hunyuan_Lite: 'tencent_Hunyuan_Lite',
  CusLLM.tencent_Hunyuan_Pro: 'tencent_Hunyuan_Pro',
  CusLLM.tencent_Hunyuan_Standard: 'tencent_Hunyuan_Standard',
  CusLLM.tencent_Hunyuan_Standard_256K: 'tencent_Hunyuan_Standard_256K',
  CusLLM.tencent_Hunyuan_Vision: 'tencent_Hunyuan_Vision',
  CusLLM.zhipu_GLM4_Flash: 'zhipu_GLM4_Flash',
  CusLLM.xfyun_Spark_Lite: 'xfyun_Spark_Lite',
  CusLLM.xfyun_Spark_Pro: 'xfyun_Spark_Pro',
  CusLLM.xfyun_TTI: 'xfyun_TTI',
  CusLLM.aliyun_Wanx_v1_TTI: 'aliyun_Wanx_v1_TTI',
  CusLLM.aliyun_Flux_Merged_TTI: 'aliyun_Flux_Merged_TTI',
  CusLLM.aliyun_Flux_Schnell_TTI: 'aliyun_Flux_Schnell_TTI',
  CusLLM.aliyun_Flux_Dev_TTI: 'aliyun_Flux_Dev_TTI',
  CusLLM.aliyun_Qwen_Max: 'aliyun_Qwen_Max',
  CusLLM.aliyun_Qwen_Max_LongContext: 'aliyun_Qwen_Max_LongContext',
  CusLLM.aliyun_Qwen_Plus: 'aliyun_Qwen_Plus',
  CusLLM.aliyun_Qwen_Turbo: 'aliyun_Qwen_Turbo',
  CusLLM.aliyun_Qwen_Long: 'aliyun_Qwen_Long',
  CusLLM.aliyun_Qwen_VL_Max_0809: 'aliyun_Qwen_VL_Max_0809',
  CusLLM.aliyun_Qwen_VL_Max: 'aliyun_Qwen_VL_Max',
  CusLLM.aliyun_Qwen_VL_Plus: 'aliyun_Qwen_VL_Plus',
  CusLLM.aliyun_Wordart_Texture_TTI_WORD: 'aliyun_Wordart_Texture_TTI_WORD',
  CusLLM.aliyun_Wordart_Semantic_TTI_WORD: 'aliyun_Wordart_Semantic_TTI_WORD',
  CusLLM.aliyun_Wordart_Surnames_TTI_WORD: 'aliyun_Wordart_Surnames_TTI_WORD',
  CusLLM.lingyiwanwu_YiLarge: 'lingyiwanwu_YiLarge',
  CusLLM.lingyiwanwu_YiMedium: 'lingyiwanwu_YiMedium',
  CusLLM.lingyiwanwu_YiVision: 'lingyiwanwu_YiVision',
  CusLLM.lingyiwanwu_YiMedium200k: 'lingyiwanwu_YiMedium200k',
  CusLLM.lingyiwanwu_YiSpark: 'lingyiwanwu_YiSpark',
  CusLLM.lingyiwanwu_YiLargeRag: 'lingyiwanwu_YiLargeRag',
  CusLLM.lingyiwanwu_YiLargeTurbo: 'lingyiwanwu_YiLargeTurbo',
  CusLLM.siliconCloud_Qwen2p5_7B_Instruct: 'siliconCloud_Qwen2p5_7B_Instruct',
  CusLLM.siliconCloud_Qwen2_7B_Instruct: 'siliconCloud_Qwen2_7B_Instruct',
  CusLLM.siliconCloud_Qwen2_1p5B_Instruct: 'siliconCloud_Qwen2_1p5B_Instruct',
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
  CusLLM.siliconCloud_Qwen2p5_Coder_7B_Instruct:
      'siliconCloud_Qwen2p5_Coder_7B_Instruct',
  CusLLM.siliconCloud_VendorA_Qwen2_72B_Instruct:
      'siliconCloud_VendorA_Qwen2_72B_Instruct',
  CusLLM.siliconCloud_Qwen2p5_72B_Instruct: 'siliconCloud_Qwen2p5_72B_Instruct',
  CusLLM.siliconCloud_Qwen2p5_32B_Instruct: 'siliconCloud_Qwen2p5_32B_Instruct',
  CusLLM.siliconCloud_Qwen2p5_14B_Instruct: 'siliconCloud_Qwen2p5_14B_Instruct',
  CusLLM.siliconCloud_Qwen2p5_Math_72B_Instruct:
      'siliconCloud_Qwen2p5_Math_72B_Instruct',
  CusLLM.siliconCloud_Qwen2_Math_72B_Instruct:
      'siliconCloud_Qwen2_Math_72B_Instruct',
  CusLLM.siliconCloud_Qwen2_57B_A14B_Instruct:
      'siliconCloud_Qwen2_57B_A14B_Instruct',
  CusLLM.siliconCloud_Yi1p5_34B_Chat_16K: 'siliconCloud_Yi1p5_34B_Chat_16K',
  CusLLM.siliconCloud_DeepSeek_V2p5: 'siliconCloud_DeepSeek_V2p5',
  CusLLM.siliconCloud_DeepSeek_Coder_V2_Instruct:
      'siliconCloud_DeepSeek_Coder_V2_Instruct',
  CusLLM.siliconCloud_DeepSeek_V2_Chat: 'siliconCloud_DeepSeek_V2_Chat',
  CusLLM.siliconCloud_internlm2p5_20B_Chat: 'siliconCloud_internlm2p5_20B_Chat',
  CusLLM.siliconCloud_Llama3p1_405B_Instruct:
      'siliconCloud_Llama3p1_405B_Instruct',
  CusLLM.siliconCloud_Llama3p1_70B_Instruct:
      'siliconCloud_Llama3p1_70B_Instruct',
  CusLLM.siliconCloud_Llama3_70B_Instruct: 'siliconCloud_Llama3_70B_Instruct',
  CusLLM.siliconCloud_gemma2_27B_Instruct: 'siliconCloud_gemma2_27B_Instruct',
  CusLLM.siliconCloud_Pro_Flux1_Schnell_TTI:
      'siliconCloud_Pro_Flux1_Schnell_TTI',
  CusLLM.siliconCloud_Pro_Flux1_Dev_TTI: 'siliconCloud_Pro_Flux1_Dev_TTI',
  CusLLM.zhipu_GLM4_Plus: 'zhipu_GLM4_Plus',
  CusLLM.zhipu_GLM4_0520: 'zhipu_GLM4_0520',
  CusLLM.zhipu_GLM4_AirX: 'zhipu_GLM4_AirX',
  CusLLM.zhipu_GLM4_Air: 'zhipu_GLM4_Air',
  CusLLM.zhipu_GLM4_Long: 'zhipu_GLM4_Long',
  CusLLM.zhipu_GLM4_FlashX: 'zhipu_GLM4_FlashX',
  CusLLM.zhipu_GLM4V_Plus: 'zhipu_GLM4V_Plus',
  CusLLM.zhipu_GLM4V: 'zhipu_GLM4V',
  CusLLM.zhipu_CogView3_Plus_TTI: 'zhipu_CogView3_Plus_TTI',
  CusLLM.zhipu_CogView3_TTI: 'zhipu_CogView3_TTI',
  CusLLM.zhipu_CogVideoX_TTV: 'zhipu_CogVideoX_TTV',
  CusLLM.infini_Yi1p5_34B_Chat: 'infini_Yi1p5_34B_Chat',
  CusLLM.infini_Baichuan2_7B_Chat: 'infini_Baichuan2_7B_Chat',
  CusLLM.infini_Baichuan2_13B_Chat: 'infini_Baichuan2_13B_Chat',
  CusLLM.infini_Baichuan2_13B_Base: 'infini_Baichuan2_13B_Base',
  CusLLM.infini_GLM4_9B_Chat: 'infini_GLM4_9B_Chat',
  CusLLM.infini_ChatGLM3: 'infini_ChatGLM3',
  CusLLM.infini_ChatGLM3_6B: 'infini_ChatGLM3_6B',
  CusLLM.infini_ChatGLM3_6B_32K: 'infini_ChatGLM3_6B_32K',
  CusLLM.infini_MtInfini_3B: 'infini_MtInfini_3B',
  CusLLM.infini_Qwen2p5_7B_Instruct: 'infini_Qwen2p5_7B_Instruct',
  CusLLM.infini_Qwen2p5_14B_Instruct: 'infini_Qwen2p5_14B_Instruct',
  CusLLM.infini_Qwen2p5_32B_Instruct: 'infini_Qwen2p5_32B_Instruct',
  CusLLM.infini_Qwen2p5_72B_Instruct: 'infini_Qwen2p5_72B_Instruct',
  CusLLM.infini_Qwen_72B_Chat: 'infini_Qwen_72B_Chat',
  CusLLM.infini_Qwen1p5_14B_Chat: 'infini_Qwen1p5_14B_Chat',
  CusLLM.infini_Qwen1p5_32B_Chat: 'infini_Qwen1p5_32B_Chat',
  CusLLM.infini_Qwen1p5_72B_Chat: 'infini_Qwen1p5_72B_Chat',
  CusLLM.infini_Qwen2_7B_Instruct: 'infini_Qwen2_7B_Instruct',
  CusLLM.infini_Qwen2_72B_Instruct: 'infini_Qwen2_72B_Instruct',
};

const _$LLModelTypeEnumMap = {
  LLModelType.cc: 'cc',
  LLModelType.vision: 'vision',
  LLModelType.tti_word: 'tti_word',
  LLModelType.voice: 'voice',
  LLModelType.tti: 'tti',
  LLModelType.iti: 'iti',
  LLModelType.image: 'image',
  LLModelType.ttv: 'ttv',
  LLModelType.itv: 'itv',
  LLModelType.video: 'video',
};

CusSysRoleSpec _$CusSysRoleSpecFromJson(Map<String, dynamic> json) =>
    CusSysRoleSpec(
      cusSysRoleSpecId: json['cusSysRoleSpecId'] as String?,
      label: json['label'] as String,
      subtitle: json['subtitle'] as String?,
      name: $enumDecodeNullable(_$CusSysRoleEnumMap, json['name']),
      hintInfo: json['hintInfo'] as String? ?? "",
      systemPrompt: json['systemPrompt'] as String,
      negativePrompt: json['negativePrompt'] as String?,
      imageUrl: json['imageUrl'] as String?,
      sysRoleType:
          $enumDecodeNullable(_$LLModelTypeEnumMap, json['sysRoleType']),
      gmtCreate: json['gmtCreate'] == null
          ? null
          : DateTime.parse(json['gmtCreate'] as String),
    );

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
      'negativePrompt': instance.negativePrompt,
    };

const _$CusSysRoleEnumMap = {
  CusSysRole.doc_translator: 'doc_translator',
  CusSysRole.doc_summarizer: 'doc_summarizer',
  CusSysRole.doc_analyzer: 'doc_analyzer',
  CusSysRole.img_translator: 'img_translator',
  CusSysRole.img_summarizer: 'img_summarizer',
  CusSysRole.img_analyzer: 'img_analyzer',
};
