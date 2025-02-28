// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nix_natural_exercise_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NixNaturalExerciseResp _$NixNaturalExerciseRespFromJson(
        Map<String, dynamic> json) =>
    NixNaturalExerciseResp(
      exercises: (json['exercises'] as List<dynamic>?)
          ?.map((e) => NixExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$NixNaturalExerciseRespToJson(
        NixNaturalExerciseResp instance) =>
    <String, dynamic>{
      'exercises': instance.exercises?.map((e) => e.toJson()).toList(),
    };

NixExercise _$NixExerciseFromJson(Map<String, dynamic> json) => NixExercise(
      tagId: (json['tag_id'] as num?)?.toInt(),
      userInput: json['user_input'] as String?,
      durationMin: (json['duration_min'] as num?)?.toInt(),
      met: (json['met'] as num?)?.toDouble(),
      nfCalories: (json['nf_calories'] as num?)?.toInt(),
      photo: json['photo'] == null
          ? null
          : NixPhoto.fromJson(json['photo'] as Map<String, dynamic>),
      compendiumCode: (json['compendium_code'] as num?)?.toInt(),
      name: json['name'] as String?,
      description: json['description'] as String?,
      benefits: json['benefits'] as String?,
    );

Map<String, dynamic> _$NixExerciseToJson(NixExercise instance) =>
    <String, dynamic>{
      'tag_id': instance.tagId,
      'user_input': instance.userInput,
      'duration_min': instance.durationMin,
      'met': instance.met,
      'nf_calories': instance.nfCalories,
      'photo': instance.photo?.toJson(),
      'compendium_code': instance.compendiumCode,
      'name': instance.name,
      'description': instance.description,
      'benefits': instance.benefits,
    };
