// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nix_search_instant_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NixSearchInstantResp _$NixSearchInstantRespFromJson(
        Map<String, dynamic> json) =>
    NixSearchInstantResp(
      common: (json['common'] as List<dynamic>?)
          ?.map((e) => NixCommon.fromJson(e as Map<String, dynamic>))
          .toList(),
      branded: (json['branded'] as List<dynamic>?)
          ?.map((e) => NixBranded.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$NixSearchInstantRespToJson(
        NixSearchInstantResp instance) =>
    <String, dynamic>{
      'common': instance.common?.map((e) => e.toJson()).toList(),
      'branded': instance.branded?.map((e) => e.toJson()).toList(),
    };

NixCommon _$NixCommonFromJson(Map<String, dynamic> json) => NixCommon(
      json['food_name'] as String?,
      json['serving_unit'] as String?,
      json['tag_name'] as String?,
      (json['serving_qty'] as num?)?.toInt(),
      json['common_type'],
      json['tag_id'] as String?,
      json['photo'] == null
          ? null
          : NixPhoto.fromJson(json['photo'] as Map<String, dynamic>),
      json['locale'] as String?,
    );

Map<String, dynamic> _$NixCommonToJson(NixCommon instance) => <String, dynamic>{
      'food_name': instance.foodName,
      'serving_unit': instance.servingUnit,
      'tag_name': instance.tagName,
      'serving_qty': instance.servingQty,
      'common_type': instance.commonType,
      'tag_id': instance.tagId,
      'photo': instance.photo?.toJson(),
      'locale': instance.locale,
    };

NixBranded _$NixBrandedFromJson(Map<String, dynamic> json) => NixBranded(
      foodName: json['food_name'] as String?,
      servingUnit: json['serving_unit'] as String?,
      nixBrandId: json['nix_brand_id'] as String?,
      brandNameItemName: json['brand_name_item_name'] as String?,
      servingQty: (json['serving_qty'] as num?)?.toInt(),
      nfCalories: (json['nf_calories'] as num?)?.toInt(),
      photo: json['photo'] == null
          ? null
          : NixPhoto.fromJson(json['photo'] as Map<String, dynamic>),
      brandName: json['brand_name'] as String?,
      region: (json['region'] as num?)?.toInt(),
      brandType: (json['brand_type'] as num?)?.toInt(),
      nixItemId: json['nix_item_id'] as String?,
      locale: json['locale'] as String?,
    );

Map<String, dynamic> _$NixBrandedToJson(NixBranded instance) =>
    <String, dynamic>{
      'food_name': instance.foodName,
      'serving_unit': instance.servingUnit,
      'nix_brand_id': instance.nixBrandId,
      'brand_name_item_name': instance.brandNameItemName,
      'serving_qty': instance.servingQty,
      'nf_calories': instance.nfCalories,
      'photo': instance.photo?.toJson(),
      'brand_name': instance.brandName,
      'region': instance.region,
      'brand_type': instance.brandType,
      'nix_item_id': instance.nixItemId,
      'locale': instance.locale,
    };
