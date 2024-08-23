import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'silicon_flow_ig_resp.g.dart';

///
/// 【以 siliconflow 的出参为基准的响应类】
/// sf平台的文生图和图生图响应是一样的结构
///
/// SiliconFlowIG => SiliconFlow image generation response
///
/*
{
  "images": [
    {
      "url": "string"
    }
  ],
  "timings": {
    "inference": 0
  },
  "seed": 0
}
*/
@JsonSerializable(explicitToJson: true)
class SiliconFlowIGResp {
  // 正确返回时的内容
  @JsonKey(name: 'images')
  List<SFIGImage>? images;
  @JsonKey(name: 'timings')
  Timings? timings;
  @JsonKey(name: 'shared_id')
  String? sharedId;

  // 返回的错误信息相关
  @JsonKey(name: 'code')
  int? code;
  @JsonKey(name: 'message')
  String? message;
  @JsonKey(name: 'data')
  String? data;
  @JsonKey(name: 'error')
  String? error;

  SiliconFlowIGResp({
    this.images,
    this.timings,
    this.sharedId,
    this.code,
    this.message,
    this.data,
    this.error,
  });

  // 从字符串转
  factory SiliconFlowIGResp.fromRawJson(String str) =>
      SiliconFlowIGResp.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory SiliconFlowIGResp.fromJson(Map<String, dynamic> srcJson) =>
      _$SiliconFlowIGRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$SiliconFlowIGRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SFIGImage {
  @JsonKey(name: 'url')
  String url;

  SFIGImage(this.url);

  // 从字符串转
  factory SFIGImage.fromRawJson(String str) =>
      SFIGImage.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory SFIGImage.fromJson(Map<String, dynamic> srcJson) =>
      _$SFIGImageFromJson(srcJson);

  Map<String, dynamic> toJson() => _$SFIGImageToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Timings {
  @JsonKey(name: 'inference')
  double inference;

  Timings(
    this.inference,
  );

  // 从字符串转
  factory Timings.fromRawJson(String str) => Timings.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory Timings.fromJson(Map<String, dynamic> srcJson) =>
      _$TimingsFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TimingsToJson(this);
}
