import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'image_generation_response.g.dart';

/// 2025-02-17 图片生成的响应，各个平台返回的格式不一样
/// 最主要的例如硅基流动，是直接返回图片结果，阿里云是返回任务id，然后轮询任务结果

// 这个是得到结果的内容，任务id那种会另外处理：轮询到完成后把图片结果放到这个response中来
@JsonSerializable(explicitToJson: true)
class ImageGenerationResponse {
  /// 阿里云的Flux
  // 系统生成的标志本次调用的id。
  @JsonKey(name: 'request_id')
  final String? requestId;

  // 成功响应的任务结果
  @JsonKey(name: 'output')
  AliyunWanxV2Output? output;

  // 表示请求失败，表示错误码，成功忽略。
  @JsonKey(name: 'code')
  final String? code;
  // 表示请求失败，表示错误信息，成功忽略。
  @JsonKey(name: 'message')
  final String? message;

  // 硅基流动
  final List<ImageGenerationResult>? images;
  final Map<String, int>? timings;
  final int? seed;

  // 智谱
  final int? created;
  final List<ImageGenerationResult>? data;
  @JsonKey(name: 'content_filter')
  final List<Map<String, dynamic>>? contentFilter;

  /// 自定义的返回结果
  List<ImageGenerationResult> results;

  ImageGenerationResponse({
    this.created,
    this.output,
    this.requestId,
    this.code,
    this.message,
    this.images,
    this.timings,
    this.seed,
    this.data,
    this.contentFilter,
    List<ImageGenerationResult>? results,
  }) : results = results ?? _generatecusText(data, images);

  static List<ImageGenerationResult> _generatecusText(
    List<ImageGenerationResult>? data,
    List<ImageGenerationResult>? images,
  ) {
    // 非流式的
    if (data != null && data.isNotEmpty) {
      return data;
    }
    // 流式的
    if (images != null && images.isNotEmpty) {
      return images;
    }

    return [];
  }

  // 从字符串转
  factory ImageGenerationResponse.fromRawJson(String str) =>
      ImageGenerationResponse.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory ImageGenerationResponse.fromJson(Map<String, dynamic> srcJson) =>
      _$ImageGenerationResponseFromJson(srcJson);

  Map<String, dynamic> toJson() => _$ImageGenerationResponseToJson(this);
}

// 统一的图片生成结果
@JsonSerializable(explicitToJson: true)
class ImageGenerationResult {
  final String url;
  @JsonKey(name: 'orig_prompt')
  final String? origPrompt;
  @JsonKey(name: 'actual_prompt')
  final String? actualPrompt;

  ImageGenerationResult({
    required this.url,
    this.origPrompt,
    this.actualPrompt,
  });

  // 从字符串转
  factory ImageGenerationResult.fromRawJson(String str) =>
      ImageGenerationResult.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory ImageGenerationResult.fromJson(Map<String, dynamic> srcJson) =>
      _$ImageGenerationResultFromJson(srcJson);

  Map<String, dynamic> toJson() => _$ImageGenerationResultToJson(this);
}

///
/// 阿里云的 "通义万相" 的请求参数
/// (注意，完整文生图，包含了提交job和查询job状态两个部分)
/// (阿里的文本对话模型已有兼容openai API的了，但文生图还是自己的)
///
/// part1 提交job 的响应
/// part2 查询job 状态的响应
/// 把栏位合并了，都放在这里
/// 所以，两个接口响应，只需要这个一个响应体
///
@JsonSerializable(explicitToJson: true)
class AliyunWanxV2Resp {
  // 本次请求的系统唯一码
  @JsonKey(name: 'request_id')
  String requestId;

  @JsonKey(name: 'output')
  AliyunWanxV2Output output;

  // 此次任务消耗了几次
  // 20240815 一张图一次，一次1毛6呢，全失败了可能就没这个参数
  @JsonKey(name: 'usage')
  AliyunWanxV2Usage? usage;

  // 提交作业请求出错时，code 和 message 指明出错原因
  @JsonKey(name: 'code')
  String? code;

  @JsonKey(name: 'message')
  String? message;

  AliyunWanxV2Resp({
    required this.requestId,
    required this.output,
    this.usage,
    this.code,
    this.message,
  });

  // 从字符串转
  factory AliyunWanxV2Resp.fromRawJson(String str) =>
      AliyunWanxV2Resp.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory AliyunWanxV2Resp.fromJson(Map<String, dynamic> srcJson) =>
      _$AliyunWanxV2RespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$AliyunWanxV2RespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AliyunWanxV2Output {
  // 本次请求的异步任务的作业 id，实际作业结果需要通过异步任务查询接口获取。
  @JsonKey(name: 'task_id')
  String taskId;

  // 被查询作业的作业状态
  // PENDING 排队中
  // RUNNING 处理中
  // SUCCEEDED 成功
  // FAILED 失败
  // UNKNOWN 作业不存在或状态未知
  @JsonKey(name: 'task_status')
  String taskStatus;

  // 文生图成功后，结果列表(不用单独独立阿里云的，和其他平台结构类似)
  @JsonKey(name: 'results')
  List<ImageGenerationResult>? results;

  // 文生图任务指标(总共多个图、成功多少、失败多少)
  @JsonKey(name: 'task_metrics')
  AliyunWanxV2OutputTaskMetric? taskMetrics;

  AliyunWanxV2Output(
    this.taskId,
    this.taskStatus,
    this.results,
    this.taskMetrics,
  );

  // 从字符串转
  factory AliyunWanxV2Output.fromRawJson(String str) =>
      AliyunWanxV2Output.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory AliyunWanxV2Output.fromJson(Map<String, dynamic> srcJson) =>
      _$AliyunWanxV2OutputFromJson(srcJson);

  Map<String, dynamic> toJson() => _$AliyunWanxV2OutputToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AliyunWanxV2OutputTaskMetric {
  @JsonKey(name: 'TOTAL')
  int total;

  @JsonKey(name: 'SUCCEEDED')
  int succeeded;

  @JsonKey(name: 'FAILED')
  int failed;

  AliyunWanxV2OutputTaskMetric(
    this.total,
    this.succeeded,
    this.failed,
  );

  // 从字符串转
  factory AliyunWanxV2OutputTaskMetric.fromRawJson(String str) =>
      AliyunWanxV2OutputTaskMetric.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory AliyunWanxV2OutputTaskMetric.fromJson(Map<String, dynamic> srcJson) =>
      _$AliyunWanxV2OutputTaskMetricFromJson(srcJson);

  Map<String, dynamic> toJson() => _$AliyunWanxV2OutputTaskMetricToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AliyunWanxV2Usage {
  @JsonKey(name: 'image_count')
  int imageCount;

  AliyunWanxV2Usage(
    this.imageCount,
  );

  // 从字符串转
  factory AliyunWanxV2Usage.fromRawJson(String str) =>
      AliyunWanxV2Usage.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory AliyunWanxV2Usage.fromJson(Map<String, dynamic> srcJson) =>
      _$AliyunWanxV2UsageFromJson(srcJson);

  Map<String, dynamic> toJson() => _$AliyunWanxV2UsageToJson(this);
}
