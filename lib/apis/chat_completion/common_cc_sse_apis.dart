// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:proste_logger/proste_logger.dart';

import '../../models/chat_competion/com_cc_req.dart';
import '../../models/chat_competion/com_cc_resp.dart';
import '../../common/llm_spec/cc_spec.dart';

import '../_self_keys.dart';
import 'common_cc_apis.dart';

final l = ProsteLogger();

/// 流式和同步通用
/// 2024-08-11 用这个库有问题；第二次第三次调用就会
/// Bad state: Stream has already been listened to.
///
Future<StreamWithCancel<ComCCResp>> lingyiSseCCResp(
  List<CCMessage> messages, {
  String? model,
  bool stream = false,
}) async {
  model = model ?? CCM_SPEC_LIST.firstWhere((e) => e.ccm == CCM.YiSpark).model;

  var body = ComCCReq(model: model, messages: messages, stream: stream);

  Map<String, String> header = {
    "Content-Type": "application/json",
    "Authorization": "Bearer $LINGYI_AK",
    // "Accept": "text/event-stream",
    // "Cache-Control": "no-cache",
  };

  try {
    var start = DateTime.now().millisecondsSinceEpoch;

    final streamController = StreamController<ComCCResp>();

    final sseStream = SSEClient.subscribeToSSE(
      method: SSERequestType.POST,
      url: platUrls[PlatUrl.lingyiwanwuCCUrl]!,
      header: header,
      body: body.toJson(),
    );

    final subscription = sseStream.listen(
      (event) {
        var tempText = event.data!.toString();

        if ((tempText).contains('[DONE]')) {
          if (!streamController.isClosed) {
            streamController.add(ComCCResp(cusText: '[DONE]'));
          }
        } else {
          l.d(tempText);
          final jsonData = json.decode(tempText);

          final commonRespBody = ComCCResp.fromJson(jsonData);

          // ??? 明明进来这里了，为什么转型后的quote为空呢
          if ((tempText).contains('quote')) {
            l.e(jsonData);
            print("xxxxxxxxx${commonRespBody.id}");
            print("xxxxxxxxx${commonRespBody.created}");
            print("xxxxxxxxx${commonRespBody.cusText}");
            print("xxxxxxxxx${jsonData['choices']}");
            print("xxxxxxxxx${commonRespBody.choices?.first.delta}");
          }
          if (!streamController.isClosed) {
            streamController.add(commonRespBody);
          }
        }
      },
      onDone: () {
        if (!streamController.isClosed) {
          streamController.add(ComCCResp(cusText: '[DONE]'));
          streamController.close();
        }
      },
      onError: (error) {
        if (!streamController.isClosed) {
          streamController.addError(error);
          streamController.close();
        }
      },
    );

    var end = DateTime.now().millisecondsSinceEpoch;
    print("API响应耗时: ${(end - start) / 1000} 秒");

    Future<void> cancel() async {
      print("执行了取消-----");
      // ？？？占位用的，先发送最后一个手动终止的信息，再实际取消(手动的没有token信息了)
      if (!streamController.isClosed) {
        streamController.add(ComCCResp(cusText: '[手动终止]'));
      }

      await subscription.cancel();

      if (!streamController.isClosed) {
        streamController.close();
      }
    }

    return StreamWithCancel(streamController.stream, cancel);
  } catch (e) {
    rethrow;
  }
}
