import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'xfyun_tti_resp.g.dart';

///
/// 讯飞云图片生成的通用响应求参数
///
@JsonSerializable(explicitToJson: true)
class XfyunTtiResp {
  // 响应的header和payload和请求的完全不一样(响应就简单全可为空了)
  @JsonKey(name: 'header')
  XfyunTtiRespHeader? header;

  @JsonKey(name: 'payload')
  XfyunTtiRespPayload? payload;

  XfyunTtiResp({
    this.header,
    this.payload,
  });

  // 从字符串转
  factory XfyunTtiResp.fromRawJson(String str) =>
      XfyunTtiResp.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory XfyunTtiResp.fromJson(Map<String, dynamic> srcJson) =>
      _$XfyunTtiRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$XfyunTtiRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class XfyunTtiRespHeader {
  // 服务错误码 ， 0表示正常，非0表示出错
  @JsonKey(name: 'code')
  int? code;

  // 返回消息描述 ，错误码的描述信息
  @JsonKey(name: 'message')
  String? message;

  // 会话的sid
  @JsonKey(name: 'sid')
  String? sid;

  // 会话的状态 ，文生图场景下为2
  @JsonKey(name: 'status')
  int? status;

  XfyunTtiRespHeader({
    this.code,
    this.message,
    this.sid,
    this.status,
  });

  // 从字符串转
  factory XfyunTtiRespHeader.fromRawJson(String str) =>
      XfyunTtiRespHeader.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory XfyunTtiRespHeader.fromJson(Map<String, dynamic> srcJson) =>
      _$XfyunTtiRespHeaderFromJson(srcJson);

  Map<String, dynamic> toJson() => _$XfyunTtiRespHeaderToJson(this);
}

@JsonSerializable(explicitToJson: true)
class XfyunTtiRespPayload {
  @JsonKey(name: 'choices')
  XfyunTtiRespChoice? choices;

  XfyunTtiRespPayload({
    this.choices,
  });

  // 从字符串转
  factory XfyunTtiRespPayload.fromRawJson(String str) =>
      XfyunTtiRespPayload.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory XfyunTtiRespPayload.fromJson(Map<String, dynamic> srcJson) =>
      _$XfyunTtiRespPayloadFromJson(srcJson);

  Map<String, dynamic> toJson() => _$XfyunTtiRespPayloadToJson(this);
}

@JsonSerializable(explicitToJson: true)
class XfyunTtiRespChoice {
  // 数据状态 ，0:开始, 1:开始, 2:结束（表示文本响应结束）
  @JsonKey(name: 'status')
  int? status;

  // 数据序号，最小值:0, 最大值:9999999
  @JsonKey(name: 'seq')
  int? seq;

  // 文本结果 ，是一个json 数组
  @JsonKey(name: 'text')
  List<XfyunTtiRespText>? text;

  XfyunTtiRespChoice({
    this.status,
    this.seq,
    this.text,
  });

  // 从字符串转
  factory XfyunTtiRespChoice.fromRawJson(String str) =>
      XfyunTtiRespChoice.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory XfyunTtiRespChoice.fromJson(Map<String, dynamic> srcJson) =>
      _$XfyunTtiRespChoiceFromJson(srcJson);

  Map<String, dynamic> toJson() => _$XfyunTtiRespChoiceToJson(this);
}

@JsonSerializable(explicitToJson: true)
class XfyunTtiRespText {
  // 返回的base64图片结果，默认分辨率512*512
  @JsonKey(name: 'content')
  String? content;

  // 结果序号，在多候选中使用
  @JsonKey(name: 'index')
  int? index;

  // 角色，assistant说明这是AI的回复
  @JsonKey(name: 'role')
  String? role;

  XfyunTtiRespText({
    this.content,
    this.index,
    this.role,
  });

  // 从字符串转
  factory XfyunTtiRespText.fromRawJson(String str) =>
      XfyunTtiRespText.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory XfyunTtiRespText.fromJson(Map<String, dynamic> srcJson) =>
      _$XfyunTtiRespTextFromJson(srcJson);

  Map<String, dynamic> toJson() => _$XfyunTtiRespTextToJson(this);
}
