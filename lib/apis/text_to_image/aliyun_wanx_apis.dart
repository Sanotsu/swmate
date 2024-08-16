// ignore_for_file: avoid_print

import 'dart:convert';

import '../../common/utils/dio_client/cus_http_client.dart';
import '../../common/utils/dio_client/cus_http_request.dart';
import '../../models/text_to_image/aliyun_wanx_req.dart';
import '../../models/text_to_image/aliyun_wanx_resp.dart';
import '../_self_keys.dart';

///
/// 文生图任务提交
///
var aliyunText2imageUrl =
    "https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis";

Future<AliyunWanxResp> commitAliyunText2ImgJob(
  WanxInput input,
  WanxParameter parameters,
) async {
  var body = AliyunWanxReq(
    model: "wanx-v1",
    input: input,
    parameters: parameters,
  );

  try {
    var start = DateTime.now().millisecondsSinceEpoch;

    var respData = await HttpUtils.post(
      path: aliyunText2imageUrl,
      method: CusHttpMethod.post,
      // 文生图有单独的遮罩，不用显示加载圈
      showLoading: false,
      headers: {
        "X-DashScope-Async": "enable", // 固定的，异步方式提交作业。
        "Content-Type": "application/json",
        "Authorization": "Bearer $ALIYUN_API_KEY",
      },
      // 可能是因为头的content type设定，这里直接传类实例即可，传toJson也可
      data: body,
    );

    print("阿里云文生图---------------------$respData");

    var end = DateTime.now().millisecondsSinceEpoch;

    print("2222222222xxxxxxxxxxxxxxxxx${(end - start) / 1000} 秒");

    ///？？？ 2024-06-11 阿里云请求报错，会进入dio的错误拦截器，这里ret就是个null了
    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    // 响应是json格式
    return AliyunWanxResp.fromJson(respData ?? {});
  } catch (e) {
    print("bbbbbbbbbbbbbbbb ${e.runtimeType}---$e");
    rethrow;
  }
}

///
/// 作业任务状态查询和结果获取接口
/// GET https://dashscope.aliyuncs.com/api/v1/tasks/{task_id}
///
Future<AliyunWanxResp> getAliyunText2ImgJobResult(String taskId) async {
  try {
    var start = DateTime.now().millisecondsSinceEpoch;

    var respData = await HttpUtils.post(
      path: "https://dashscope.aliyuncs.com/api/v1/tasks/$taskId",
      method: CusHttpMethod.get,
      headers: {
        "Authorization": "Bearer $ALIYUN_API_KEY",
      },
    );

    print("阿里云文生图结果查询---------------------$respData");

    var end = DateTime.now().millisecondsSinceEpoch;

    print("333333xxxxxxxxxxxxxxxxx${(end - start) / 1000} 秒");

    ///？？？ 2024-06-11 阿里云请求报错，会进入dio的错误拦截器，这里ret就是个null了
    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    // 响应是json格式
    return AliyunWanxResp.fromJson(respData ?? {});
  } catch (e) {
    print("aaaaaas ${e.runtimeType}---$e");
    // API请求报错，显示报错信息
    rethrow;
  }
}
