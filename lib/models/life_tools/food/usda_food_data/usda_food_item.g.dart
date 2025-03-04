// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usda_food_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

USDAFoodItem _$USDAFoodItemFromJson(Map<String, dynamic> json) => USDAFoodItem(
      (json['fdcId'] as num).toInt(),
      json['description'] as String,
      discontinuedDate: json['discontinuedDate'] as String?,
      foodComponents: json['foodComponents'] as List<dynamic>?,
      foodAttributes: json['foodAttributes'] as List<dynamic>?,
      foodPortions: (json['foodPortions'] as List<dynamic>?)
          ?.map((e) => USDAFoodPortion.fromJson(e as Map<String, dynamic>))
          .toList(),
      publicationDate: json['publicationDate'] as String?,
      foodNutrients: (json['foodNutrients'] as List<dynamic>?)
          ?.map((e) => USDAFoodNutrient.fromJson(e as Map<String, dynamic>))
          .toList(),
      dataType: json['dataType'] as String?,
      foodClass: json['foodClass'] as String?,
      modifiedDate: json['modifiedDate'] as String?,
      availableDate: json['availableDate'] as String?,
      brandOwner: json['brandOwner'] as String?,
      brandName: json['brandName'] as String?,
      dataSource: json['dataSource'] as String?,
      brandedFoodCategory: json['brandedFoodCategory'] as String?,
      gtinUpc: json['gtinUpc'] as String?,
      householdServingFullText: json['householdServingFullText'] as String?,
      ingredients: json['ingredients'] as String?,
      marketCountry: json['marketCountry'] as String?,
      servingSize: (json['servingSize'] as num?)?.toDouble(),
      servingSizeUnit: json['servingSizeUnit'] as String?,
      foodUpdateLog: (json['foodUpdateLog'] as List<dynamic>?)
          ?.map((e) => USDAFoodUpdateLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      labelNutrients: json['labelNutrients'] == null
          ? null
          : USDALabelNutrient.fromJson(
              json['labelNutrients'] as Map<String, dynamic>),
      foodCode: json['foodCode'],
      allHighlightFields: json['allHighlightFields'] as String?,
      finalFoodInputFoods: (json['finalFoodInputFoods'] as List<dynamic>?)
          ?.map(
              (e) => USDAFinalFoodInputFood.fromJson(e as Map<String, dynamic>))
          .toList(),
      foodAttributeTypes: (json['foodAttributeTypes'] as List<dynamic>?)
          ?.map(
              (e) => USDAFoodAttributeType.fromJson(e as Map<String, dynamic>))
          .toList(),
      foodCategory: json['foodCategory'],
      foodMeasures: (json['foodMeasures'] as List<dynamic>?)
          ?.map((e) => USDAFoodMeasure.fromJson(e as Map<String, dynamic>))
          .toList(),
      foodVersionIds: json['foodVersionIds'] as List<dynamic>?,
      microbes: json['microbes'] as List<dynamic>?,
      publishedDate: json['publishedDate'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      tradeChannels: (json['tradeChannels'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      additionalDescriptions: json['additionalDescriptions'] as String?,
      commonNames: json['commonNames'] as String?,
      mostRecentAcquisitionDate: json['mostRecentAcquisitionDate'] as String?,
      ndbNumber: (json['ndbNumber'] as num?)?.toInt(),
      endDate: json['endDate'] as String?,
      startDate: json['startDate'] as String?,
      wweiaFoodCategory: json['wweiaFoodCategory'] == null
          ? null
          : USDAWweiaFoodCategory.fromJson(
              json['wweiaFoodCategory'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$USDAFoodItemToJson(USDAFoodItem instance) =>
    <String, dynamic>{
      'fdcId': instance.fdcId,
      'description': instance.description,
      'discontinuedDate': instance.discontinuedDate,
      'foodComponents': instance.foodComponents,
      'foodAttributes': instance.foodAttributes,
      'foodPortions': instance.foodPortions?.map((e) => e.toJson()).toList(),
      'publicationDate': instance.publicationDate,
      'foodNutrients': instance.foodNutrients?.map((e) => e.toJson()).toList(),
      'dataType': instance.dataType,
      'foodClass': instance.foodClass,
      'modifiedDate': instance.modifiedDate,
      'availableDate': instance.availableDate,
      'brandOwner': instance.brandOwner,
      'brandName': instance.brandName,
      'dataSource': instance.dataSource,
      'brandedFoodCategory': instance.brandedFoodCategory,
      'gtinUpc': instance.gtinUpc,
      'householdServingFullText': instance.householdServingFullText,
      'ingredients': instance.ingredients,
      'marketCountry': instance.marketCountry,
      'servingSize': instance.servingSize,
      'servingSizeUnit': instance.servingSizeUnit,
      'foodUpdateLog': instance.foodUpdateLog?.map((e) => e.toJson()).toList(),
      'labelNutrients': instance.labelNutrients?.toJson(),
      'foodCode': instance.foodCode,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
      'wweiaFoodCategory': instance.wweiaFoodCategory?.toJson(),
      'commonNames': instance.commonNames,
      'additionalDescriptions': instance.additionalDescriptions,
      'ndbNumber': instance.ndbNumber,
      'mostRecentAcquisitionDate': instance.mostRecentAcquisitionDate,
      'publishedDate': instance.publishedDate,
      'foodCategory': instance.foodCategory,
      'tradeChannels': instance.tradeChannels,
      'allHighlightFields': instance.allHighlightFields,
      'score': instance.score,
      'microbes': instance.microbes,
      'finalFoodInputFoods':
          instance.finalFoodInputFoods?.map((e) => e.toJson()).toList(),
      'foodMeasures': instance.foodMeasures?.map((e) => e.toJson()).toList(),
      'foodAttributeTypes':
          instance.foodAttributeTypes?.map((e) => e.toJson()).toList(),
      'foodVersionIds': instance.foodVersionIds,
    };

USDAFoodNutrient _$USDAFoodNutrientFromJson(Map<String, dynamic> json) =>
    USDAFoodNutrient(
      json['type'] as String?,
      json['nutrient'] == null
          ? null
          : USDANutrient.fromJson(json['nutrient'] as Map<String, dynamic>),
      json['foodNutrientDerivation'] == null
          ? null
          : USDAFoodNutrientDerivation.fromJson(
              json['foodNutrientDerivation'] as Map<String, dynamic>),
      (json['id'] as num?)?.toInt(),
      (json['amount'] as num?)?.toDouble(),
      (json['dataPoints'] as num?)?.toInt(),
      (json['max'] as num?)?.toDouble(),
      (json['min'] as num?)?.toDouble(),
      (json['median'] as num?)?.toDouble(),
      (json['minYearAcquired'] as num?)?.toInt(),
      (json['nutrientAnalysisDetails'] as List<dynamic>?)
          ?.map((e) =>
              USDANutrientAnalysisDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['nutrientId'] as num?)?.toInt(),
      json['nutrientName'] as String?,
      json['nutrientNumber'] as String?,
      json['unitName'] as String?,
      json['derivationCode'] as String?,
      json['derivationDescription'] as String?,
      (json['derivationId'] as num?)?.toInt(),
      (json['value'] as num?)?.toDouble(),
      (json['foodNutrientSourceId'] as num?)?.toInt(),
      json['foodNutrientSourceCode'] as String?,
      json['foodNutrientSourceDescription'] as String?,
      (json['rank'] as num?)?.toInt(),
      (json['indentLevel'] as num?)?.toInt(),
      (json['foodNutrientId'] as num?)?.toInt(),
      (json['percentDailyValue'] as num?)?.toInt(),
      json['number'] as String?,
      json['name'] as String?,
    );

Map<String, dynamic> _$USDAFoodNutrientToJson(USDAFoodNutrient instance) =>
    <String, dynamic>{
      'type': instance.type,
      'nutrient': instance.nutrient?.toJson(),
      'foodNutrientDerivation': instance.foodNutrientDerivation?.toJson(),
      'id': instance.id,
      'amount': instance.amount,
      'dataPoints': instance.dataPoints,
      'max': instance.max,
      'min': instance.min,
      'median': instance.median,
      'minYearAcquired': instance.minYearAcquired,
      'nutrientAnalysisDetails':
          instance.nutrientAnalysisDetails?.map((e) => e.toJson()).toList(),
      'nutrientId': instance.nutrientId,
      'nutrientName': instance.nutrientName,
      'nutrientNumber': instance.nutrientNumber,
      'unitName': instance.unitName,
      'derivationCode': instance.derivationCode,
      'derivationDescription': instance.derivationDescription,
      'derivationId': instance.derivationId,
      'value': instance.value,
      'foodNutrientSourceId': instance.foodNutrientSourceId,
      'foodNutrientSourceCode': instance.foodNutrientSourceCode,
      'foodNutrientSourceDescription': instance.foodNutrientSourceDescription,
      'rank': instance.rank,
      'indentLevel': instance.indentLevel,
      'foodNutrientId': instance.foodNutrientId,
      'percentDailyValue': instance.percentDailyValue,
      'number': instance.number,
      'name': instance.name,
    };

USDANutrient _$USDANutrientFromJson(Map<String, dynamic> json) => USDANutrient(
      (json['id'] as num).toInt(),
      json['number'] as String,
      json['name'] as String,
      (json['rank'] as num).toInt(),
      json['unitName'] as String,
      indentLevel: (json['indentLevel'] as num?)?.toInt(),
      isNutrientLabel: json['isNutrientLabel'] as bool?,
      numberOfDecimals: (json['numberOfDecimals'] as num?)?.toInt(),
      shortestName: json['shortestName'] as String?,
    );

Map<String, dynamic> _$USDANutrientToJson(USDANutrient instance) =>
    <String, dynamic>{
      'id': instance.id,
      'number': instance.number,
      'name': instance.name,
      'rank': instance.rank,
      'unitName': instance.unitName,
      'isNutrientLabel': instance.isNutrientLabel,
      'indentLevel': instance.indentLevel,
      'numberOfDecimals': instance.numberOfDecimals,
      'shortestName': instance.shortestName,
    };

USDAFoodNutrientDerivation _$USDAFoodNutrientDerivationFromJson(
        Map<String, dynamic> json) =>
    USDAFoodNutrientDerivation(
      (json['id'] as num).toInt(),
      json['code'] as String,
      json['description'] as String,
    );

Map<String, dynamic> _$USDAFoodNutrientDerivationToJson(
        USDAFoodNutrientDerivation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'description': instance.description,
    };

USDANutrientAnalysisDetail _$USDANutrientAnalysisDetailFromJson(
        Map<String, dynamic> json) =>
    USDANutrientAnalysisDetail(
      subSampleId: (json['subSampleId'] as num?)?.toInt(),
      nutrientId: (json['nutrientId'] as num?)?.toInt(),
      nutrientAcquisitionDetails: (json['nutrientAcquisitionDetails']
              as List<dynamic>?)
          ?.map((e) =>
              USDANutrientAcquisitionDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      amount: (json['amount'] as num?)?.toDouble(),
      labMethodTechnique: json['labMethodTechnique'] as String?,
      labMethodDescription: json['labMethodDescription'] as String?,
      labMethodOriginalDescription:
          json['labMethodOriginalDescription'] as String?,
      loq: (json['loq'] as num?)?.toDouble(),
      labMethodLink: json['labMethodLink'] as String?,
    );

Map<String, dynamic> _$USDANutrientAnalysisDetailToJson(
        USDANutrientAnalysisDetail instance) =>
    <String, dynamic>{
      'subSampleId': instance.subSampleId,
      'nutrientId': instance.nutrientId,
      'nutrientAcquisitionDetails':
          instance.nutrientAcquisitionDetails?.map((e) => e.toJson()).toList(),
      'amount': instance.amount,
      'labMethodTechnique': instance.labMethodTechnique,
      'labMethodDescription': instance.labMethodDescription,
      'labMethodOriginalDescription': instance.labMethodOriginalDescription,
      'loq': instance.loq,
      'labMethodLink': instance.labMethodLink,
    };

USDANutrientAcquisitionDetail _$USDANutrientAcquisitionDetailFromJson(
        Map<String, dynamic> json) =>
    USDANutrientAcquisitionDetail(
      sampleUnitId: (json['sampleUnitId'] as num?)?.toInt(),
      purchaseDate: json['purchaseDate'] as String?,
      storeCity: json['storeCity'] as String?,
      storeState: json['storeState'] as String?,
      packerCity: json['packerCity'] as String?,
      packerState: json['packerState'] as String?,
    );

Map<String, dynamic> _$USDANutrientAcquisitionDetailToJson(
        USDANutrientAcquisitionDetail instance) =>
    <String, dynamic>{
      'sampleUnitId': instance.sampleUnitId,
      'purchaseDate': instance.purchaseDate,
      'storeCity': instance.storeCity,
      'storeState': instance.storeState,
      'packerCity': instance.packerCity,
      'packerState': instance.packerState,
    };

USDAFoodUpdateLog _$USDAFoodUpdateLogFromJson(Map<String, dynamic> json) =>
    USDAFoodUpdateLog(
      discontinuedDate: json['discontinuedDate'] as String?,
      foodAttributes: json['foodAttributes'] as List<dynamic>?,
      fdcId: (json['fdcId'] as num).toInt(),
      description: json['description'] as String,
      publicationDate: json['publicationDate'] as String?,
      dataType: json['dataType'] as String?,
      foodClass: json['foodClass'] as String?,
      modifiedDate: json['modifiedDate'] as String?,
      availableDate: json['availableDate'] as String?,
      brandOwner: json['brandOwner'] as String?,
      brandName: json['brandName'] as String?,
      dataSource: json['dataSource'] as String?,
      brandedFoodCategory: json['brandedFoodCategory'] as String?,
      gtinUpc: json['gtinUpc'] as String?,
      ingredients: json['ingredients'] as String?,
      marketCountry: json['marketCountry'] as String?,
      servingSize: (json['servingSize'] as num?)?.toDouble(),
      servingSizeUnit: json['servingSizeUnit'] as String?,
      packageWeight: json['packageWeight'] as String?,
    );

Map<String, dynamic> _$USDAFoodUpdateLogToJson(USDAFoodUpdateLog instance) =>
    <String, dynamic>{
      'discontinuedDate': instance.discontinuedDate,
      'foodAttributes': instance.foodAttributes,
      'fdcId': instance.fdcId,
      'description': instance.description,
      'publicationDate': instance.publicationDate,
      'dataType': instance.dataType,
      'foodClass': instance.foodClass,
      'modifiedDate': instance.modifiedDate,
      'availableDate': instance.availableDate,
      'brandOwner': instance.brandOwner,
      'brandName': instance.brandName,
      'dataSource': instance.dataSource,
      'brandedFoodCategory': instance.brandedFoodCategory,
      'gtinUpc': instance.gtinUpc,
      'ingredients': instance.ingredients,
      'marketCountry': instance.marketCountry,
      'servingSize': instance.servingSize,
      'servingSizeUnit': instance.servingSizeUnit,
      'packageWeight': instance.packageWeight,
    };

USDAFinalFoodInputFood _$USDAFinalFoodInputFoodFromJson(
        Map<String, dynamic> json) =>
    USDAFinalFoodInputFood(
      json['foodDescription'] as String?,
      (json['gramWeight'] as num?)?.toInt(),
      (json['id'] as num?)?.toInt(),
      json['portionCode'] as String?,
      json['portionDescription'] as String?,
      json['unit'] as String?,
      (json['rank'] as num?)?.toInt(),
      (json['srCode'] as num?)?.toInt(),
      (json['value'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$USDAFinalFoodInputFoodToJson(
        USDAFinalFoodInputFood instance) =>
    <String, dynamic>{
      'foodDescription': instance.foodDescription,
      'gramWeight': instance.gramWeight,
      'id': instance.id,
      'portionCode': instance.portionCode,
      'portionDescription': instance.portionDescription,
      'unit': instance.unit,
      'rank': instance.rank,
      'srCode': instance.srCode,
      'value': instance.value,
    };

USDAFoodPortion _$USDAFoodPortionFromJson(Map<String, dynamic> json) =>
    USDAFoodPortion(
      id: (json['id'] as num?)?.toInt(),
      value: (json['value'] as num?)?.toDouble(),
      measureUnit: json['measureUnit'] == null
          ? null
          : USDAMeasureUnit.fromJson(
              json['measureUnit'] as Map<String, dynamic>),
      modifier: json['modifier'] as String?,
      gramWeight: (json['gramWeight'] as num?)?.toDouble(),
      sequenceNumber: (json['sequenceNumber'] as num?)?.toInt(),
      minYearAcquired: (json['minYearAcquired'] as num?)?.toInt(),
      amount: (json['amount'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$USDAFoodPortionToJson(USDAFoodPortion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'value': instance.value,
      'measureUnit': instance.measureUnit?.toJson(),
      'modifier': instance.modifier,
      'gramWeight': instance.gramWeight,
      'sequenceNumber': instance.sequenceNumber,
      'minYearAcquired': instance.minYearAcquired,
      'amount': instance.amount,
    };

USDAMeasureUnit _$USDAMeasureUnitFromJson(Map<String, dynamic> json) =>
    USDAMeasureUnit(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      abbreviation: json['abbreviation'] as String?,
    );

Map<String, dynamic> _$USDAMeasureUnitToJson(USDAMeasureUnit instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'abbreviation': instance.abbreviation,
    };

USDAWweiaFoodCategory _$USDAWweiaFoodCategoryFromJson(
        Map<String, dynamic> json) =>
    USDAWweiaFoodCategory(
      wweiaFoodCategoryDescription:
          json['wweiaFoodCategoryDescription'] as String?,
      wweiaFoodCategoryCode: (json['wweiaFoodCategoryCode'] as num?)?.toInt(),
    );

Map<String, dynamic> _$USDAWweiaFoodCategoryToJson(
        USDAWweiaFoodCategory instance) =>
    <String, dynamic>{
      'wweiaFoodCategoryDescription': instance.wweiaFoodCategoryDescription,
      'wweiaFoodCategoryCode': instance.wweiaFoodCategoryCode,
    };

USDAFoodMeasure _$USDAFoodMeasureFromJson(Map<String, dynamic> json) =>
    USDAFoodMeasure(
      disseminationText: json['disseminationText'] as String?,
      gramWeight: (json['gramWeight'] as num?)?.toInt(),
      id: (json['id'] as num?)?.toInt(),
      modifier: json['modifier'] as String?,
      rank: (json['rank'] as num?)?.toInt(),
      measureUnitAbbreviation: json['measureUnitAbbreviation'] as String?,
      measureUnitName: json['measureUnitName'] as String?,
      measureUnitId: (json['measureUnitId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$USDAFoodMeasureToJson(USDAFoodMeasure instance) =>
    <String, dynamic>{
      'disseminationText': instance.disseminationText,
      'gramWeight': instance.gramWeight,
      'id': instance.id,
      'modifier': instance.modifier,
      'rank': instance.rank,
      'measureUnitAbbreviation': instance.measureUnitAbbreviation,
      'measureUnitName': instance.measureUnitName,
      'measureUnitId': instance.measureUnitId,
    };

USDAFoodAttributeType _$USDAFoodAttributeTypeFromJson(
        Map<String, dynamic> json) =>
    USDAFoodAttributeType(
      json['name'] as String?,
      json['description'] as String?,
      (json['id'] as num?)?.toInt(),
      (json['foodAttributes'] as List<dynamic>?)
          ?.map((e) => USDAFoodAttribute.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$USDAFoodAttributeTypeToJson(
        USDAFoodAttributeType instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'id': instance.id,
      'foodAttributes':
          instance.foodAttributes?.map((e) => e.toJson()).toList(),
    };

USDAFoodAttribute _$USDAFoodAttributeFromJson(Map<String, dynamic> json) =>
    USDAFoodAttribute(
      value: json['value'] as String?,
      name: json['name'] as String?,
      id: (json['id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$USDAFoodAttributeToJson(USDAFoodAttribute instance) =>
    <String, dynamic>{
      'value': instance.value,
      'name': instance.name,
      'id': instance.id,
    };

USDALabelNutrient _$USDALabelNutrientFromJson(Map<String, dynamic> json) =>
    USDALabelNutrient(
      fat: json['fat'] == null
          ? null
          : NutrientValue.fromJson(json['fat'] as Map<String, dynamic>),
      saturatedFat: json['saturatedFat'] == null
          ? null
          : NutrientValue.fromJson(
              json['saturatedFat'] as Map<String, dynamic>),
      transFat: json['transFat'] == null
          ? null
          : NutrientValue.fromJson(json['transFat'] as Map<String, dynamic>),
      cholesterol: json['cholesterol'] == null
          ? null
          : NutrientValue.fromJson(json['cholesterol'] as Map<String, dynamic>),
      sodium: json['sodium'] == null
          ? null
          : NutrientValue.fromJson(json['sodium'] as Map<String, dynamic>),
      carbohydrates: json['carbohydrates'] == null
          ? null
          : NutrientValue.fromJson(
              json['carbohydrates'] as Map<String, dynamic>),
      fiber: json['fiber'] == null
          ? null
          : NutrientValue.fromJson(json['fiber'] as Map<String, dynamic>),
      sugars: json['sugars'] == null
          ? null
          : NutrientValue.fromJson(json['sugars'] as Map<String, dynamic>),
      protein: json['protein'] == null
          ? null
          : NutrientValue.fromJson(json['protein'] as Map<String, dynamic>),
      calcium: json['calcium'] == null
          ? null
          : NutrientValue.fromJson(json['calcium'] as Map<String, dynamic>),
      iron: json['iron'] == null
          ? null
          : NutrientValue.fromJson(json['iron'] as Map<String, dynamic>),
      potassium: json['potassium'] == null
          ? null
          : NutrientValue.fromJson(json['potassium'] as Map<String, dynamic>),
      calories: json['calories'] == null
          ? null
          : NutrientValue.fromJson(json['calories'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$USDALabelNutrientToJson(USDALabelNutrient instance) =>
    <String, dynamic>{
      'fat': instance.fat?.toJson(),
      'saturatedFat': instance.saturatedFat?.toJson(),
      'transFat': instance.transFat?.toJson(),
      'cholesterol': instance.cholesterol?.toJson(),
      'sodium': instance.sodium?.toJson(),
      'carbohydrates': instance.carbohydrates?.toJson(),
      'fiber': instance.fiber?.toJson(),
      'sugars': instance.sugars?.toJson(),
      'protein': instance.protein?.toJson(),
      'calcium': instance.calcium?.toJson(),
      'iron': instance.iron?.toJson(),
      'potassium': instance.potassium?.toJson(),
      'calories': instance.calories?.toJson(),
    };

NutrientValue _$NutrientValueFromJson(Map<String, dynamic> json) =>
    NutrientValue(
      (json['value'] as num).toDouble(),
    );

Map<String, dynamic> _$NutrientValueToJson(NutrientValue instance) =>
    <String, dynamic>{
      'value': instance.value,
    };
