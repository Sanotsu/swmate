// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jikan_related_character_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JikanRelatedCharacterResp _$JikanRelatedCharacterRespFromJson(
        Map<String, dynamic> json) =>
    JikanRelatedCharacterResp(
      (json['data'] as List<dynamic>)
          .map((e) => JKRelatedCharacter.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$JikanRelatedCharacterRespToJson(
        JikanRelatedCharacterResp instance) =>
    <String, dynamic>{
      'data': instance.data.map((e) => e.toJson()).toList(),
    };

JKRelatedCharacter _$JKRelatedCharacterFromJson(Map<String, dynamic> json) =>
    JKRelatedCharacter(
      character: json['character'] == null
          ? null
          : JKData.fromJson(json['character'] as Map<String, dynamic>),
      role: json['role'] as String?,
      favorites: (json['favorites'] as num?)?.toInt(),
      voiceActors: (json['voice_actors'] as List<dynamic>?)
          ?.map((e) => JKVoiceActor.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$JKRelatedCharacterToJson(JKRelatedCharacter instance) =>
    <String, dynamic>{
      'character': instance.character?.toJson(),
      'role': instance.role,
      'favorites': instance.favorites,
      'voice_actors': instance.voiceActors?.map((e) => e.toJson()).toList(),
    };

JKVoiceActor _$JKVoiceActorFromJson(Map<String, dynamic> json) => JKVoiceActor(
      person: json['person'] == null
          ? null
          : JKData.fromJson(json['person'] as Map<String, dynamic>),
      language: json['language'] as String?,
    );

Map<String, dynamic> _$JKVoiceActorToJson(JKVoiceActor instance) =>
    <String, dynamic>{
      'person': instance.person?.toJson(),
      'language': instance.language,
    };
