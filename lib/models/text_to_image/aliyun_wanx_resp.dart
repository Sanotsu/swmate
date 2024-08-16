import 'package:json_annotation/json_annotation.dart';

part 'aliyun_wanx_resp.g.dart';

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
class AliyunWanxResp {
  // 本次请求的系统唯一码
  @JsonKey(name: 'request_id')
  String requestId;

  @JsonKey(name: 'output')
  WanxOutput output;

  // 此次任务消耗了几次
  // 20240815 一张图一次，一次1毛6呢，全失败了可能就没这个参数
  @JsonKey(name: 'usage')
  WanxUsage? usage;

  // 提交作业请求出错时，code 和 message 指明出错原因
  @JsonKey(name: 'code')
  String? code;

  @JsonKey(name: 'message')
  String? message;

  AliyunWanxResp({
    required this.requestId,
    required this.output,
    this.usage,
    this.code,
    this.message,
  });

  factory AliyunWanxResp.fromJson(Map<String, dynamic> srcJson) =>
      _$AliyunWanxRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$AliyunWanxRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class WanxOutput {
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
  List<WanxOutputResult>? results;

  // 文生图任务指标(总共多个图、成功多少、失败多少)
  @JsonKey(name: 'task_metrics')
  WanxTaskMetric? taskMetrics;

  WanxOutput(
    this.taskId,
    this.taskStatus,
    this.results,
    this.taskMetrics,
  );

  factory WanxOutput.fromJson(Map<String, dynamic> srcJson) =>
      _$WanxOutputFromJson(srcJson);

  Map<String, dynamic> toJson() => _$WanxOutputToJson(this);
}

@JsonSerializable(explicitToJson: true)
class WanxOutputResult {
  @JsonKey(name: 'url')
  String? url;

  WanxOutputResult(
    this.url,
  );

  factory WanxOutputResult.fromJson(Map<String, dynamic> srcJson) =>
      _$WanxOutputResultFromJson(srcJson);

  Map<String, dynamic> toJson() => _$WanxOutputResultToJson(this);
}

@JsonSerializable(explicitToJson: true)
class WanxTaskMetric {
  @JsonKey(name: 'TOTAL')
  int total;

  @JsonKey(name: 'SUCCEEDED')
  int succeeded;

  @JsonKey(name: 'FAILED')
  int failed;

  WanxTaskMetric(
    this.total,
    this.succeeded,
    this.failed,
  );

  factory WanxTaskMetric.fromJson(Map<String, dynamic> srcJson) =>
      _$WanxTaskMetricFromJson(srcJson);

  Map<String, dynamic> toJson() => _$WanxTaskMetricToJson(this);
}

@JsonSerializable(explicitToJson: true)
class WanxUsage {
  @JsonKey(name: 'image_count')
  int imageCount;

  WanxUsage(
    this.imageCount,
  );

  factory WanxUsage.fromJson(Map<String, dynamic> srcJson) =>
      _$WanxUsageFromJson(srcJson);

  Map<String, dynamic> toJson() => _$WanxUsageToJson(this);
}
