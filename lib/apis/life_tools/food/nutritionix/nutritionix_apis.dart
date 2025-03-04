// 查询指定编号的食品详情
import 'dart:convert';

import '../../../../common/constants/default_models.dart';
import '../../../../common/utils/dio_client/cus_http_client.dart';
import '../../../../common/utils/dio_client/cus_http_request.dart';
import '../../../../models/life_tools/food/nutritionix/nix_natural_exercise_resp.dart';
import '../../../../models/life_tools/food/nutritionix/nix_natural_nutrient_resp.dart';
import '../../../../models/life_tools/food/nutritionix/nix_search_instant_resp.dart';
import '../../../get_app_key_helper.dart';

var baseUsda = "https://trackapi.nutritionix.com/v2";

Future<Map<String, String>> _getNutritionixHeaders() async {
  return {
    'Content-Type': 'application/json',
    'x-app-id': getStoredUserKey(
      "USER_NUTRITIONIX_APP_ID",
      DefaultApiKeys.nutritionixAppId,
    ),
    'x-app-key': getStoredUserKey(
      "USER_NUTRITIONIX_APP_KEY",
      DefaultApiKeys.nutritionixAppKey,
    ),
  };
}

///
/// 此请求文档地址：https://docx.riversand.com/developers/docs/natural-language-for-nutrients
/// 参数只保留少部分
/// 4个主要api：
///   /v2/natural/nutrients 自然语言查询食品营养素
///   /v2/search/instant    条件查询品牌食品(关键字查询食品列表)
///   /v2/search/item       指定编号查询(可以配合关键字查询显示即时信息)
///   /v2/natural/exercise  自然语言查询运动消耗(描述运动细节，和人体基本数据，得到消耗结果)
///
/// 通过自然语言查询食物
/// 注意：自然语言搜索的结果结构和指定编号(upc或nixItemId)的结果结构时类似的
///     不过前缀没有这两个编号而已，而条件查询品牌食品时common也没有这两个编号
Future<NixNaturalNutrientResp> searchNixNutrientFoodByNL(
  String query, {
  // 是否返回配方
  bool? includeSubrecipe = true,
  // 是否返回组成
  bool? ingredientStatement = true,
}) async {
  if (query.isEmpty) {
    throw Exception("查询条件不可为空");
  }

  try {
    var respData = await HttpUtils.post(
      method: CusHttpMethod.post,
      // 这里不传就随机一个类型
      path: "$baseUsda/natural/nutrients",
      // 因为上拉下拉有加载圈，就不显示请求的加载了
      showLoading: false,
      // 因为存在404找不到单词也保存，但单独处理了，就不在http拦截器中报错了
      showErrorMessage: false,
      headers: _getNutritionixHeaders(),
      data: {
        "query": query,
        "include_subrecipe": includeSubrecipe,
        "ingredient_statement": ingredientStatement,
        // 页面请求上有的，加上试一下
        // 是否行检测，如果是true，那一行只能有1种食物
        "line_delimited": false,
        "claims": true,
        "taxonomy": true,
        "use_raw_foods": false
      },
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return NixNaturalNutrientResp.fromJson(respData);
  } catch (e) {
    rethrow;
  }
}

/// 关键字查询食品实例
/// 结果会有品牌和基础两个食品分类
/// (高级用户参数栏位还要多些，其实这里也只是使用少量参数)
Future<NixSearchInstantResp> searchNixInstants(
  String query, {
  // 确定是否在结果中包含品牌食品（杂货店和餐厅）。
  bool? branded = true,
  // 可指定查询一组品牌食品
  List<String>? brandIds,
  // 按品牌类型过滤品牌结果。
  // 1=Restaurant(餐厅)，2=Grocery(杂货店)，Null表示不进行筛选。
  int? brandedType,
  // 按区域id筛选品牌结果。1=美国，2=英国。null指定不进行区域筛选，只返回美国。
  int? brandedRegion,
  // 是否只返回视频名称
  bool? brandedFoodNameOnly,
  // 是否包括 common 常见的食物结果。
  bool? common,
  // 包括没有杂货店或餐厅标签的普通食物。仅当“common”字段设置为true时应用。
  bool? commonGrocery,
  // 包括普通餐厅的食物。仅当“common”字段设置为true时应用。
  bool? commonRestaurant,
}) async {
  if (query.isEmpty) {
    throw Exception("查询条件不可为空");
  }

  try {
    var respData = await HttpUtils.get(
      // 这里不传就随机一个类型
      path: "$baseUsda/search/instant",
      // 因为上拉下拉有加载圈，就不显示请求的加载了
      showLoading: false,
      // 因为存在404找不到单词也保存，但单独处理了，就不在http拦截器中报错了
      showErrorMessage: false,
      headers: _getNutritionixHeaders(),
      queryParameters: {
        "query": query,
        "branded": branded,
      },
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return NixSearchInstantResp.fromJson(respData);
  } catch (e) {
    rethrow;
  }
}

/// 通过指定编号查询带营养素的食品信息
Future<NixNaturalNutrientResp> searchNixNutrientFoodById({
  // 两个编号必须有一个(理论上不应该两个都传，毕竟两个的结果不一致的话就没意义了)
  String? upc,
  String? nixItemId,
}) async {
  // 两个编号必须有一个,且不能为空
  Map<String, dynamic> params = {};
  if (nixItemId != null && nixItemId.isNotEmpty) {
    params.addAll({"nix_item_id": nixItemId});
  } else if (upc != null && upc.isNotEmpty) {
    params.addAll({"upc": upc});
  } else {
    throw Exception("upc或nixItemId不可都为空");
  }

  try {
    var respData = await HttpUtils.get(
      // 这里不传就随机一个类型
      path: "$baseUsda/search/item",
      // 因为上拉下拉有加载圈，就不显示请求的加载了
      showLoading: false,
      // 因为存在404找不到单词也保存，但单独处理了，就不在http拦截器中报错了
      showErrorMessage: false,
      headers: _getNutritionixHeaders(),
      queryParameters: params,
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return NixNaturalNutrientResp.fromJson(respData);
  } catch (e) {
    rethrow;
  }
}

/// 通过自然语言查询运动消耗
Future<NixNaturalExerciseResp> searchNixExerciseByNL(
  // 运动的简单描述：“I ran 1 mile”
  String query, {
  // 传入身高体重年龄更方便计算(不传可能使用典型值)
  double? weightKg,
  double? heightCm,
  double? age,
}) async {
  if (query.isEmpty) {
    throw Exception("查询条件不可为空");
  }

  Map<String, dynamic> params = {"query": query};
  if (weightKg != null) params['weight_kg'] = weightKg;
  if (heightCm != null) params['height_cm'] = heightCm;
  if (age != null) params['age'] = age;

  try {
    var respData = await HttpUtils.post(
      method: CusHttpMethod.post,
      // 这里不传就随机一个类型
      path: "$baseUsda/natural/exercise",
      // 因为上拉下拉有加载圈，就不显示请求的加载了
      showLoading: false,
      // 因为存在404找不到单词也保存，但单独处理了，就不在http拦截器中报错了
      showErrorMessage: false,
      headers: _getNutritionixHeaders(),
      data: params,
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return NixNaturalExerciseResp.fromJson(respData);
  } catch (e) {
    rethrow;
  }
}
