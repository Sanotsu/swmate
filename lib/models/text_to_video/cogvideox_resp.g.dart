// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cogvideox_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CogVideoXResp _$CogVideoXRespFromJson(Map<String, dynamic> json) =>
    CogVideoXResp(
      requestId: json['request_id'] as String?,
      id: json['id'] as String?,
      model: json['model'] as String?,
      taskStatus: json['task_status'] as String?,
      error: json['error'] == null
          ? null
          : ZhipuError.fromJson(json['error'] as Map<String, dynamic>),
    )..videoResult = (json['video_result'] as List<dynamic>?)
        ?.map((e) => CogVideoxResult.fromJson(e as Map<String, dynamic>))
        .toList();

Map<String, dynamic> _$CogVideoXRespToJson(CogVideoXResp instance) =>
    <String, dynamic>{
      'request_id': instance.requestId,
      'id': instance.id,
      'model': instance.model,
      'task_status': instance.taskStatus,
      'error': instance.error?.toJson(),
      'video_result': instance.videoResult?.map((e) => e.toJson()).toList(),
    };

CogVideoxResult _$CogVideoxResultFromJson(Map<String, dynamic> json) =>
    CogVideoxResult(
      json['url'] as String,
      json['cover_image_url'] as String,
    );

Map<String, dynamic> _$CogVideoxResultToJson(CogVideoxResult instance) =>
    <String, dynamic>{
      'url': instance.url,
      'cover_image_url': instance.coverImageUrl,
    };
