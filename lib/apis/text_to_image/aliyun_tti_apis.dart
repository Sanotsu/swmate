import 'dart:convert';

import '../../common/utils/dio_client/cus_http_client.dart';
import '../../common/utils/dio_client/cus_http_request.dart';
import '../../models/text_to_image/aliyun_tti_req.dart';
import '../../models/text_to_image/aliyun_tti_resp.dart';
import '../get_app_key_helper.dart';
import '../platform_keys.dart';

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

  try {
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

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return AliyunTtiResp.fromJson(respData ?? {});
  } catch (e) {
    rethrow;
  }
}

///
/// 作业任务状态查询和结果获取接口
/// GET https://dashscope.aliyuncs.com/api/v1/tasks/{task_id}
///
Future<AliyunTtiResp> getAliyunText2ImgJobResult(String taskId) async {
  try {
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

    ///？？？ 2024-06-11 阿里云请求报错，会进入dio的错误拦截器，这里ret就是个null了
    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    // 响应是json格式
    return AliyunTtiResp.fromJson(respData ?? {});
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}
