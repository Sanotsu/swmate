// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_completion_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatCompletionResponse _$ChatCompletionResponseFromJson(
        Map<String, dynamic> json) =>
    ChatCompletionResponse(
      id: readJsonValue(json, 'id') as String,
      object: readJsonValue(json, 'object') as String?,
      created: (readJsonValue(json, 'created') as num?)?.toInt(),
      model: readJsonValue(json, 'model') as String,
      choices: (readJsonValue(json, 'choices') as List<dynamic>)
          .map((e) => ChatCompletionChoice.fromJson(e as Map<String, dynamic>))
          .toList(),
      usage: readJsonValue(json, 'usage') == null
          ? null
          : ChatCompletionUsage.fromJson(
              readJsonValue(json, 'usage') as Map<String, dynamic>),
      searchResults: (readJsonValue(json, 'searchResults') as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      systemFingerprint: readJsonValue(json, 'systemFingerprint') as String?,
      cusText: json['cusText'] as String?,
    );

Map<String, dynamic> _$ChatCompletionResponseToJson(
        ChatCompletionResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'object': instance.object,
      'created': instance.created,
      'model': instance.model,
      'choices': instance.choices.map((e) => e.toJson()).toList(),
      'usage': instance.usage?.toJson(),
      'searchResults': instance.searchResults,
      'systemFingerprint': instance.systemFingerprint,
      'cusText': instance.cusText,
    };

ChatCompletionChoice _$ChatCompletionChoiceFromJson(
        Map<String, dynamic> json) =>
    ChatCompletionChoice(
      index: (readJsonValue(json, 'index') as num?)?.toInt(),
      message: readJsonValue(json, 'message') as Map<String, dynamic>?,
      delta: readJsonValue(json, 'delta') as Map<String, dynamic>?,
      finishReason: readJsonValue(json, 'finishReason') as String?,
      toolCalls: (readJsonValue(json, 'toolCalls') as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );

Map<String, dynamic> _$ChatCompletionChoiceToJson(
        ChatCompletionChoice instance) =>
    <String, dynamic>{
      'index': instance.index,
      'message': instance.message,
      'delta': instance.delta,
      'finishReason': instance.finishReason,
      'toolCalls': instance.toolCalls,
    };

ChatCompletionUsage _$ChatCompletionUsageFromJson(Map<String, dynamic> json) =>
    ChatCompletionUsage(
      promptTokens: (readJsonValue(json, 'promptTokens') as num).toInt(),
      completionTokens:
          (readJsonValue(json, 'completionTokens') as num).toInt(),
      totalTokens: (readJsonValue(json, 'totalTokens') as num).toInt(),
    );

Map<String, dynamic> _$ChatCompletionUsageToJson(
        ChatCompletionUsage instance) =>
    <String, dynamic>{
      'promptTokens': instance.promptTokens,
      'completionTokens': instance.completionTokens,
      'totalTokens': instance.totalTokens,
    };
