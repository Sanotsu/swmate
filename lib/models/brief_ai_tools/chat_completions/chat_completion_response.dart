import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../../mapper_utils.dart';

part 'chat_completion_response.g.dart';

@JsonSerializable(explicitToJson: true)
class ChatCompletionResponse {
  @JsonKey(readValue: readJsonValue)
  final String id;

  // 2025-03-03 智谱的流式响应没有此栏位
  @JsonKey(readValue: readJsonValue)
  final String? object;

  // 2025-03-03 无问芯穹流式响应可能没有此栏位
  @JsonKey(readValue: readJsonValue)
  final int? created;

  @JsonKey(readValue: readJsonValue)
  final String model;

  @JsonKey(readValue: readJsonValue)
  final List<ChatCompletionChoice> choices;

  @JsonKey(readValue: readJsonValue)
  final ChatCompletionUsage? usage;

  @JsonKey(readValue: readReferenceValue)
  final List<Map<String, dynamic>>? searchResults;

  @JsonKey(readValue: readJsonValue)
  final String? systemFingerprint;

  /// 自定义的返回文本
  String cusText;

  ChatCompletionResponse({
    required this.id,
    this.object,
    this.created,
    required this.model,
    required this.choices,
    this.usage,
    this.searchResults,
    this.systemFingerprint,
    String? cusText,
  }) : cusText = cusText ?? _generatecusText(choices);

  // 自定义的响应文本(比如流式返回最后是个[DONE]没法转型，但可以自行设定；而正常响应时可以从其他值中得到)
  static String _generatecusText(List<ChatCompletionChoice>? choices) {
    // 非流式的
    if (choices != null && choices.isNotEmpty && choices[0].message != null) {
      return choices[0].message?["content"] ?? "";
    }
    // 流式的
    if (choices != null && choices.isNotEmpty && choices[0].delta != null) {
      return choices[0].delta?["content"] ?? "";
    }

    return '';
  }

  // 从字符串转
  factory ChatCompletionResponse.fromRawJson(String str) =>
      ChatCompletionResponse.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory ChatCompletionResponse.fromJson(Map<String, dynamic> srcJson) =>
      _$ChatCompletionResponseFromJson(srcJson);

  Map<String, dynamic> toJson() => _$ChatCompletionResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ChatCompletionChoice {
  // 2025-03-03 无问芯穹流式响应最后一条choices为空数组
  @JsonKey(readValue: readJsonValue)
  final int? index;

  // 同步时从这里取
  @JsonKey(readValue: readJsonValue)
  final Map<String, dynamic>? message;

  // 流式时从这里取
  @JsonKey(readValue: readJsonValue)
  final Map<String, dynamic>? delta;

  @JsonKey(readValue: readJsonValue)
  final String? finishReason;

  @JsonKey(readValue: readJsonValue)
  final List<Map<String, dynamic>>? toolCalls;

  ChatCompletionChoice({
    this.index,
    this.message,
    this.delta,
    this.finishReason,
    this.toolCalls,
  });

  // 从字符串转
  factory ChatCompletionChoice.fromRawJson(String str) =>
      ChatCompletionChoice.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory ChatCompletionChoice.fromJson(Map<String, dynamic> srcJson) =>
      _$ChatCompletionChoiceFromJson(srcJson);

  Map<String, dynamic> toJson() => _$ChatCompletionChoiceToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ChatCompletionUsage {
  @JsonKey(readValue: readJsonValue)
  final int promptTokens;

  @JsonKey(readValue: readJsonValue)
  final int completionTokens;

  @JsonKey(readValue: readJsonValue)
  final int totalTokens;

  ChatCompletionUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  // 从字符串转
  factory ChatCompletionUsage.fromRawJson(String str) =>
      ChatCompletionUsage.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory ChatCompletionUsage.fromJson(Map<String, dynamic> srcJson) =>
      _$ChatCompletionUsageFromJson(srcJson);

  Map<String, dynamic> toJson() => _$ChatCompletionUsageToJson(this);
}
