import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:proste_logger/proste_logger.dart';

import '../../common/llm_spec/cus_brief_llm_model.dart';
import '../../models/brief_ai_tools/chat_competion/com_cc_req.dart';
import '../../models/brief_ai_tools/chat_competion/com_cc_resp.dart';
import '../../common/llm_spec/constant_llm_enum.dart';
import '../../common/utils/dio_client/cus_http_client.dart';
import '../../common/utils/dio_client/cus_http_request.dart';
import '../../common/utils/dio_client/interceptor_error.dart';
import '../../services/chat_service.dart';
import 'chat_helper.dart';

final l = ProsteLogger();

///
///-----------------------------------------------------------------------------
/// 通用的对话请求方法

/// siliconFlow 的请求方法
Future<StreamWithCancel<ComCCResp>> getCCRespWithCancel(
  List<CCMessage> messages,
  CusBriefLLMSpec llmSpec, {
  bool stream = false,
  bool? webSearch = true,
}) async {
  var body = llmSpec.platform == ApiPlatform.zhipu
      ? ComCCReq.glm(
          model: llmSpec.model,
          messages: messages,
          stream: stream,
          // 翻译的时候联网反而可能会出事，所以加一个可以控制联网的参数
          tools: webSearch == true
              ? [
                  CCTool(
                    "web_search",
                    webSearch: CCWebSearch(enable: true, searchResult: true),
                  )
                ]
              : null,
        )
      : ComCCReq(model: llmSpec.model, messages: messages, stream: stream);

  var headers = await ChatService.getHeaders(llmSpec);
  return getSseCcResponse(
    "${ChatService.getBaseUrl(llmSpec.platform)}/chat/completions",
    headers,
    body.toJson(),
    stream: stream,
  );
}

///
/// 这个是通用的对话请求方法，不处理流式响应的
/// 比如用于小量文本的翻译等
///
Future<ComCCResp> getCCResp(
  List<CCMessage> messages,
  CusBriefLLMSpec llmSpec, {
  bool? webSearch = true,
}) async {
  var body = llmSpec.platform == ApiPlatform.zhipu
      ? ComCCReq.glm(
          model: llmSpec.model,
          messages: messages,
          // 翻译的时候联网反而可能会出事，所以加一个可以控制联网的参数
          tools: webSearch == true
              ? [
                  CCTool(
                    "web_search",
                    webSearch: CCWebSearch(enable: true, searchResult: true),
                  )
                ]
              : null,
        )
      : ComCCReq(model: llmSpec.model, messages: messages);

  var headers = await ChatService.getHeaders(llmSpec);

  try {
    var respData = await HttpUtils.post(
      path: "${ChatService.getBaseUrl(llmSpec.platform)}/chat/completions",
      method: CusHttpMethod.post,
      responseType: CusRespType.json,
      headers: headers,
      data: body.toJson(),
    );

    if (respData.runtimeType == String) respData = json.decode(respData);

    return ComCCResp.fromJson(respData);
  } on CusHttpException catch (e) {
    return ComCCResp(
      cusText: """HTTP请求响应异常:
\n\n错误代码: ${e.cusCode}
\n\n错误信息: ${e.cusMsg}
\n\n\n\n原始信息: ${e.errRespString}""",
    );
  } catch (e) {
    rethrow;
  }
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

/// 获取流式和非流式的对话响应数据
Future<StreamWithCancel<ComCCResp>> getSseCcResponse(
  String url,
  Map<String, dynamic> headers,
  Map<String, dynamic> data, {
  bool stream = false,
}) async {
  try {
    var respData = await HttpUtils.post(
      path: url,
      method: CusHttpMethod.post,
      responseType: stream ? CusRespType.stream : CusRespType.json,
      headers: headers,
      data: data,
    );

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
          //   "【Event】 ${event.id}, ${event.event}, ${event.retry}, ${event.data}",
          // );

          // 如果流式响应其实在报错，则要单独
          // 腾讯的响应，报错的时候不是正常流格式，是一个含Response栏位的json字符串,
          // 得取出来才和其他结构类似
          if ((event.data).contains('"Response":{"Error"')) {
            if (!streamController.isClosed) {
              streamController.add(
                ComCCResp.fromJson(jsonDecode(event.data)["Response"]),
              );
              streamController.close();
            }
          } else {
            // 正常的分段数据
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
        throw CusHttpException(cusCode: 500, cusMsg: '不符合预期的数据流响应类型');
      }
    } else {
      if (respData.runtimeType == String) {
        respData = json.decode(respData);
      }

      // 2024-08-17 腾讯的响应，在最外面还多一个Response栏位,得取出来才和其他结构类似
      if (respData["Response"] != null) {
        respData = respData["Response"];
      }

      return StreamWithCancel(
        Stream.value(ComCCResp.fromJson(respData)),
        () async {},
      );
    }
  } on CusHttpException catch (e) {
    // 报错时也要流式返回，并手动添加一条结束标志
    final streamController = StreamController<ComCCResp>();
    streamController.add(
      ComCCResp(
        cusText: """HTTP请求响应异常:\n\n错误代码: ${e.cusCode}
            \n\n错误信息: ${e.cusMsg}
            \n\n错误原文: ${e.errMessage}
            \n\n原始信息: ${e.errRespString}
            \n\n""",
      ),
    );
    streamController.add(ComCCResp(cusText: '[DONE]-后台响应错误'));
    streamController.close();

    return StreamWithCancel(streamController.stream, () async {});
  } catch (e) {
    rethrow;
  }
}
