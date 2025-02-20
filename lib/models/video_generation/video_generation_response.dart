import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

import '../../common/llm_spec/cus_llm_spec.dart';
import '../mapper_utils.dart';

part 'video_generation_response.g.dart';

/// 2025-02-19 图片生成的响应，目前的3个平台都是先返回任务编号，再轮询任务结果
/// 区别在于返回的结构不一样，轮询得到的结果也不一样

// 所以这里
// VideoGenerationSubmitResponse 调用大模型得到任务信息的响应
// VideoGenerationTaskResponse 是提交任务的响应，轮询得到的结果，最后结果也是从这里轮询结束后得到
// VideoGenerationResponse  最后的视频生成的结果，合并多个平台的最后结果

// 最后合并的结果
@JsonSerializable(explicitToJson: true)
class VideoGenerationResponse {
  @JsonKey(name: 'request_id')
  final String? requestId;
  @JsonKey(name: 'task_id')
  final String? taskId;
  final String? status;
  final List<VideoResult>? results;
  final String? code;
  final String? message;

  VideoGenerationResponse({
    this.requestId,
    this.taskId,
    this.status,
    this.results,
    this.code,
    this.message,
  });

  // 从字符串转
  factory VideoGenerationResponse.fromRawJson(String str) =>
      VideoGenerationResponse.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory VideoGenerationResponse.fromJson(Map<String, dynamic> json) =>
      _$VideoGenerationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VideoGenerationResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class VideoResult {
  final String url;
  @JsonKey(name: 'cover_image_url')
  final String? coverImageUrl;

  VideoResult({
    required this.url,
    this.coverImageUrl,
  });

  factory VideoResult.fromJson(Map<String, dynamic> json) =>
      _$VideoResultFromJson(json);

  Map<String, dynamic> toJson() => _$VideoResultToJson(this);
}

// 调用大模型得到任务信息的响应
@JsonSerializable(explicitToJson: true)
class VideoGenerationSubmitResponse {
  // 硅基流动: requestId
  // 只返回请求编号，轮询请求编号得到任务信息
  // @JsonKey(name: 'request_id')
  // 2025-02-19 硅基流动的请求编号是requestId，其他的是request_id
  @JsonKey(readValue: readJsonValue)
  final String? requestId;

  // 智谱AI: request_id id model task_status
  // 会返回请求编号和任务编号，用这个任务编号获取结果
  final String? id;
  // 本次调用的模型名称
  final String? model;
  // 处理状态，PROCESSING（处理中），SUCCESS（成功），FAIL（失败）。需通过查询获取结果
  @JsonKey(name: 'task_status')
  final String? taskStatus;

  // 阿里云的提交任务和轮询任务的output主体结构是一样的
  // output request_id code message
  final AliyunVideoOutput? output;
  // 请求失败的错误码。请求成功时不会返回此参数
  final String? code;
  // 请求失败的详细信息。请求成功时不会返回此参数
  final String? message;

  VideoGenerationSubmitResponse({
    this.requestId,
    this.id,
    this.model,
    this.taskStatus,
    this.output,
    this.code,
    this.message,
  });

  // 从字符串转
  factory VideoGenerationSubmitResponse.fromRawJson(String str) =>
      VideoGenerationSubmitResponse.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory VideoGenerationSubmitResponse.fromJson(Map<String, dynamic> json) =>
      _$VideoGenerationSubmitResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VideoGenerationSubmitResponseToJson(this);

  factory VideoGenerationSubmitResponse.fromResponseBody(
    Map<String, dynamic> json,
    ApiPlatform platform,
  ) {
    switch (platform) {
      case ApiPlatform.siliconCloud:
        return VideoGenerationSubmitResponse(
          requestId: json['requestId'] as String?,
        );

      case ApiPlatform.aliyun:
        return VideoGenerationSubmitResponse(
          requestId: json['request_id'] as String?,
          output: json['output'] != null
              ? AliyunVideoOutput.fromJson(
                  json['output'] as Map<String, dynamic>)
              : null,
          code: json['code'] as String?,
          message: json['message'] as String?,
        );

      case ApiPlatform.zhipu:
        return VideoGenerationSubmitResponse(
          requestId: json['request_id'] as String?,
          id: json['id'] as String?,
          model: json['model'] as String?,
          taskStatus: json['task_status'] as String?,
        );

      default:
        return VideoGenerationSubmitResponse(
          requestId: json['request_id'] as String?,
        );
    }
  }
}

// 轮询得到的结果
@JsonSerializable(explicitToJson: true)
class VideoGenerationTaskResponse {
  /// 硅基流动: status position reason results

  // 状态: Succeed, InProgress
  final String? status;
  // Position in the result set
  final int? position;
  // Reason for the operation
  final String? reason;
  // 结果
  final SiliconflowVideoStatusResult? results;

  /// 智谱AI: model video_result task_status request_id id
  final String? model;
  @JsonKey(name: 'video_result')
  final List<VideoResult>? videoResult;
  // 处理状态，PROCESSING（处理中），SUCCESS（成功），FAIL（失败） 注：处理中状态需通过查询获取结果
  @JsonKey(name: 'task_status')
  final String? taskStatus;
  @JsonKey(name: 'request_id')
  final String? requestId;
  final String? id;

