import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:dio/dio.dart';
import '../../common/constants.dart';
import '../../common/utils/dio_client/cus_http_client.dart';
import '../../common/utils/dio_client/cus_http_request.dart';
import '../../common/utils/dio_client/interceptor_error.dart';
import '../../models/chat_completions/chat_completion_response.dart';

/// 处理兼容 OpenAI 规范的响应
Future<(Stream<ChatCompletionResponse>, VoidCallback)> getStreamResponse(
  String url,
  Map<String, String> headers,
  Map<String, dynamic> requestBody, {
  bool stream = true,
}) async {
  final streamController = StreamController<ChatCompletionResponse>();

  try {
    final response = await HttpUtils.post(
      path: url,
      method: CusHttpMethod.post,
      headers: headers,
      data: requestBody,
      responseType: stream ? CusRespType.stream : CusRespType.json,
      showLoading: false,
      showErrorMessage: false,
    );

    if (stream) {
      // 处理 ResponseBody
      final responseBody = response as ResponseBody;
      // 2025-02-17 ??? 这里流式接收的数据，可能会不完整？？？导致确实内容？
      final subscription = responseBody.stream.listen(
        (data) async {
          // 注意，这个流式接收可能不是一行一块，可能有时候会收到多行数据
          // 换行后过滤空行
          String text = utf8.decode(data);
          final lines = text.split('\n');

          for (var line in lines) {
            if (line.startsWith('data: ')) {
              String jsonStr = line.substring(6);

              // 检查是否是结束标记
              if (jsonStr.trim() == '[DONE]') {
                // 正常的结束标记就关闭流
                if (!streamController.isClosed) {
                  streamController.close();
                }
                continue;
              }

              // 正常的分段数据
              try {
                final jsonData = json.decode(jsonStr);

                // print('jsonData--流式响应数据: $jsonData');
                // 2025-02-17 ??? 流式处理太快导致显示不完整，加上上面的打印大概率可以显示，所有增加延迟？？？
                // await Future.delayed(Duration(milliseconds: 50));

                final response = ChatCompletionResponse.fromJson(jsonData);
                if (!streamController.isClosed) {
                  streamController.add(response);
                }
              } catch (e) {
                print('解析响应数据出错: $e');
                // 流式响应出错时，继续处理下一行
                continue;
              }
            }
          }
        },
        // 流式响应出错时，添加错误响应
        onError: (error) {
          if (!streamController.isClosed) {
            streamController.addError(error);
            streamController.close();
          }
        },
        // 正常流式响应结束时，也直接关闭
        onDone: () {
          if (!streamController.isClosed) {
            streamController.close();
          }
        },
      );

      // 手动终止流时，添加特殊标记，先发送最后一个手动终止的信息，再实际取消(手动的没有token信息了)
      void cancel() {
        if (!streamController.isClosed) {
          // 添加手动终止响应
          streamController.add(ChatCompletionResponse(
            id: 'cancel',
            object: 'chat.completion',
            created: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            model: requestBody['model'],
            choices: [
              ChatCompletionChoice(
                index: 0,
                delta: {'role': CusRole.assistant.name, 'content': '[手动终止]'},
                finishReason: 'cancelled',
              )
            ],
            cusText: '[手动终止]',
          ));
        }
        subscription.cancel();
        if (!streamController.isClosed) {
          streamController.close();
        }
      }

      return (streamController.stream, cancel);
    } else {
      final chatResponse = ChatCompletionResponse.fromJson(response);
      streamController.add(chatResponse);
      streamController.close();

      // 非流式不需要取消功能
      return (streamController.stream, () {});
    }
  } on CusHttpException catch (e) {
    // 报错时也要流式返回，并手动添加一条结束标志
    final streamErrorController = StreamController<ChatCompletionResponse>();

    // 当作正常流程，不添加错误响应
    // streamController.addError(e);

    // 添加错误响应
    streamErrorController.add(ChatCompletionResponse(
      id: 'error',
      object: 'chat.completion',
      created: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      model: requestBody['model'],
      choices: [
        ChatCompletionChoice(
          index: 0,
          delta: {'role': CusRole.assistant.name, 'content': '[ERROR]'},
          finishReason: 'error',
        )
      ],
      cusText: """HTTP请求响应异常:\n\n错误代码: ${e.cusCode}
            \n\n错误信息: ${e.cusMsg}
            \n\n错误原文: ${e.errMessage}
            \n\n原始信息: ${e.errRespString}
            \n\n""",
    ));

    streamErrorController.close();

    return (streamErrorController.stream, () {});
  } catch (e) {
    rethrow;
  }
}
