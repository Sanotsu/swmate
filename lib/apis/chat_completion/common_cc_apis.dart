// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:proste_logger/proste_logger.dart';

import '../../common/utils/tools.dart';
import '../../models/chat_competion/com_cc_req.dart';
import '../../models/chat_competion/com_cc_resp.dart';
import '../../common/llm_spec/cc_spec.dart';
import '../../common/utils/dio_client/cus_http_client.dart';
import '../../common/utils/dio_client/cus_http_request.dart';
import '../../common/utils/dio_client/interceptor_error.dart';
import '../_self_keys.dart';

final l = ProsteLogger();

enum PlatUrl {
  tencentCCUrl,
  aliyunCCUrl,
  baiduCCUrl,
  baiduCCAuthUrl,
  siliconFlowCCUrl,
  lingyiwanwuCCUrl,
}

const Map<PlatUrl, String> platUrls = {
  PlatUrl.tencentCCUrl: "https://hunyuan.tencentcloudapi.com/",
  PlatUrl.aliyunCCUrl:
      "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation",
  PlatUrl.baiduCCUrl:
      "https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat/",
  PlatUrl.baiduCCAuthUrl: "https://aip.baidubce.com/oauth/2.0/token",
  PlatUrl.siliconFlowCCUrl: "https://api.siliconflow.cn/v1/chat/completions",
  PlatUrl.lingyiwanwuCCUrl: "https://api.lingyiwanwu.com/v1/chat/completions",
};

///
///===========可以取消流的写法
///
class StreamWithCancel<T> {
  final Stream<T> stream;
  final Future<void> Function() cancel;

  StreamWithCancel(this.stream, this.cancel);
}

/// 获取流式和非流式的对话响应数据
Future<StreamWithCancel<ComCCResp>> getCCResponse(
  String url,
  Map<String, dynamic> headers,
  Map<String, dynamic> data, {
  bool stream = false,
}) async {
  try {
    var start = DateTime.now().millisecondsSinceEpoch;

    var respData = await HttpUtils.post(
      path: url,
      method: CusHttpMethod.post,
      responseType: stream ? CusRespType.stream : CusRespType.json,
      headers: headers,
      data: data,
    );

    var end = DateTime.now().millisecondsSinceEpoch;
    print("API响应耗时: ${(end - start) / 1000} 秒");
    print("-------------在转换前--------$respData)----------");

    if (stream) {
      // 处理流式响应
      if (respData is ResponseBody) {
        final streamController = StreamController<ComCCResp>();
        // 处理 text/event-stream 格式的流式数据时，确实可能会遇到一行数据过长而被截断的情况。
        // 为了处理这种情况，我们需要累积数据，直到我们得到一个完整的 JSON 对象。
        StringBuffer accumulatedData = StringBuffer();

        final subscription = respData.stream.transform(
          StreamTransformer.fromHandlers(
            handleData: (data, sink) {
              // try {
              // l.d(data.toString().length);

              final decodedData = utf8.decoder.convert(data);

              // 使用 StringBuffer 来累积数据，直到我们得到一个完整的行。
              accumulatedData.write(decodedData);

              final lines = accumulatedData.toString().split('\n');

              for (var line in lines) {
                // l.d(line);
                if (line.startsWith('data: ')) {
                  sink.add(line);
                }
              }
              // 清空 StringBuffer 中已经处理过的行
              accumulatedData.clear();
              accumulatedData.write(lines.last);
              // } catch (e) {
              //   print("解码错误: $e");
              //   sink.addError(e);
              // }
            },
          ),
        ).listen((data) async {
          // try {
          if ((data as String).contains('[DONE]')) {
            if (!streamController.isClosed) {
              streamController.add(ComCCResp(cusText: '[DONE]'));
              streamController.close();
            }
          } else {
            /// ???? 2024-08-10 几个问题
            ///  1 这里在流式取yi-larger-rag的quotes，内容很长，print和debugPrint无法完整打印
            ///     使用developer的log方法不会正确显示
            ///  2 打印data的长度来看，应该是完整sse消息，但是下面json转型时就会报错 FormatException: Unexpected end of input (at character 3619)
            ///     而且报错的位置看不出错误来。
            ///  3 推测此时处理的流式响应的data数据不完整，怎么应对不知道，暂时如果不是json就不转了
            var tempText = data.toString().substring(5);

            print("${tempText.length} ${data.toString().length}");
            l.d("${isJsonString(tempText)}--$data");

            if (isJsonString(tempText)) {
              final jsonData = json.decode(tempText);
              final commonRespBody = ComCCResp.fromJson(jsonData);
              if (!streamController.isClosed) {
                streamController.add(commonRespBody);
              }
            }
          }
          // } catch (e) {
          //   print("JSON解码错误: $e");
          //   if (!streamController.isClosed) {
          //     streamController.addError(e);
          //   }
          // }
        }, onDone: () {
          if (!streamController.isClosed) {
            streamController.add(ComCCResp(cusText: '[DONE]'));
            streamController.close();
          }
        }, onError: (error) {
          if (!streamController.isClosed) {
            streamController.addError(error);
            streamController.close();
          }
        });

        Future<void> cancel() async {
          print("执行了取消-----");
          // ？？？占位用的，先发送最后一个手动终止的信息，再实际取消(手动的更没有token信息了)
          if (!streamController.isClosed) {
            streamController.add(ComCCResp(cusText: '[手动终止]'));
          }
          await subscription.cancel();
          if (!streamController.isClosed) {
            streamController.close();
          }
        }

        return StreamWithCancel(streamController.stream, cancel);
      } else {
        throw HttpException(code: 500, msg: '不符合预期的数据流响应类型');
      }
    } else {
      if (respData.runtimeType == String) {
        respData = json.decode(respData);
      }
      return StreamWithCancel(
        Stream.value(ComCCResp.fromJson(respData)),
        () async {},
      );
    }
  } on HttpException catch (e) {
    return StreamWithCancel(
      Stream.value(ComCCResp(
        cusText: "【HttpException】${e.toString()}",
      )),
      () async {},
    );
  } catch (e) {
    rethrow;
  }
}

