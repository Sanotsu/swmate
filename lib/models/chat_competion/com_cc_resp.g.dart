// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'com_cc_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComCCResp _$ComCCRespFromJson(Map<String, dynamic> json) => ComCCResp(
      id: json['id'] as String?,
      object: json['object'] as String?,
      created: (json['created'] as num?)?.toInt(),
      model: json['model'] as String?,
      choices: (json['choices'] as List<dynamic>?)
          ?.map((e) => CCChoice.fromJson(e as Map<String, dynamic>))
          .toList(),
      usage: json['usage'] == null
          ? null
          : CCUsage.fromJson(json['usage'] as Map<String, dynamic>),
      content: json['content'] as String?,
      lastOne: json['lastOne'] as bool?,
      sentenceId: (json['sentence_id'] as num?)?.toInt(),
      isEnd: json['is_end'] as bool?,
      isTruncated: json['is_truncated'] as bool?,
      result: json['result'] as String?,
      needClearHistory: json['need_clear_history'] as bool?,
      banRound: (json['ban_round'] as num?)?.toInt(),
      errorCode: (json['error_code'] as num?)?.toInt(),
      errorMsg: json['error_msg'] as String?,
      cusText: json['cusText'] as String?,
    );

Map<String, dynamic> _$ComCCRespToJson(ComCCResp instance) => <String, dynamic>{
      'id': instance.id,
      'object': instance.object,
      'created': instance.created,
      'model': instance.model,
      'choices': instance.choices?.map((e) => e.toJson()).toList(),
      'usage': instance.usage?.toJson(),
      'content': instance.content,
      'lastOne': instance.lastOne,
      'cusText': instance.cusText,
      'sentence_id': instance.sentenceId,
      'is_end': instance.isEnd,
      'is_truncated': instance.isTruncated,
      'result': instance.result,
      'need_clear_history': instance.needClearHistory,
      'ban_round': instance.banRound,
      'error_code': instance.errorCode,
      'error_msg': instance.errorMsg,
    };

CCQuote _$CCQuoteFromJson(Map<String, dynamic> json) => CCQuote(
      num: (json['num'] as num?)?.toInt(),
      url: json['url'] as String?,
      title: json['title'] as String?,
    );

Map<String, dynamic> _$CCQuoteToJson(CCQuote instance) => <String, dynamic>{
      'num': instance.num,
      'url': instance.url,
      'title': instance.title,
    };

CCUsage _$CCUsageFromJson(Map<String, dynamic> json) => CCUsage(
      (json['completion_tokens'] as num).toInt(),
      (json['prompt_tokens'] as num).toInt(),
      (json['total_tokens'] as num).toInt(),
    );

Map<String, dynamic> _$CCUsageToJson(CCUsage instance) => <String, dynamic>{
      'completion_tokens': instance.completionTokens,
      'prompt_tokens': instance.promptTokens,
      'total_tokens': instance.totalTokens,
    };

CCChoice _$CCChoiceFromJson(Map<String, dynamic> json) => CCChoice(
      (json['index'] as num).toInt(),
      json['message'] == null
          ? null
          : CCMessage.fromJson(json['message'] as Map<String, dynamic>),
      json['delta'] == null
          ? null
          : CCDelta.fromJson(json['delta'] as Map<String, dynamic>),
      json['finish_reason'] as String?,
    );

Map<String, dynamic> _$CCChoiceToJson(CCChoice instance) => <String, dynamic>{
      'index': instance.index,
      'message': instance.message?.toJson(),
      'delta': instance.delta?.toJson(),
      'finish_reason': instance.finishReason,
    };

CCMessage _$CCMessageFromJson(Map<String, dynamic> json) => CCMessage(
      role: json['role'] as String,
      content: json['content'],
    );

Map<String, dynamic> _$CCMessageToJson(CCMessage instance) => <String, dynamic>{
      'role': instance.role,
      'content': instance.content,
    };

CCDelta _$CCDeltaFromJson(Map<String, dynamic> json) => CCDelta(
      json['role'] as String?,
      json['content'] as String?,
      (json['quote'] as List<dynamic>?)
          ?.map((e) => CCQuote.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CCDeltaToJson(CCDelta instance) => <String, dynamic>{
      'role': instance.role,
      'content': instance.content,
      'quote': instance.quote?.map((e) => e.toJson()).toList(),
    };
