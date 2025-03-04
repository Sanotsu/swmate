import 'dart:convert';

import '../../../common/utils/dio_client/cus_http_client.dart';
import '../../../common/utils/dio_client/cus_http_request.dart';
import '../../../models/life_tools/bangumi/bangumi.dart';

const bgmBase = "https://api.bgm.tv";

// v0 实验版本条件查询
// 2024-09-25 因为文档说可能会变：实验性 API， 本 schema 和实际的 API 行为都可能随时发生改动
// 所以暂时不用 https://bangumi.github.io/api/#/
Future<List<BGMSubject>> getBangumiSubject(
  BgmParam params, {
  int? page = 1,
  int? pageSize = 10,

  // int? type = 2, // 1书籍 2动画 3音乐 4游戏 6三次元，没有5
  // List<String>? tag, // eg. "tag": ["童年","原创"],
  // List<String>? airdate, // eg. "air_date": [">=2020-07-01","<2020-10-01"],
  // List<String>? rating, // eg. "rating": [">=6","<8"],
  // List<String>? rank, // eg. "rank": [">10","<=18"],
  // bool? nsfw = false,
}) async {
  try {
    // 页面要放在url，其他条件在data中
    // limit: 取多少条
    // offser: 从哪个偏移数开始(数据的索引从0开始)
    var url =
        "$bgmBase/v0/search/subjects?limit=$pageSize&offset=${pageSize! * page!}";

    var respData = await HttpUtils.post(
      path: url,
      // 因为上拉下拉有加载圈，就不显示请求的加载了
      showLoading: false,
      method: CusHttpMethod.post,
      data: params.toJson(),
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    // 正常响应是取data属性了，不知道报错时怎样
    return (respData['data'] as List<dynamic>)
        .map((e) => BGMSubject.fromJson(e))
        .toList();
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}

// 查询指定条目
Future<BGMSubject> getBangumiSubjectById(int id) async {
  try {
    var url = "$bgmBase/v0/subjects/$id";

    var respData = await HttpUtils.get(
      path: url,
      // 因为上拉下拉有加载圈，就不显示请求的加载了
      showLoading: false,
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return BGMSubject.fromJson(respData);
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}

// 查询条目关联的人物(演职表)
Future<List<BGMSubjectRelation>> getBangumiSubjectRelated(
  int id, {
  String? type = "persons", // persons | characters | subjects
}) async {
  try {
    var url = "$bgmBase/v0/subjects/$id/$type";

    List respData = await HttpUtils.get(
      path: url,
      // 因为上拉下拉有加载圈，就不显示请求的加载了
      showLoading: false,
    );

    return respData.map((e) => BGMSubjectRelation.fromJson(e)).toList();
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}

// 没有v0前缀的查询(栏位可能够用了)
Future<BGMLargeSubjectResp> searchBangumiLargeSubjectByKeyword(
  // 查询条件不可为空
  String keyword, {
  int? type = 2, // 1书籍 2动画 3音乐 4游戏 6三次元，没有5
  String? responseGroup = "large", // small medium large
  int? start = 0, // 开始条数
  int? maxResults = 25, // 每页条数
}) async {
  try {
    if (keyword.isEmpty) {
      throw Exception("关键字不可为空");
    }

    var respData = await HttpUtils.get(
      path: "$bgmBase/search/subject/$keyword",
      // 因为上拉下拉有加载圈，就不显示请求的加载了
      showLoading: false,
      queryParameters: {
        "type": type,
        "responseGroup": responseGroup,
        "start": start,
        "max_results": maxResults,
      },
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return BGMLargeSubjectResp.fromJson(respData);
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}

// 查询每日放送,一个周的每日
Future<List<BGMLargeCalendar>> getBangumiCalendar() async {
  try {
    List respData = await HttpUtils.get(
      path: "$bgmBase/calendar",
      // 因为上拉下拉有加载圈，就不显示请求的加载了
      showLoading: false,
    );

    return respData.map((e) => BGMLargeCalendar.fromJson(e)).toList();
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}

/// 查询指定番剧的剧集简介信息
Future<BGMEpisodeResp> getBangumiEpisodesById(
  int id, {
  // 章节类型： 0 = 本篇; 1 = 特别篇; 2 = OP; 3 = ED; 4 = 预告/宣传/广告; 5 = MAD; 6 = 其他
  int? type = 0,
  int? limit = 100,
  int offset = 0,
}) async {
  try {
    var respData = await HttpUtils.get(
        path: "$bgmBase/v0/episodes",
        // 因为上拉下拉有加载圈，就不显示请求的加载了
        showLoading: false,
        queryParameters: {
          "subject_id": id,
          "type": type,
          "limit": limit,
          "offset": offset,
        });

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return BGMEpisodeResp.fromJson(respData);
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}
