import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'nix_natural_nutrient_resp.g.dart';

/// nutritionix 食物营养素请求的响应
/// https://www.nutritionix.com/business/api
///
/// 自然语言查询食品营养素信息
/// 具体接口文档：
/// https://docx.riversand.com/developers/docs/natural-language-for-nutrients
///
/// 前缀缩写： Nix
@JsonSerializable(explicitToJson: true)
class NixNaturalNutrientResp {
  @JsonKey(name: 'foods')
  List<NixNutrientFood>? foods;

  NixNaturalNutrientResp({
    this.foods,
  });

  // 从字符串转
  factory NixNaturalNutrientResp.fromRawJson(String str) =>
      NixNaturalNutrientResp.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory NixNaturalNutrientResp.fromJson(Map<String, dynamic> srcJson) =>
      _$NixNaturalNutrientRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$NixNaturalNutrientRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class NixNutrientFood {
  @JsonKey(name: 'food_name')
  String? foodName;

  @JsonKey(name: 'brand_name')
  String? brandName;

  @JsonKey(name: 'serving_qty')
  int? servingQty;

  @JsonKey(name: 'serving_unit')
  String? servingUnit;

  @JsonKey(name: 'serving_weight_grams')
  int? servingWeightGrams;

  @JsonKey(name: 'nf_metric_qty')
  int? nfMetricQty;

  @JsonKey(name: 'nf_metric_uom')
  String? nfMetricUom;

  @JsonKey(name: 'nf_calories')
  double? nfCalories;

  @JsonKey(name: 'nf_total_fat')
  double? nfTotalFat;

  @JsonKey(name: 'nf_saturated_fat')
  double? nfSaturatedFat;

  @JsonKey(name: 'nf_cholesterol')
  int? nfCholesterol;

  @JsonKey(name: 'nf_sodium')
  double? nfSodium;

  @JsonKey(name: 'nf_total_carbohydrate')
  double? nfTotalCarbohydrate;

  @JsonKey(name: 'nf_dietary_fiber')
  double? nfDietaryFiber;

  @JsonKey(name: 'nf_sugars')
  double? nfSugars;

  @JsonKey(name: 'nf_protein')
  double? nfProtein;

  @JsonKey(name: 'nf_potassium')
  double? nfPotassium;

  @JsonKey(name: 'nf_p')
  double? nfP;

  @JsonKey(name: 'full_nutrients')
  List<NixFullNutrient>? fullNutrients;

  @JsonKey(name: 'nix_brand_name')
  String? nixBrandName;

  @JsonKey(name: 'nix_brand_id')
  String? nixBrandId;

  @JsonKey(name: 'nix_item_name')
  String? nixItemName;

  @JsonKey(name: 'nix_item_id')
  String? nixItemId;

  @JsonKey(name: 'upc')
  String? upc;

  @JsonKey(name: 'consumed_at')
  String? consumedAt;

  @JsonKey(name: 'metadata')
  NixMetadata? metadata;

  @JsonKey(name: 'source')
  int? source;

  @JsonKey(name: 'ndb_no')
  int? ndbNo;

  @JsonKey(name: 'tags')
  NixTag? tags;

  @JsonKey(name: 'alt_measures')
  List<NixAltMeasure>? altMeasures;

  @JsonKey(name: 'lat')
  double? lat;

  @JsonKey(name: 'lng')
  double? lng;

  @JsonKey(name: 'meal_type')
  int? mealType;

  @JsonKey(name: 'photo')
  NixPhoto? photo;

  @JsonKey(name: 'sub_recipe')
  String? subRecipe;

  @JsonKey(name: 'note')
  String? note;

  @JsonKey(name: 'class_code')
  String? classCode;

  @JsonKey(name: 'brick_code')
  String? brickCode;

  @JsonKey(name: 'tag_id')
  String? tagId;

  @JsonKey(name: 'updated_at')
  String? updatedAt;

  @JsonKey(name: 'nf_ingredient_statement')
  dynamic nfIngredientStatement;

  NixNutrientFood({
    this.foodName,
    this.servingQty,
    this.servingUnit,
    this.servingWeightGrams,
    this.nfMetricQty,
    this.nfMetricUom,
    this.nfCalories,
    this.nfTotalFat,
    this.nfSaturatedFat,
    this.nfCholesterol,
    this.nfSodium,
    this.nfTotalCarbohydrate,
    this.nfDietaryFiber,
    this.nfSugars,
    this.nfProtein,
    this.nfPotassium,
    this.nfP,
    this.fullNutrients,
    this.consumedAt,
    this.metadata,
    this.source,
    this.ndbNo,
    this.tags,
    this.altMeasures,
    this.mealType,
    this.photo,
    this.brandName,
    this.brickCode,
    this.classCode,
    this.lat,
    this.lng,
    this.nixBrandId,
    this.nixBrandName,
    this.nixItemId,
    this.nixItemName,
    this.subRecipe,
    this.tagId,
    this.note,
    this.updatedAt,
    this.upc,
    this.nfIngredientStatement,
  });

  // 从字符串转
  factory NixNutrientFood.fromRawJson(String str) =>
      NixNutrientFood.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory NixNutrientFood.fromJson(Map<String, dynamic> srcJson) =>
      _$NixNutrientFoodFromJson(srcJson);

  Map<String, dynamic> toJson() => _$NixNutrientFoodToJson(this);
}

@JsonSerializable(explicitToJson: true)
class NixFullNutrient {
  @JsonKey(name: 'attr_id')
  int? attrId;

