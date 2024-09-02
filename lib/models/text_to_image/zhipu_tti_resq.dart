import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../chat_competion/com_cc_resp.dart';

part 'zhipu_tti_resq.g.dart';

///
/// 智谱AI的 CogView文生图的响应
/// 请求参数和响应内容相较其他比较少一点
///
@JsonSerializable(explicitToJson: true)
class CogViewResp {
  // 创建时间戳
  @JsonKey(name: 'created')
  int? created;

  @JsonKey(name: 'data')
  List<CogViewData>? data;

  // 返回内容安全的相关信息。(glm和cogview都是一样的结构，推测其他也是一样的)
  @JsonKey(name: 'content_filter')
  List<ZhipuContentFilter>? contentFilter;

  // 通用错误信息
  @JsonKey(name: 'error')
  ZhipuError? error;

  CogViewResp({
    this.created,
    this.data,
    this.contentFilter,
    this.error,
  });

  // 从字符串转
  factory CogViewResp.fromRawJson(String str) =>
      CogViewResp.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory CogViewResp.fromJson(Map<String, dynamic> srcJson) =>
      _$CogViewRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$CogViewRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CogViewData {
  // 图片链接。图片的临时链接有效期为 30天，请及时转存图片。
  @JsonKey(name: 'url')
  String? url;

  CogViewData(
    this.url,
  );

  // 从字符串转
  factory CogViewData.fromRawJson(String str) =>
      CogViewData.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory CogViewData.fromJson(Map<String, dynamic> srcJson) =>
      _$CogViewDataFromJson(srcJson);

  Map<String, dynamic> toJson() => _$CogViewDataToJson(this);
}

@JsonSerializable()
class ZhipuError {
  @JsonKey(name: 'code')
  String? code;

  @JsonKey(name: 'message')
  String? message;

  ZhipuError({
    this.code,
    this.message,
  });

  // 从字符串转
  factory ZhipuError.fromRawJson(String str) =>
      ZhipuError.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory ZhipuError.fromJson(Map<String, dynamic> srcJson) =>
      _$ZhipuErrorFromJson(srcJson);

  Map<String, dynamic> toJson() => _$ZhipuErrorToJson(this);
}
