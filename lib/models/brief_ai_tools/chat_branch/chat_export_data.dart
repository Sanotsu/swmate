import 'package:json_annotation/json_annotation.dart';
import '../../../common/llm_spec/constant_llm_enum.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import 'chat_branch_message.dart';
import 'chat_branch_session.dart';

part 'chat_export_data.g.dart';

@JsonSerializable(explicitToJson: true)
class ChatExportData {
  final List<ChatSessionExport> sessions;

  ChatExportData({required this.sessions});

  factory ChatExportData.fromJson(Map<String, dynamic> json) =>
      _$ChatExportDataFromJson(json);

  Map<String, dynamic> toJson() => _$ChatExportDataToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ChatSessionExport {
  final int id;
  final String title;
  final DateTime createTime;
  final DateTime updateTime;
  final CusBriefLLMSpec llmSpec;
  final LLModelType modelType;
  final List<ChatMessageExport> messages;

  ChatSessionExport({
    required this.id,
    required this.title,
    required this.createTime,
    required this.updateTime,
    required this.llmSpec,
    required this.modelType,
    required this.messages,
  });

  factory ChatSessionExport.fromSession(ChatBranchSession session) {
    return ChatSessionExport(
      id: session.id,
      title: session.title,
      createTime: session.createTime,
      updateTime: session.updateTime,
      llmSpec: session.llmSpec,
      modelType: session.modelType,
      messages: session.messages
          .map((msg) => ChatMessageExport.fromMessage(msg))
          .toList(),
    );
  }

  factory ChatSessionExport.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionExportFromJson(json);

  Map<String, dynamic> toJson() => _$ChatSessionExportToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ChatMessageExport {
  final String messageId;
  final String role;
  final String content;
  final DateTime createTime;
  final String? reasoningContent;
  final int? thinkingDuration;
  final String? contentVoicePath;
  final String? imagesUrl;
  final String? videosUrl;
  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;
  final String? modelLabel;
  final int branchIndex;
  final int depth;
  final String branchPath;
  final String? parentMessageId;

  ChatMessageExport({
    required this.messageId,
    required this.role,
    required this.content,
    required this.createTime,
    this.reasoningContent,
    this.thinkingDuration,
    this.contentVoicePath,
    this.imagesUrl,
    this.videosUrl,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.modelLabel,
    required this.branchIndex,
    required this.depth,
    required this.branchPath,
    this.parentMessageId,
  });

  factory ChatMessageExport.fromMessage(ChatBranchMessage message) {
    return ChatMessageExport(
      messageId: message.messageId,
      role: message.role,
      content: message.content,
      createTime: message.createTime,
      reasoningContent: message.reasoningContent,
      thinkingDuration: message.thinkingDuration,
      contentVoicePath: message.contentVoicePath,
      imagesUrl: message.imagesUrl,
      videosUrl: message.videosUrl,
      promptTokens: message.promptTokens,
      completionTokens: message.completionTokens,
      totalTokens: message.totalTokens,
      modelLabel: message.modelLabel,
      branchIndex: message.branchIndex,
      depth: message.depth,
      branchPath: message.branchPath,
      parentMessageId: message.parent.target?.messageId,
    );
  }

  factory ChatMessageExport.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageExportFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageExportToJson(this);
} 