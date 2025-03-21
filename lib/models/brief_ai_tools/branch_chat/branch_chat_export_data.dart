import 'package:json_annotation/json_annotation.dart';
import '../../../common/llm_spec/constant_llm_enum.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import 'branch_chat_message.dart';
import 'branch_chat_session.dart';

part 'branch_chat_export_data.g.dart';

@JsonSerializable(explicitToJson: true)
class BranchChatExportData {
  final List<BranchChatSessionExport> sessions;

  BranchChatExportData({required this.sessions});

  factory BranchChatExportData.fromJson(Map<String, dynamic> json) =>
      _$BranchChatExportDataFromJson(json);

  Map<String, dynamic> toJson() => _$BranchChatExportDataToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BranchChatSessionExport {
  final int id;
  final String title;
  final DateTime createTime;
  final DateTime updateTime;
  final CusBriefLLMSpec llmSpec;
  final LLModelType modelType;
  final List<BranchChatMessageExport> messages;

  BranchChatSessionExport({
    required this.id,
    required this.title,
    required this.createTime,
    required this.updateTime,
    required this.llmSpec,
    required this.modelType,
    required this.messages,
  });

  factory BranchChatSessionExport.fromSession(BranchChatSession session) {
    return BranchChatSessionExport(
      id: session.id,
      title: session.title,
      createTime: session.createTime,
      updateTime: session.updateTime,
      llmSpec: session.llmSpec,
      modelType: session.modelType,
      messages: session.messages
          .map((msg) => BranchChatMessageExport.fromMessage(msg))
          .toList(),
    );
  }

  factory BranchChatSessionExport.fromJson(Map<String, dynamic> json) =>
      _$BranchChatSessionExportFromJson(json);

  Map<String, dynamic> toJson() => _$BranchChatSessionExportToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BranchChatMessageExport {
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

  BranchChatMessageExport({
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

  factory BranchChatMessageExport.fromMessage(BranchChatMessage message) {
    return BranchChatMessageExport(
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

  factory BranchChatMessageExport.fromJson(Map<String, dynamic> json) =>
      _$BranchChatMessageExportFromJson(json);

  Map<String, dynamic> toJson() => _$BranchChatMessageExportToJson(this);
}
