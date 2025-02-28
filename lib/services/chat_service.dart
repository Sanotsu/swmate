// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import '../common/llm_spec/cus_brief_llm_model.dart';
import '../common/llm_spec/constant_llm_enum.dart';
import '../models/brief_ai_tools/chat_completions/chat_completion_response.dart';
import '../models/brief_ai_tools/chat_competion/com_cc_state.dart';
import 'dart:io';
import '../common/constants/default_models.dart';
import '../services/cus_get_storage.dart';
import '../models/brief_ai_tools/chat_completions/chat_completion_request.dart';
import '../apis/chat_completion/openai_compatible_apis.dart';

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
  // 暴露出去
  static String getBaseUrl(ApiPlatform platform) => _getBaseUrl(platform);
  static Future<String> getApiKey(CusBriefLLMSpec model) => _getApiKey(model);
  static Future<Map<String, String>> getHeaders(CusBriefLLMSpec model) =>
      _getHeaders(model);

  // 私有方法
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

  static Future<(Stream<ChatCompletionResponse>, VoidCallback)> sendMessage(
    CusBriefLLMSpec model,
    List<ChatMessage> messages, {
    File? image,
    File? voice,
    bool stream = true,
  }) async {
    final headers = await _getHeaders(model);
    final baseUrl = "${_getBaseUrl(model.platform)}/chat/completions";

    // 构建消息内容
    final messagesList = messages.map((m) {
      if (m.imageUrl != null) {
        final bytes = File(m.imageUrl!).readAsBytesSync();
        final base64Image = base64Encode(bytes);
        return {
          'role': m.role,
          'content': [
            {'type': 'text', 'text': m.content},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
            }
          ]
        };
      } else {
        return {'role': m.role, 'content': m.content};
      }
    }).toList();

    final request = ChatCompletionRequest(
      model: model.model,
      messages: messagesList,
      stream: stream,
      temperature: 0.7,
    );

    final requestBody = request.toRequestBody(model.platform);

    return getStreamResponse(baseUrl, headers, requestBody, stream: stream);
  }
}
