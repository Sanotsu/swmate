import '../../common/llm_spec/cus_llm_spec.dart';
import 'chat_completion_tool.dart';

class ChatCompletionRequest {
  // OpenAI 标准参数
  final String model;
  final List<Map<String, dynamic>> messages;
  final List<ChatCompletionTool>? tools;
  final ChatCompletionToolChoice? toolChoice;
  final double? temperature;
  final double? topP;
  final int? maxTokens;
  final bool stream;
  final List<String>? stop;
  final double? presencePenalty;
  final double? frequencyPenalty;
  final int? n;
  final Map<String, dynamic>? responseFormat;
  final String? user;
  final int? seed;

  // 其他平台特有参数
  // 硅基流动特有
  final double? topK;

  // 智谱AI特有
  final String? requestId;
  final bool? doSample;
  final String? type;
  final String? userId;

  // 百度特有
  final bool? webSearch;
  final Map<String, dynamic>? streamOptions;
  final Map<String, dynamic>? metadata;
  final int? parallelToolCalls;

  // 阿里云特有
  final bool? enableSearch;

  const ChatCompletionRequest({
    required this.model,
    required this.messages,
    this.tools,
    this.toolChoice,
    this.temperature,
    this.topP,
    this.maxTokens,
    this.stream = true,
    this.stop,
    this.presencePenalty,
    this.frequencyPenalty,
    this.n,
    this.responseFormat,
    this.user,
    this.seed,
    // 其他平台特有参数
    this.topK,
    this.requestId,
    this.doSample,
    this.type,
    this.userId,
    this.webSearch,
    this.streamOptions,
    this.metadata,
    this.parallelToolCalls,
    this.enableSearch,
  });

  Map<String, dynamic> toRequestBody(ApiPlatform platform) {
    // OpenAI 标准请求体
    final Map<String, dynamic> base = {
      'model': model,
      'messages': messages,
      'stream': stream,
      if (tools != null) 'tools': tools!.map((t) => t.toJson()).toList(),
      if (toolChoice != null) 'tool_choice': toolChoice!.toJson(),
      if (temperature != null) 'temperature': temperature,
      if (topP != null) 'top_p': topP,
      if (maxTokens != null) 'max_tokens': maxTokens,
      if (stop != null) 'stop': stop,
      if (presencePenalty != null) 'presence_penalty': presencePenalty,
      if (frequencyPenalty != null) 'frequency_penalty': frequencyPenalty,
      if (n != null) 'n': n,
      if (responseFormat != null) 'response_format': responseFormat,
      if (user != null) 'user': user,
      if (seed != null) 'seed': seed,
    };

    // 各平台特有参数
    switch (platform) {
      case ApiPlatform.baidu:
        return {
          ...base,
          if (maxTokens != null) 'max_completion_tokens': maxTokens, // 参数名不同
          if (webSearch != null) 'web_search': webSearch,
          if (streamOptions != null) 'stream_options': streamOptions,
          if (metadata != null) 'metadata': metadata,
          if (parallelToolCalls != null)
            'parallel_tool_calls': parallelToolCalls,
        };

      case ApiPlatform.siliconCloud:
        return {
          ...base,
          if (topK != null) 'top_k': topK,
        };

      case ApiPlatform.zhipu:
        return {
          ...base,
          if (requestId != null) 'request_id': requestId,
          if (doSample != null) 'do_sample': doSample,
          if (type != null) 'type': type,
          if (userId != null) 'user_id': userId,
        };

      case ApiPlatform.aliyun:
        return {
          ...base,
          if (enableSearch != null) 'enable_search': enableSearch,
        };

      case ApiPlatform.tencent:
      case ApiPlatform.lingyiwanwu:
      case ApiPlatform.infini:
        // 完全兼容 OpenAI 接口
        return base;

      default:
        return base;
    }
  }
}
