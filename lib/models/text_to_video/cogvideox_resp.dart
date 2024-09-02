import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../text_to_image/zhipu_tti_resq.dart';

part 'cogvideox_resp.g.dart';

///
/// 智谱AI的 CogVideoX文生视频的响应
/// part1 提交job 的响应
/// part2 查询job状态的响应
/// 把栏位合并了，都放在这里
/// 所以，两个接口响应，只需要这个一个响应体
///
@JsonSerializable(explicitToJson: true)
class CogVideoXResp {
  // 用户在客户端请求时提交的任务编号或者平台生成的任务编号
  @JsonKey(name: 'request_id')
  String? requestId;

  // 智谱 AI 开放平台生成的任务订单号，调用请求结果接口时请使用此订单号
  @JsonKey(name: 'id')
  String? id;

  // 本次调用的模型名称
  @JsonKey(name: 'model')
  String? model;

  // 处理状态(和阿里云通义万相不一样)，
  // PROCESSING（处理中），SUCCESS（成功），FAIL（失败）。
  // 需通过查询获取结果
  @JsonKey(name: 'task_status')
  String? taskStatus;

  // 通用错误信息
  @JsonKey(name: 'error')
  ZhipuError? error;

  // 任务查询的响应结果会多一个栏位
  @JsonKey(name: 'video_result')
  List<CogVideoxResult>? videoResult;

  CogVideoXResp({
    this.requestId,
    this.id,
    this.model,
    this.taskStatus,
    this.error,
  });

  // 从字符串转
  factory CogVideoXResp.fromRawJson(String str) =>
      CogVideoXResp.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory CogVideoXResp.fromJson(Map<String, dynamic> srcJson) =>
      _$CogVideoXRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$CogVideoXRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CogVideoxResult {
  // 视频url
  @JsonKey(name: 'url')
  String url;

  // 视频封面url
  @JsonKey(name: 'cover_image_url')
  String coverImageUrl;

  CogVideoxResult(
    this.url,
    this.coverImageUrl,
  );

  // 从字符串转
  factory CogVideoxResult.fromRawJson(String str) =>
      CogVideoxResult.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory CogVideoxResult.fromJson(Map<String, dynamic> srcJson) =>
      _$CogVideoxResultFromJson(srcJson);

  Map<String, dynamic> toJson() => _$CogVideoxResultToJson(this);
}
