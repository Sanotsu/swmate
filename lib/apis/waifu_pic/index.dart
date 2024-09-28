import 'dart:convert';

import '../../common/utils/dio_client/cus_http_client.dart';
import '../../common/utils/dio_client/cus_http_request.dart';

///
/// 获取 waifu.pics 图片
///
/// 单个图片： GET https://api.waifu.pics/{type}/{category}
/// 随机30张图片： POST https://api.waifu.pics/many/{type}/{category}
///
/// 获取waifu.im 的图片 https://docs.waifu.im/reference/api-reference/search
/// 参数更多，但不知道是不是同一个源
/// https://api.waifu.im/search?included_tags={array[string]}&is_nsfw={string}
///
/*
  curl --request POST \
  --url https://api.waifu.pics/many/sfw/pat \
  --header 'accept: application/json' \
  --header 'content-type: application/json' \
  --data '
  {
    "type": "sfw",
    "category":"pat"
  }
'  
  */
Future<List<String>> getWaifuPicImages({
  String? type = "sfw", // 只有2个 sfw | nsfw
  String? category, // 分类
  bool isMany = false, // 是否多个，是则为POST 否则为GET
  // 现在两个源 pics | im
  // 上面3个参数是默认 pics 的，im 的带上前缀(虽然原本支持参数很多，但这里只提供少数)
  String source = "pics",
  String imIncludedTags = "waifu", // 虽说是支持多个，但添加多个tag时报错
  // 如果tag本身就是nsfw的，那这个bool没效果，都是工作场合不安全；
  // 但tag不是nsfw，不加上这个false，则可能出现工作场合不安全
  bool imIsNsfw = false,
  int imLimit = 1,
}) async {
  try {
    if (source == "im") {
      var respData = await HttpUtils.get(
        path:
            "https://api.waifu.im/search?included_tags=$imIncludedTags&is_nsfw=$imIsNsfw${imLimit > 1 ? "&limit=$imLimit" : ""}",
      );

      if (respData.runtimeType == String) {
        respData = json.decode(respData);
      }

      // 这个响应体内容很多，暂时只取得地址即可
      return (respData["images"] as List<dynamic>)
          .map((e) => (e["url"] as String))
          .toList();
    } else {
      var respData = (isMany)
          ? await HttpUtils.post(
              path: "https://api.waifu.pics/many/$type/$category",
              method: CusHttpMethod.post,
              headers: {"Content-Type": "application/json"},
              data: {"type": type, "category": category})
          : await HttpUtils.get(
              path: "https://api.waifu.pics/$type/$category",
            );

      if (respData.runtimeType == String) {
        respData = json.decode(respData);
      }

      if (isMany) {
        return (respData["files"] as List<dynamic>).cast<String>();
      } else {
        return [respData["url"]];
      }
    }
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}
