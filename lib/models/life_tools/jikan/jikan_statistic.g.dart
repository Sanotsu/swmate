// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jikan_statistic.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JikanStatistic _$JikanStatisticFromJson(Map<String, dynamic> json) =>
    JikanStatistic(
      JikanStatisticData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$JikanStatisticToJson(JikanStatistic instance) =>
    <String, dynamic>{
      'data': instance.data.toJson(),
    };

JikanStatisticData _$JikanStatisticDataFromJson(Map<String, dynamic> json) =>
    JikanStatisticData(
      watching: (json['watching'] as num?)?.toInt(),
      planToWatch: (json['plan_to_watch'] as num?)?.toInt(),
      reading: (json['reading'] as num?)?.toInt(),
      planToRead: (json['plan_to_read'] as num?)?.toInt(),
      completed: (json['completed'] as num?)?.toInt(),
      onHold: (json['on_hold'] as num?)?.toInt(),
      dropped: (json['dropped'] as num?)?.toInt(),
      total: (json['total'] as num?)?.toInt(),
      scores: (json['scores'] as List<dynamic>?)
          ?.map((e) => JikanStatisticScore.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$JikanStatisticDataToJson(JikanStatisticData instance) =>
    <String, dynamic>{
      'watching': instance.watching,
      'plan_to_watch': instance.planToWatch,
      'reading': instance.reading,
      'plan_to_read': instance.planToRead,
      'completed': instance.completed,
      'on_hold': instance.onHold,
      'dropped': instance.dropped,
      'total': instance.total,
      'scores': instance.scores?.map((e) => e.toJson()).toList(),
    };

JikanStatisticScore _$JikanStatisticScoreFromJson(Map<String, dynamic> json) =>
    JikanStatisticScore(
      (json['score'] as num).toInt(),
      (json['votes'] as num).toInt(),
      (json['percentage'] as num).toDouble(),
    );

Map<String, dynamic> _$JikanStatisticScoreToJson(
        JikanStatisticScore instance) =>
    <String, dynamic>{
      'score': instance.score,
      'votes': instance.votes,
      'percentage': instance.percentage,
    };
