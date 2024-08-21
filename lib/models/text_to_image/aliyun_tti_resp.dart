import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'aliyun_tti_resp.g.dart';

///
/// 阿里云的 "通义万相" 的请求参数
/// (注意，完整文生图，包含了提交job和查询job状态两个部分)
/// (阿里的文本对话模型已有兼容openai API的了，但文生图还是自己的)
///
/// part1 提交job 的响应
/// part2 查询job状态的响应
/// 把栏位合并了，都放在这里
/// 所以，两个接口响应，只需要这个一个响应体
///
@JsonSerializable(explicitToJson: true)
class AliyunTtiResp {
  // 本次请求的系统唯一码
  @JsonKey(name: 'request_id')
  String requestId;

  @JsonKey(name: 'output')
  AliyunTtiOutput output;

  // 此次任务消耗了几次
  // 20240815 一张图一次，一次1毛6呢，全失败了可能就没这个参数
  @JsonKey(name: 'usage')
  AliyunTtiUsage? usage;

  // 提交作业请求出错时，code 和 message 指明出错原因
  @JsonKey(name: 'code')
  String? code;

  @JsonKey(name: 'message')
  String? message;

  AliyunTtiResp({
    required this.requestId,
    required this.output,
    this.usage,
    this.code,
    this.message,
  });

  // 从字符串转
  factory AliyunTtiResp.fromRawJson(String str) =>
      AliyunTtiResp.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory AliyunTtiResp.fromJson(Map<String, dynamic> srcJson) =>
      _$AliyunTtiRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$AliyunTtiRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AliyunTtiOutput {
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

  // 文生图成功后，结果列表
  @JsonKey(name: 'results')
  List<AliyunTtiOutputResult>? results;

  // 文生图任务指标(总共多个图、成功多少、失败多少)
  @JsonKey(name: 'task_metrics')
  AliyunTtiTaskMetric? taskMetrics;

  AliyunTtiOutput(
    this.taskId,
    this.taskStatus,
    this.results,
    this.taskMetrics,
  );

  // 从字符串转
  factory AliyunTtiOutput.fromRawJson(String str) =>
      AliyunTtiOutput.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory AliyunTtiOutput.fromJson(Map<String, dynamic> srcJson) =>
      _$AliyunTtiOutputFromJson(srcJson);

  Map<String, dynamic> toJson() => _$AliyunTtiOutputToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AliyunTtiOutputResult {
  @JsonKey(name: 'url')
  String? url;
  // 锦书创意文字的文字变形是这两个单独的
  @JsonKey(name: 'svg_url')
  String? svgUrl;
  @JsonKey(name: 'png_url')
  String? pngUrl;

  AliyunTtiOutputResult({this.url, this.svgUrl, this.pngUrl});

  // 从字符串转
  factory AliyunTtiOutputResult.fromRawJson(String str) =>
      AliyunTtiOutputResult.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory AliyunTtiOutputResult.fromJson(Map<String, dynamic> srcJson) =>
      _$AliyunTtiOutputResultFromJson(srcJson);

  Map<String, dynamic> toJson() => _$AliyunTtiOutputResultToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AliyunTtiTaskMetric {
  @JsonKey(name: 'TOTAL')
  int total;

  @JsonKey(name: 'SUCCEEDED')
  int succeeded;

  @JsonKey(name: 'FAILED')
  int failed;

  AliyunTtiTaskMetric(
    this.total,
    this.succeeded,
    this.failed,
  );

  // 从字符串转
  factory AliyunTtiTaskMetric.fromRawJson(String str) =>
      AliyunTtiTaskMetric.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory AliyunTtiTaskMetric.fromJson(Map<String, dynamic> srcJson) =>
      _$AliyunTtiTaskMetricFromJson(srcJson);

  Map<String, dynamic> toJson() => _$AliyunTtiTaskMetricToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AliyunTtiUsage {
  @JsonKey(name: 'image_count')
  int imageCount;

  AliyunTtiUsage(
    this.imageCount,
  );

  // 从字符串转
  factory AliyunTtiUsage.fromRawJson(String str) =>
      AliyunTtiUsage.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory AliyunTtiUsage.fromJson(Map<String, dynamic> srcJson) =>
      _$AliyunTtiUsageFromJson(srcJson);

  Map<String, dynamic> toJson() => _$AliyunTtiUsageToJson(this);
}
