// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'silicon_flow_ig_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SiliconFlowIGResp _$SiliconFlowIGRespFromJson(Map<String, dynamic> json) =>
    SiliconFlowIGResp(
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => SFIGImage.fromJson(e as Map<String, dynamic>))
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

Map<String, dynamic> _$SiliconFlowIGRespToJson(SiliconFlowIGResp instance) =>
    <String, dynamic>{
      'images': instance.images?.map((e) => e.toJson()).toList(),
      'timings': instance.timings?.toJson(),
      'shared_id': instance.sharedId,
      'code': instance.code,
      'message': instance.message,
      'data': instance.data,
      'error': instance.error,
    };

SFIGImage _$SFIGImageFromJson(Map<String, dynamic> json) => SFIGImage(
      json['url'] as String,
    );

Map<String, dynamic> _$SFIGImageToJson(SFIGImage instance) => <String, dynamic>{
      'url': instance.url,
    };

Timings _$TimingsFromJson(Map<String, dynamic> json) => Timings(
      (json['inference'] as num).toDouble(),
    );

Map<String, dynamic> _$TimingsToJson(Timings instance) => <String, dynamic>{
      'inference': instance.inference,
    };
