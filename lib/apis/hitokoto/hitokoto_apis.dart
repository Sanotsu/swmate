import 'dart:convert';

import '../../common/utils/dio_client/cus_http_client.dart';
import '../../models/hitokoto/hitokoto.dart';

var hitoBase = "https://v1.hitokoto.cn";

Future<Hitokoto> getHitokoto({
  // 类型：a动画；b漫画；c游戏；d文学；e原创；f来自网络；g其他；h影视；i诗词；j网易云；k哲学；l抖机灵；其他作为 动画 类型处理
  String? cate,
}) async {
  try {
    var respData = await HttpUtils.get(
      // 这里不传就随机一个类型
      path: "$hitoBase?c=${cate ?? ''}",
      // 因为上拉下拉有加载圈，就不显示请求的加载了
      showLoading: false,
      // 因为存在404找不到单词也保存，但单独处理了，就不在http拦截器中报错了
      showErrorMessage: false,
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return Hitokoto.fromJson(respData);
  } catch (e) {
    rethrow;
  }
}
