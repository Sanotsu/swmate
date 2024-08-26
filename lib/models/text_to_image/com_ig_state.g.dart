// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'com_ig_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LlmIGResult _$LlmIGResultFromJson(Map<String, dynamic> json) => LlmIGResult(
      requestId: json['requestId'] as String,
      taskId: json['taskId'] as String?,
      isFinish: json['isFinish'] as bool? ?? false,
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

Map<String, dynamic> _$LlmIGResultToJson(LlmIGResult instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'taskId': instance.taskId,
      'isFinish': instance.isFinish,
      'prompt': instance.prompt,
      'negativePrompt': instance.negativePrompt,
      'style': instance.style,
      'imageUrls': instance.imageUrls,
      'gmtCreate': instance.gmtCreate.toIso8601String(),
      'llmSpec': instance.llmSpec?.toJson(),
    };
