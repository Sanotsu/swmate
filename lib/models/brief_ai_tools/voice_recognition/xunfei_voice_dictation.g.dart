// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'xunfei_voice_dictation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

XunfeiVoiceDictation _$XunfeiVoiceDictationFromJson(
        Map<String, dynamic> json) =>
    XunfeiVoiceDictation(
      json['sid'] as String?,
      (json['code'] as num?)?.toInt(),
      json['message'] as String?,
      json['data'] == null
          ? null
          : XVDData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$XunfeiVoiceDictationToJson(
        XunfeiVoiceDictation instance) =>
    <String, dynamic>{
      'sid': instance.sid,
      'code': instance.code,
      'message': instance.message,
      'data': instance.data?.toJson(),
    };

XVDData _$XVDDataFromJson(Map<String, dynamic> json) => XVDData(
      (json['status'] as num?)?.toInt(),
      json['result'] == null
          ? null
          : XVDDataResult.fromJson(json['result'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$XVDDataToJson(XVDData instance) => <String, dynamic>{
      'status': instance.status,
      'result': instance.result?.toJson(),
    };

XVDDataResult _$XVDDataResultFromJson(Map<String, dynamic> json) =>
    XVDDataResult(
      json['ls'] as bool?,
      (json['bg'] as num?)?.toInt(),
      (json['ed'] as num?)?.toInt(),
      (json['ws'] as List<dynamic>?)
          ?.map((e) => XVDDataResultWs.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['sn'] as num?)?.toInt(),
    );

Map<String, dynamic> _$XVDDataResultToJson(XVDDataResult instance) =>
    <String, dynamic>{
      'sn': instance.sn,
      'ls': instance.ls,
      'bg': instance.bg,
      'ed': instance.ed,
      'ws': instance.ws?.map((e) => e.toJson()).toList(),
    };

XVDDataResultWs _$XVDDataResultWsFromJson(Map<String, dynamic> json) =>
    XVDDataResultWs(
      (json['bg'] as num?)?.toInt(),
      (json['cw'] as List<dynamic>?)
          ?.map((e) => XVDDataResultWsCw.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$XVDDataResultWsToJson(XVDDataResultWs instance) =>
    <String, dynamic>{
      'bg': instance.bg,
      'cw': instance.cw?.map((e) => e.toJson()).toList(),
    };

XVDDataResultWsCw _$XVDDataResultWsCwFromJson(Map<String, dynamic> json) =>
    XVDDataResultWsCw(
      (json['sc'] as num?)?.toInt(),
      json['w'] as String?,
    );

Map<String, dynamic> _$XVDDataResultWsCwToJson(XVDDataResultWsCw instance) =>
    <String, dynamic>{
      'w': instance.w,
      'sc': instance.sc,
    };
