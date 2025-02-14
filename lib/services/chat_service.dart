// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import '../apis/chat_completion/common_cc_apis.dart';
import '../common/constants.dart';
import '../common/llm_spec/cus_brief_llm_model.dart';
import '../common/llm_spec/cus_llm_spec.dart';
import '../models/chat_competion/com_cc_state.dart';
import 'dart:io';
import '../common/constants/default_models.dart';
import '../services/cus_get_storage.dart';

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

  static Future<String> _getApiKey(CusBriefLLMSpec model) async {
    if (model.cusLlmSpecId?.endsWith('_builtin') ?? false) {
      // 使用内置的 API Key
      switch (model.platform) {
        case ApiPlatform.baidu:
          return DefaultApiKeys.baiduApiKey;
        case ApiPlatform.siliconCloud:
          return DefaultApiKeys.siliconCloudAK;
        case ApiPlatform.lingyiwanwu:
          return DefaultApiKeys.lingyiAK;
        case ApiPlatform.zhipu:
          return DefaultApiKeys.zhipuAK;
        case ApiPlatform.infini:
          return DefaultApiKeys.infiniAK;
        case ApiPlatform.aliyun:
          return DefaultApiKeys.aliyunApiKey;
        case ApiPlatform.tencent:
          return DefaultApiKeys.tencentApiKey;
        default:
          throw Exception('不支持的平台');
      }
    } else {
      // 使用用户的 API Key
      final userKeys = MyGetStorage().getUserAKMap();
      String? apiKey;

      switch (model.platform) {
        case ApiPlatform.baidu:
          apiKey = userKeys['USER_BAIDU_API_KEY_V2'];
          break;
        case ApiPlatform.siliconCloud:
          apiKey = userKeys['USER_SILICON_CLOUD_AK'];
          break;
        case ApiPlatform.lingyiwanwu:
          apiKey = userKeys['USER_LINGYIWANWU_AK'];
          break;
        case ApiPlatform.zhipu:
          apiKey = userKeys['USER_ZHIPU_AK'];
          break;
        case ApiPlatform.infini:
          apiKey = userKeys['USER_INFINI_GEN_STUDIO_AK'];
          break;
        case ApiPlatform.aliyun:
          apiKey = userKeys['USER_ALIYUN_API_KEY'];
          break;
        case ApiPlatform.tencent:
          apiKey = userKeys['USER_TENCENT_API_KEY'];
          break;
        default:
          throw Exception('不支持的平台');
      }

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('未配置该平台的 API Key');
      }
      return apiKey;
    }
  }

  static Future<Map<String, String>> _getHeaders(
    CusBriefLLMSpec model,
  ) async {
    final apiKey = await _getApiKey(model);

    switch (model.platform) {
      case ApiPlatform.baidu ||
            ApiPlatform.siliconCloud ||
            ApiPlatform.lingyiwanwu ||
            ApiPlatform.zhipu ||
            ApiPlatform.infini ||
            ApiPlatform.aliyun ||
            ApiPlatform.tencent:
        return {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        };
      // ... 其他平台的 headers
      default:
        throw Exception('不支持的平台');
    }
  }

  static Future<(Stream<String>, VoidCallback)> sendMessage(
    CusBriefLLMSpec model,
    List<ChatMessage> messages, {
    File? image,
    File? voice,
  }) async {
    final headers = await _getHeaders(model);
    final baseUrl = "${_getBaseUrl(model.platform)}/chat/completions";

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
      baseUrl,
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
        // 先发送最后一个手动终止的信息，再实际取消
        if (!streamController.isClosed) {
          streamController.add('[手动终止]');
        }
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
    CusBriefLLMSpec model,
    String voicePath,
    List<ChatMessage> messages,
  ) async {
    final url = '${_getBaseUrl(model.platform)}/audio/transcriptions';
    final headers = await _getHeaders(model);

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
