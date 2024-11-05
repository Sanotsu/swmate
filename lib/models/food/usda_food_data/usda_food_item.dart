import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'usda_food_item.g.dart';

/// 查询指定单个食品编号得到的详情数据
/// https://api.nal.usda.gov/fdc/v1/food/534358?api_key=DEMO_KEY
/// 查询多个fdcids
/// https://api.nal.usda.gov/fdc/v1/foods?fdcIds=534358&fdcIds=373052&api_key=DEMO_KEY
/// 查询某个类别的食品列表
/// https://api.nal.usda.gov/fdc/v1/foods/list?pageSize=3&api_key=DEMO_KEY
///
/// 因为原接口说明，这食品查询的两个请求的响应是下列之一
///    AbridgedFoodItem
///    BrandedFoodItem
///    FoundationFoodItem
///    SRLegacyFoodItem
///    SurveyFoodItem
///   而列表查询的响应是 AbridgedFoodItem，
///   所以为了省事栏位全合并了，单纯fooditem(甚至只保留一些可能用的到的栏位就好)
@JsonSerializable(explicitToJson: true)
class USDAFoodItem {
  // 2029-10-14
  // 单个食品和多个食品查询，条件中可以指定返回栏位是`format=full`还是`format=abridged`
  // 列表查询可指定`dataType=[Branded,Foundation,Survey(FNDDS),SR Legacy]`中的一个或多个
  //    条件查询其实也是这样
  // 所以栏位暂时就用最大的

  // https://api.nal.usda.gov/fdc/v1/food/534358?format=full&api_key=DEMO_KEY
  // https://api.nal.usda.gov/fdc/v1/foods?fdcIds=534358&fdcIds=373052&format=full&api_key=DEMO_KEY
  @JsonKey(name: 'fdcId')
  int fdcId;

  @JsonKey(name: 'description')
  String description;

  @JsonKey(name: 'discontinuedDate')
  String? discontinuedDate;

  @JsonKey(name: 'foodComponents')
  List<dynamic>? foodComponents;

  @JsonKey(name: 'foodAttributes')
  List<dynamic>? foodAttributes;

  @JsonKey(name: 'foodPortions')
  List<USDAFoodPortion>? foodPortions;

  @JsonKey(name: 'publicationDate')
  String? publicationDate;

  // 2024-10-15 注意：指定单个或多个fdcid的营养素结构，和list查询和条件查询，3个结构都不一样，前者甚至还是嵌套的结构
  // 而且不同datatype返回的栏位也各不相同
  // 最省事也不省事的办法，还是把所有栏位放在一起，在明确接口调用的时，指定获取不同的栏位
  @JsonKey(name: 'foodNutrients')
  List<USDAFoodNutrient>? foodNutrients;

  @JsonKey(name: 'dataType')
  String? dataType;

  @JsonKey(name: 'foodClass')
  String? foodClass;

  @JsonKey(name: 'modifiedDate')
  String? modifiedDate;

  @JsonKey(name: 'availableDate')
  String? availableDate;

  @JsonKey(name: 'brandOwner')
  String? brandOwner;

  @JsonKey(name: 'brandName')
  String? brandName;

  @JsonKey(name: 'dataSource')
  String? dataSource;

  @JsonKey(name: 'brandedFoodCategory')
  String? brandedFoodCategory;

  @JsonKey(name: 'gtinUpc')
  String? gtinUpc;

  @JsonKey(name: 'householdServingFullText')
  String? householdServingFullText;

  @JsonKey(name: 'ingredients')
  String? ingredients;

  @JsonKey(name: 'marketCountry')
  String? marketCountry;

  @JsonKey(name: 'servingSize')
  double? servingSize;

  @JsonKey(name: 'servingSizeUnit')
  String? servingSizeUnit;

  @JsonKey(name: 'foodUpdateLog')
  List<USDAFoodUpdateLog>? foodUpdateLog;

  @JsonKey(name: 'labelNutrients')
  USDALabelNutrient? labelNutrients;

  // 查询分类列表的栏位
  // fdcId 、description、dataType、publicationDate、foodCode、foodNutrients
  // 2024-10-14 注意，在list查询时是字符串，但关键字查询时，确实int类型
  @JsonKey(name: 'foodCode')
  dynamic foodCode;

  @JsonKey(name: 'startDate')
  String? startDate;

