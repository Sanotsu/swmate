// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usda_food_search_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

USDASearchResultResp _$USDASearchResultRespFromJson(
        Map<String, dynamic> json) =>
    USDASearchResultResp(
      (json['totalHits'] as num).toInt(),
      (json['currentPage'] as num).toInt(),
      (json['totalPages'] as num).toInt(),
      (json['pageList'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      USDAFoodSearchCriteria.fromJson(
          json['foodSearchCriteria'] as Map<String, dynamic>),
      (json['foods'] as List<dynamic>)
          .map((e) => USDAFoodItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      USDAAggregation.fromJson(json['aggregations'] as Map<String, dynamic>),
      error: json['error'] == null
          ? null
          : USDAError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$USDASearchResultRespToJson(
        USDASearchResultResp instance) =>
    <String, dynamic>{
      'totalHits': instance.totalHits,
      'currentPage': instance.currentPage,
      'totalPages': instance.totalPages,
      'pageList': instance.pageList,
      'foodSearchCriteria': instance.foodSearchCriteria.toJson(),
      'foods': instance.foods.map((e) => e.toJson()).toList(),
      'aggregations': instance.aggregations.toJson(),
      'error': instance.error?.toJson(),
    };

USDAFoodSearchCriteria _$USDAFoodSearchCriteriaFromJson(
        Map<String, dynamic> json) =>
    USDAFoodSearchCriteria(
      query: json['query'] as String?,
      generalSearchInput: json['generalSearchInput'] as String?,
      pageNumber: (json['pageNumber'] as num?)?.toInt(),
      numberOfResultsPerPage: (json['numberOfResultsPerPage'] as num?)?.toInt(),
      pageSize: (json['pageSize'] as num?)?.toInt(),
      requireAllWords: json['requireAllWords'] as bool?,
    );

Map<String, dynamic> _$USDAFoodSearchCriteriaToJson(
        USDAFoodSearchCriteria instance) =>
    <String, dynamic>{
      'query': instance.query,
      'generalSearchInput': instance.generalSearchInput,
      'pageNumber': instance.pageNumber,
      'numberOfResultsPerPage': instance.numberOfResultsPerPage,
      'pageSize': instance.pageSize,
      'requireAllWords': instance.requireAllWords,
    };

USDAAggregation _$USDAAggregationFromJson(Map<String, dynamic> json) =>
    USDAAggregation(
      Map<String, int>.from(json['dataType'] as Map),
      json['nutrients'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$USDAAggregationToJson(USDAAggregation instance) =>
    <String, dynamic>{
      'dataType': instance.dataType,
      'nutrients': instance.nutrients,
    };

USDAError _$USDAErrorFromJson(Map<String, dynamic> json) => USDAError(
      json['code'] as String,
      json['message'] as String,
    );

Map<String, dynamic> _$USDAErrorToJson(USDAError instance) => <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
    };
