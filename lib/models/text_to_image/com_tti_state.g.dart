// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'com_tti_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LlmTtiResult _$LlmTtiResultFromJson(Map<String, dynamic> json) => LlmTtiResult(
      requestId: json['requestId'] as String,
      prompt: json['prompt'] as String,
      negativePrompt: json['negativePrompt'] as String?,
      style: json['style'] as String,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      gmtCreate: DateTime.parse(json['gmtCreate'] as String),
      llmSpec: json['llmSpec'] == null
          ? null
          : CusLLMSpec.fromJson(json['llmSpec'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LlmTtiResultToJson(LlmTtiResult instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'prompt': instance.prompt,
      'negativePrompt': instance.negativePrompt,
      'style': instance.style,
      'imageUrls': instance.imageUrls,
      'gmtCreate': instance.gmtCreate.toIso8601String(),
      'llmSpec': instance.llmSpec?.toJson(),
    };