  @JsonKey(name: 'endDate')
  String? endDate;

  @JsonKey(name: 'wweiaFoodCategory')
  USDAWweiaFoodCategory? wweiaFoodCategory;

  // 条件查询中还有这些栏位，上面部分栏位可能没有
  // https://api.nal.usda.gov/fdc/v1/foods/search?api_key=DEMO_KEY&query=Cheddar%20Cheese&pageSize=3&dataType=Branded,Foundation,Survey%20%28FNDDS%29,SR%20Legacy

  @JsonKey(name: 'commonNames')
  String? commonNames;

  @JsonKey(name: 'additionalDescriptions')
  String? additionalDescriptions;

  @JsonKey(name: 'ndbNumber')
  int? ndbNumber;

  @JsonKey(name: 'mostRecentAcquisitionDate')
  String? mostRecentAcquisitionDate;

  @JsonKey(name: 'publishedDate')
  String? publishedDate;

  // 2024-10-15 条件查询时，这个栏位是个字符串，但指定fdcid查询full栏位时，这个栏位是个对象
  @JsonKey(name: 'foodCategory')
  dynamic foodCategory;

  @JsonKey(name: 'tradeChannels')
  List<String>? tradeChannels;

  @JsonKey(name: 'allHighlightFields')
  String? allHighlightFields;

  // 搜索结构的匹配度 Relative score indicating how well the food matches the search criteria.
  @JsonKey(name: 'score')
  double? score;

  @JsonKey(name: 'microbes')
  List<dynamic>? microbes;

  @JsonKey(name: 'finalFoodInputFoods')
  List<USDAFinalFoodInputFood>? finalFoodInputFoods;

  @JsonKey(name: 'foodMeasures')
  List<USDAFoodMeasure>? foodMeasures;

  @JsonKey(name: 'foodAttributeTypes')
  List<USDAFoodAttributeType>? foodAttributeTypes;

  @JsonKey(name: 'foodVersionIds')
  List<dynamic>? foodVersionIds;

  USDAFoodItem(
    this.fdcId,
    this.description, {
    this.discontinuedDate,
    this.foodComponents,
    this.foodAttributes,
    this.foodPortions,
    this.publicationDate,
    this.foodNutrients,
    this.dataType,
    this.foodClass,
    this.modifiedDate,
    this.availableDate,
    this.brandOwner,
    this.brandName,
    this.dataSource,
    this.brandedFoodCategory,
    this.gtinUpc,
    this.householdServingFullText,
    this.ingredients,
    this.marketCountry,
    this.servingSize,
    this.servingSizeUnit,
    this.foodUpdateLog,
    this.labelNutrients,
    this.foodCode,
    this.allHighlightFields,
    this.finalFoodInputFoods,
    this.foodAttributeTypes,
    this.foodCategory,
    this.foodMeasures,
    this.foodVersionIds,
    this.microbes,
    this.publishedDate,
    this.score,
    this.tradeChannels,
    this.additionalDescriptions,
    this.commonNames,
    this.mostRecentAcquisitionDate,
    this.ndbNumber,
    this.endDate,
    this.startDate,
    this.wweiaFoodCategory,
  });

  factory USDAFoodItem.fromJson(Map<String, dynamic> srcJson) =>
      _$USDAFoodItemFromJson(srcJson);

  Map<String, dynamic> toJson() => _$USDAFoodItemToJson(this);
}

@JsonSerializable(explicitToJson: true)
class USDAFoodNutrient {
  // 指定单个或多个fdcid查询返回的营养素结构
  @JsonKey(name: 'type')
  String? type;

  @JsonKey(name: 'nutrient')
  USDANutrient? nutrient;