  /// 阿里云: output usage request_id
  final AliyunVideoOutput? output;
  final AliyunVideoUsage? usage;

  VideoGenerationTaskResponse({
    this.status,
    this.position,
    this.reason,
    this.results,
    this.requestId,
    this.id,
    this.model,
    this.taskStatus,
    this.videoResult,
    this.output,
    this.usage,
  });

  // 从字符串转
  factory VideoGenerationTaskResponse.fromRawJson(String str) =>
      VideoGenerationTaskResponse.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory VideoGenerationTaskResponse.fromJson(Map<String, dynamic> json) =>
      _$VideoGenerationTaskResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VideoGenerationTaskResponseToJson(this);

  VideoGenerationTaskResponse fromResponseBody(
    Map<String, dynamic> json,
    ApiPlatform platform,
  ) {
    switch (platform) {
      case ApiPlatform.siliconCloud:
        return VideoGenerationTaskResponse(
          status: json['status'] as String?,
          position: json['position'] as int?,
          reason: json['reason'] as String?,
          results: json['results'] != null
              ? SiliconflowVideoStatusResult.fromJson(
                  json['results'] as Map<String, dynamic>)
              : null,
        );

      case ApiPlatform.aliyun:
        return VideoGenerationTaskResponse(
          requestId: json['request_id'] as String?,
          output: json['output'] != null
              ? AliyunVideoOutput.fromJson(
                  json['output'] as Map<String, dynamic>)
              : null,
          usage: json['usage'] != null
              ? AliyunVideoUsage.fromJson(json['usage'] as Map<String, dynamic>)
              : null,
        );

      case ApiPlatform.zhipu:
        return VideoGenerationTaskResponse(
          requestId: json['request_id'] as String?,
          id: json['id'] as String?,
          model: json['model'] as String?,
          taskStatus: json['task_status'] as String?,
          videoResult: json['video_result'] != null
              ? (json['video_result'] as List)
                  .map((e) => VideoResult.fromJson(e as Map<String, dynamic>))
                  .toList()
              : null,
        );

      default:
        return VideoGenerationTaskResponse(
          requestId: json['request_id'] as String?,
        );
    }
  }
}

// 阿里云视频生成的额外类
@JsonSerializable(explicitToJson: true)
class AliyunVideoOutput {
  // 本次请求的异步任务的作业 id，实际作业结果需要通过异步任务查询接口获取。
  @JsonKey(name: 'task_id')
  String? taskId;

  // 被查询作业的作业状态
  // PENDING 排队中
  // RUNNING 处理中
  // SUCCEEDED 成功
  // FAILED 失败
  // UNKNOWN 作业不存在或状态未知
  @JsonKey(name: 'task_status')
  String? taskStatus;

  @JsonKey(name: 'submit_time')
  String? submitTime;

  @JsonKey(name: 'scheduled_time')
  String? scheduledTime;

  @JsonKey(name: 'end_time')
  String? endTime;

  @JsonKey(name: 'video_url')
  String? videoUrl;

  // 错误码
  final String? code;
  final String? message;

  AliyunVideoOutput(
    this.taskId,
    this.taskStatus,
    this.submitTime,
    this.scheduledTime,
    this.endTime,
    this.videoUrl,
    this.code,
    this.message,
  );

  // 从字符串转
  factory AliyunVideoOutput.fromRawJson(String str) =>
      AliyunVideoOutput.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory AliyunVideoOutput.fromJson(Map<String, dynamic> srcJson) =>
      _$AliyunVideoOutputFromJson(srcJson);

  Map<String, dynamic> toJson() => _$AliyunVideoOutputToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AliyunVideoUsage {
  @JsonKey(name: 'video_count')
  String? videoCount;

  // 文生视频就上面一个，图生视频有这两个属性
  @JsonKey(name: 'video_duration')
  String? videoDuration;

  @JsonKey(name: 'video_ratio')
  String? videoRatio;

  AliyunVideoUsage(
    this.videoCount,
    this.videoDuration,
    this.videoRatio,
  );

  // 从字符串转
  factory AliyunVideoUsage.fromRawJson(String str) =>
      AliyunVideoUsage.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory AliyunVideoUsage.fromJson(Map<String, dynamic> srcJson) =>
      _$AliyunVideoUsageFromJson(srcJson);

  Map<String, dynamic> toJson() => _$AliyunVideoUsageToJson(this);
}

// 硅基流动视频生成的额外类
@JsonSerializable(explicitToJson: true)
class SiliconflowVideoStatusResult {
  int? seed;
  final Map<String, int>? timings;
  final List<VideoResult>? videos;

  SiliconflowVideoStatusResult(
    this.seed,
    this.timings,
    this.videos,
  );

  // 从字符串转
  factory SiliconflowVideoStatusResult.fromRawJson(String str) =>
      SiliconflowVideoStatusResult.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory SiliconflowVideoStatusResult.fromJson(Map<String, dynamic> srcJson) =>
      _$SiliconflowVideoStatusResultFromJson(srcJson);

  Map<String, dynamic> toJson() => _$SiliconflowVideoStatusResultToJson(this);
}
