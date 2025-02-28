// ignore_for_file: non_constant_identifier_names
import 'dart:convert';

import '../../../common/constants/constants.dart';
import '../../../common/utils/dio_client/cus_http_client.dart';
import '../../../models/life_tools/news/momoyu_info_resp.dart';

//
// 摸摸鱼热榜 https://momoyu.cc/
// 它没有开放API，这里只是使用f12看到了友好的API地址，所以直接使用，不保真
// 进入首页刷新所有：
//    https://momoyu.cc/api/hot/list?type=0
// 指定分类的刷新：
//    https://momoyu.cc/api/hot/item?id=1
// 当前在线人数（正在摸鱼）：
//    https://momoyu.cc/api/user/count

// id不保证一定对，原作者数据来源也不详细

List<CusLabel> MomoyuItems = [
  // 新闻资讯
  CusLabel(cnLabel: "今日头条", value: 69),
  CusLabel(cnLabel: "虎嗅", value: 38),
  // 热门社区
  CusLabel(cnLabel: "微博热搜", value: 3),
  CusLabel(cnLabel: "知乎热榜", value: 1),
  CusLabel(cnLabel: "虎扑步行街", value: 47),
  CusLabel(cnLabel: "豆瓣热话", value: 2), // 很久没更新数据了
  // 视频平台
  CusLabel(cnLabel: "B站", value: 18),
  // 购物平台
  CusLabel(cnLabel: "值得买3小时热门", value: 28),
  // IT科技
  CusLabel(cnLabel: "IT之家", value: 6),
  CusLabel(cnLabel: "中关村在线", value: 7),
  CusLabel(cnLabel: "爱范儿", value: 9),
  // 程序员聚集地
  CusLabel(cnLabel: "开源中国", value: 12),
  CusLabel(cnLabel: "CSDN", value: 46),
  CusLabel(cnLabel: "掘金", value: 52),
];

var momoyuBase = "https://momoyu.cc/api";

// 一次性查询所有的信息
Future<MomoyuInfoResp<List<MMYData>>> getMomoyuList() async {
  try {
    var respData = await HttpUtils.get(
      path: "$momoyuBase/hot/list",
      // 因为上拉下拉有加载圈，就不显示请求的加载了
      showLoading: false,
      queryParameters: {"type": 0},
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return MomoyuInfoResp.fromJson(
      respData,
      (items) => (items as List<dynamic>)
          .map((i) => MMYData.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}

// 知道分类编号查询
Future<MomoyuInfoResp<MMYIdData>> getMomoyuItem({
  int id = 1, // type为item时，需要指定类别
}) async {
  try {
    var respData = await HttpUtils.get(
      path: "$momoyuBase/hot/item",
      // 因为上拉下拉有加载圈，就不显示请求的加载了
      showLoading: false,
      queryParameters: {"id": id},
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    if (respData["status"] != 100000) {
      throw Exception("查询数据失败，请稍候重试");
    }

    return MomoyuInfoResp.fromJson(
      respData,
      (i) => MMYIdData.fromJson(i as Map<String, dynamic>),
    );
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}

// 当前在线人数
Future<MomoyuInfoResp<int>> getMomoyuUserCount() async {
  try {
    var respData = await HttpUtils.get(
      path: "$momoyuBase/user/count",
      showLoading: false,
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return MomoyuInfoResp.fromJson(
      respData,
      (i) => int.tryParse(i.toString()) ?? 0,
    );
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}




// 兼容所有，但取值时类型不明确，暂不用
// Future<MomoyuInfoResp> getMomoyuNews({
//   String type = "list", // list(所有) 或者 item(指定类别)
//   int reqType = 1, // type为list时，需要指定返回的结构类型(0或1)
//   int id = 1, // type为item时，需要指定类别
// }) async {
//   try {
//     var respData = await HttpUtils.get(
//       path: "$momoyuBase/hot/$type",
//       // 因为上拉下拉有加载圈，就不显示请求的加载了
//       showLoading: false,
//       queryParameters: type == "list" ? {"type": reqType} : {"id": id},
//     );

//     if (respData.runtimeType == String) {
//       respData = json.decode(respData);
//     }

//     return MomoyuInfoResp<Map<String, dynamic>>.fromJson(
//       respData,
//       (json) => json as Map<String, dynamic>,
//     );
//   } catch (e) {
//     // API请求报错，显示报错信息
//     rethrow;
//   }
// }