  @JsonKey(name: 'foodNutrientDerivation')
  USDAFoodNutrientDerivation? foodNutrientDerivation;

  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'amount')
  double? amount;

  // 指定查询，format=full时栏位更多
  @JsonKey(name: 'dataPoints')
  int? dataPoints;

  @JsonKey(name: 'max')
  double? max;

  @JsonKey(name: 'min')
  double? min;

  @JsonKey(name: 'median')
  double? median;

  @JsonKey(name: 'minYearAcquired')
  int? minYearAcquired;

  @JsonKey(name: 'nutrientAnalysisDetails')
  List<USDANutrientAnalysisDetail>? nutrientAnalysisDetails;

  // 条件查询返回的营养素栏位
  @JsonKey(name: 'nutrientId')
  int? nutrientId;

  @JsonKey(name: 'nutrientName')
  String? nutrientName;

  @JsonKey(name: 'nutrientNumber')
  String? nutrientNumber;

  @JsonKey(name: 'unitName')
  String? unitName;

  @JsonKey(name: 'derivationCode')
  String? derivationCode;

  @JsonKey(name: 'derivationDescription')
  String? derivationDescription;

  @JsonKey(name: 'derivationId')
  int? derivationId;

  @JsonKey(name: 'value')
  double? value;

  @JsonKey(name: 'foodNutrientSourceId')
  int? foodNutrientSourceId;

  @JsonKey(name: 'foodNutrientSourceCode')
  String? foodNutrientSourceCode;

  @JsonKey(name: 'foodNutrientSourceDescription')
  String? foodNutrientSourceDescription;

  @JsonKey(name: 'rank')
  int? rank;

  @JsonKey(name: 'indentLevel')
  int? indentLevel;

  @JsonKey(name: 'foodNutrientId')
  int? foodNutrientId;

  @JsonKey(name: 'percentDailyValue')
  int? percentDailyValue;

  // 分类列表查询的营养素结构
  // number、name、amount、unitName
  @JsonKey(name: 'number')
  String? number;

  @JsonKey(name: 'name')
  String? name;

  // 默认的是全部栏位的
  USDAFoodNutrient(
    this.type,
    this.nutrient,
    this.foodNutrientDerivation,
    this.id,
    this.amount,
    this.dataPoints,
    this.max,
    this.min,
    this.median,
    this.minYearAcquired,
    this.nutrientAnalysisDetails,
    this.nutrientId,
    this.nutrientName,
    this.nutrientNumber,
    this.unitName,
    this.derivationCode,
    this.derivationDescription,
    this.derivationId,
    this.value,
    this.foodNutrientSourceId,
    this.foodNutrientSourceCode,
    this.foodNutrientSourceDescription,
    this.rank,
    this.indentLevel,
    this.foodNutrientId,
    this.percentDailyValue,
    this.number,
    this.name,
  );

  USDAFoodNutrient.fdcid(
    this.type,
    this.nutrient,
    this.foodNutrientDerivation,
    this.id,
    this.amount,
    this.dataPoints,
    this.max,
    this.min,
    this.median,
    this.minYearAcquired,
    this.nutrientAnalysisDetails,
  );

  USDAFoodNutrient.list(
    this.number,
    this.name,
    this.amount,
    this.unitName,
  );

  USDAFoodNutrient.search(
    this.nutrientId,
    this.nutrientName,
    this.nutrientNumber,
    this.unitName,
    this.derivationCode,
    this.derivationDescription,
    this.derivationId,
    this.value,
    this.foodNutrientSourceId,
    this.foodNutrientSourceCode,
    this.foodNutrientSourceDescription,
    this.rank,
    this.indentLevel,
    this.foodNutrientId,
    this.percentDailyValue,
  );

  // 从字符串转
  factory USDAFoodNutrient.fromRawJson(String str) =>
      USDAFoodNutrient.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory USDAFoodNutrient.fromJson(Map<String, dynamic> srcJson) =>
      _$USDAFoodNutrientFromJson(srcJson);

  Map<String, dynamic> toJson() => _$USDAFoodNutrientToJson(this);
}

@JsonSerializable(explicitToJson: true)
class USDANutrient {
  @JsonKey(name: 'id')
  int id;

  @JsonKey(name: 'number')
  String number;

  @JsonKey(name: 'name')
  String name;

  @JsonKey(name: 'rank')
  int rank;

  @JsonKey(name: 'unitName')
  String unitName;

  // 查询full栏位还有标签内容
  @JsonKey(name: 'isNutrientLabel')
  bool? isNutrientLabel;

  @JsonKey(name: 'indentLevel')
  int? indentLevel;

  @JsonKey(name: 'numberOfDecimals')
  int? numberOfDecimals;

  @JsonKey(name: 'shortestName')
  String? shortestName;

  USDANutrient(
    this.id,
    this.number,
    this.name,
    this.rank,
    this.unitName, {
    this.indentLevel,
    this.isNutrientLabel,
    this.numberOfDecimals,
    this.shortestName,
  });

