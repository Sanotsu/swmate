class ChatCompletionTool {
  final String type;
  final ChatCompletionFunction function;

  const ChatCompletionTool({
    required this.type,
    required this.function,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'function': function.toJson(),
  };
}

class ChatCompletionFunction {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  const ChatCompletionFunction({
    required this.name,
    required this.description,
    required this.parameters,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'parameters': parameters,
  };
}

class ChatCompletionToolChoice {
  final String type;
  final String? function;

  const ChatCompletionToolChoice({
    required this.type,
    this.function,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    if (function != null) 'function': function,
  };

  static const none = ChatCompletionToolChoice(type: 'none');
  static const auto = ChatCompletionToolChoice(type: 'auto');
} 