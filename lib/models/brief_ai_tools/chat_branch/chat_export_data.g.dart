// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_export_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatExportData _$ChatExportDataFromJson(Map<String, dynamic> json) =>
    ChatExportData(
      sessions: (json['sessions'] as List<dynamic>)
          .map((e) => ChatSessionExport.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ChatExportDataToJson(ChatExportData instance) =>
    <String, dynamic>{
      'sessions': instance.sessions.map((e) => e.toJson()).toList(),
    };

ChatSessionExport _$ChatSessionExportFromJson(Map<String, dynamic> json) =>
    ChatSessionExport(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      createTime: DateTime.parse(json['createTime'] as String),
      updateTime: DateTime.parse(json['updateTime'] as String),
      llmSpec:
          CusBriefLLMSpec.fromJson(json['llmSpec'] as Map<String, dynamic>),
      modelType: $enumDecode(_$LLModelTypeEnumMap, json['modelType']),
      messages: (json['messages'] as List<dynamic>)
          .map((e) => ChatMessageExport.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ChatSessionExportToJson(ChatSessionExport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'createTime': instance.createTime.toIso8601String(),
      'updateTime': instance.updateTime.toIso8601String(),
      'llmSpec': instance.llmSpec.toJson(),
      'modelType': _$LLModelTypeEnumMap[instance.modelType]!,
      'messages': instance.messages.map((e) => e.toJson()).toList(),
    };

const _$LLModelTypeEnumMap = {
  LLModelType.cc: 'cc',
  LLModelType.vision: 'vision',
  LLModelType.reasoner: 'reasoner',
  LLModelType.tti: 'tti',
  LLModelType.iti: 'iti',
  LLModelType.image: 'image',
  LLModelType.ttv: 'ttv',
  LLModelType.itv: 'itv',
  LLModelType.video: 'video',
  LLModelType.audio: 'audio',
  LLModelType.asr: 'asr',
  LLModelType.tts: 'tts',
  LLModelType.omni: 'omni',
};

ChatMessageExport _$ChatMessageExportFromJson(Map<String, dynamic> json) =>
    ChatMessageExport(
      messageId: json['messageId'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      createTime: DateTime.parse(json['createTime'] as String),
      reasoningContent: json['reasoningContent'] as String?,
      thinkingDuration: (json['thinkingDuration'] as num?)?.toInt(),
      contentVoicePath: json['contentVoicePath'] as String?,
      imagesUrl: json['imagesUrl'] as String?,
      videosUrl: json['videosUrl'] as String?,
      promptTokens: (json['promptTokens'] as num?)?.toInt(),
      completionTokens: (json['completionTokens'] as num?)?.toInt(),
      totalTokens: (json['totalTokens'] as num?)?.toInt(),
      modelLabel: json['modelLabel'] as String?,
      branchIndex: (json['branchIndex'] as num).toInt(),
      depth: (json['depth'] as num).toInt(),
      branchPath: json['branchPath'] as String,
      parentMessageId: json['parentMessageId'] as String?,
    );

Map<String, dynamic> _$ChatMessageExportToJson(ChatMessageExport instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'role': instance.role,
      'content': instance.content,
      'createTime': instance.createTime.toIso8601String(),
      'reasoningContent': instance.reasoningContent,
      'thinkingDuration': instance.thinkingDuration,
      'contentVoicePath': instance.contentVoicePath,
      'imagesUrl': instance.imagesUrl,
      'videosUrl': instance.videosUrl,
      'promptTokens': instance.promptTokens,
      'completionTokens': instance.completionTokens,
      'totalTokens': instance.totalTokens,
      'modelLabel': instance.modelLabel,
      'branchIndex': instance.branchIndex,
      'depth': instance.depth,
      'branchPath': instance.branchPath,
      'parentMessageId': instance.parentMessageId,
    };
