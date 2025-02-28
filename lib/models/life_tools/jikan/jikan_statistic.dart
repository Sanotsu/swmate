import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'jikan_statistic.g.dart';

///
/// 非官方的 MyAnimeList(MAL) API 指定动漫ID返回评分构成的数据结构
///
/// GET https://api.jikan.moe/v4/anime/{id}/statistics
///
@JsonSerializable(explicitToJson: true)
class JikanStatistic {
  @JsonKey(name: 'data')
  JikanStatisticData data;

  JikanStatistic(
    this.data,
  );

  // 从字符串转
  factory JikanStatistic.fromRawJson(String str) =>
      JikanStatistic.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JikanStatistic.fromJson(Map<String, dynamic> srcJson) =>
      _$JikanStatisticFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JikanStatisticToJson(this);
}

@JsonSerializable(explicitToJson: true)
class JikanStatisticData {
  // 动漫统计和漫画统计稍微不同，动画时watch，漫画时reading
  @JsonKey(name: 'watching')
  int? watching;

  @JsonKey(name: 'plan_to_watch')
  int? planToWatch;

  @JsonKey(name: 'reading')
  int? reading;

  @JsonKey(name: 'plan_to_read')
  int? planToRead;

  @JsonKey(name: 'completed')
  int? completed;

  @JsonKey(name: 'on_hold')
  int? onHold;

  @JsonKey(name: 'dropped')
  int? dropped;

  @JsonKey(name: 'total')
  int? total;

  @JsonKey(name: 'scores')
  List<JikanStatisticScore>? scores;

  JikanStatisticData({
    this.watching,
    this.planToWatch,
    this.reading,
    this.planToRead,
    this.completed,
    this.onHold,
    this.dropped,
    this.total,
    this.scores,
  });

  // 从字符串转
  factory JikanStatisticData.fromRawJson(String str) =>
      JikanStatisticData.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JikanStatisticData.fromJson(Map<String, dynamic> srcJson) =>
      _$JikanStatisticDataFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JikanStatisticDataToJson(this);
}

@JsonSerializable(explicitToJson: true)
class JikanStatisticScore {
  @JsonKey(name: 'score')
  int score;

  @JsonKey(name: 'votes')
  int votes;

  @JsonKey(name: 'percentage')
  double percentage;

  JikanStatisticScore(
    this.score,
    this.votes,
    this.percentage,
  );

  // 从字符串转
  factory JikanStatisticScore.fromRawJson(String str) =>
      JikanStatisticScore.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JikanStatisticScore.fromJson(Map<String, dynamic> srcJson) =>
      _$JikanStatisticScoreFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JikanStatisticScoreToJson(this);
}
