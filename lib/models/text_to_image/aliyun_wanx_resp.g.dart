// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aliyun_wanx_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AliyunWanxResp _$AliyunWanxRespFromJson(Map<String, dynamic> json) =>
    AliyunWanxResp(
      requestId: json['request_id'] as String,
      output: WanxOutput.fromJson(json['output'] as Map<String, dynamic>),
      usage: json['usage'] == null
          ? null
          : WanxUsage.fromJson(json['usage'] as Map<String, dynamic>),
      code: json['code'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$AliyunWanxRespToJson(AliyunWanxResp instance) =>
    <String, dynamic>{
      'request_id': instance.requestId,
      'output': instance.output.toJson(),
      'usage': instance.usage?.toJson(),
      'code': instance.code,
      'message': instance.message,
    };

WanxOutput _$WanxOutputFromJson(Map<String, dynamic> json) => WanxOutput(
      json['task_id'] as String,
      json['task_status'] as String,
      (json['results'] as List<dynamic>?)
          ?.map((e) => WanxOutputResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['task_metrics'] == null
          ? null
          : WanxTaskMetric.fromJson(
              json['task_metrics'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$WanxOutputToJson(WanxOutput instance) =>
    <String, dynamic>{
      'task_id': instance.taskId,
      'task_status': instance.taskStatus,
      'results': instance.results?.map((e) => e.toJson()).toList(),
      'task_metrics': instance.taskMetrics?.toJson(),
    };

WanxOutputResult _$WanxOutputResultFromJson(Map<String, dynamic> json) =>
    WanxOutputResult(
      json['url'] as String?,
    );

Map<String, dynamic> _$WanxOutputResultToJson(WanxOutputResult instance) =>
    <String, dynamic>{
      'url': instance.url,
    };

WanxTaskMetric _$WanxTaskMetricFromJson(Map<String, dynamic> json) =>
    WanxTaskMetric(
      (json['TOTAL'] as num).toInt(),
      (json['SUCCEEDED'] as num).toInt(),
      (json['FAILED'] as num).toInt(),
    );

Map<String, dynamic> _$WanxTaskMetricToJson(WanxTaskMetric instance) =>
    <String, dynamic>{
      'TOTAL': instance.total,
      'SUCCEEDED': instance.succeeded,
      'FAILED': instance.failed,
    };

WanxUsage _$WanxUsageFromJson(Map<String, dynamic> json) => WanxUsage(
      (json['image_count'] as num).toInt(),
    );

Map<String, dynamic> _$WanxUsageToJson(WanxUsage instance) => <String, dynamic>{
      'image_count': instance.imageCount,
    };
