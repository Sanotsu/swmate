// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cogvideox_req.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CogVideoXReq _$CogVideoXReqFromJson(Map<String, dynamic> json) => CogVideoXReq(
      model: json['model'] as String,
      prompt: json['prompt'] as String?,
      imageUrl: json['image_url'] as String?,
      requestId: json['request_id'] as String?,
      userId: json['user_id'] as String?,
    );

Map<String, dynamic> _$CogVideoXReqToJson(CogVideoXReq instance) =>
    <String, dynamic>{
      'model': instance.model,
      'prompt': instance.prompt,
      'image_url': instance.imageUrl,
      'request_id': instance.requestId,
      'user_id': instance.userId,
    };
