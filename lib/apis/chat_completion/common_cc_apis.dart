// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:proste_logger/proste_logger.dart';

import '../../common/utils/tools.dart';
import '../../models/chat_competion/com_cc_req.dart';
import '../../models/chat_competion/com_cc_resp.dart';
import '../../common/llm_spec/cc_spec.dart';
import '../../common/utils/dio_client/cus_http_client.dart';
import '../../common/utils/dio_client/cus_http_request.dart';
import '../../common/utils/dio_client/interceptor_error.dart';
import '../../services/cus_get_storage.dart';
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
/// dio 中处理SSE的解析器
/// 来源: https://github.com/cfug/dio/issues/1279#issuecomment-1326121953
///
class SseTransformer extends StreamTransformerBase<String, SseMessage> {
  const SseTransformer();
  @override
  Stream<SseMessage> bind(Stream<String> stream) {
    return Stream.eventTransformed(stream, (sink) => SseEventSink(sink));
  }
}

class SseEventSink implements EventSink<String> {
  final EventSink<SseMessage> _eventSink;

  String? _id;
  String _event = "message";
  String _data = "";
  int? _retry;

  SseEventSink(this._eventSink);

  @override
  void add(String event) {
    if (event.startsWith("id:")) {
      _id = event.substring(3);
      return;
    }
    if (event.startsWith("event:")) {
      _event = event.substring(6);
      return;
    }
    if (event.startsWith("data:")) {
      _data = event.substring(5);
      return;
    }
    if (event.startsWith("retry:")) {
      _retry = int.tryParse(event.substring(6));
      return;
    }
    if (event.isEmpty) {
      _eventSink.add(
        SseMessage(id: _id, event: _event, data: _data, retry: _retry),
      );
      _id = null;
      _event = "message";
      _data = "";
      _retry = null;
    }

    // 自己加的，请求报错时不是一个正常的流的结构，是个json,直接添加即可
    if (isJsonString(event)) {
      _eventSink.add(
        SseMessage(id: _id, event: _event, data: event, retry: _retry),
      );

      _id = null;
      _event = "message";
      _data = "";
      _retry = null;
    }
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _eventSink.addError(error, stackTrace);
  }

  @override
  void close() {
    _eventSink.close();
  }
}

class SseMessage {
  final String? id;
  final String event;
  final String data;
  final int? retry;

  const SseMessage({
    this.id,
    required this.event,
    required this.data,
    this.retry,
  });
}

///
///===========可以取消流的写法
///
class StreamWithCancel<T> {
  final Stream<T> stream;
  final Future<void> Function() cancel;

  StreamWithCancel(this.stream, this.cancel);

  static StreamWithCancel<T> empty<T>() {
    return StreamWithCancel<T>(const Stream.empty(), () async {});
  }
}

var lineRegex = RegExp(r'^([^:]*)(?::)?(?: )?(.*)?$');

/// 获取流式和非流式的对话响应数据
Future<StreamWithCancel<ComCCResp>> getSseCcResponse(
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

        StreamTransformer<Uint8List, List<int>> unit8Transformer =
            StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            sink.add(List<int>.from(data));
          },
        );

        final subscription = respData.stream
            // 创建一个自定义的 StreamTransformer 来处理 Uint8List 到 String 的转换。
            .transform(unit8Transformer)
            .transform(const Utf8Decoder())
            // 将输入的 Stream<String> 按照行（即换行符 \n 或 \r\n）进行分割，并将每一行作为一个单独的事件发送到输出流中。
            .transform(const LineSplitter())
            .transform(const SseTransformer())
            // 处理每一行数据
            .listen((event) async {
          // print(
          //   "Event: ${event.id}, ${event.event}, ${event.retry}, ${event.data}",
          // );

          // 如果包含DONE，是正常获取AI接口的结束
          if ((event.data).contains('[DONE]')) {
            if (!streamController.isClosed) {
              streamController.add(ComCCResp(cusText: '[DONE]'));
              streamController.close();
            }
          } else {
            final jsonData = json.decode(event.data);
            final commonRespBody = ComCCResp.fromJson(jsonData);
            if (!streamController.isClosed) {
              streamController.add(commonRespBody);
            }
          }
        }, onDone: () {
          // 流处理完手动补一个结束子串
          if (!streamController.isClosed) {
            streamController.add(ComCCResp(cusText: '[DONE]-onDone'));
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
    // 报错时也要流式返回，并手动添加一条结束标志
    final streamController = StreamController<ComCCResp>();
    streamController.add(
      ComCCResp(cusText: "HTTP请求响应异常:\n\n错误代码: ${e.code}\n\n错误信息: ${e.msg}"),
    );
    streamController.add(ComCCResp(cusText: '[DONE]-后台响应错误'));
    streamController.close();

    return StreamWithCancel(streamController.stream, () async {});
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

///
///-----------------------------------------------------------------------------
/// 百度的请求方法
///
/// 使用 AK，SK 生成鉴权签名（Access Token）
/// token 有效期是30天
Future<String> getAccessToken() async {
  // 这个获取的token的结果是一个_Map<String, dynamic>，不用转json直接取就得到Access Token了

  try {
    var respData = await HttpUtils.post(
      path: platUrls[PlatUrl.baiduCCAuthUrl]!,
      method: CusHttpMethod.post,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      data: {
        "grant_type": "client_credentials",
        "client_id": BAIDU_API_KEY,
        "client_secret": BAIDU_SECRET_KEY,
      },
    );

    // 计算今天往后的 14 天(官方过期是30甜)
    DateTime expiredDate = DateTime.now().add(const Duration(days: 14));

    // 保存token信息到缓存
    await MyGetStorage().setBaiduTokenInfo({
      "accessToken": respData['access_token'].toString(),
      "expiredDate": expiredDate.toIso8601String(),
    });

    // 响应是json格式
    return respData['access_token'];
  } catch (e) {
    rethrow;
  }
}

Future<StreamWithCancel<ComCCResp>> baiduCCRespWithCancel(
  List<CCMessage> messages, {
  String? model,
  bool stream = false,
  String? system,
}) async {
  model = model ??
      CCM_SPEC_LIST.firstWhere((e) => e.ccm == CCM.baidu_Ernie_Tiny_8K).model;

  // 获取token信息
  var tokenInfo = MyGetStorage().getBaiduTokenInfo();
  String token = "";
  if (tokenInfo["accessToken"] != null &&
      tokenInfo["expiredDate"] != null &&
      DateTime.now().isBefore(DateTime.parse(tokenInfo["expiredDate"]!))) {
    token = tokenInfo["accessToken"]!;
  } else {
    token = await getAccessToken();
  }

  var body = ComCCReq.baidu(messages: messages, stream: stream);

  var headers = {"Content-Type": "application/json"};

  return getSseCcResponse(
    "${platUrls[PlatUrl.baiduCCUrl]!}$model?access_token=$token",
    headers,
    body.toJson(),
    stream: stream,
  );
}

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
  return getSseCcResponse(
    platUrls[PlatUrl.siliconFlowCCUrl]!,
    headers,
    body.toFullJson(),
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

  var body = ComCCReq(model: model, messages: messages, stream: stream);

  var header = {
    "Content-Type": "application/json",
    "Authorization": "Bearer $LINGYI_AK",
  };

  return getSseCcResponse(
    platUrls[PlatUrl.lingyiwanwuCCUrl]!,
    header,
    body.toJson(),
    stream: stream,
  );
}
