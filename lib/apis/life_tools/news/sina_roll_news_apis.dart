import 'dart:convert';

import '../../../common/utils/dio_client/cus_http_client.dart';
import '../../../models/life_tools/news/sina_roll_news_resp.dart';

var sinaRollNewsBase = "https://feed.mix.sina.com.cn/api/roll/get";

// 查询热门话题
Future<SinaRollNewsResp> getSinaRollNewsList({
  int page = 1,
  int size = 10,
  int lid = 2509,
}) async {
  try {
    var respData = await HttpUtils.get(
      path: sinaRollNewsBase,
      // 因为上拉下拉有加载圈，就不显示请求的加载了
      showLoading: false,
      queryParameters: {
        "pageid": 153,
        "lid": lid,
        "page": page,
        "num": size,
      },
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    if (respData["result"] == null) {
      throw Exception("返回结果不正确: $respData");
    }

    return SinaRollNewsResp.fromJson(respData["result"]);
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}
