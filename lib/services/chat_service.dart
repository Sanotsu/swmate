// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import '../apis/chat_completion/common_cc_apis.dart';
import '../apis/platform_keys.dart';
import '../common/constants.dart';
import '../common/llm_spec/cus_llm_model.dart';
import '../common/llm_spec/cus_llm_spec.dart';
import '../models/chat_competion/com_cc_state.dart';
import 'dart:io';

/// 2025-02-13 改版后所有平台都使用open API兼容的版本，不兼容的就不用了。
///     讯飞每个模型的AK都单独的，太麻烦了，而且效果并不出类拔萃，放弃支持它平台的调用了
/// 当前文档地址：
/// 百度 https://cloud.baidu.com/doc/WENXINWORKSHOP/s/Fm2vrveyu
/// 阿里 https://help.aliyun.com/zh/model-studio/developer-reference/compatibility-of-openai-with-dashscope
/// 腾讯 https://console.cloud.tencent.com/hunyuan/start
/// 智谱 https://open.bigmodel.cn/dev/api/normal-model/glm-4
/// 零一万物 https://platform.lingyiwanwu.com/docs/api-reference
/// 无问芯穹 https://docs.infini-ai.com/gen-studio/api/maas.html#/operations/chatCompletions
/// 硅基流动 https://docs.siliconflow.cn/cn/api-reference/chat-completions/chat-completions

class ChatService {
  static String _getBaseUrl(ApiPlatform platform) {
    switch (platform) {
      case ApiPlatform.lingyiwanwu:
        return 'https://api.lingyiwanwu.com/v1';
      case ApiPlatform.zhipu:
        return 'https://open.bigmodel.cn/api/paas/v4';
      case ApiPlatform.siliconCloud:
        return 'https://api.siliconflow.cn/v1';
      case ApiPlatform.infini:
        return 'https://cloud.infini-ai.com/maas/v1';
      case ApiPlatform.aliyun:
        return 'https://dashscope.aliyuncs.com/compatible-mode/v1';
      case ApiPlatform.baidu:
        return 'https://qianfan.baidubce.com/v2';
      case ApiPlatform.tencent:
        return 'https://api.hunyuan.cloud.tencent.com/v1/';
      default:
        throw Exception('不支持的平台');
    }
  }

  static String _getApiKey(ApiPlatform platform) {
    switch (platform) {
      case ApiPlatform.lingyiwanwu:
        return LINGYI_AK;
      case ApiPlatform.zhipu:
        return ZHIPU_AK;
      case ApiPlatform.siliconCloud:
        return SILICON_CLOUD_AK;
      case ApiPlatform.infini:
        return INFINI_GEN_STUDIO_AK;
      case ApiPlatform.aliyun:
        return ALIYUN_API_KEY;
      case ApiPlatform.baidu:
        return BAIDU_API_KEY_V2;
      case ApiPlatform.tencent:
        return TENCENT_API_KEY;
      default:
        throw Exception('不支持的平台');
    }
  }

  static Future<Map<String, String>> _getHeaders(
      CusLLMSpec model, String apiKey) async {
    // final headers = {
    //   'Content-Type': 'application/json',
    // };

    // switch (model.platform) {
    //   case ApiPlatform.lingyiwanwu:
    //     headers['Authorization'] = 'Bearer $apiKey';
    //     break;
    //   case ApiPlatform.zhipu:
    //     // 智谱需要特殊的token生成逻辑
    //    final token = zhipuGenerateToken(apiKey);
    //    headers['Authorization'] = 'Bearer $token';
    //     break;
    //   case ApiPlatform.siliconCloud:
    //     headers['Authorization'] = 'Bearer $apiKey';
    //     break;
    //   case ApiPlatform.infini:
    //     headers['Authorization'] = 'Bearer $apiKey';
    //     break;
    //   case ApiPlatform.aliyun:
    //     headers['Authorization'] = 'Bearer $apiKey';
    //     break;
    //   case ApiPlatform.baidu:
    //     headers['Authorization'] = 'Bearer $apiKey';
    //     break;
    //   case ApiPlatform.tencent:
    //     headers['Authorization'] = 'Bearer $apiKey';
    //     break;
    //   default:
    //     throw Exception('不支持的平台');
    // }

    // return headers;

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
  }

  static Future<(Stream<String>, VoidCallback)> sendMessage(
    CusLLMSpec model,
    List<ChatMessage> messages, {
    File? image,
    File? voice,
  }) async {
    final url = '${_getBaseUrl(model.platform)}/chat/completions';
    final headers = await _getHeaders(model, _getApiKey(model.platform));

    // 构建请求体
    // ？？？ 2025-02-13 这个是非常简化的请求体，不同平台，不同模型，请求参数差别很大的，后续可能需要定制一下
    final Map<String, dynamic> requestBody = {
      'model': model.model,
      'stream': true,
    };

    // 构建消息内容
    requestBody['messages'] = messages.map((m) {
      // 如果消息包含图片，构建多模态内容
      if (m.imageUrl != null) {
        final bytes = File(m.imageUrl!).readAsBytesSync();
        final base64Image = base64Encode(bytes);

        return {
          'role': m.role,
          'content': [
            {
              'type': 'text',
              'text': m.content,
            },
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
            }
          ]
        };
      } else {
        // 普通文本消息
        return {
          'role': m.role,
          'content': m.content,
        };
      }
    }).toList();

    final streamController = StreamController<String>();
    final streamWithCancel = await getSseCcResponse(
      url,
      headers,
      requestBody,
      stream: true,
    );

    // 订阅流
    final subscription = streamWithCancel.stream.listen(
      (resp) {
        if (resp.cusText == '[DONE]' || resp.cusText == '[手动终止]') {
          if (!streamController.isClosed) {
            streamController.close();
          }
        } else {
          streamController.add(resp.cusText);
        }
      },
      onError: (error) {
        streamController.addError(error);
        streamController.close();
      },
      onDone: () {
        if (!streamController.isClosed) {
          streamController.close();
        }
      },
    );

    // 返回流和取消函数
    return (
      streamController.stream,
      () {
        subscription.cancel();
        streamWithCancel.cancel();
        if (!streamController.isClosed) {
          streamController.close();
        }
      }
    );
  }

  // ??? 暂未用到
  static Future<void> sendVoice(
    CusLLMSpec model,
    String voicePath,
    List<ChatMessage> messages,
  ) async {
    final url = '${_getBaseUrl(model.platform)}/audio/transcriptions';
    final headers = await _getHeaders(model, _getApiKey(model.platform));

    // 创建multipart请求
    var request = http.MultipartRequest('POST', Uri.parse(url))
      ..headers.addAll(headers)
      ..fields['model'] = model.model
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        voicePath,
      ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('语音转写失败: ${response.statusCode}');
    }

    final transcription = jsonDecode(response.body)['text'];

    // 将转写文本作为新消息发送
    messages.add(
      ChatMessage(
        messageId: DateTime.now().toString(),
        dateTime: DateTime.now(),
        role: CusRole.user.name,
        content: transcription,
        contentVoicePath: voicePath,
      ),
    );
  }
}
