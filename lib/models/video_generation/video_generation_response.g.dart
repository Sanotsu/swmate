// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_generation_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoGenerationResponse _$VideoGenerationResponseFromJson(
        Map<String, dynamic> json) =>
    VideoGenerationResponse(
      requestId: json['request_id'] as String?,
      taskId: json['task_id'] as String?,
      status: json['status'] as String?,
      results: (json['results'] as List<dynamic>?)
          ?.map((e) => VideoResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      code: json['code'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$VideoGenerationResponseToJson(
        VideoGenerationResponse instance) =>
    <String, dynamic>{
      'request_id': instance.requestId,
      'task_id': instance.taskId,
      'status': instance.status,
      'results': instance.results?.map((e) => e.toJson()).toList(),
      'code': instance.code,
      'message': instance.message,
    };

VideoResult _$VideoResultFromJson(Map<String, dynamic> json) => VideoResult(
      url: json['url'] as String,
      coverImageUrl: json['cover_image_url'] as String?,
    );

Map<String, dynamic> _$VideoResultToJson(VideoResult instance) =>
    <String, dynamic>{
      'url': instance.url,
      'cover_image_url': instance.coverImageUrl,
    };

VideoGenerationSubmitResponse _$VideoGenerationSubmitResponseFromJson(
        Map<String, dynamic> json) =>
    VideoGenerationSubmitResponse(
      requestId: readJsonValue(json, 'requestId') as String?,
      id: json['id'] as String?,
      model: json['model'] as String?,
      taskStatus: json['task_status'] as String?,
      output: json['output'] == null
          ? null
          : AliyunVideoOutput.fromJson(json['output'] as Map<String, dynamic>),
      code: json['code'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$VideoGenerationSubmitResponseToJson(
        VideoGenerationSubmitResponse instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'id': instance.id,
      'model': instance.model,
      'task_status': instance.taskStatus,
      'output': instance.output?.toJson(),
      'code': instance.code,
      'message': instance.message,
    };

VideoGenerationTaskResponse _$VideoGenerationTaskResponseFromJson(
        Map<String, dynamic> json) =>
    VideoGenerationTaskResponse(
      status: json['status'] as String?,
      position: (json['position'] as num?)?.toInt(),
      reason: json['reason'] as String?,
      results: json['results'] == null
          ? null
          : SiliconflowVideoStatusResult.fromJson(
              json['results'] as Map<String, dynamic>),
      requestId: json['request_id'] as String?,
      id: json['id'] as String?,
      model: json['model'] as String?,
      taskStatus: json['task_status'] as String?,
      videoResult: (json['video_result'] as List<dynamic>?)
          ?.map((e) => VideoResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      output: json['output'] == null
          ? null
          : AliyunVideoOutput.fromJson(json['output'] as Map<String, dynamic>),
      usage: json['usage'] == null
          ? null
          : AliyunVideoUsage.fromJson(json['usage'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$VideoGenerationTaskResponseToJson(
        VideoGenerationTaskResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'position': instance.position,
      'reason': instance.reason,
      'results': instance.results?.toJson(),
      'model': instance.model,
      'video_result': instance.videoResult?.map((e) => e.toJson()).toList(),
      'task_status': instance.taskStatus,
      'request_id': instance.requestId,
      'id': instance.id,
      'output': instance.output?.toJson(),
      'usage': instance.usage?.toJson(),
    };

AliyunVideoOutput _$AliyunVideoOutputFromJson(Map<String, dynamic> json) =>
    AliyunVideoOutput(
      json['task_id'] as String?,
      json['task_status'] as String?,
      json['submit_time'] as String?,
      json['scheduled_time'] as String?,
      json['end_time'] as String?,
      json['video_url'] as String?,
      json['code'] as String?,
      json['message'] as String?,
    );

Map<String, dynamic> _$AliyunVideoOutputToJson(AliyunVideoOutput instance) =>
    <String, dynamic>{
      'task_id': instance.taskId,
      'task_status': instance.taskStatus,
      'submit_time': instance.submitTime,
      'scheduled_time': instance.scheduledTime,
      'end_time': instance.endTime,
      'video_url': instance.videoUrl,
      'code': instance.code,
      'message': instance.message,
    };

AliyunVideoUsage _$AliyunVideoUsageFromJson(Map<String, dynamic> json) =>
    AliyunVideoUsage(
      json['video_count'] as String?,
      json['video_duration'] as String?,
      json['video_ratio'] as String?,
    );

Map<String, dynamic> _$AliyunVideoUsageToJson(AliyunVideoUsage instance) =>
    <String, dynamic>{
      'video_count': instance.videoCount,
      'video_duration': instance.videoDuration,
      'video_ratio': instance.videoRatio,
    };

SiliconflowVideoStatusResult _$SiliconflowVideoStatusResultFromJson(
        Map<String, dynamic> json) =>
    SiliconflowVideoStatusResult(
      (json['seed'] as num?)?.toInt(),
      (json['timings'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ),
      (json['videos'] as List<dynamic>?)
          ?.map((e) => VideoResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SiliconflowVideoStatusResultToJson(
        SiliconflowVideoStatusResult instance) =>
    <String, dynamic>{
      'seed': instance.seed,
      'timings': instance.timings,
      'videos': instance.videos?.map((e) => e.toJson()).toList(),
    };
