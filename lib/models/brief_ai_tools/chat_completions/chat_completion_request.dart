class ChatCompletionRequest {
  //  简化的参数
  final String model;
  final List<Map<String, dynamic>> messages;
  final bool stream;
  // 所有额外参数（根据平台或者模型参数不固定）
  final Map<String, dynamic>? additionalParams;

  const ChatCompletionRequest({
    required this.model,
    required this.messages,
    this.stream = true,
    // 添加额外参数字段
    this.additionalParams,
  });

  Map<String, dynamic> toRequestBody() {
    // 基础请求体
    final Map<String, dynamic> base = {
      'model': model,
      'messages': messages,
      'stream': stream,
    };

    if (additionalParams != null) {
      base.addAll(additionalParams!);
    }

    return base;
  }
}
