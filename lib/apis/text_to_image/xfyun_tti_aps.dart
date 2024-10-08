import 'dart:convert';

import '../../common/constants.dart';
import '../../common/utils/dio_client/cus_http_client.dart';
import '../../common/utils/dio_client/cus_http_request.dart';
import '../../common/utils/dio_client/interceptor_error.dart';
import '../../models/text_to_image/xfyun_tti_req.dart';
import '../../models/text_to_image/xfyun_tti_resp.dart';
import '../gen_access_token/xfyun_signature.dart';
import '../get_app_key_helper.dart';
import '../platform_keys.dart';

var xfyunTtiUrl = "https://spark-api.cn-huabei-1.xf-yun.com/v2.1/tti";

/// 讯飞云文生图，传入尺寸(必须是123x123格式),图片提示语
Future<XfyunTtiResp> getXfyunTtiResp(
  String imageSize,
  String prompt,
) async {
  // 生成鉴权后的url
  var authUrl = genXfyunAssembleAuthUrl(
    xfyunTtiUrl,
    getStoredUserKey(SKN.xfyunApiKey.name, XUNFEI_API_KEY),
    getStoredUserKey(SKN.xfyunApiSecret.name, XUNFEI_API_SECRET),
    "POST",
  );

// 处理参数，构建请求体
  var tempSize = imageSize.split("x");
  var parameter = XfyunTtiReqParameter(
    chat: XfyunTtiReqChat(
      height: int.tryParse(tempSize[0]) ?? 512,
      width: int.tryParse(tempSize[1]) ?? 512,
    ),
  );
  var payload = XfyunTtiReqPayload(
    message: XfyunTtiReqMessage(
      // 固定角色，没有反向提示词
      text: [XfyunTtiReqText(role: CusRole.user.name, content: prompt)],
    ),
  );

  var req = XfyunTtiReq(
    header: XfyunTtiReqHeader(
      appId: getStoredUserKey(SKN.xfyunAppId.name, XUNFEI_APP_ID),
    ),
    parameter: parameter,
    payload: payload,
  );

  try {
    var respData = await HttpUtils.post(
      path: authUrl,
      method: CusHttpMethod.post,
      // 文生图有单独的遮罩，不用显示加载圈
      showLoading: false,
      headers: {
        "Content-Type": "application/json",
      },
      // 可能是因为头的content type设定，这里直接传类实例即可，传toJson也可
      data: req.toJson(),
    );

    /// 2024-06-06 注意，这里报错的时候，响应的是String，而正常获取回复响应是_Map<String, dynamic>
    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    // 响应是json格式
    return XfyunTtiResp.fromJson(respData);
  } on CusHttpException catch (e) {
    // 虽然返回的 CusHttpException 是自己定义的类型，但我有把原始保存内容存入其中的变量
    // 可以再转为json返回出来
    return XfyunTtiResp.fromJson(json.decode(e.errRespString));
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}
