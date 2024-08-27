// ignore_for_file: avoid_print

import 'dart:convert';

import '../../common/utils/dio_client/cus_http_client.dart';
import '../../common/utils/dio_client/cus_http_request.dart';
import '../../models/text_to_image/aliyun_tti_req.dart';
import '../../models/text_to_image/aliyun_tti_resp.dart';
import '../_self_keys.dart';
import '../get_app_key_helper.dart';

///
/// 文生图任务提交
///
var aliyunText2imageUrl =
    "https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis";

/// 文生图任务提交
Future<AliyunTtiResp> commitAliyunText2ImgJob(
  String model,
  AliyunTtiInput input,
  AliyunTtiParameter parameters,
) async {
  return commitAliyunJob(
    aliyunText2imageUrl,
    model,
    input,
    parameters,
  );
}

/// 锦书的路径不一样

var wordartUrl = "https://dashscope.aliyuncs.com/api/v1/services/aigc/wordart/";

/// 文字纹理 https://dashscope.aliyuncs.com/api/v1/services/aigc/wordart/texture
/// 文字变形 https://dashscope.aliyuncs.com/api/v1/services/aigc/wordart/semantic
/// 百家姓字 https://dashscope.aliyuncs.com/api/v1/services/aigc/wordart/surnames
Future<AliyunTtiResp> commitAliyunWordartJob(
  String model,
  AliyunTtiInput input,
  AliyunTtiParameter parameters, {
  String type = "texture",
}) async {
  if (!['texture', "semantic", "surnames"].contains(type.toLowerCase())) {
    type = "texture";
  }

  return commitAliyunJob(
    "$wordartUrl$type",
    model,
    input,
    parameters,
  );
}

///
/// 文生图任务提交
///
Future<AliyunTtiResp> commitAliyunJob(
  String url,
  String model,
  AliyunTtiInput input,
  AliyunTtiParameter parameters, {
  String type = "texture",
}) async {
  var body = AliyunTtiReq(
    model: model,
    input: input,
    parameters: parameters,
  );

  print("阿里云生图参数${body.toRawJson()}");

  try {
    var start = DateTime.now().millisecondsSinceEpoch;

    var respData = await HttpUtils.post(
      path: url,
      method: CusHttpMethod.post,
      showLoading: false,
      headers: {
        "X-DashScope-Async": "enable",
        "Content-Type": "application/json",
        "Authorization":
            "Bearer ${getStoredUserKey(SKN.aliyunApiKey.name, ALIYUN_API_KEY)}",
      },
      data: body.toJson(),
    );

    print("阿里云文生图---------------------$respData");

    var end = DateTime.now().millisecondsSinceEpoch;

    print("2222222222xxxxxxxxxxxxxxxxx${(end - start) / 1000} 秒");

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return AliyunTtiResp.fromJson(respData ?? {});
  } catch (e) {
    print("bbbbbbbbbbbbbbbb ${e.runtimeType}---$e");
    rethrow;
  }
}

///
/// 作业任务状态查询和结果获取接口
/// GET https://dashscope.aliyuncs.com/api/v1/tasks/{task_id}
///
Future<AliyunTtiResp> getAliyunText2ImgJobResult(String taskId) async {
  try {
    var start = DateTime.now().millisecondsSinceEpoch;

    var respData = await HttpUtils.post(
      path: "https://dashscope.aliyuncs.com/api/v1/tasks/$taskId",
      method: CusHttpMethod.get,
      // 文生图有单独的遮罩，不用显示加载圈
      showLoading: false,
      headers: {
        "Authorization":
            "Bearer ${getStoredUserKey(SKN.aliyunApiKey.name, ALIYUN_API_KEY)}",
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
    return AliyunTtiResp.fromJson(respData ?? {});
  } catch (e) {
    print("aaaaaas ${e.runtimeType}---$e");
    // API请求报错，显示报错信息
    rethrow;
  }
}
