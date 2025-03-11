import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';

import '../common/llm_spec/constant_llm_enum.dart';
import '../common/utils/dio_client/cus_http_client.dart';
import '../common/utils/dio_client/cus_http_request.dart';
import '../models/brief_ai_tools/chat_branch/chat_branch_message.dart';
import 'cus_get_storage.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  Future<Map<String, dynamic>> generateResponse({
    required List<ChatBranchMessage> messages,
    String? modelLabel,
    bool stream = true,
    void Function(String)? onStream,
  }) async {
    final startTime = DateTime.now();
    String content = '';

    try {
      final userKeys = MyGetStorage().getUserAKMap();
      var apiKey =
          userKeys[ApiPlatformAKLabel.USER_INFINI_GEN_STUDIO_API_KEY.name];

      print('apiKey: $apiKey');
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };

      var requestBody = {
        'messages': messages
            .map((m) => {
                  'role': m.role,
                  'content': m.content,
                })
            .toList(),
        // 'model': modelLabel,
        'model': 'deepseek-v3',
        'stream': stream,
      };

      if (stream && onStream != null) {
        final ResponseBody streamResponse = await HttpUtils.post(
          path: 'https://cloud.infini-ai.com/maas/v1/chat/completions',
          method: CusHttpMethod.post,
          headers: headers,
          data: requestBody,
          responseType: CusRespType.stream,
          showLoading: false,
          showErrorMessage: false,
        );

        await for (final chunk in streamResponse.stream) {
          String text = utf8.decode(chunk);
          final lines = text.split('\n');

          for (var line in lines) {
            if (line.startsWith('data: ')) {
              String jsonStr = line.substring(6);
              if (jsonStr.trim() == '[DONE]') continue;

              try {
                final jsonData = json.decode(jsonStr);
                final chunkText = _parseStreamChunk(jsonData);
                if (chunkText.isNotEmpty) {
                  content += chunkText;
                  onStream(chunkText);
                }
              } catch (e) {
                print('解析响应数据出错: $e');
              }
            }
          }
        }
      } else {
        final response = await HttpUtils.post(
          path: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
          method: CusHttpMethod.post,
          headers: headers,
          data: requestBody,
          responseType: CusRespType.json,
          showLoading: false,
          showErrorMessage: false,
        );
        content = response['content'];
      }

      final endTime = DateTime.now();

      return {
        'content': content,
        'reasoningContent': null,
        'thinkingDuration': endTime.difference(startTime).inMilliseconds,
        'promptTokens': null,
        'completionTokens': null,
        'totalTokens': null,
      };
    } catch (e) {
      rethrow;
    }
  }

  String _parseStreamChunk(dynamic chunk) {
    // 根据实际的流式响应格式解析文本
    try {
      if (chunk is Map) {
        return chunk['choices']?[0]?['delta']?['content'] ?? '';
      }
      return '';
    } catch (e) {
      return '';
    }
  }
}
