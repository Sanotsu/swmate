import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import 'usda_food_item.dart';

part 'usda_food_search_resp.g.dart';

/// 2024-10-14 关键字条件查询的响应，还支持其他一些参数
/// https://api.nal.usda.gov/fdc/v1/foods/search?query=cheddar%20cheese
///   &dataType=Foundation,SR%20Legacy
///   &pageSize=25
///   &pageNumber=2
///   &sortBy=dataType.keyword
///   &sortOrder=asc
///   &brandOwner=Kar%20Nut%20Products%20Company
/// 参看：https://app.swaggerhub.com/apis/fdcnal/food-data_central_api/1.0.1#/FDC/getFoodsSearch
/// 类名尽量使用其schema的命名+USDA前缀
///   注意：文档schema的栏位和实际返回的可能不一样，以实际返回的为准

@JsonSerializable(explicitToJson: true)
class USDASearchResultResp {
  @JsonKey(name: 'totalHits')
  int totalHits;

  @JsonKey(name: 'currentPage')
  int currentPage;

  @JsonKey(name: 'totalPages')
  int totalPages;

  @JsonKey(name: 'pageList')
  List<int> pageList;

  @JsonKey(name: 'foodSearchCriteria')
  USDAFoodSearchCriteria foodSearchCriteria;

  @JsonKey(name: 'foods')
  List<USDAFoodItem> foods;

  @JsonKey(name: 'aggregations')
  USDAAggregation aggregations;

  // 还有报错的
  @JsonKey(name: 'error')
  USDAError? error;

  USDASearchResultResp(
    this.totalHits,
    this.currentPage,
    this.totalPages,
    this.pageList,
    this.foodSearchCriteria,
    this.foods,
    this.aggregations, {
    this.error,
  });

  // 从字符串转
  factory USDASearchResultResp.fromRawJson(String str) =>
      USDASearchResultResp.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory USDASearchResultResp.fromJson(Map<String, dynamic> srcJson) =>
      _$USDASearchResultRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$USDASearchResultRespToJson(this);
}

// 食品条件查询标准
// https://app.swaggerhub.com/apis/fdcnal/food-data_central_api/1.0.1#/FoodSearchCriteria
@JsonSerializable(explicitToJson: true)
class USDAFoodSearchCriteria {
  @JsonKey(name: 'query')
  String? query;

  @JsonKey(name: 'generalSearchInput')
  String? generalSearchInput;

  @JsonKey(name: 'pageNumber')
  int? pageNumber;

  @JsonKey(name: 'numberOfResultsPerPage')
  int? numberOfResultsPerPage;

  @JsonKey(name: 'pageSize')
  int? pageSize;

  @JsonKey(name: 'requireAllWords')
  bool? requireAllWords;

  USDAFoodSearchCriteria({
    this.query,
    this.generalSearchInput,
    this.pageNumber,
    this.numberOfResultsPerPage,
    this.pageSize,
    this.requireAllWords,
  });

  // 从字符串转
  factory USDAFoodSearchCriteria.fromRawJson(String str) =>
      USDAFoodSearchCriteria.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory USDAFoodSearchCriteria.fromJson(Map<String, dynamic> srcJson) =>
      _$USDAFoodSearchCriteriaFromJson(srcJson);

  Map<String, dynamic> toJson() => _$USDAFoodSearchCriteriaToJson(this);
}

// 条件查询聚合的栏位
@JsonSerializable(explicitToJson: true)
class USDAAggregation {
  @JsonKey(name: 'dataType')
  Map<String, int> dataType;

  // 2024-10-14 暂时只看到一个{}，具体什么结构不知道
  @JsonKey(name: 'nutrients')
  Map<dynamic, dynamic> nutrients;

  USDAAggregation(
    this.dataType,
    this.nutrients,
  );

  // 从字符串转
  factory USDAAggregation.fromRawJson(String str) =>
      USDAAggregation.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory USDAAggregation.fromJson(Map<String, dynamic> srcJson) =>
      _$USDAAggregationFromJson(srcJson);

  Map<String, dynamic> toJson() => _$USDAAggregationToJson(this);
}

// 请求报错应该会有这两个参数，所有的请求都可能有这个报错
@JsonSerializable()
class USDAError {
  @JsonKey(name: 'code')
  String code;

  @JsonKey(name: 'message')
  String message;

  USDAError(
    this.code,
    this.message,
  );

  // 从字符串转
  factory USDAError.fromRawJson(String str) =>
      USDAError.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory USDAError.fromJson(Map<String, dynamic> srcJson) =>
      _$USDAErrorFromJson(srcJson);

  Map<String, dynamic> toJson() => _$USDAErrorToJson(this);
}
