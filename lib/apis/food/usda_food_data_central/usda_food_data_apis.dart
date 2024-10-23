import 'dart:convert';

import '../../../common/utils/dio_client/cus_http_client.dart';
import '../../../models/food/usda_food_data/usda_food_item.dart';
import '../../../models/food/usda_food_data/usda_food_search_resp.dart';

/// 来源：https://fdc.nal.usda.gov/api-guide.html
/// 关于数据类型的说明：https://fdc.nal.usda.gov/data-documentation.html
/// 2024-10-17 目前API是测试用的demo，后续可以去网站注册，可以提高到API调用每日上限到1000次。

var baseUsda = "https://api.nal.usda.gov/fdc/v1";

/// 条件查询食品信息
Future<USDASearchResultResp> searchUSDAFoods(
  // 关键字，不可为null，但可以为空字串
  String query, {
  List<String>? dataType, // 数据类型 [Branded,Foundation,Survey (FNDDS),SR Legacy]
  int? pageSize = 10,
  int? pageNumber = 1,
  // 排序的字段：dataType.keyword, lowercaseDescription.keyword, fdcId, publishedDate
  String? sortBy = "dataType.keyword",
  // 排序的方式
  String? sortOrder = "asc", // asc desc
  // 品牌，只适用在品牌分类的食品中
  String? brandOwner,
}) async {
  try {
    var respData = await HttpUtils.get(
      // 这里不传就随机一个类型
      path: "$baseUsda/foods/search",
      // 因为上拉下拉有加载圈，就不显示请求的加载了
      showLoading: false,
      // 因为存在404找不到单词也保存，但单独处理了，就不在http拦截器中报错了
      showErrorMessage: false,
      queryParameters: {
        "api_key": "DEMO_KEY",
        "query": query,
        // 2024-10-14 根据定义，暂时固定为查询基础数据
        // "dataType": ["Foundation"],
        "dataType": dataType,
        "pageSize": pageSize,
        "pageNumber": pageNumber,
      },
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return USDASearchResultResp.fromJson(respData);
  } catch (e) {
    rethrow;
  }
}

// 查询指定编号的食品详情
Future<USDAFoodItem> getUSDAFoodById(
  // 食品编号
  int fdcId, {
  // 返回的栏位
  String? format = "full", // abridged, full
}) async {
  try {
    var respData = await HttpUtils.get(
      // 这里不传就随机一个类型
      path: "$baseUsda/food/$fdcId",
      // 因为上拉下拉有加载圈，就不显示请求的加载了
      showLoading: false,
      // 因为存在404找不到单词也保存，但单独处理了，就不在http拦截器中报错了
      showErrorMessage: false,
      queryParameters: {
        "api_key": "DEMO_KEY",
        "format": format,
      },
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return USDAFoodItem.fromJson(respData);
  } catch (e) {
    rethrow;
  }
}
