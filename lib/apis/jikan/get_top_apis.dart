import 'dart:convert';

import '../../common/utils/dio_client/cus_http_client.dart';
import '../../models/jikan/jikan_top.dart';

///
/// Jikn 是非官方的 MyAnimeList(MAL) API 动漫排行榜接口返回的数据结构
/// https://docs.api.jikan.moe/
///
/// 2024-09-19 暂时只关注这4个接口(MAL)y已经有很多第三方客户端了，我就只弄自己感兴趣的部分
/// 动画排行榜 https://api.jikan.moe/v4/top/anime
/// 漫画排行榜 https://api.jikan.moe/v4/top/manga
/// 角色排行榜 https://api.jikan.moe/v4/top/characters
/// 人物排行榜 https://api.jikan.moe/v4/top/people
///
/// 统一带上JK(Jikan)前缀
///
Future<JikanTop> getJikanTop({
  // anime | manga | characters | people
  String type = 'anime',
  int page = 1,
  int limit = 25,
}) async {
  try {
    var url = "https://api.jikan.moe/v4/top/$type?page=$page&limit=$limit";

    var respData = await HttpUtils.get(
      path: url,
      // 因为上拉下拉有加载圈，就不显示请求的加载了
      showLoading: false,
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    print("respData===========$respData");

    // 响应是json格式的列表 List<dynamic>
    return JikanTop.fromJson(respData);
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}
