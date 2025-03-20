import 'package:uuid/uuid.dart';

class CharacterChatMessage {
  final String id;
  String content;
  // 思考内容和时长
  String? reasoningContent;
  int? thinkingDuration;
  String role; // 'user', 'assistant', 'system'
  String? characterId; // 对应角色ID，用户消息为null
  DateTime timestamp;
  String? contentVoicePath; // 语音消息路径
  String? imagesUrl; // 图片URL，多个用逗号分隔
  int? promptTokens; // 提示词token数
  int? completionTokens; // 回复token数
  int? totalTokens; // 总token数

  CharacterChatMessage({
    String? id,
    required this.content,
    required this.role,
    this.characterId,
    this.reasoningContent,
    this.thinkingDuration,
    DateTime? timestamp,
    this.contentVoicePath,
    this.imagesUrl,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  // JSON序列化和反序列化方法
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'role': role,
      'characterId': characterId,
      'reasoningContent': reasoningContent,
      'thinkingDuration': thinkingDuration,
      'timestamp': timestamp.toIso8601String(),
      'contentVoicePath': contentVoicePath,
      'imagesUrl': imagesUrl,
      'promptTokens': promptTokens,
      'completionTokens': completionTokens,
      'totalTokens': totalTokens,
    };
  }

  factory CharacterChatMessage.fromJson(Map<String, dynamic> json) {
    return CharacterChatMessage(
      id: json['id'],
      content: json['content'],
      role: json['role'],
      characterId: json['characterId'],
      reasoningContent: json['reasoningContent'],
      thinkingDuration: json['thinkingDuration'],
      timestamp: DateTime.parse(json['timestamp']),
      contentVoicePath: json['contentVoicePath'],
      imagesUrl: json['imagesUrl'],
      promptTokens: json['promptTokens'],
      completionTokens: json['completionTokens'],
      totalTokens: json['totalTokens'],
    );
  }
}
