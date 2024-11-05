import 'package:json_annotation/json_annotation.dart';

import 'nix_natural_nutrient_resp.dart';

part 'nix_natural_exercise_resp.g.dart';

/// nutritionix 食物营养素请求的响应
/// https://www.nutritionix.com/business/api
///
/// 自然语言查询运动消耗信息
/// 具体接口文档：
/// https://docx.riversand.com/developers/docs/natural-language-for-nutrients
///
/// 前缀缩写： Nix
@JsonSerializable(explicitToJson: true)
class NixNaturalExerciseResp {
  @JsonKey(name: 'exercises')
  List<NixExercise>? exercises;

  NixNaturalExerciseResp({
    this.exercises,
  });

  factory NixNaturalExerciseResp.fromJson(Map<String, dynamic> srcJson) =>
      _$NixNaturalExerciseRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$NixNaturalExerciseRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class NixExercise {
  @JsonKey(name: 'tag_id')
  int? tagId;

  @JsonKey(name: 'user_input')
  String? userInput;

  @JsonKey(name: 'duration_min')
  int? durationMin;

  @JsonKey(name: 'met')
  double? met;

  @JsonKey(name: 'nf_calories')
  int? nfCalories;

  @JsonKey(name: 'photo')
  NixPhoto? photo;

  @JsonKey(name: 'compendium_code')
  int? compendiumCode;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'description')
  String? description;

  @JsonKey(name: 'benefits')
  String? benefits;

  NixExercise({
    this.tagId,
    this.userInput,
    this.durationMin,
    this.met,
    this.nfCalories,
    this.photo,
    this.compendiumCode,
    this.name,
    this.description,
    this.benefits,
  });

  factory NixExercise.fromJson(Map<String, dynamic> srcJson) =>
      _$NixExerciseFromJson(srcJson);

  Map<String, dynamic> toJson() => _$NixExerciseToJson(this);
}
