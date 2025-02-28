import 'dart:convert';

import '../../../common/utils/dio_client/cus_http_client.dart';
import '../../../models/life_tools/news/readhub_hot_topic_resp.dart';

var readhubBase = "https://api.readhub.cn";

// 查询热门话题
Future<ReadhubHotTopicResp> getReadhubHotTopicList({
  int page = 1,
  int size = 10,
}) async {
  try {
    var respData = await HttpUtils.get(
      path: "$readhubBase/topic/list",
      // 因为上拉下拉有加载圈，就不显示请求的加载了
      showLoading: false,
      queryParameters: {"page": page, "size": size},
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    if (respData["data"] == null) {
      throw Exception("返回结果不正确: $respData");
    }

    return ReadhubHotTopicResp.fromJson(respData["data"]);
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}
