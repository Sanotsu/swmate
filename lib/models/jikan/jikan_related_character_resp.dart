import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import 'jikan_data.dart';

part 'jikan_related_character_resp.g.dart';

///
/// 动漫关联的角色、漫画关联的角色
/// getAnimeCharacters
/// getMangaCharacters
/// 两者类似，前者有额外的favorites和voice_actors
///
@JsonSerializable(explicitToJson: true)
class JikanRelatedCharacterResp {
  /// 报错的相关栏位没有加

  @JsonKey(name: 'data')
  List<JKRelatedCharacter> data;

  JikanRelatedCharacterResp(
    this.data,
  );

  // 从字符串转
  factory JikanRelatedCharacterResp.fromRawJson(String str) =>
      JikanRelatedCharacterResp.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JikanRelatedCharacterResp.fromJson(Map<String, dynamic> srcJson) =>
      _$JikanRelatedCharacterRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JikanRelatedCharacterRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class JKRelatedCharacter {
  // 结果好像只保留了mail_id url images name 栏位，
  @JsonKey(name: 'character')
  JKData? character;

  @JsonKey(name: 'role')
  String? role;

  @JsonKey(name: 'favorites')
  int? favorites;

  @JsonKey(name: 'voice_actors')
  List<JKVoiceActor>? voiceActors;

  JKRelatedCharacter({
    this.character,
    this.role,
    this.favorites,
    this.voiceActors,
  });

  // 从字符串转
  factory JKRelatedCharacter.fromRawJson(String str) =>
      JKRelatedCharacter.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JKRelatedCharacter.fromJson(Map<String, dynamic> srcJson) =>
      _$JKRelatedCharacterFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JKRelatedCharacterToJson(this);
}

@JsonSerializable(explicitToJson: true)
class JKVoiceActor {
  // 结果好像只保留了mail_id url images name 栏位，
  @JsonKey(name: 'person')
  JKData? person;

  @JsonKey(name: 'language')
  String? language;

  JKVoiceActor({
    this.person,
    this.language,
  });

  // 从字符串转
  factory JKVoiceActor.fromRawJson(String str) =>
      JKVoiceActor.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JKVoiceActor.fromJson(Map<String, dynamic> srcJson) =>
      _$JKVoiceActorFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JKVoiceActorToJson(this);
}
