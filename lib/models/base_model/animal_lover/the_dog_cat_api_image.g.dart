// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'the_dog_cat_api_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TheDogCatApiImage _$TheDogCatApiImageFromJson(Map<String, dynamic> json) =>
    TheDogCatApiImage(
      json['id'] as String,
      json['url'] as String,
      (json['width'] as num).toInt(),
      (json['height'] as num).toInt(),
    );

Map<String, dynamic> _$TheDogCatApiImageToJson(TheDogCatApiImage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'width': instance.width,
      'height': instance.height,
    };
