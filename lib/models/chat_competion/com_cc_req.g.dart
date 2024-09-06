// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'com_cc_req.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComCCReq _$ComCCReqFromJson(Map<String, dynamic> json) => ComCCReq(
      model: json['model'] as String?,
      messages: (json['messages'] as List<dynamic>?)
          ?.map((e) => CCMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      stream: json['stream'] as bool? ?? false,
      maxTokens: (json['max_tokens'] as num?)?.toInt(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      topP: (json['top_p'] as num?)?.toDouble(),
    )
      ..tools = (json['tools'] as List<dynamic>?)
          ?.map((e) => CCTool.fromJson(e as Map<String, dynamic>))
          .toList()
      ..toolChoice = json['tool_choice'] as String?
      ..n = (json['n'] as num?)?.toInt()
      ..topK = (json['top_k'] as num?)?.toDouble()
      ..frequencyPenalty = (json['frequency_penalty'] as num?)?.toDouble()
      ..stop =
          (json['stop'] as List<dynamic>?)?.map((e) => e as String).toList()
      ..system = json['system'] as String?
      ..userId = json['user_id'] as String?
      ..prompt = json['prompt'] as String?
      ..image = json['image'] as String?
      ..penaltyScore = (json['penalty_score'] as num?)?.toDouble()
      ..maxOutputTokens = (json['max_output_tokens'] as num?)?.toInt()
      ..requestId = json['request_id'] as String?
      ..doSample = json['do_sample'] as bool?;

Map<String, dynamic> _$ComCCReqToJson(ComCCReq instance) => <String, dynamic>{
      'model': instance.model,
      'messages': instance.messages?.map((e) => e.toJson()).toList(),
      'tools': instance.tools?.map((e) => e.toJson()).toList(),
      'tool_choice': instance.toolChoice,
      'max_tokens': instance.maxTokens,
      'top_p': instance.topP,
      'temperature': instance.temperature,
      'stream': instance.stream,
      'n': instance.n,
      'top_k': instance.topK,
      'frequency_penalty': instance.frequencyPenalty,
      'stop': instance.stop,
      'system': instance.system,
      'user_id': instance.userId,
      'prompt': instance.prompt,
      'image': instance.image,
      'penalty_score': instance.penaltyScore,
      'max_output_tokens': instance.maxOutputTokens,
      'request_id': instance.requestId,
      'do_sample': instance.doSample,
    };

CCTool _$CCToolFromJson(Map<String, dynamic> json) => CCTool(
      json['type'] as String,
      function: json['function'] == null
          ? null
          : CCFunction.fromJson(json['function'] as Map<String, dynamic>),
      retrieval: json['retrieval'] == null
          ? null
          : CCRetrieval.fromJson(json['retrieval'] as Map<String, dynamic>),
      webSearch: json['web_search'] == null
          ? null
          : CCWebSearch.fromJson(json['web_search'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CCToolToJson(CCTool instance) => <String, dynamic>{
      'type': instance.type,
      'function': instance.function?.toJson(),
      'retrieval': instance.retrieval?.toJson(),
      'web_search': instance.webSearch?.toJson(),
    };

CCFunction _$CCFunctionFromJson(Map<String, dynamic> json) => CCFunction(
      json['name'] as String,
      description: json['description'] as String?,
      parameters: json['parameters'] as String?,
    );

Map<String, dynamic> _$CCFunctionToJson(CCFunction instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'parameters': instance.parameters,
    };

CCRetrieval _$CCRetrievalFromJson(Map<String, dynamic> json) => CCRetrieval(
      json['knowledge_id'] as String,
      promptTemplate: json['prompt_template'] as String?,
    );

Map<String, dynamic> _$CCRetrievalToJson(CCRetrieval instance) =>
    <String, dynamic>{
      'knowledge_id': instance.knowledgeId,
      'prompt_template': instance.promptTemplate,
    };

CCWebSearch _$CCWebSearchFromJson(Map<String, dynamic> json) => CCWebSearch(
      enable: json['enable'] as bool?,
      searchQuery: json['search_query'] as String?,
      searchResult: json['search_result'] as bool?,
    );

Map<String, dynamic> _$CCWebSearchToJson(CCWebSearch instance) =>
    <String, dynamic>{
      'enable': instance.enable,
      'search_query': instance.searchQuery,
      'search_result': instance.searchResult,
    };
