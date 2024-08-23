// ignore_for_file: avoid_print

import 'dart:convert';

import '../../common/utils/dio_client/cus_http_client.dart';
import '../../common/utils/dio_client/cus_http_request.dart';
import '../../common/utils/dio_client/interceptor_error.dart';
import '../../models/image_to_image/silicon_flow_iti_req.dart';
import '../../models/text_to_image/silicon_flow_ig_resp.dart';
import '../_self_keys.dart';

///
/// 获取siliconFlow的图生图响应结果
/// 图生图和文生图的结果结构是一样的
///

// 获取图生图路径
String genSfItiPath(String model) =>
    "https://api.siliconflow.cn/v1/$model/image-to-image";

///
/// 获取sf的图生图结果
///
Future<SiliconFlowIGResp> getSFImageToImageResp(SiliconflowItiReq req, String model) async {
  try {
    var start = DateTime.now().millisecondsSinceEpoch;
    var respData = await HttpUtils.post(
      path: genSfItiPath(model),
      method: CusHttpMethod.post,
      // 图生图有单独的遮罩，不用显示加载圈
      showLoading: false,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $SILICON_CLOUD_AK",
      },
      // 可能是因为头的content type设定，这里直接传类实例即可，传toJson也可
      data: req.toJson(),
    );

    var end = DateTime.now().millisecondsSinceEpoch;
    print("getSFTtiResp 响应耗时: ${(end - start) / 1000} 秒");
    print("getSFTtiResp 返回的结果：${respData.runtimeType} $respData");

    // lr.e(respData);

    /// 2024-06-06 注意，这里报错的时候，响应的是String，而正常获取回复响应是_Map<String, dynamic>
    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    // 响应是json格式
    return SiliconFlowIGResp.fromJson(respData);
  } on CusHttpException catch (e) {
    // 虽然返回的 CusHttpException 是自己定义的类型，但我有把原始保存内容存入其中的变量
    // 可以再转为json返回出来
    return SiliconFlowIGResp.fromJson(json.decode(e.responseString));
  } catch (e) {
    print("gggggggggggggggggggggggggg ${e.runtimeType}---$e");
    // API请求报错，显示报错信息
    rethrow;
  }
}
