// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aliyun_tti_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AliyunTtiResp _$AliyunTtiRespFromJson(Map<String, dynamic> json) =>
    AliyunTtiResp(
      requestId: json['request_id'] as String,
      output: AliyunTtiOutput.fromJson(json['output'] as Map<String, dynamic>),
      usage: json['usage'] == null
          ? null
          : AliyunTtiUsage.fromJson(json['usage'] as Map<String, dynamic>),
      code: json['code'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$AliyunTtiRespToJson(AliyunTtiResp instance) =>
    <String, dynamic>{
      'request_id': instance.requestId,
      'output': instance.output.toJson(),
      'usage': instance.usage?.toJson(),
      'code': instance.code,
      'message': instance.message,
    };

AliyunTtiOutput _$AliyunTtiOutputFromJson(Map<String, dynamic> json) =>
    AliyunTtiOutput(
      json['task_id'] as String,
      json['task_status'] as String,
      (json['results'] as List<dynamic>?)
          ?.map(
              (e) => AliyunTtiOutputResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['task_metrics'] == null
          ? null
          : AliyunTtiTaskMetric.fromJson(
              json['task_metrics'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AliyunTtiOutputToJson(AliyunTtiOutput instance) =>
    <String, dynamic>{
      'task_id': instance.taskId,
      'task_status': instance.taskStatus,
      'results': instance.results?.map((e) => e.toJson()).toList(),
      'task_metrics': instance.taskMetrics?.toJson(),
    };

AliyunTtiOutputResult _$AliyunTtiOutputResultFromJson(
        Map<String, dynamic> json) =>
    AliyunTtiOutputResult(
      url: json['url'] as String?,
      svgUrl: json['svg_url'] as String?,
      pngUrl: json['png_url'] as String?,
    );

Map<String, dynamic> _$AliyunTtiOutputResultToJson(
        AliyunTtiOutputResult instance) =>
    <String, dynamic>{
      'url': instance.url,
      'svg_url': instance.svgUrl,
      'png_url': instance.pngUrl,
    };

AliyunTtiTaskMetric _$AliyunTtiTaskMetricFromJson(Map<String, dynamic> json) =>
    AliyunTtiTaskMetric(
      (json['TOTAL'] as num).toInt(),
      (json['SUCCEEDED'] as num).toInt(),
      (json['FAILED'] as num).toInt(),
    );

Map<String, dynamic> _$AliyunTtiTaskMetricToJson(
        AliyunTtiTaskMetric instance) =>
    <String, dynamic>{
      'TOTAL': instance.total,
      'SUCCEEDED': instance.succeeded,
      'FAILED': instance.failed,
    };

AliyunTtiUsage _$AliyunTtiUsageFromJson(Map<String, dynamic> json) =>
    AliyunTtiUsage(
      (json['image_count'] as num).toInt(),
    );

Map<String, dynamic> _$AliyunTtiUsageToJson(AliyunTtiUsage instance) =>
    <String, dynamic>{
      'image_count': instance.imageCount,
    };
