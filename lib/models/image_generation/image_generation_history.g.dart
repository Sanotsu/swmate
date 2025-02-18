// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_generation_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImageGenerationHistory _$ImageGenerationHistoryFromJson(
        Map<String, dynamic> json) =>
    ImageGenerationHistory(
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
          : CusBriefLLMSpec.fromJson(json['llmSpec'] as Map<String, dynamic>),
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

Map<String, dynamic> _$ImageGenerationHistoryToJson(
        ImageGenerationHistory instance) =>
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
  LLModelType.tti: 'tti',
  LLModelType.tti_word: 'tti_word',
  LLModelType.iti: 'iti',
  LLModelType.ttv: 'ttv',
  LLModelType.voice: 'voice',
  LLModelType.image: 'image',
};
