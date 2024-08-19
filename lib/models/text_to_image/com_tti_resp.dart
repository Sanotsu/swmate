import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'com_tti_resp.g.dart';

///
/// 【以 siliconflow 的出参为基准的响应类】
///
/// ComTtiResp => common text to image response
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
class ComTtiResp {
  // 正确返回时的内容
  @JsonKey(name: 'images')
  List<TtiImage>? images;
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

  ComTtiResp({
    this.images,
    this.timings,
    this.sharedId,
    this.code,
    this.message,
    this.data,
    this.error,
  });

  // 从字符串转
  factory ComTtiResp.fromRawJson(String str) =>
      ComTtiResp.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory ComTtiResp.fromJson(Map<String, dynamic> srcJson) =>
      _$ComTtiRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$ComTtiRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TtiImage {
  @JsonKey(name: 'url')
  String url;

  TtiImage(this.url);

  // 从字符串转
  factory TtiImage.fromRawJson(String str) =>
      TtiImage.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory TtiImage.fromJson(Map<String, dynamic> srcJson) =>
      _$TtiImageFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TtiImageToJson(this);
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
