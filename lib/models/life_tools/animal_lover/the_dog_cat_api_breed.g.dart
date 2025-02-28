// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'the_dog_cat_api_breed.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TheDogCatApiResp _$TheDogCatApiRespFromJson(Map<String, dynamic> json) =>
    TheDogCatApiResp(
      json['id'] as String,
      json['url'] as String,
      (json['breeds'] as List<dynamic>)
          .map((e) => Breed.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TheDogCatApiRespToJson(TheDogCatApiResp instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'breeds': instance.breeds.map((e) => e.toJson()).toList(),
    };

Breed _$BreedFromJson(Map<String, dynamic> json) => Breed(
      id: json['id'],
      name: json['name'] as String?,
      breedGroup: json['breed_group'] as String?,
      temperament: json['temperament'] as String?,
      origin: json['origin'] as String?,
      description: json['description'] as String?,
      lifeSpan: json['life_span'] as String?,
      altNames: json['alt_names'] as String?,
      wikipediaUrl: json['wikipedia_url'] as String?,
      referenceImageId: json['reference_image_id'] as String?,
      dataSource: json['data_source'] as String?,
    );

Map<String, dynamic> _$BreedToJson(Breed instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'breed_group': instance.breedGroup,
      'temperament': instance.temperament,
      'origin': instance.origin,
      'description': instance.description,
      'life_span': instance.lifeSpan,
      'alt_names': instance.altNames,
      'wikipedia_url': instance.wikipediaUrl,
      'reference_image_id': instance.referenceImageId,
      'data_source': instance.dataSource,
    };
