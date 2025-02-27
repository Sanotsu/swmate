import 'dart:convert';
import 'dart:io';
import '../common/constants/default_models.dart';
import '../common/llm_spec/cus_brief_llm_model.dart';
import '../common/llm_spec/cus_llm_spec.dart';
import '../common/utils/dio_client/cus_http_client.dart';
import '../common/utils/dio_client/cus_http_request.dart';
import '../models/video_generation/video_generation_request.dart';
import '../models/video_generation/video_generation_response.dart';
import 'cus_get_storage.dart';

class VideoGenerationService {
  static String _getBaseUrl(ApiPlatform platform) {
    switch (platform) {
      case ApiPlatform.aliyun:
        return 'https://dashscope.aliyuncs.com/api/v1/services/aigc/video-generation/video-synthesis';
      case ApiPlatform.zhipu:
        return 'https://open.bigmodel.cn/api/paas/v4/videos/generations';
      case ApiPlatform.siliconCloud:
        return 'https://api.siliconflow.cn/v1/video/submit';
      default:
        throw Exception('不支持的平台');
    }
  }

  static String _getBaseTaskUrl(ApiPlatform platform) {
    // 阿里云和智谱是GET，任务编号接在url后面，硅基流动是POST，任务编号接在body中
    switch (platform) {
      case ApiPlatform.aliyun:
        return 'https://dashscope.aliyuncs.com/api/v1/tasks';
      case ApiPlatform.zhipu:
        return 'https://open.bigmodel.cn/api/paas/v4/async-result';
      case ApiPlatform.siliconCloud:
        return 'https://api.siliconflow.cn/v1/video/status';

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

  static Future<Map<String, String>> _getHeaders(CusBriefLLMSpec model) async {
    final apiKey = await _getApiKey(model);

    switch (model.platform) {
      case ApiPlatform.siliconCloud || ApiPlatform.zhipu:
        return {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        };
      case ApiPlatform.aliyun:
        return {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'X-DashScope-Async': 'enable',
        };

      // ... 其他平台的 headers
      default:
        throw Exception('不支持的平台');
    }
  }

  // 生成视频
  // 2025-02-25 返回提交任务的响应，而不是生成结果,因为视频生成耗时较长，需要轮询任务状态
  static Future<VideoGenerationSubmitResponse> generateVideo(
    CusBriefLLMSpec model,
    String prompt, {
    String? referenceImagePath,
    int? fps,
    String? size,
    Map<String, dynamic>? extraParams,
  }) async {
    final headers = await _getHeaders(model);
    final baseUrl = _getBaseUrl(model.platform);

    // 处理参考图片
    String? referenceImage;
    if (referenceImagePath != null) {
      final bytes = await File(referenceImagePath).readAsBytes();
      referenceImage = "data:image/png;base64,${base64Encode(bytes)}";
    }

    final request = VideoGenerationRequest(
      model: model.model,
      prompt: prompt,
      image: referenceImage,
      imageUrl: referenceImage,
      // fps: fps,
      // size: size,
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
    );

    return VideoGenerationSubmitResponse.fromResponseBody(
      response,
      model.platform,
    );

    // // 先解析任务提交响应
    // var resp = VideoGenerationSubmitResponse.fromResponseBody(
    //   response,
    //   model.platform,
    // );

    // String taskId = "";

    // switch (model.platform) {
    //   case ApiPlatform.siliconCloud:
    //     taskId = resp.requestId ?? "";
    //     break;
    //   case ApiPlatform.aliyun:
    //     taskId = resp.output?.taskId ?? "";
    //     break;
    //   case ApiPlatform.zhipu:
    //     taskId = resp.id ?? "";
    //     break;
    //   default:
    //     throw Exception('不支持的平台');
    // }

    // return pollTaskStatus(taskId, model, submitResp: resp);
  }

  static Future<VideoGenerationResponse> pollTaskStatus(
    String taskId,
    CusBriefLLMSpec model, {
    VideoGenerationSubmitResponse? submitResp,
  }) async {
    const maxAttempts = 30; // 最大轮询次数
    const interval = Duration(seconds: 2); // 轮询间隔

    for (var i = 0; i < maxAttempts; i++) {
      final response = await queryTaskStatus(taskId, model);

      // 这里任务的状态都使用阿里云的枚举
      switch (model.platform) {
        case ApiPlatform.siliconCloud:
          if (response.taskStatus == 'Succeed') {
            return VideoGenerationResponse(
              requestId: submitResp?.requestId,
              taskId: taskId,
              status: 'SUCCEEDED',
              results: response.results?.videos ?? [],
            );
          }
          break;
        case ApiPlatform.aliyun:
          if (response.output?.taskStatus == 'SUCCEEDED') {
            return VideoGenerationResponse(
              requestId: submitResp?.requestId,
              taskId: taskId,
              status: 'SUCCEEDED',
              results: response.output?.videoUrl != null
                  ? [VideoResult(url: response.output?.videoUrl ?? '')]
                  : [],
            );
          }
          if (response.output?.taskStatus == 'FAILED' ||
              response.output?.taskStatus == 'UNKNOWN') {
            throw Exception('视频生成失败');
          }
          break;
        case ApiPlatform.zhipu:
          if (response.taskStatus == 'SUCCESS') {
            return VideoGenerationResponse(
              requestId: submitResp?.requestId,
              taskId: taskId,
              status: 'SUCCEEDED',
              results: response.videoResult ?? [],
            );
          }
          if (response.output?.taskStatus == 'FAIL') {
            throw Exception('视频生成失败');
          }
          break;
        default:
          throw Exception('不支持的平台');
      }

      await Future.delayed(interval);
    }

    throw Exception('任务超时');
  }

  // 查询任务状态
  static Future<VideoGenerationTaskResponse> queryTaskStatus(
    String taskId,
    CusBriefLLMSpec model,
  ) async {
    final headers = await _getHeaders(model);

    dynamic taskResponse;

    switch (model.platform) {
      case ApiPlatform.siliconCloud:
        taskResponse = await HttpUtils.post(
          method: CusHttpMethod.post,
          path: _getBaseTaskUrl(model.platform),
          headers: headers,
          data: {'requestId': taskId},
        );
        break;

      case ApiPlatform.aliyun:
        taskResponse = await HttpUtils.get(
          path: "${_getBaseTaskUrl(model.platform)}/$taskId",
          headers: headers,
        );
        break;

      case ApiPlatform.zhipu:
        taskResponse = await HttpUtils.get(
          path: "${_getBaseTaskUrl(model.platform)}/$taskId",
          headers: headers,
        );
        break;

      default:
        throw Exception('不支持的平台');
    }

    return VideoGenerationTaskResponse.fromJson(taskResponse);
  }
}
