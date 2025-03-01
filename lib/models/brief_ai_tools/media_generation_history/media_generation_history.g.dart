// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_generation_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaGenerationHistory _$MediaGenerationHistoryFromJson(
        Map<String, dynamic> json) =>
    MediaGenerationHistory(
      requestId: json['requestId'] as String,
      prompt: json['prompt'] as String,
      negativePrompt: json['negativePrompt'] as String?,
      refImageUrls: (json['refImageUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      modelType: $enumDecode(_$LLModelTypeEnumMap, json['modelType']),
      llmSpec:
          CusBriefLLMSpec.fromJson(json['llmSpec'] as Map<String, dynamic>),
      taskId: json['taskId'] as String?,
      taskStatus: json['taskStatus'] as String?,
      isSuccess: json['isSuccess'] as bool? ?? false,
      isProcessing: json['isProcessing'] as bool? ?? false,
      isFailed: json['isFailed'] as bool? ?? false,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      videoUrls: (json['videoUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      audioUrls: (json['audioUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      otherParams: json['otherParams'] as String?,
      gmtCreate: DateTime.parse(json['gmtCreate'] as String),
      gmtModified: json['gmtModified'] == null
          ? null
          : DateTime.parse(json['gmtModified'] as String),
    );

Map<String, dynamic> _$MediaGenerationHistoryToJson(
        MediaGenerationHistory instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'prompt': instance.prompt,
      'negativePrompt': instance.negativePrompt,
      'refImageUrls': instance.refImageUrls,
      'modelType': _$LLModelTypeEnumMap[instance.modelType]!,
      'llmSpec': instance.llmSpec.toJson(),
      'taskId': instance.taskId,
      'taskStatus': instance.taskStatus,
      'isSuccess': instance.isSuccess,
      'isProcessing': instance.isProcessing,
      'isFailed': instance.isFailed,
      'imageUrls': instance.imageUrls,
      'videoUrls': instance.videoUrls,
      'audioUrls': instance.audioUrls,
      'otherParams': instance.otherParams,
      'gmtCreate': instance.gmtCreate.toIso8601String(),
      'gmtModified': instance.gmtModified?.toIso8601String(),
    };

const _$LLModelTypeEnumMap = {
  LLModelType.cc: 'cc',
  LLModelType.vision: 'vision',
  LLModelType.voice: 'voice',
  LLModelType.tti: 'tti',
  LLModelType.iti: 'iti',
  LLModelType.image: 'image',
  LLModelType.ttv: 'ttv',
  LLModelType.itv: 'itv',
  LLModelType.video: 'video',
};
