// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zhipu_tti_resq.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CogViewResp _$CogViewRespFromJson(Map<String, dynamic> json) => CogViewResp(
      created: (json['created'] as num?)?.toInt(),
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => CogViewData.fromJson(e as Map<String, dynamic>))
          .toList(),
      contentFilter: (json['content_filter'] as List<dynamic>?)
          ?.map((e) => ZhipuContentFilter.fromJson(e as Map<String, dynamic>))
          .toList(),
      error: json['error'] == null
          ? null
          : ZhipuError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CogViewRespToJson(CogViewResp instance) =>
    <String, dynamic>{
      'created': instance.created,
      'data': instance.data?.map((e) => e.toJson()).toList(),
      'content_filter': instance.contentFilter?.map((e) => e.toJson()).toList(),
      'error': instance.error?.toJson(),
    };

CogViewData _$CogViewDataFromJson(Map<String, dynamic> json) => CogViewData(
      json['url'] as String?,
    );

Map<String, dynamic> _$CogViewDataToJson(CogViewData instance) =>
    <String, dynamic>{
      'url': instance.url,
    };

ZhipuError _$ZhipuErrorFromJson(Map<String, dynamic> json) => ZhipuError(
      code: json['code'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$ZhipuErrorToJson(ZhipuError instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
    };
