// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enum_nix_nutrient.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnumNixNutrient _$EnumNixNutrientFromJson(Map<String, dynamic> json) =>
    EnumNixNutrient(
      (json['attr_id'] as num).toInt(),
      (json['2018 NFP'] as num).toInt(),
      json['usda_tag'] as String,
      json['name'] as String,
      json['unit'] as String,
      (json['natural (common)'] as num).toInt(),
      (json['item (cpg)'] as num).toInt(),
      (json['item(restaurant)'] as num).toInt(),
      notes: json['Notes'] as String?,
      bulkCsvField: json['bulk_csv_field'] as String?,
    );

Map<String, dynamic> _$EnumNixNutrientToJson(EnumNixNutrient instance) =>
    <String, dynamic>{
      'attr_id': instance.attrId,
      '2018 NFP': instance.npf2018,
      'usda_tag': instance.usdaTag,
      'name': instance.name,
      'unit': instance.unit,
      'natural (common)': instance.naturalCommon,
      'item (cpg)': instance.itemCpg,
      'item(restaurant)': instance.itemRestaurant,
      'Notes': instance.notes,
      'bulk_csv_field': instance.bulkCsvField,
    };
