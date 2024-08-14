// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'com_tti_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComTtiResp _$ComTtiRespFromJson(Map<String, dynamic> json) => ComTtiResp(
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => TtiImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      timings: json['timings'] == null
          ? null
          : Timings.fromJson(json['timings'] as Map<String, dynamic>),
      sharedId: json['shared_id'] as String?,
      code: (json['code'] as num?)?.toInt(),
      message: json['message'] as String?,
      data: json['data'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$ComTtiRespToJson(ComTtiResp instance) =>
    <String, dynamic>{
      'images': instance.images?.map((e) => e.toJson()).toList(),
      'timings': instance.timings?.toJson(),
      'shared_id': instance.sharedId,
      'code': instance.code,
      'message': instance.message,
      'data': instance.data,
      'error': instance.error,
    };

TtiImage _$TtiImageFromJson(Map<String, dynamic> json) => TtiImage(
      json['url'] as String,
    );

Map<String, dynamic> _$TtiImageToJson(TtiImage instance) => <String, dynamic>{
      'url': instance.url,
    };

Timings _$TimingsFromJson(Map<String, dynamic> json) => Timings(
      (json['inference'] as num).toDouble(),
    );

Map<String, dynamic> _$TimingsToJson(Timings instance) => <String, dynamic>{
      'inference': instance.inference,
    };
