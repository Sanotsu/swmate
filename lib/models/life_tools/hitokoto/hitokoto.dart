import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'hitokoto.g.dart';

/// 一言的API响应
/// https://developer.hitokoto.cn/sentence/
/// 语句库数据来源：https://github.com/hitokoto-osc/sentences-bundle
///
@JsonSerializable(explicitToJson: true)
class Hitokoto {
  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'uuid')
  String? uuid;

  @JsonKey(name: 'hitokoto')
  String? hitokoto;

  @JsonKey(name: 'type')
  String? type;

  @JsonKey(name: 'from')
  String? from;

  @JsonKey(name: 'from_who')
  String? fromWho;

  @JsonKey(name: 'creator')
  String? creator;

  @JsonKey(name: 'creator_uid')
  int? creatorUid;

  @JsonKey(name: 'reviewer')
  int? reviewer;

  @JsonKey(name: 'commit_from')
  String? commitFrom;

  @JsonKey(name: 'created_at')
  String? createdAt;

  @JsonKey(name: 'length')
  int? length;

  Hitokoto({
    this.id,
    this.uuid,
    this.hitokoto,
    this.type,
    this.from,
    this.fromWho,
    this.creator,
    this.creatorUid,
    this.reviewer,
    this.commitFrom,
    this.createdAt,
    this.length,
  });

  factory Hitokoto.fromRawJson(String str) =>
      Hitokoto.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Hitokoto.fromJson(Map<String, dynamic> srcJson) =>
      _$HitokotoFromJson(srcJson);

  Map<String, dynamic> toJson() => _$HitokotoToJson(this);
}
