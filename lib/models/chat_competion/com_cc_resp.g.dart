// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'com_cc_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComCCResp _$ComCCRespFromJson(Map<String, dynamic> json) => ComCCResp(
      id: readJsonValue(json, 'id') as String?,
      object: readJsonValue(json, 'object') as String?,
      created: (readJsonValue(json, 'created') as num?)?.toInt(),
      model: readJsonValue(json, 'model') as String?,
      choices: (readJsonValue(json, 'choices') as List<dynamic>?)
          ?.map((e) => CCChoice.fromJson(e as Map<String, dynamic>))
          .toList(),
      usage: readJsonValue(json, 'usage') == null
          ? null
          : CCUsage.fromJson(
              readJsonValue(json, 'usage') as Map<String, dynamic>),
      content: readJsonValue(json, 'content') as String?,
      lastOne: readJsonValue(json, 'lastOne') as bool?,
      sentenceId: (readJsonValue(json, 'sentenceId') as num?)?.toInt(),
      isEnd: readJsonValue(json, 'isEnd') as bool?,
      isTruncated: readJsonValue(json, 'isTruncated') as bool?,
      result: readJsonValue(json, 'result') as String?,
      needClearHistory: readJsonValue(json, 'needClearHistory') as bool?,
      banRound: (readJsonValue(json, 'banRound') as num?)?.toInt(),
      errorCode: (readJsonValue(json, 'errorCode') as num?)?.toInt(),
      errorMsg: readJsonValue(json, 'errorMsg') as String?,
      code: json['code'],
      message: json['message'] as String?,
      sid: json['sid'] as String?,
      tencentErrorMsg: json['Error'] == null
          ? null
          : TencentError.fromJson(json['Error'] as Map<String, dynamic>),
      note: json['Note'] as String?,
      requestId: json['RequestId'] as String?,
      webSearch: (json['web_search'] as List<dynamic>?)
          ?.map((e) => GLMWebSearch.fromJson(e as Map<String, dynamic>))
          .toList(),
      contentFilter: (json['content_filter'] as List<dynamic>?)
          ?.map((e) => ZhipuContentFilter.fromJson(e as Map<String, dynamic>))
          .toList(),
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
      'sentenceId': instance.sentenceId,
      'isEnd': instance.isEnd,
      'isTruncated': instance.isTruncated,
      'result': instance.result,
      'needClearHistory': instance.needClearHistory,
      'banRound': instance.banRound,
      'errorCode': instance.errorCode,
      'errorMsg': instance.errorMsg,
      'code': instance.code,
      'message': instance.message,
      'sid': instance.sid,
      'Error': instance.tencentErrorMsg?.toJson(),
      'Note': instance.note,
      'RequestId': instance.requestId,
      'web_search': instance.webSearch?.map((e) => e.toJson()).toList(),
      'content_filter': instance.contentFilter?.map((e) => e.toJson()).toList(),
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

GLMWebSearch _$GLMWebSearchFromJson(Map<String, dynamic> json) => GLMWebSearch(
      icon: json['icon'] as String?,
      title: json['title'] as String?,
      link: json['link'] as String?,
      media: json['media'] as String?,
      content: json['content'] as String?,
    );

Map<String, dynamic> _$GLMWebSearchToJson(GLMWebSearch instance) =>
    <String, dynamic>{
      'icon': instance.icon,
      'title': instance.title,
      'link': instance.link,
      'media': instance.media,
      'content': instance.content,
    };

ZhipuContentFilter _$ZhipuContentFilterFromJson(Map<String, dynamic> json) =>
    ZhipuContentFilter(
      role: json['role'] as String?,
      level: (json['level'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ZhipuContentFilterToJson(ZhipuContentFilter instance) =>
    <String, dynamic>{
      'role': instance.role,
      'level': instance.level,
    };

CCUsage _$CCUsageFromJson(Map<String, dynamic> json) => CCUsage(
      (readJsonValue(json, 'completionTokens') as num).toInt(),
      (readJsonValue(json, 'promptTokens') as num).toInt(),
      (readJsonValue(json, 'totalTokens') as num).toInt(),
    );

Map<String, dynamic> _$CCUsageToJson(CCUsage instance) => <String, dynamic>{
      'completionTokens': instance.completionTokens,
      'promptTokens': instance.promptTokens,
      'totalTokens': instance.totalTokens,
    };

CCChoice _$CCChoiceFromJson(Map<String, dynamic> json) => CCChoice(
      (json['index'] as num?)?.toInt(),
      readJsonValue(json, 'message') == null
          ? null
          : CCMessage.fromJson(
              readJsonValue(json, 'message') as Map<String, dynamic>),
      readJsonValue(json, 'delta') == null
          ? null
          : CCDelta.fromJson(
              readJsonValue(json, 'delta') as Map<String, dynamic>),
      readJsonValue(json, 'finishReason') as String?,
    );

Map<String, dynamic> _$CCChoiceToJson(CCChoice instance) => <String, dynamic>{
      'index': instance.index,
      'message': instance.message?.toJson(),
      'delta': instance.delta?.toJson(),
      'finishReason': instance.finishReason,
    };

CCMessage _$CCMessageFromJson(Map<String, dynamic> json) => CCMessage(
      role: readJsonValue(json, 'role') as String,
      content: readJsonValue(json, 'content'),
    );

Map<String, dynamic> _$CCMessageToJson(CCMessage instance) => <String, dynamic>{
      'role': instance.role,
      'content': instance.content,
    };

CCDelta _$CCDeltaFromJson(Map<String, dynamic> json) => CCDelta(
      readJsonValue(json, 'role') as String?,
      readJsonValue(json, 'content') as String?,
      (json['quote'] as List<dynamic>?)
          ?.map((e) => CCQuote.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CCDeltaToJson(CCDelta instance) => <String, dynamic>{
      'role': instance.role,
      'content': instance.content,
      'quote': instance.quote?.map((e) => e.toJson()).toList(),
    };