  @JsonKey(name: 'value')
  double? value;

  NixFullNutrient({
    this.attrId,
    this.value,
  });

  // 从字符串转
  factory NixFullNutrient.fromRawJson(String str) =>
      NixFullNutrient.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory NixFullNutrient.fromJson(Map<String, dynamic> srcJson) =>
      _$NixFullNutrientFromJson(srcJson);

  Map<String, dynamic> toJson() => _$NixFullNutrientToJson(this);
}

@JsonSerializable(explicitToJson: true)
class NixMetadata {
  @JsonKey(name: 'is_raw_food')
  bool? isRawFood;

  NixMetadata({
    this.isRawFood,
  });

  // 从字符串转
  factory NixMetadata.fromRawJson(String str) =>
      NixMetadata.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory NixMetadata.fromJson(Map<String, dynamic> srcJson) =>
      _$NixMetadataFromJson(srcJson);

  Map<String, dynamic> toJson() => _$NixMetadataToJson(this);
}

@JsonSerializable(explicitToJson: true)
class NixTag {
  @JsonKey(name: 'item')
  String? item;

  @JsonKey(name: 'measure')
  String? measure;

  @JsonKey(name: 'quantity')
  String? quantity;

  @JsonKey(name: 'food_group')
  int? foodGroup;

  @JsonKey(name: 'tag_id')
  int? tagId;

  NixTag({
    this.item,
    this.measure,
    this.quantity,
    this.foodGroup,
    this.tagId,
  });

  // 从字符串转
  factory NixTag.fromRawJson(String str) => NixTag.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory NixTag.fromJson(Map<String, dynamic> srcJson) =>
      _$NixTagFromJson(srcJson);

  Map<String, dynamic> toJson() => _$NixTagToJson(this);
}

@JsonSerializable(explicitToJson: true)
class NixAltMeasure {
  @JsonKey(name: 'serving_weight')
  int? servingWeight;

  @JsonKey(name: 'measure')
  String? measure;

  @JsonKey(name: 'seq')
  int? seq;

  @JsonKey(name: 'qty')
  int? qty;

  NixAltMeasure({
    this.servingWeight,
    this.measure,
    this.seq,
    this.qty,
  });

  // 从字符串转
  factory NixAltMeasure.fromRawJson(String str) =>
      NixAltMeasure.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory NixAltMeasure.fromJson(Map<String, dynamic> srcJson) =>
      _$NixAltMeasureFromJson(srcJson);

  Map<String, dynamic> toJson() => _$NixAltMeasureToJson(this);
}

@JsonSerializable(explicitToJson: true)
class NixPhoto {
  @JsonKey(name: 'thumb')
  String? thumb;

  @JsonKey(name: 'highres')
  String? highres;

  @JsonKey(name: 'is_user_uploaded')
  bool? isUserUploaded;

  NixPhoto({
    this.thumb,
    this.highres,
    this.isUserUploaded,
  });

  // 从字符串转
  factory NixPhoto.fromRawJson(String str) =>
      NixPhoto.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory NixPhoto.fromJson(Map<String, dynamic> srcJson) =>
      _$NixPhotoFromJson(srcJson);

  Map<String, dynamic> toJson() => _$NixPhotoToJson(this);
}
