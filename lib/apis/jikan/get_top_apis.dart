import 'dart:convert';

import '../../common/utils/dio_client/cus_http_client.dart';
import '../../models/jikan/jikan_statistic.dart';
import '../../models/jikan/jikan_top.dart';

enum MALType {
  anime,
  manga,
  characters,
  people,
}

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
/// type = anime | manga | characters | people
///
Future<JikanTop> getJikanTop({
  // anime | manga | characters | people
  MALType type = MALType.anime,
  int page = 1,
  int limit = 25,
}) async {
  try {
    var url =
        "https://api.jikan.moe/v4/top/${type.name}?page=$page&limit=$limit";

    var respData = await HttpUtils.get(
      path: url,
      // 因为上拉下拉有加载圈，就不显示请求的加载了
      showLoading: false,
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return JikanTop.fromJson(respData);
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}

///
/// MAL 的 指定动漫漫画的评分组成(人物和角色没有)
/// https://api.jikan.moe/v4/{type}/{id}/statistics
///
Future<JikanStatistic> getAMStatistics(
  int id, {
  MALType type = MALType.anime, // anime | manga
}) async {
  try {
    var url = "https://api.jikan.moe/v4/${type.name}/$id/statistics";

    var respData = await HttpUtils.get(
      path: url,
      // 因为上拉下拉有加载圈，就不显示请求的加载了
      showLoading: false,
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return JikanStatistic.fromJson(respData);
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}

///
/// MAL 的 指定动漫漫画的详情栏位
/// https://api.jikan.moe/v4/{type}/{id}/full
///
Future<JikanTop> getJikanFull(
  int id, {
  MALType type = MALType.anime, // anime | manga | characters | people
}) async {
  try {
    var url = "https://api.jikan.moe/v4/${type.name}/$id/full";

    var respData = await HttpUtils.get(
      path: url,
      // 因为上拉下拉有加载圈，就不显示请求的加载了
      showLoading: false,
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    print("getJikanFull===========$respData");

    // 响应是json格式的列表 List<dynamic>
    return JikanTop.fromJson(respData);
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}

///
/// MAL 的 指定动漫漫画的图片
/// https://api.jikan.moe/v4/{type}/{id}/pictures
///
Future<List<JKImage>> getJikanPictures(
  int id, {
  MALType type = MALType.anime, // anime | manga | characters | people
}) async {
  try {
    var url = "https://api.jikan.moe/v4/${type.name}/$id/pictures";

    var respData = await HttpUtils.get(
      path: url,
      // 因为上拉下拉有加载圈，就不显示请求的加载了
      showLoading: false,
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    // 要取结果的data属性，其值为 JKImage list结构
    return (respData["data"] as List<dynamic>)
        .map((e) => JKImage.fromJson(e))
        .toList();
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}

///
/// MAL 的 条件查询动漫漫画(动漫和漫画条件栏位较多，角色和人物就很少)
/// 所以简单搜索，统一这几个
/// q : 关键字
/// letter: 以此字母开头(只能是1个字母，感觉意义不大，暂时不会按字母筛选)
/// order_by:
///   动漫："mal_id" "favorites" "title" "start_date" "end_date" "score" "scored_by" "rank" "popularity" "members" "episodes"
///   漫画："mal_id" "favorites" "title" "start_date" "end_date" "score" "scored_by" "rank" "popularity" "members" "chapters" "volumes"
///   角色："mal_id" "favorites" "name"
///   人物："mal_id" "favorites" "name" "birthday"
/// sort: "desc" | "asc"
/// page、limit
/// https://api.jikan.moe/v4/{type}?q=xxx&order_by=xxx&page=xxx……
///
Future<JikanTop> getJikanSearch({
  // anime | manga | characters | people
  MALType type = MALType.anime,
  String q = '',
  String orderBy = "favorites",
  String sort = "desc",
  int page = 1,
  int limit = 25,
}) async {
  try {
    // var url =
    //     "https://api.jikan.moe/v4/${type.name}?q=$q&order_by=$orderBy&sort=$sort&page=$page&limit=$limit";

    // 简单点，只关键字搜索，其他默认
    var url =
        "https://api.jikan.moe/v4/${type.name}?q=$q&page=$page&limit=$limit";

    var respData = await HttpUtils.get(
      path: url,
      // 因为上拉下拉有加载圈，就不显示请求的加载了
      showLoading: false,
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    print("getJikanSearch===========$respData");

    // 响应是json格式的列表 List<dynamic>
    return JikanTop.fromJson(respData);
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}
