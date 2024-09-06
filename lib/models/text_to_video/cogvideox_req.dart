import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'cogvideox_req.g.dart';

///
/// 智谱AI的 CogVideoX文生视频的请求
/// 2024-09-02
/// 由于能找到可以个人认证的文生视频的接口比较少，国内能直接用的更少，这些类型参数就一一匹配
///
/// 也分两步：提交任务，查询任务。但查询只需要get请求参数带任务id即可，所以文生视频的请求只需要这一个类
///
/// 后续的batch再看
///
@JsonSerializable(explicitToJson: true)
class CogVideoXReq {
  // 模型名称
  @JsonKey(name: 'model')
  String model;

  // 视频的文本描述、最大支持500Tokens输入
  // prompt和image_url，二者必填其一。
  @JsonKey(name: 'prompt')
  String? prompt;

  // 上传图片进行图生视频，支持通过URL或Base64编码传入图片。
  //  图片支持.png、jpeg、.jpg 格式；图片比例建议为：3:2； 图片大小：不超过5M
  // prompt和image_url，二者必填其一。
  @JsonKey(name: 'image_url')
  String? imageUrl;

  // 由用户端传参，需保证唯一性；用于区分每次请求的唯一标识，用户端不传时平台会默认生成。
  @JsonKey(name: 'request_id')
  String? requestId;

  // 终端用户的唯一ID，协助平台对终端用户的违规行为、生成违法及不良信息或其他滥用行为进行干预。
  // ID长度要求：最少6个字符，最多128个字符。
  @JsonKey(name: 'user_id')
  String? userId;

  CogVideoXReq({
    required this.model,
    required this.prompt,
    this.imageUrl,
    this.requestId,
    this.userId,
  });

  // 从字符串转
  factory CogVideoXReq.fromRawJson(String str) =>
      CogVideoXReq.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory CogVideoXReq.fromJson(Map<String, dynamic> srcJson) =>
      _$CogVideoXReqFromJson(srcJson);

  Map<String, dynamic> toJson() => _$CogVideoXReqToJson(this);
}


/// 
/// 2024-09-02 暂时先不处理
/// 智谱AI 有提高 Batch API
/// 专为处理大规模数据请求而设计，适用于无需即时反馈的任务。
/// 通过 Batch API，开发者可以提交大量的 API 请求，并在 24 小时内获得请求结果，价格仅为标准版定价的50% 。
///
/// 大致流程：
///  1 构建批量任务需要的.jsonl文件
///  2 创建批量任务
///  3 查询批量任务
///  4 下载批量任务结果
///