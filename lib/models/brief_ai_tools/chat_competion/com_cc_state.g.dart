// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'com_cc_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
      messageId: json['messageId'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      role: json['role'] as String,
      content: json['content'] as String,
      reasoningContent: json['reasoningContent'] as String?,
      thinkingDuration: (json['thinkingDuration'] as num?)?.toInt(),
      contentVoicePath: json['contentVoicePath'] as String?,
      quotes: (json['quotes'] as List<dynamic>?)
          ?.map((e) => CCQuote.fromJson(e as Map<String, dynamic>))
          .toList(),
      imageUrl: json['imageUrl'] as String?,
      promptTokens: (json['promptTokens'] as num?)?.toInt(),
      completionTokens: (json['completionTokens'] as num?)?.toInt(),
      totalTokens: (json['totalTokens'] as num?)?.toInt(),
      modelLabel: json['modelLabel'] as String?,
    );

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'dateTime': instance.dateTime.toIso8601String(),
      'role': instance.role,
      'content': instance.content,
      'reasoningContent': instance.reasoningContent,
      'thinkingDuration': instance.thinkingDuration,
      'contentVoicePath': instance.contentVoicePath,
      'quotes': instance.quotes?.map((e) => e.toJson()).toList(),
      'imageUrl': instance.imageUrl,
      'promptTokens': instance.promptTokens,
      'completionTokens': instance.completionTokens,
      'totalTokens': instance.totalTokens,
      'modelLabel': instance.modelLabel,
    };

ChatHistory _$ChatHistoryFromJson(Map<String, dynamic> json) => ChatHistory(
      uuid: json['uuid'] as String,
      title: json['title'] as String,
      gmtCreate: DateTime.parse(json['gmtCreate'] as String),
      gmtModified: DateTime.parse(json['gmtModified'] as String),
      messages: (json['messages'] as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      llmName: json['llmName'] as String,
      cloudPlatformName: json['cloudPlatformName'] as String?,
      i2tImagePath: json['i2tImagePath'] as String?,
      chatType: json['chatType'] as String,
    );

Map<String, dynamic> _$ChatHistoryToJson(ChatHistory instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'title': instance.title,
      'gmtCreate': instance.gmtCreate.toIso8601String(),
      'gmtModified': instance.gmtModified.toIso8601String(),
      'messages': instance.messages.map((e) => e.toJson()).toList(),
      'llmName': instance.llmName,
      'cloudPlatformName': instance.cloudPlatformName,
      'chatType': instance.chatType,
      'i2tImagePath': instance.i2tImagePath,
    };

BriefChatHistory _$BriefChatHistoryFromJson(Map<String, dynamic> json) =>
    BriefChatHistory(
      uuid: json['uuid'] as String,
      title: json['title'] as String,
      gmtCreate: DateTime.parse(json['gmtCreate'] as String),
      gmtModified: DateTime.parse(json['gmtModified'] as String),
      messages: (json['messages'] as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      llmSpec:
          CusBriefLLMSpec.fromJson(json['llmSpec'] as Map<String, dynamic>),
      modelType: $enumDecode(_$LLModelTypeEnumMap, json['modelType']),
    );

Map<String, dynamic> _$BriefChatHistoryToJson(BriefChatHistory instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'title': instance.title,
      'gmtCreate': instance.gmtCreate.toIso8601String(),
      'gmtModified': instance.gmtModified.toIso8601String(),
      'messages': instance.messages.map((e) => e.toJson()).toList(),
      'llmSpec': instance.llmSpec.toJson(),
      'modelType': _$LLModelTypeEnumMap[instance.modelType]!,
    };

const _$LLModelTypeEnumMap = {
  LLModelType.cc: 'cc',
  LLModelType.vision: 'vision',
  LLModelType.voice: 'voice',
  LLModelType.tti: 'tti',
  LLModelType.iti: 'iti',
  LLModelType.image: 'image',
  LLModelType.ttv: 'ttv',
  LLModelType.itv: 'itv',
  LLModelType.video: 'video',
};

GroupChatHistory _$GroupChatHistoryFromJson(Map<String, dynamic> json) =>
    GroupChatHistory(
      uuid: json['uuid'] as String,
      title: json['title'] as String,
      messages: (json['messages'] as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      modelMsgMap: (json['modelMsgMap'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k,
            (e as List<dynamic>)
                .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
                .toList()),
      ),
      gmtCreate: DateTime.parse(json['gmtCreate'] as String),
      gmtModified: DateTime.parse(json['gmtModified'] as String),
    );

Map<String, dynamic> _$GroupChatHistoryToJson(GroupChatHistory instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'title': instance.title,
      'messages': instance.messages.map((e) => e.toJson()).toList(),
      'modelMsgMap': instance.modelMsgMap
          .map((k, e) => MapEntry(k, e.map((e) => e.toJson()).toList())),
      'gmtCreate': instance.gmtCreate.toIso8601String(),
      'gmtModified': instance.gmtModified.toIso8601String(),
    };
