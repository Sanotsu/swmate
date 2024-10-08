// 知道分类编号查询
import 'dart:convert';

import '../../common/utils/dio_client/cus_http_client.dart';
import '../../common/utils/dio_client/interceptor_error.dart';
import '../../models/free_dictionary/free_dictionary_resp.dart';

/// API来源和说明：https://github.com/meetDeveloper/freeDictionaryAPI

var fdBase = "https://api.dictionaryapi.dev/api/v2/entries/en";

Future<FreeDictionaryItem> getFreeDictionaryItem(String word) async {
  try {
    var respData = await HttpUtils.get(
      path: "$fdBase/$word",
      // 因为上拉下拉有加载圈，就不显示请求的加载了
      showLoading: false,
      // 因为存在404找不到单词也保存，但单独处理了，就不在http拦截器中报错了
      showErrorMessage: false,
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    if (respData is List<dynamic>) {
      return FreeDictionaryItem.fromJson(
        respData.first as Map<String, dynamic>,
      );
    } else {
      return FreeDictionaryItem.fromJson(respData);
    }
  } on CusHttpException catch (e) {
    // API请求报错，显示报错信息
    // 如果找不到输入的单词，是响应404错误
    // 可以构建一下，方便展示
    return FreeDictionaryItem.fromJson(json.decode(e.errRespString));
  } catch (e) {
    rethrow;
  }
}
