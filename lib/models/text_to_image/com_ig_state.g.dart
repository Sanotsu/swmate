// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'com_ig_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LlmIGVGResult _$LlmIGVGResultFromJson(Map<String, dynamic> json) =>
    LlmIGVGResult(
      requestId: json['requestId'] as String,
      taskId: json['taskId'] as String?,
      isFinish: json['isFinish'] as bool? ?? false,
      prompt: json['prompt'] as String,
      negativePrompt: json['negativePrompt'] as String?,
      style: json['style'] as String?,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      gmtCreate: DateTime.parse(json['gmtCreate'] as String),
      llmSpec: json['llmSpec'] == null
          ? null
          : CusLLMSpec.fromJson(json['llmSpec'] as Map<String, dynamic>),
      videoUrls: (json['videoUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      videoCoverImageUrls: (json['videoCoverImageUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      refImageUrls: (json['refImageUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      modelType: $enumDecode(_$LLModelTypeEnumMap, json['modelType']),
    );

Map<String, dynamic> _$LlmIGVGResultToJson(LlmIGVGResult instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'taskId': instance.taskId,
      'isFinish': instance.isFinish,
      'prompt': instance.prompt,
      'negativePrompt': instance.negativePrompt,
      'style': instance.style,
      'imageUrls': instance.imageUrls,
      'videoUrls': instance.videoUrls,
      'videoCoverImageUrls': instance.videoCoverImageUrls,
      'refImageUrls': instance.refImageUrls,
      'gmtCreate': instance.gmtCreate.toIso8601String(),
      'llmSpec': instance.llmSpec?.toJson(),
      'modelType': _$LLModelTypeEnumMap[instance.modelType]!,
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
