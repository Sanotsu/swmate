import 'dart:convert';

import '../../common/utils/dio_client/cus_http_client.dart';
import '../../models/news/news_api_resp.dart';
import '../platform_keys.dart';

var newsapiBase = "https://newsapi.org/v2";

// 查询热门话题
Future<NewsApiResp> getNewsapiList({
  int page = 1,
  int pageSize = 100,
  // 热点 top-headlines | 所有 everything
  String type = "top-headlines",
  String? query,
  String? category,
}) async {
  var params = {
    "apiKey": NEWS_API_KEY,

    // 新闻来源，可以在 https://newsapi.org/v2/top-headlines/sources 查到相关信息(结构体的id栏位)

    /// 不能和 country 或 category 一起用
    // "sources": '',

    "page": page,
    // 默认100。为了减少请求次数，可以保留个大数字
    "pageSize": pageSize,
  };

// 2024-11-06 就只给两个选项，热榜和所有的查询
  if (type == "top-headlines") {
    /// 热榜时，这几个栏位不可都为空: sources, q, country, category
    params.addAll({
      // 查询热榜暂时不用关键字查询，默认分类显示所有
      // "q": query ?? "",

      // ISO 3166-1编码的两个字母的国家编号【目前免费的看起来只能用 us 才有值】
      // 不能和 sources 参数一起用
      // https://www.iso.org/obp/ui/#search
      // "country": 'us',

      // 新闻的分类： business entertainment general health science sports technology
      // 不能和 sources 参数一起用
      "category": category ?? 'general',
    });
  } else {
    // 所有搜索时，后面栏位不可全为空： q, qInTitle, sources, domains.
    params.addAll({
      // 搜索的关键字(带双引号可以强制匹配)
      // 2024-11-07 查询热榜时只有分类就不带上查询了，查询就从所有新闻来
      "q": "$query",

      // 搜索限制到的字段,可以用逗号添加多个
      // title | description | content
      "searchIn": "title,description",

      // 新闻的网域,多个用逗号连接，例如 bbc.co.uk,techcrunch.com,engadget.com
      // "domains": "",

      // 排除的域,多个用逗号连接，例如 bbc.co.uk,techcrunch.com,engadget.com
      // "excludeDomains": "",

      // 搜索的时间范围，ISO 8601 格式字符串
      // "from": '',
      // "to": '',

      // 标题的语言,可选性
      // ar de en es fr he it nl no pt ru sv ud zh
      // "language": "zh",

      // 排序方式
      // relevancy: 与q关系更密切的文章排在前面
      // popularity: 来自流行来源和出版商的文章优先
      // publishedAt(默认): 最新文章排在第一位
      "sortBy": "publishedAt",
    });
  }

  try {
    var respData = await HttpUtils.get(
      path: "$newsapiBase/$type",
      // 因为上拉下拉有加载圈，就不显示请求的加载了
      showLoading: false,
      queryParameters: params,
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return NewsApiResp.fromJson(respData);
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}
