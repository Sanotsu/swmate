import 'package:json_annotation/json_annotation.dart';

part 'enum_nix_nutrient.g.dart';

/// 专门给营养素列表枚举值创建的类
/// https://docx.riversand.com/developers/docs/list-of-all-nutrients-and-nutrient-ids-from-api
@JsonSerializable(explicitToJson: true)
class EnumNixNutrient {
  @JsonKey(name: 'attr_id')
  int attrId;

  @JsonKey(name: '2018 NFP')
  int npf2018;

  @JsonKey(name: 'usda_tag')
  String usdaTag;

  @JsonKey(name: 'name')
  String name;

  @JsonKey(name: 'unit')
  String unit;

  @JsonKey(name: 'natural (common)')
  int naturalCommon;

  @JsonKey(name: 'item (cpg)')
  int itemCpg;

  @JsonKey(name: 'item(restaurant)')
  int itemRestaurant;

  @JsonKey(name: 'Notes')
  String? notes;

  @JsonKey(name: 'bulk_csv_field')
  String? bulkCsvField;

  EnumNixNutrient(
    this.attrId,
    this.npf2018,
    this.usdaTag,
    this.name,
    this.unit,
    this.naturalCommon,
    this.itemCpg,
    this.itemRestaurant, {
    this.notes,
    this.bulkCsvField,
  });

  factory EnumNixNutrient.fromJson(Map<String, dynamic> srcJson) =>
      _$EnumNixNutrientFromJson(srcJson);

  Map<String, dynamic> toJson() => _$EnumNixNutrientToJson(this);
}
