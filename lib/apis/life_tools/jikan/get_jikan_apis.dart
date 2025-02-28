import 'dart:convert';

import '../../../common/utils/dio_client/cus_http_client.dart';
import '../../../models/life_tools/jikan/jikan_related_character_resp.dart';
import '../../../models/life_tools/jikan/jikan_statistic.dart';
import '../../../models/life_tools/jikan/jikan_data.dart';
import '../../../views/life_tools/anime_top/_components.dart';

var jikanBase = "https://api.jikan.moe/v4";

///
/// Jika非官方的 MyAnimeList(MAL) API 动漫排行榜接口返回的数据结构
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

/// 查询top数据
Future<JikanResp> getJikanTop({
  // anime | manga | characters | people
  MALType type = MALType.anime,
  int page = 1,
  int limit = 25,
}) async {
  try {
    var respData = await HttpUtils.get(
      path: "$jikanBase/top/${type.name}",
      // 因为上拉下拉有加载圈，就不显示请求的加载了
      showLoading: false,
      queryParameters: {
        "page": page,
        "limit": limit,
      },
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return JikanResp.fromJson(respData);
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
    var respData = await HttpUtils.get(
      path: "$jikanBase/${type.name}/$id/statistics",
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
Future<JikanResp> getJikanFull(
  int id, {
  MALType type = MALType.anime, // anime | manga | characters | people
}) async {
  try {
    var respData = await HttpUtils.get(
      path: "$jikanBase/${type.name}/$id/full",
      showLoading: false,
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return JikanResp.fromJson(respData);
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
    var respData = await HttpUtils.get(
      path: "$jikanBase/${type.name}/$id/pictures",
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
Future<JikanResp> getJikanSearch({
  // anime | manga | characters | people
  MALType type = MALType.anime,
  String q = '',
  String orderBy = "favorites",
  String sort = "desc",
  int page = 1,
  int limit = 25,
}) async {
  try {
    // 简单点，只关键字搜索，其他默认
    // 2024-09-24 people实测默认排序是name，https://api.jikan.moe/v4/people?q=one&order_by=name
    // 但执行这个会报错，所以要改为mal_id
    if (type == MALType.people) {
      orderBy = "mal_id";
    }
    var url = "$jikanBase/${type.name}";

    var respData = await HttpUtils.get(
      path: url,
      showLoading: false,
      queryParameters: {
        "q": q,
        "order_by": orderBy,
        "page": page,
        "limit": limit,
      },
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return JikanResp.fromJson(respData);
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}

///
/// MAL 获取播放日期表
Future<JikanResp> getJikanSchedules({
  // Enum: "monday" "tuesday" "wednesday" "thursday"
  // "friday" "saturday" "sunday" "unknown" "other"
  String? filter,
  // Enum: "true" "false"
  bool? sfw,
  // Enum: "true" "false"
  bool? kids,
  int page = 1,
  int limit = 25,
}) async {
  try {
    var url = "$jikanBase/schedules";

    // 这样都是接口预设值
    Map<String, dynamic> map = {
      "page": page,
      "limit": limit,
    };

    // 不传fillter则查询一周所有7天
    if (filter != null) map.addAll({"filter": filter});
    if (sfw != null) map.addAll({"sfw": sfw});
    if (kids != null) map.addAll({"kids": kids});

    var respData = await HttpUtils.get(
      path: url,
      showLoading: false,
      queryParameters: map,
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return JikanResp.fromJson(respData);
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}

/// MAL 获取数据库中播放季列表数据
Future<JikanSeasonResp> getJikanSeasons() async {
  try {
    var respData = await HttpUtils.get(
      path: "$jikanBase/seasons",
      showLoading: false,
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return JikanSeasonResp.fromJson(respData);
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}

/// 获得当季播放信息
/// 不传年份和季节就是当前季
Future<JikanResp> getJikanSingleSeason({
  int? year,
  // Enum: "winter", "spring", "summer", "fall"
  String? season,
  // Enum: "tv" "movie" "ova" "special" "ona" "music"
  String? filter,
  // Enum: "true" "false"
  bool sfw = false,
  int page = 1,
  int limit = 25,
}) async {
  try {
    var url = "$jikanBase/seasons";
    if (year != null && season != null) {
      url = "$url/$year/$season";
    } else {
      url = "$url/now";
    }

    // 这样都是接口预设值
    var map = {"sfw": sfw, "page": page, "limit": limit};

    // 不传fillter则查询一周所有7天
    if (filter != null) map.addAll({"filter": filter});

    var respData = await HttpUtils.get(
      path: url,
      showLoading: false,
      queryParameters: map,
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return JikanResp.fromJson(respData);
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}

/// 获取动漫或漫画关联的角色
Future<JikanRelatedCharacterResp> getJikanRelatedCharacters(
  int id, {
  // anime | manga
  MALType type = MALType.anime,
}) async {
  try {
    var respData = await HttpUtils.get(
      path: "$jikanBase/${type.name}/$id/characters",
      showLoading: false,
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return JikanRelatedCharacterResp.fromJson(respData);
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}
