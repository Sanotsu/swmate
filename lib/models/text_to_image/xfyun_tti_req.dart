import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'xfyun_tti_req.g.dart';

///
/// 讯飞云图片生成的通用请求参数
///
/*
示例参数
{
  "header": {
    "app_id": "your_appid", // 应用的app_id
    "uid":"your_uid" // 非必传
    },
  "parameter": {
    "chat": {
      "domain": "general",
      "width": 512,
      "height": 512
      }
    },
  "payload": {
    "message": {
      "text": [{
        "role": CusRole.user.name,
        "content": "帮我画一座山"
        }]
    }
  }
}
*/
@JsonSerializable(explicitToJson: true)
class XfyunTtiReq {
  // 响应的header和payload和请求的完全不一样
  // (2024-08-17考虑放到一起？)
  @JsonKey(name: 'header')
  XfyunTtiReqHeader header;

  @JsonKey(name: 'parameter')
  XfyunTtiReqParameter parameter;

  @JsonKey(name: 'payload')
  XfyunTtiReqPayload payload;

  XfyunTtiReq({
    required this.header,
    required this.parameter,
    required this.payload,
  });

  // 从字符串转
  factory XfyunTtiReq.fromRawJson(String str) =>
      XfyunTtiReq.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory XfyunTtiReq.fromJson(Map<String, dynamic> srcJson) =>
      _$XfyunTtiReqFromJson(srcJson);

  Map<String, dynamic> toJson() => _$XfyunTtiReqToJson(this);
}

@JsonSerializable(explicitToJson: true)
class XfyunTtiReqHeader {
  @JsonKey(name: 'app_id')
  String appId;
  @JsonKey(name: 'uid')
  String? uid;

  XfyunTtiReqHeader({
    required this.appId,
    this.uid,
  });

  // 从字符串转
  factory XfyunTtiReqHeader.fromRawJson(String str) =>
      XfyunTtiReqHeader.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory XfyunTtiReqHeader.fromJson(Map<String, dynamic> srcJson) =>
      _$XfyunTtiReqHeaderFromJson(srcJson);

  Map<String, dynamic> toJson() => _$XfyunTtiReqHeaderToJson(this);
}

@JsonSerializable(explicitToJson: true)
class XfyunTtiReqParameter {
  @JsonKey(name: 'chat')
  XfyunTtiReqChat chat;

  XfyunTtiReqParameter({
    required this.chat,
  });

  // 从字符串转
  factory XfyunTtiReqParameter.fromRawJson(String str) =>
      XfyunTtiReqParameter.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory XfyunTtiReqParameter.fromJson(Map<String, dynamic> srcJson) =>
      _$XfyunTtiReqParameterFromJson(srcJson);

  Map<String, dynamic> toJson() => _$XfyunTtiReqParameterToJson(this);
}

@JsonSerializable(explicitToJson: true)
class XfyunTtiReqChat {
  @JsonKey(name: 'domain')
  String? domain;

  @JsonKey(name: 'width')
  int width;

  @JsonKey(name: 'height')
  int height;

  XfyunTtiReqChat({
    this.domain,
    required this.width,
    required this.height,
  });

  // 从字符串转
  factory XfyunTtiReqChat.fromRawJson(String str) =>
      XfyunTtiReqChat.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory XfyunTtiReqChat.fromJson(Map<String, dynamic> srcJson) =>
      _$XfyunTtiReqChatFromJson(srcJson);

  Map<String, dynamic> toJson() => _$XfyunTtiReqChatToJson(this);
}

@JsonSerializable(explicitToJson: true)
class XfyunTtiReqPayload {
  @JsonKey(name: 'message')
  XfyunTtiReqMessage message;

  XfyunTtiReqPayload({
    required this.message,
  });

  // 从字符串转
  factory XfyunTtiReqPayload.fromRawJson(String str) =>
      XfyunTtiReqPayload.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory XfyunTtiReqPayload.fromJson(Map<String, dynamic> srcJson) =>
      _$XfyunTtiReqPayloadFromJson(srcJson);

  Map<String, dynamic> toJson() => _$XfyunTtiReqPayloadToJson(this);
}

@JsonSerializable(explicitToJson: true)
class XfyunTtiReqMessage {
  @JsonKey(name: 'text')
  List<XfyunTtiReqText> text;

  XfyunTtiReqMessage({
    required this.text,
  });

  // 从字符串转
  factory XfyunTtiReqMessage.fromRawJson(String str) =>
      XfyunTtiReqMessage.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory XfyunTtiReqMessage.fromJson(Map<String, dynamic> srcJson) =>
      _$XfyunTtiReqMessageFromJson(srcJson);

  Map<String, dynamic> toJson() => _$XfyunTtiReqMessageToJson(this);
}

@JsonSerializable(explicitToJson: true)
class XfyunTtiReqText {
  @JsonKey(name: 'role')
  String role;

  @JsonKey(name: 'content')
  String content;

  XfyunTtiReqText({
    required this.role,
    required this.content,
  });

  // 从字符串转
  factory XfyunTtiReqText.fromRawJson(String str) =>
      XfyunTtiReqText.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory XfyunTtiReqText.fromJson(Map<String, dynamic> srcJson) =>
      _$XfyunTtiReqTextFromJson(srcJson);

  Map<String, dynamic> toJson() => _$XfyunTtiReqTextToJson(this);
}
