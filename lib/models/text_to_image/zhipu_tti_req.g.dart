// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zhipu_tti_req.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CogViewReq _$CogViewReqFromJson(Map<String, dynamic> json) => CogViewReq(
      model: json['model'] as String,
      prompt: json['prompt'] as String?,
      size: json['size'] as String? ?? "1024x1024",
      userId: json['user_id'] as String?,
    );

Map<String, dynamic> _$CogViewReqToJson(CogViewReq instance) =>
    <String, dynamic>{
      'model': instance.model,
      'prompt': instance.prompt,
      'size': instance.size,
      'user_id': instance.userId,
    };
