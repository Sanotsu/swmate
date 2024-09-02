// ignore_for_file: avoid_print

import 'dart:convert';

import '../../common/utils/dio_client/cus_http_client.dart';
import '../../common/utils/dio_client/cus_http_request.dart';
import '../../models/text_to_video/cogvideox_req.dart';
import '../../models/text_to_video/cogvideox_resp.dart';
import '../_self_keys.dart';
import '../get_app_key_helper.dart';

///
/// 处理智谱AI的文生视频数据
///

// 提交任务 url
String zhipuCogVideoXCommitTaskUrl =
    "https://open.bigmodel.cn/api/paas/v4/videos/generations";

// 查询任务 url
String zhipuCogVideoXGetResultUrl(String id) =>
    "https://open.bigmodel.cn/api/paas/v4/async-result/$id";

///
/// 提交任务
///
Future<CogVideoXResp> commitZhipuCogVideoXTask(CogVideoXReq req) async {
  try {
    var start = DateTime.now().millisecondsSinceEpoch;
    var respData = await HttpUtils.post(
      path: zhipuCogVideoXCommitTaskUrl,
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

    var end = DateTime.now().millisecondsSinceEpoch;
    print("getZhipuTtiResp 响应耗时: ${(end - start) / 1000} 秒");
    print("getZhipuTtiResp 返回的结果：${respData.runtimeType} $respData");

    // lr.e(respData);

    /// 2024-06-06 注意，这里报错的时候，响应的是String，而正常获取回复响应是_Map<String, dynamic>
    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    // 响应是json格式
    return CogVideoXResp.fromJson(respData);
  } catch (e) {
    print("CogVideoXResp ERROR ${e.runtimeType}---$e");
    // API请求报错，显示报错信息
    rethrow;
  }
}

///
/// 查询任务
///
Future<CogVideoXResp> getZhipuCogVideoXResult(String taskId) async {
  try {
    var start = DateTime.now().millisecondsSinceEpoch;

    var respData = await HttpUtils.get(
      path: zhipuCogVideoXGetResultUrl(taskId),
      // 文生图有单独的遮罩，不用显示加载圈
      showLoading: false,
      headers: {
        "Content-Type": "application/json",
        "Authorization":
            "Bearer ${getStoredUserKey(SKN.zhipuAK.name, ZHIPU_AK)}",
      },
    );

    print("getZhipuCogVideoXResult---------------------$respData");

    var end = DateTime.now().millisecondsSinceEpoch;

    print("getZhipuCogVideoXResult 耗时 ${(end - start) / 1000} 秒");

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    // 响应是json格式
    return CogVideoXResp.fromJson(respData ?? {});
  } catch (e) {
    print("getZhipuCogVideoXResult Error ${e.runtimeType}---$e");
    // API请求报错，显示报错信息
    rethrow;
  }
}
