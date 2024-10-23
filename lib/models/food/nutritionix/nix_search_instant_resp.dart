import 'package:json_annotation/json_annotation.dart';

import 'nix_natural_nutrient_resp.dart';

part 'nix_search_instant_resp.g.dart';

/// nutritionix 食物营养素请求的响应
/// https://www.nutritionix.com/business/api
///
/// 关键字查询食品概要信息
/// 具体接口文档：
/// https://docx.riversand.com/developers/docs/instant-endpoint
///
/// 前缀缩写： Nix
///
@JsonSerializable(explicitToJson: true)
class NixSearchInstantResp {
  @JsonKey(name: 'common')
  List<NixCommon>? common;

  @JsonKey(name: 'branded')
  List<NixBranded>? branded;

  NixSearchInstantResp({
    this.common,
    this.branded,
  });

  factory NixSearchInstantResp.fromJson(Map<String, dynamic> srcJson) =>
      _$NixSearchInstantRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$NixSearchInstantRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class NixCommon {
  @JsonKey(name: 'food_name')
  String? foodName;

  @JsonKey(name: 'serving_unit')
  String? servingUnit;

  @JsonKey(name: 'tag_name')
  String? tagName;

  @JsonKey(name: 'serving_qty')
  int? servingQty;

  @JsonKey(name: 'common_type')
  dynamic commonType;

  @JsonKey(name: 'tag_id')
  String? tagId;

  @JsonKey(name: 'photo')
  NixPhoto? photo;

  @JsonKey(name: 'locale')
  String? locale;

  NixCommon(
    this.foodName,
    this.servingUnit,
    this.tagName,
    this.servingQty,
    this.commonType,
    this.tagId,
    this.photo,
    this.locale,
  );

  factory NixCommon.fromJson(Map<String, dynamic> srcJson) =>
      _$NixCommonFromJson(srcJson);

  Map<String, dynamic> toJson() => _$NixCommonToJson(this);
}

@JsonSerializable(explicitToJson: true)
class NixBranded {
  @JsonKey(name: 'food_name')
  String? foodName;

  @JsonKey(name: 'serving_unit')
  String? servingUnit;

  @JsonKey(name: 'nix_brand_id')
  String? nixBrandId;

  @JsonKey(name: 'brand_name_item_name')
  String? brandNameItemName;

  @JsonKey(name: 'serving_qty')
  int? servingQty;

  @JsonKey(name: 'nf_calories')
  int? nfCalories;

  @JsonKey(name: 'photo')
  NixPhoto? photo;

  @JsonKey(name: 'brand_name')
  String? brandName;

  @JsonKey(name: 'region')
  int? region;

  @JsonKey(name: 'brand_type')
  int? brandType;

  @JsonKey(name: 'nix_item_id')
  String? nixItemId;

  @JsonKey(name: 'locale')
  String? locale;

  NixBranded({
    this.foodName,
    this.servingUnit,
    this.nixBrandId,
    this.brandNameItemName,
    this.servingQty,
    this.nfCalories,
    this.photo,
    this.brandName,
    this.region,
    this.brandType,
    this.nixItemId,
    this.locale,
  });

  factory NixBranded.fromJson(Map<String, dynamic> srcJson) =>
      _$NixBrandedFromJson(srcJson);

  Map<String, dynamic> toJson() => _$NixBrandedToJson(this);
}