/// 2024-08-09 BAT 的请求参数和响应有很多不同，下面是没有处理的
// /// 腾讯的请求方法
// Future<StreamWithCancel<ComCCResp>> tencentCCRespWitchCancel(
//   List<CCMessage> messages, {
//   String? model,
//   bool stream = false,
// }) async {
//   model = model ?? CCM_SPEC_MAP[CCM.tencent_Hunyuan_Lite]!.model;
//   var body = ComCCReq(model: model, messages: messages, stream: stream);
//   var headers = genHunyuanLiteSignatureHeaders(
//     commonReqBodyToJson(body, caseType: "pascal"),
//     TENCENT_SECRET_ID,
//     TENCENT_SECRET_KEY,
//   );
//   return getCCResponse(
//     platUrls[PlatUrl.tencentCCUrl]!,
//     headers,
//     body.toJson(caseType: "pascal"),
//     stream: stream,
//   );
// }

// /// 阿里的请求方法
// Future<StreamWithCancel<ComCCResp>> aliyunCCRespWithCancel(
//   List<CCMessage> messages, {
//   String? model,
//   bool stream = false,
// }) async {
//   model = model ?? CCM_SPEC_MAP[CCM.aliyun_Qwen_1p8B_Chat]!.model;
//   var body = ComCCReq(
//     model: model,
//     input: AliyunInput(messages: messages),
//     parameters: stream
//         ? AliyunParameters(resultFormat: "message", incrementalOutput: true)
//         : AliyunParameters(resultFormat: "message"),
//   );
//   var headers = {
//     "Content-Type": "application/json",
//     "Authorization": "Bearer $ALIYUN_API_KEY",
//   };
//   if (stream) {
//     headers.addAll({"X-DashScope-SSE": "enable"});
//   }
//   return getCCResponse(
//     platUrls[PlatUrl.aliyunCCUrl]!,
//     headers,
//     body.toJson(),
//     stream: stream,
//   );
// }

// Future<StreamWithCancel<ComCCResp>> baiduCCRespWithCancel(
//   List<CCMessage> messages, {
//   String? model,
//   bool stream = false,
//   String? system,
// }) async {
//   model = model ?? CCM_SPEC_MAP[CCM.baidu_Ernie_Speed_128K]!.model;
//   String token = await getAccessToken();
//   var body = system != null
//       ? ComCCReq(messages: messages, stream: stream, system: system)
//       : ComCCReq(messages: messages, stream: stream);
//   var headers = {"Content-Type": "application/json"};
//   return getCCResponse(
//     "${platUrls[PlatUrl.baiduCCUrl]!}$model?access_token=$token",
//     headers,
//     body.toJson(),
//     stream: stream,
//   );
// }

/// siliconFlow 的请求方法
Future<StreamWithCancel<ComCCResp>> siliconFlowCCRespWithCancel(
  List<CCMessage> messages, {
  String? model,
  bool stream = false,
}) async {
  model = model ??
      CCM_SPEC_LIST
          .firstWhere((e) => e.ccm == CCM.siliconCloud_Qwen2_7B_Instruct)
          .model;

  var body = ComCCReq(model: model, messages: messages, stream: stream);
  var headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer $SILICON_CLOUD_AK",
  };
  return getCCResponse(
    platUrls[PlatUrl.siliconFlowCCUrl]!,
    headers,
    body.toJson(),
    stream: stream,
  );
}

/// 流式和同步通用
Future<StreamWithCancel<ComCCResp>> lingyiwanwuCCRespWithCancel(
  List<CCMessage> messages, {
  String? model,
  bool stream = false,
}) async {
  model = model ?? CCM_SPEC_LIST.firstWhere((e) => e.ccm == CCM.YiSpark).model;

  var body = model == "yi-vision"
      ? ComCCReq.yiVision(model: model, messages: messages, stream: stream)
      : ComCCReq(model: model, messages: messages, stream: stream);

  // var temp = body.toJson();

  // Map<String, dynamic> tb = {
  //   "model": "yi-vision",
  //   "messages": "${temp['messages']}",
  //   "stream": true,
  //   "max_tokens": 1024
  // };

  var header = {
    "Content-Type": "application/json",
    "Authorization": "Bearer $LINGYI_AK",
  };

  return getCCResponse(
    platUrls[PlatUrl.lingyiwanwuCCUrl]!,
    header,
    body.toJson(),
    // tb,
    stream: stream,
  );
}
