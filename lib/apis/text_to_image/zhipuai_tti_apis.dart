import 'dart:convert';

import '../../common/utils/dio_client/cus_http_client.dart';
import '../../common/utils/dio_client/cus_http_request.dart';
import '../../models/text_to_image/zhipu_tti_req.dart';
import '../../models/text_to_image/zhipu_tti_resq.dart';
import '../get_app_key_helper.dart';
import '../platform_keys.dart';

///
/// 获取siliconFlow的文生图响应结果
///

// 获取文生图路径
String genCogViewTtiPath() =>
    "https://open.bigmodel.cn/api/paas/v4/images/generations";

///
/// 获取sf的文生图结果
///
Future<CogViewResp> getZhipuTtiResp(CogViewReq req) async {
  try {
    var respData = await HttpUtils.post(
      path: genCogViewTtiPath(),
      method: CusHttpMethod.post,
      // 文生图有单独的遮罩，不用显示加载圈
      showLoading: false,
      headers: {
        "Content-Type": "application/json",
        "Authorization":
            "Bearer ${getStoredUserKey(SKN.zhipuAK.name, ZHIPU_AK)}",
      },
      // 可能是因为头的content type设定，这里直接传类实例即可，传toJson也可
      data: req.toJson(),
    );

    /// 2024-06-06 注意，这里报错的时候，响应的是String，而正常获取回复响应是_Map<String, dynamic>
    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    // 响应是json格式
    return CogViewResp.fromJson(respData);
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}