  factory USDANutrient.fromJson(Map<String, dynamic> srcJson) =>
      _$USDANutrientFromJson(srcJson);

  Map<String, dynamic> toJson() => _$USDANutrientToJson(this);
}

@JsonSerializable(explicitToJson: true)
class USDAFoodNutrientDerivation {
  @JsonKey(name: 'id')
  int id;

  @JsonKey(name: 'code')
  String code;

  @JsonKey(name: 'description')
  String description;

  USDAFoodNutrientDerivation(
    this.id,
    this.code,
    this.description,
  );

  factory USDAFoodNutrientDerivation.fromJson(Map<String, dynamic> srcJson) =>
      _$USDAFoodNutrientDerivationFromJson(srcJson);

  Map<String, dynamic> toJson() => _$USDAFoodNutrientDerivationToJson(this);
}

@JsonSerializable(explicitToJson: true)
class USDANutrientAnalysisDetail {
  @JsonKey(name: 'subSampleId')
  int? subSampleId;

  @JsonKey(name: 'nutrientId')
  int? nutrientId;

  @JsonKey(name: 'nutrientAcquisitionDetails')
  List<USDANutrientAcquisitionDetail>? nutrientAcquisitionDetails;

  @JsonKey(name: 'amount')
  double? amount;

  @JsonKey(name: 'labMethodTechnique')
  String? labMethodTechnique;

  @JsonKey(name: 'labMethodDescription')
  String? labMethodDescription;

  @JsonKey(name: 'labMethodOriginalDescription')
  String? labMethodOriginalDescription;

  @JsonKey(name: 'loq')
  double? loq;

  @JsonKey(name: 'labMethodLink')
  String? labMethodLink;

  USDANutrientAnalysisDetail({
    this.subSampleId,
    this.nutrientId,
    this.nutrientAcquisitionDetails,
    this.amount,
    this.labMethodTechnique,
    this.labMethodDescription,
    this.labMethodOriginalDescription,
    this.loq,
    this.labMethodLink,
  });

  factory USDANutrientAnalysisDetail.fromJson(Map<String, dynamic> srcJson) =>
      _$USDANutrientAnalysisDetailFromJson(srcJson);

  Map<String, dynamic> toJson() => _$USDANutrientAnalysisDetailToJson(this);
}

@JsonSerializable(explicitToJson: true)
class USDANutrientAcquisitionDetail {
  @JsonKey(name: 'sampleUnitId')
  int? sampleUnitId;

  @JsonKey(name: 'purchaseDate')
  String? purchaseDate;

  @JsonKey(name: 'storeCity')
  String? storeCity;

  @JsonKey(name: 'storeState')
  String? storeState;

  @JsonKey(name: 'packerCity')
  String? packerCity;

  @JsonKey(name: 'packerState')
  String? packerState;

  USDANutrientAcquisitionDetail({
    this.sampleUnitId,
    this.purchaseDate,
    this.storeCity,
    this.storeState,
    this.packerCity,
    this.packerState,
  });

  factory USDANutrientAcquisitionDetail.fromJson(
          Map<String, dynamic> srcJson) =>
      _$USDANutrientAcquisitionDetailFromJson(srcJson);

  Map<String, dynamic> toJson() => _$USDANutrientAcquisitionDetailToJson(this);
}

// 食品修改日志（应该是Branded类型的栏位，应该用不到）
@JsonSerializable(explicitToJson: true)
class USDAFoodUpdateLog {
  @JsonKey(name: 'discontinuedDate')
  String? discontinuedDate;

  @JsonKey(name: 'foodAttributes')
  List<dynamic>? foodAttributes;

  @JsonKey(name: 'fdcId')
  int fdcId;

  @JsonKey(name: 'description')
  String description;

  @JsonKey(name: 'publicationDate')
  String? publicationDate;

  @JsonKey(name: 'dataType')
  String? dataType;

  @JsonKey(name: 'foodClass')
  String? foodClass;

  @JsonKey(name: 'modifiedDate')
  String? modifiedDate;

  @JsonKey(name: 'availableDate')
  String? availableDate;

  @JsonKey(name: 'brandOwner')
  String? brandOwner;

  @JsonKey(name: 'brandName')
  String? brandName;

  @JsonKey(name: 'dataSource')
  String? dataSource;

  @JsonKey(name: 'brandedFoodCategory')
  String? brandedFoodCategory;

