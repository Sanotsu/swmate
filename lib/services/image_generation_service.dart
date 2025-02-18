import 'dart:async';
import '../common/constants/default_models.dart';
import '../common/llm_spec/cus_brief_llm_model.dart';
import '../common/llm_spec/cus_llm_spec.dart';
import '../common/utils/dio_client/cus_http_client.dart';
import '../common/utils/dio_client/cus_http_request.dart';
import '../models/image_generation/image_generation_request.dart';
import '../models/image_generation/image_generation_response.dart';
import 'cus_get_storage.dart';

/// 2025-02-17
/// 图片生成的API各个平台就算同样模型参数啥的也不太一样；
/// 同一个平台不同模型，API路径不一样，请求参数也不一样，所以可能需要单独处理
/// 暂时测试支持阿里云(先返回任务ID，然后轮询任务状态)、硅基流动(直接返回结果)、智谱(直接返回结果)
class ImageGenerationService {
  static String _getBaseUrl(ApiPlatform platform) {
    switch (platform) {
      case ApiPlatform.zhipu:
        return 'https://open.bigmodel.cn/api/paas/v4/images/generations';
      case ApiPlatform.siliconCloud:
        return 'https://api.siliconflow.cn/v1/images/generations';
      case ApiPlatform.aliyun:
        return 'https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis';

      default:
        throw Exception('不支持的平台');
    }
  }

  /// 分成taskid进行查询时，需要轮询任务状态的URL
  static String _getBaseTaskUrl(ApiPlatform platform) {
    switch (platform) {
      case ApiPlatform.aliyun:
        return 'https://dashscope.aliyuncs.com/api/v1/tasks';

      default:
        throw Exception('不支持的平台');
    }
  }

  static Future<String> _getApiKey(CusBriefLLMSpec model) async {
    if (model.cusLlmSpecId?.endsWith('_builtin') ?? false) {
      // 使用内置的 API Key
      switch (model.platform) {
        case ApiPlatform.siliconCloud:
          return DefaultApiKeys.siliconCloudAK;
        case ApiPlatform.zhipu:
          return DefaultApiKeys.zhipuAK;
        case ApiPlatform.aliyun:
          return DefaultApiKeys.aliyunApiKey;
        default:
          throw Exception('不支持的平台');
      }
    } else {
      // 使用用户的 API Key
      final userKeys = MyGetStorage().getUserAKMap();
      String? apiKey;

      switch (model.platform) {
        case ApiPlatform.siliconCloud:
          apiKey = userKeys['USER_SILICON_CLOUD_AK'];
          break;
        case ApiPlatform.zhipu:
          apiKey = userKeys['USER_ZHIPU_AK'];
          break;
        case ApiPlatform.aliyun:
          apiKey = userKeys['USER_ALIYUN_API_KEY'];
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
      case ApiPlatform.siliconCloud || ApiPlatform.zhipu:
        return {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        };
      case ApiPlatform.aliyun:
        return {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'X-DashScope-Async': 'enable',
        };
      // ... 其他平台的 headers
      default:
        throw Exception('不支持的平台');
    }
  }

  static Future<ImageGenerationResponse> generateImage(
    CusBriefLLMSpec model,
    String prompt, {
    int? n,
    String? size,
    Map<String, dynamic>? extraParams,
  }) async {
    final headers = await _getHeaders(model);
    final baseUrl = _getBaseUrl(model.platform);

    final request = ImageGenerationRequest(
      model: model.model,
      prompt: prompt,
      n: n,
      size: size,
    );

    final requestBody = {
      ...request.toRequestBody(model.platform),
      ...?extraParams
    };

    final response = await HttpUtils.post(
      path: baseUrl,
      method: CusHttpMethod.post,
      headers: headers,
      data: requestBody,
      showLoading: false,
    );

    // 先解析响应
    var resp = ImageGenerationResponse.fromJson(response);

    // 如果是阿里云平台的，需要轮询任务状态
    if (model.platform == ApiPlatform.aliyun) {
      if (resp.output != null) {
        var taskId = resp.output!.taskId;
        return pollTaskStatus(model, taskId);
      } else {
        throw Exception('阿里云返回的任务ID为空');
      }
    } else {
      return resp;
    }
  }

  static Future<ImageGenerationResponse> pollTaskStatus(
    CusBriefLLMSpec model,
    String taskId,
  ) async {
    const maxAttempts = 30; // 最大轮询次数
    const interval = Duration(seconds: 2); // 轮询间隔

    for (var i = 0; i < maxAttempts; i++) {
      final response = await _queryTaskStatus(model, taskId);

      if (response.output.taskStatus == 'SUCCEEDED') {
        return ImageGenerationResponse(
          requestId: taskId,
          created: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          results: response.output.results ?? [],
        );
      }

      if (response.output.taskStatus == 'FAILED' ||
          response.output.taskStatus == 'UNKNOWN') {
        throw Exception(response.message ?? '图片生成失败');
      }

      await Future.delayed(interval);
    }

    throw Exception('任务超时');
  }

  static Future<AliyunWanxV2Resp> _queryTaskStatus(
    CusBriefLLMSpec model,
    String taskId,
  ) async {
    final headers = await _getHeaders(model);
    final baseUrl = "${_getBaseTaskUrl(model.platform)}/$taskId";

    final response = await HttpUtils.get(
      path: baseUrl,
      headers: headers,
      showLoading: false,
    );

    return AliyunWanxV2Resp.fromJson(response);
  }
}
