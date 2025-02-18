// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_generation_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImageGenerationResponse _$ImageGenerationResponseFromJson(
        Map<String, dynamic> json) =>
    ImageGenerationResponse(
      created: (json['created'] as num?)?.toInt(),
      output: json['output'] == null
          ? null
          : AliyunWanxV2Output.fromJson(json['output'] as Map<String, dynamic>),
      requestId: json['request_id'] as String?,
      code: json['code'] as String?,
      message: json['message'] as String?,
      images: (json['images'] as List<dynamic>?)
          ?.map(
              (e) => ImageGenerationResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      timings: (json['timings'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ),
      seed: (json['seed'] as num?)?.toInt(),
      data: (json['data'] as List<dynamic>?)
          ?.map(
              (e) => ImageGenerationResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      contentFilter: (json['content_filter'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      results: (json['results'] as List<dynamic>?)
          ?.map(
              (e) => ImageGenerationResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ImageGenerationResponseToJson(
        ImageGenerationResponse instance) =>
    <String, dynamic>{
      'request_id': instance.requestId,
      'output': instance.output?.toJson(),
      'code': instance.code,
      'message': instance.message,
      'images': instance.images?.map((e) => e.toJson()).toList(),
      'timings': instance.timings,
      'seed': instance.seed,
      'created': instance.created,
      'data': instance.data?.map((e) => e.toJson()).toList(),
      'content_filter': instance.contentFilter,
      'results': instance.results.map((e) => e.toJson()).toList(),
    };

ImageGenerationResult _$ImageGenerationResultFromJson(
        Map<String, dynamic> json) =>
    ImageGenerationResult(
      url: json['url'] as String,
      origPrompt: json['orig_prompt'] as String?,
      actualPrompt: json['actual_prompt'] as String?,
    );

Map<String, dynamic> _$ImageGenerationResultToJson(
        ImageGenerationResult instance) =>
    <String, dynamic>{
      'url': instance.url,
      'orig_prompt': instance.origPrompt,
      'actual_prompt': instance.actualPrompt,
    };

AliyunWanxV2Resp _$AliyunWanxV2RespFromJson(Map<String, dynamic> json) =>
    AliyunWanxV2Resp(
      requestId: json['request_id'] as String,
      output:
          AliyunWanxV2Output.fromJson(json['output'] as Map<String, dynamic>),
      usage: json['usage'] == null
          ? null
          : AliyunWanxV2Usage.fromJson(json['usage'] as Map<String, dynamic>),
      code: json['code'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$AliyunWanxV2RespToJson(AliyunWanxV2Resp instance) =>
    <String, dynamic>{
      'request_id': instance.requestId,
      'output': instance.output.toJson(),
      'usage': instance.usage?.toJson(),
      'code': instance.code,
      'message': instance.message,
    };

AliyunWanxV2Output _$AliyunWanxV2OutputFromJson(Map<String, dynamic> json) =>
    AliyunWanxV2Output(
      json['task_id'] as String,
      json['task_status'] as String,
      (json['results'] as List<dynamic>?)
          ?.map(
              (e) => ImageGenerationResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['task_metrics'] == null
          ? null
          : AliyunWanxV2OutputTaskMetric.fromJson(
              json['task_metrics'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AliyunWanxV2OutputToJson(AliyunWanxV2Output instance) =>
    <String, dynamic>{
      'task_id': instance.taskId,
      'task_status': instance.taskStatus,
      'results': instance.results?.map((e) => e.toJson()).toList(),
      'task_metrics': instance.taskMetrics?.toJson(),
    };

AliyunWanxV2OutputTaskMetric _$AliyunWanxV2OutputTaskMetricFromJson(
        Map<String, dynamic> json) =>
    AliyunWanxV2OutputTaskMetric(
      (json['TOTAL'] as num).toInt(),
      (json['SUCCEEDED'] as num).toInt(),
      (json['FAILED'] as num).toInt(),
    );

Map<String, dynamic> _$AliyunWanxV2OutputTaskMetricToJson(
        AliyunWanxV2OutputTaskMetric instance) =>
    <String, dynamic>{
      'TOTAL': instance.total,
      'SUCCEEDED': instance.succeeded,
      'FAILED': instance.failed,
    };

AliyunWanxV2Usage _$AliyunWanxV2UsageFromJson(Map<String, dynamic> json) =>
    AliyunWanxV2Usage(
      (json['image_count'] as num).toInt(),
    );

Map<String, dynamic> _$AliyunWanxV2UsageToJson(AliyunWanxV2Usage instance) =>
    <String, dynamic>{
      'image_count': instance.imageCount,
    };
