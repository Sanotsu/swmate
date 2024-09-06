// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'xfyun_tti_req.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

XfyunTtiReq _$XfyunTtiReqFromJson(Map<String, dynamic> json) => XfyunTtiReq(
      header:
          XfyunTtiReqHeader.fromJson(json['header'] as Map<String, dynamic>),
      parameter: XfyunTtiReqParameter.fromJson(
          json['parameter'] as Map<String, dynamic>),
      payload:
          XfyunTtiReqPayload.fromJson(json['payload'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$XfyunTtiReqToJson(XfyunTtiReq instance) =>
    <String, dynamic>{
      'header': instance.header.toJson(),
      'parameter': instance.parameter.toJson(),
      'payload': instance.payload.toJson(),
    };

XfyunTtiReqHeader _$XfyunTtiReqHeaderFromJson(Map<String, dynamic> json) =>
    XfyunTtiReqHeader(
      appId: json['app_id'] as String,
      uid: json['uid'] as String?,
    );

Map<String, dynamic> _$XfyunTtiReqHeaderToJson(XfyunTtiReqHeader instance) =>
    <String, dynamic>{
      'app_id': instance.appId,
      'uid': instance.uid,
    };

XfyunTtiReqParameter _$XfyunTtiReqParameterFromJson(
        Map<String, dynamic> json) =>
    XfyunTtiReqParameter(
      chat: XfyunTtiReqChat.fromJson(json['chat'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$XfyunTtiReqParameterToJson(
        XfyunTtiReqParameter instance) =>
    <String, dynamic>{
      'chat': instance.chat.toJson(),
    };

XfyunTtiReqChat _$XfyunTtiReqChatFromJson(Map<String, dynamic> json) =>
    XfyunTtiReqChat(
      domain: json['domain'] as String?,
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
    );

Map<String, dynamic> _$XfyunTtiReqChatToJson(XfyunTtiReqChat instance) =>
    <String, dynamic>{
      'domain': instance.domain,
      'width': instance.width,
      'height': instance.height,
    };

XfyunTtiReqPayload _$XfyunTtiReqPayloadFromJson(Map<String, dynamic> json) =>
    XfyunTtiReqPayload(
      message:
          XfyunTtiReqMessage.fromJson(json['message'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$XfyunTtiReqPayloadToJson(XfyunTtiReqPayload instance) =>
    <String, dynamic>{
      'message': instance.message.toJson(),
    };

XfyunTtiReqMessage _$XfyunTtiReqMessageFromJson(Map<String, dynamic> json) =>
    XfyunTtiReqMessage(
      text: (json['text'] as List<dynamic>)
          .map((e) => XfyunTtiReqText.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$XfyunTtiReqMessageToJson(XfyunTtiReqMessage instance) =>
    <String, dynamic>{
      'text': instance.text.map((e) => e.toJson()).toList(),
    };

XfyunTtiReqText _$XfyunTtiReqTextFromJson(Map<String, dynamic> json) =>
    XfyunTtiReqText(
      role: json['role'] as String,
      content: json['content'] as String,
    );

Map<String, dynamic> _$XfyunTtiReqTextToJson(XfyunTtiReqText instance) =>
    <String, dynamic>{
      'role': instance.role,
      'content': instance.content,
    };
