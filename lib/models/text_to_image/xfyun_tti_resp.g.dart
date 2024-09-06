// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'xfyun_tti_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

XfyunTtiResp _$XfyunTtiRespFromJson(Map<String, dynamic> json) => XfyunTtiResp(
      header: json['header'] == null
          ? null
          : XfyunTtiRespHeader.fromJson(json['header'] as Map<String, dynamic>),
      payload: json['payload'] == null
          ? null
          : XfyunTtiRespPayload.fromJson(
              json['payload'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$XfyunTtiRespToJson(XfyunTtiResp instance) =>
    <String, dynamic>{
      'header': instance.header?.toJson(),
      'payload': instance.payload?.toJson(),
    };

XfyunTtiRespHeader _$XfyunTtiRespHeaderFromJson(Map<String, dynamic> json) =>
    XfyunTtiRespHeader(
      code: (json['code'] as num?)?.toInt(),
      message: json['message'] as String?,
      sid: json['sid'] as String?,
      status: (json['status'] as num?)?.toInt(),
    );

Map<String, dynamic> _$XfyunTtiRespHeaderToJson(XfyunTtiRespHeader instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'sid': instance.sid,
      'status': instance.status,
    };

XfyunTtiRespPayload _$XfyunTtiRespPayloadFromJson(Map<String, dynamic> json) =>
    XfyunTtiRespPayload(
      choices: json['choices'] == null
          ? null
          : XfyunTtiRespChoice.fromJson(
              json['choices'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$XfyunTtiRespPayloadToJson(
        XfyunTtiRespPayload instance) =>
    <String, dynamic>{
      'choices': instance.choices?.toJson(),
    };

XfyunTtiRespChoice _$XfyunTtiRespChoiceFromJson(Map<String, dynamic> json) =>
    XfyunTtiRespChoice(
      status: (json['status'] as num?)?.toInt(),
      seq: (json['seq'] as num?)?.toInt(),
      text: (json['text'] as List<dynamic>?)
          ?.map((e) => XfyunTtiRespText.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$XfyunTtiRespChoiceToJson(XfyunTtiRespChoice instance) =>
    <String, dynamic>{
      'status': instance.status,
      'seq': instance.seq,
      'text': instance.text?.map((e) => e.toJson()).toList(),
    };

XfyunTtiRespText _$XfyunTtiRespTextFromJson(Map<String, dynamic> json) =>
    XfyunTtiRespText(
      content: json['content'] as String?,
      index: (json['index'] as num?)?.toInt(),
      role: json['role'] as String?,
    );

Map<String, dynamic> _$XfyunTtiRespTextToJson(XfyunTtiRespText instance) =>
    <String, dynamic>{
      'content': instance.content,
      'index': instance.index,
      'role': instance.role,
    };