  @JsonKey(name: 'gtinUpc')
  String? gtinUpc;

  @JsonKey(name: 'ingredients')
  String? ingredients;

  @JsonKey(name: 'marketCountry')
  String? marketCountry;

  @JsonKey(name: 'servingSize')
  double? servingSize;

  @JsonKey(name: 'servingSizeUnit')
  String? servingSizeUnit;

  @JsonKey(name: 'packageWeight')
  String? packageWeight;

  USDAFoodUpdateLog({
    this.discontinuedDate,
    this.foodAttributes,
    required this.fdcId,
    required this.description,
    this.publicationDate,
    this.dataType,
    this.foodClass,
    this.modifiedDate,
    this.availableDate,
    this.brandOwner,
    this.brandName,
    this.dataSource,
    this.brandedFoodCategory,
    this.gtinUpc,
    this.ingredients,
    this.marketCountry,
    this.servingSize,
    this.servingSizeUnit,
    this.packageWeight,
  });

  factory USDAFoodUpdateLog.fromJson(Map<String, dynamic> srcJson) =>
      _$USDAFoodUpdateLogFromJson(srcJson);

  Map<String, dynamic> toJson() => _$USDAFoodUpdateLogToJson(this);
}

@JsonSerializable(explicitToJson: true)
class USDAFinalFoodInputFood {
  @JsonKey(name: 'foodDescription')
  String? foodDescription;

  @JsonKey(name: 'gramWeight')
  int? gramWeight;

  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'portionCode')
  String? portionCode;

  @JsonKey(name: 'portionDescription')
  String? portionDescription;

  @JsonKey(name: 'unit')
  String? unit;

  @JsonKey(name: 'rank')
  int? rank;

  @JsonKey(name: 'srCode')
  int? srCode;

  @JsonKey(name: 'value')
  double? value;

  USDAFinalFoodInputFood(
    this.foodDescription,
    this.gramWeight,
    this.id,
    this.portionCode,
    this.portionDescription,
    this.unit,
    this.rank,
    this.srCode,
    this.value,
  );

  factory USDAFinalFoodInputFood.fromJson(Map<String, dynamic> srcJson) =>
      _$USDAFinalFoodInputFoodFromJson(srcJson);

  Map<String, dynamic> toJson() => _$USDAFinalFoodInputFoodToJson(this);
}

@JsonSerializable(explicitToJson: true)
class USDAFoodPortion {
  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'value')
  double? value;

  @JsonKey(name: 'measureUnit')
  USDAMeasureUnit? measureUnit;

  @JsonKey(name: 'modifier')
  String? modifier;

  @JsonKey(name: 'gramWeight')
  double? gramWeight;

  @JsonKey(name: 'sequenceNumber')
  int? sequenceNumber;

  @JsonKey(name: 'minYearAcquired')
  int? minYearAcquired;

  @JsonKey(name: 'amount')
  double? amount;

  USDAFoodPortion({
    this.id,
    this.value,
    this.measureUnit,
    this.modifier,
    this.gramWeight,
    this.sequenceNumber,
    this.minYearAcquired,
    this.amount,
  });

  factory USDAFoodPortion.fromJson(Map<String, dynamic> srcJson) =>
      _$USDAFoodPortionFromJson(srcJson);

  Map<String, dynamic> toJson() => _$USDAFoodPortionToJson(this);
}

@JsonSerializable(explicitToJson: true)
class USDAMeasureUnit {
  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'abbreviation')
  String? abbreviation;

  USDAMeasureUnit({
    this.id,
    this.name,
    this.abbreviation,
  });

  factory USDAMeasureUnit.fromJson(Map<String, dynamic> srcJson) =>
      _$USDAMeasureUnitFromJson(srcJson);

  Map<String, dynamic> toJson() => _$USDAMeasureUnitToJson(this);
}

@JsonSerializable(explicitToJson: true)
class USDAWweiaFoodCategory {
  @JsonKey(name: 'wweiaFoodCategoryDescription')
  String? wweiaFoodCategoryDescription;

  @JsonKey(name: 'wweiaFoodCategoryCode')
  int? wweiaFoodCategoryCode;

  USDAWweiaFoodCategory({
    this.wweiaFoodCategoryDescription,
    this.wweiaFoodCategoryCode,
  });

