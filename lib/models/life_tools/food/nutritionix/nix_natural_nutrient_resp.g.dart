// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nix_natural_nutrient_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NixNaturalNutrientResp _$NixNaturalNutrientRespFromJson(
        Map<String, dynamic> json) =>
    NixNaturalNutrientResp(
      foods: (json['foods'] as List<dynamic>?)
          ?.map((e) => NixNutrientFood.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$NixNaturalNutrientRespToJson(
        NixNaturalNutrientResp instance) =>
    <String, dynamic>{
      'foods': instance.foods?.map((e) => e.toJson()).toList(),
    };

NixNutrientFood _$NixNutrientFoodFromJson(Map<String, dynamic> json) =>
    NixNutrientFood(
      foodName: json['food_name'] as String?,
      servingQty: (json['serving_qty'] as num?)?.toInt(),
      servingUnit: json['serving_unit'] as String?,
      servingWeightGrams: (json['serving_weight_grams'] as num?)?.toInt(),
      nfMetricQty: (json['nf_metric_qty'] as num?)?.toInt(),
      nfMetricUom: json['nf_metric_uom'] as String?,
      nfCalories: (json['nf_calories'] as num?)?.toDouble(),
      nfTotalFat: (json['nf_total_fat'] as num?)?.toDouble(),
      nfSaturatedFat: (json['nf_saturated_fat'] as num?)?.toDouble(),
      nfCholesterol: (json['nf_cholesterol'] as num?)?.toInt(),
      nfSodium: (json['nf_sodium'] as num?)?.toDouble(),
      nfTotalCarbohydrate: (json['nf_total_carbohydrate'] as num?)?.toDouble(),
      nfDietaryFiber: (json['nf_dietary_fiber'] as num?)?.toDouble(),
      nfSugars: (json['nf_sugars'] as num?)?.toDouble(),
      nfProtein: (json['nf_protein'] as num?)?.toDouble(),
      nfPotassium: (json['nf_potassium'] as num?)?.toDouble(),
      nfP: (json['nf_p'] as num?)?.toDouble(),
      fullNutrients: (json['full_nutrients'] as List<dynamic>?)
          ?.map((e) => NixFullNutrient.fromJson(e as Map<String, dynamic>))
          .toList(),
      consumedAt: json['consumed_at'] as String?,
      metadata: json['metadata'] == null
          ? null
          : NixMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      source: (json['source'] as num?)?.toInt(),
      ndbNo: (json['ndb_no'] as num?)?.toInt(),
      tags: json['tags'] == null
          ? null
          : NixTag.fromJson(json['tags'] as Map<String, dynamic>),
      altMeasures: (json['alt_measures'] as List<dynamic>?)
          ?.map((e) => NixAltMeasure.fromJson(e as Map<String, dynamic>))
          .toList(),
      mealType: (json['meal_type'] as num?)?.toInt(),
      photo: json['photo'] == null
          ? null
          : NixPhoto.fromJson(json['photo'] as Map<String, dynamic>),
      brandName: json['brand_name'] as String?,
      brickCode: json['brick_code'] as String?,
      classCode: json['class_code'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      nixBrandId: json['nix_brand_id'] as String?,
      nixBrandName: json['nix_brand_name'] as String?,
      nixItemId: json['nix_item_id'] as String?,
      nixItemName: json['nix_item_name'] as String?,
      subRecipe: (json['sub_recipe'] as List<dynamic>?)
          ?.map((e) => NixSubRecipe.fromJson(e as Map<String, dynamic>))
          .toList(),
      tagId: json['tag_id'] as String?,
      note: json['note'] as String?,
      updatedAt: json['updated_at'] as String?,
      upc: json['upc'] as String?,
      nfIngredientStatement: json['nf_ingredient_statement'],
    );

Map<String, dynamic> _$NixNutrientFoodToJson(NixNutrientFood instance) =>
    <String, dynamic>{
      'food_name': instance.foodName,
      'brand_name': instance.brandName,
      'serving_qty': instance.servingQty,
      'serving_unit': instance.servingUnit,
      'serving_weight_grams': instance.servingWeightGrams,
      'nf_metric_qty': instance.nfMetricQty,
      'nf_metric_uom': instance.nfMetricUom,
      'nf_calories': instance.nfCalories,
      'nf_total_fat': instance.nfTotalFat,
      'nf_saturated_fat': instance.nfSaturatedFat,
      'nf_cholesterol': instance.nfCholesterol,
      'nf_sodium': instance.nfSodium,
      'nf_total_carbohydrate': instance.nfTotalCarbohydrate,
      'nf_dietary_fiber': instance.nfDietaryFiber,
      'nf_sugars': instance.nfSugars,
      'nf_protein': instance.nfProtein,
      'nf_potassium': instance.nfPotassium,
      'nf_p': instance.nfP,
      'full_nutrients': instance.fullNutrients?.map((e) => e.toJson()).toList(),
      'nix_brand_name': instance.nixBrandName,
      'nix_brand_id': instance.nixBrandId,
      'nix_item_name': instance.nixItemName,
      'nix_item_id': instance.nixItemId,
      'upc': instance.upc,
      'consumed_at': instance.consumedAt,
      'metadata': instance.metadata?.toJson(),
      'source': instance.source,
      'ndb_no': instance.ndbNo,
      'tags': instance.tags?.toJson(),
      'alt_measures': instance.altMeasures?.map((e) => e.toJson()).toList(),
      'lat': instance.lat,
      'lng': instance.lng,
      'meal_type': instance.mealType,
      'photo': instance.photo?.toJson(),
      'sub_recipe': instance.subRecipe?.map((e) => e.toJson()).toList(),
      'note': instance.note,
      'class_code': instance.classCode,
      'brick_code': instance.brickCode,
      'tag_id': instance.tagId,
      'updated_at': instance.updatedAt,
      'nf_ingredient_statement': instance.nfIngredientStatement,
    };

NixFullNutrient _$NixFullNutrientFromJson(Map<String, dynamic> json) =>
    NixFullNutrient(
      attrId: (json['attr_id'] as num?)?.toInt(),
      value: (json['value'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$NixFullNutrientToJson(NixFullNutrient instance) =>
    <String, dynamic>{
      'attr_id': instance.attrId,
      'value': instance.value,
    };

NixMetadata _$NixMetadataFromJson(Map<String, dynamic> json) => NixMetadata(
      isRawFood: json['is_raw_food'] as bool?,
    );

Map<String, dynamic> _$NixMetadataToJson(NixMetadata instance) =>
    <String, dynamic>{
      'is_raw_food': instance.isRawFood,
    };

NixTag _$NixTagFromJson(Map<String, dynamic> json) => NixTag(
      item: json['item'] as String?,
      measure: json['measure'] as String?,
      quantity: json['quantity'] as String?,
      foodGroup: (json['food_group'] as num?)?.toInt(),
      tagId: (json['tag_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$NixTagToJson(NixTag instance) => <String, dynamic>{
      'item': instance.item,
      'measure': instance.measure,
      'quantity': instance.quantity,
      'food_group': instance.foodGroup,
      'tag_id': instance.tagId,
    };

NixAltMeasure _$NixAltMeasureFromJson(Map<String, dynamic> json) =>
    NixAltMeasure(
      servingWeight: (json['serving_weight'] as num?)?.toInt(),
      measure: json['measure'] as String?,
      seq: (json['seq'] as num?)?.toInt(),
      qty: (json['qty'] as num?)?.toInt(),
    );

Map<String, dynamic> _$NixAltMeasureToJson(NixAltMeasure instance) =>
    <String, dynamic>{
      'serving_weight': instance.servingWeight,
      'measure': instance.measure,
      'seq': instance.seq,
      'qty': instance.qty,
    };

NixSubRecipe _$NixSubRecipeFromJson(Map<String, dynamic> json) => NixSubRecipe(
      servingWeight: (json['serving_weight'] as num?)?.toInt(),
      food: json['food'] as String?,
      ndbNumber: (json['ndb_number'] as num?)?.toInt(),
      calories: (json['calories'] as num?)?.toDouble(),
      tagId: (json['tag_id'] as num?)?.toInt(),
      recipeId: (json['recipe_id'] as num?)?.toInt(),
      servingQty: (json['serving_qty'] as num?)?.toDouble(),
      servingUnit: json['serving_unit'] as String?,
    );

Map<String, dynamic> _$NixSubRecipeToJson(NixSubRecipe instance) =>
    <String, dynamic>{
      'serving_weight': instance.servingWeight,
      'food': instance.food,
      'ndb_number': instance.ndbNumber,
      'calories': instance.calories,
      'tag_id': instance.tagId,
      'recipe_id': instance.recipeId,
      'serving_qty': instance.servingQty,
      'serving_unit': instance.servingUnit,
    };

NixPhoto _$NixPhotoFromJson(Map<String, dynamic> json) => NixPhoto(
      thumb: json['thumb'] as String?,
      highres: json['highres'] as String?,
      isUserUploaded: json['is_user_uploaded'] as bool?,
    );

Map<String, dynamic> _$NixPhotoToJson(NixPhoto instance) => <String, dynamic>{
      'thumb': instance.thumb,
      'highres': instance.highres,
      'is_user_uploaded': instance.isUserUploaded,
    };