  factory USDAWweiaFoodCategory.fromJson(Map<String, dynamic> srcJson) =>
      _$USDAWweiaFoodCategoryFromJson(srcJson);

  Map<String, dynamic> toJson() => _$USDAWweiaFoodCategoryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class USDAFoodMeasure {
  @JsonKey(name: 'disseminationText')
  String? disseminationText;

  @JsonKey(name: 'gramWeight')
  int? gramWeight;

  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'modifier')
  String? modifier;

  @JsonKey(name: 'rank')
  int? rank;

  @JsonKey(name: 'measureUnitAbbreviation')
  String? measureUnitAbbreviation;

  @JsonKey(name: 'measureUnitName')
  String? measureUnitName;

  @JsonKey(name: 'measureUnitId')
  int? measureUnitId;

  USDAFoodMeasure({
    this.disseminationText,
    this.gramWeight,
    this.id,
    this.modifier,
    this.rank,
    this.measureUnitAbbreviation,
    this.measureUnitName,
    this.measureUnitId,
  });

  factory USDAFoodMeasure.fromJson(Map<String, dynamic> srcJson) =>
      _$USDAFoodMeasureFromJson(srcJson);

  Map<String, dynamic> toJson() => _$USDAFoodMeasureToJson(this);
}

@JsonSerializable(explicitToJson: true)
class USDAFoodAttributeType {
  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'description')
  String? description;

  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'foodAttributes')
  List<USDAFoodAttribute>? foodAttributes;

  USDAFoodAttributeType(
    this.name,
    this.description,
    this.id,
    this.foodAttributes,
  );

  factory USDAFoodAttributeType.fromJson(Map<String, dynamic> srcJson) =>
      _$USDAFoodAttributeTypeFromJson(srcJson);

  Map<String, dynamic> toJson() => _$USDAFoodAttributeTypeToJson(this);
}

@JsonSerializable(explicitToJson: true)
class USDAFoodAttribute {
  @JsonKey(name: 'value')
  String? value;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'id')
  int? id;

  USDAFoodAttribute({
    this.value,
    this.name,
    this.id,
  });

  factory USDAFoodAttribute.fromJson(Map<String, dynamic> srcJson) =>
      _$USDAFoodAttributeFromJson(srcJson);

  Map<String, dynamic> toJson() => _$USDAFoodAttributeToJson(this);
}

// 标签营养素
@JsonSerializable(explicitToJson: true)
class USDALabelNutrient {
  @JsonKey(name: 'fat')
  NutrientValue? fat;

  @JsonKey(name: 'saturatedFat')
  NutrientValue? saturatedFat;

  @JsonKey(name: 'transFat')
  NutrientValue? transFat;

  @JsonKey(name: 'cholesterol')
  NutrientValue? cholesterol;

  @JsonKey(name: 'sodium')
  NutrientValue? sodium;

  @JsonKey(name: 'carbohydrates')
  NutrientValue? carbohydrates;

  @JsonKey(name: 'fiber')
  NutrientValue? fiber;

  @JsonKey(name: 'sugars')
  NutrientValue? sugars;

  @JsonKey(name: 'protein')
  NutrientValue? protein;

  @JsonKey(name: 'calcium')
  NutrientValue? calcium;

  @JsonKey(name: 'iron')
  NutrientValue? iron;

  @JsonKey(name: 'potassium')
  NutrientValue? potassium;

  @JsonKey(name: 'calories')
  NutrientValue? calories;

  USDALabelNutrient({
    this.fat,
    this.saturatedFat,
    this.transFat,
    this.cholesterol,
    this.sodium,
    this.carbohydrates,
    this.fiber,
    this.sugars,
    this.protein,
    this.calcium,
    this.iron,
    this.potassium,
    this.calories,
  });

  factory USDALabelNutrient.fromJson(Map<String, dynamic> srcJson) =>
      _$USDALabelNutrientFromJson(srcJson);

  Map<String, dynamic> toJson() => _$USDALabelNutrientToJson(this);
}

@JsonSerializable(explicitToJson: true)
class NutrientValue {
  // 还可能是int？那就只能是dynamic了
  @JsonKey(name: 'value')
  double value;

  NutrientValue(this.value);

  factory NutrientValue.fromJson(Map<String, dynamic> srcJson) =>
      _$NutrientValueFromJson(srcJson);

  Map<String, dynamic> toJson() => _$NutrientValueToJson(this);
}
