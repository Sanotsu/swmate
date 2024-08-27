import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../mapper_utils.dart';

part 'com_cc_resp.g.dart';

///
/// 【以零一万物的出参为基准的响应类】
///   siliconflow 完全适配
///
/// 正常结构:
/// {
/// id、object、created、model都有
/// 同步时:
/// choices [{
///      "index": 0,
///      "message": {
///        "role": "assistant",
///        "content": "Hello! My name is Yi,?"
///      },
///      "finish_reason": "stop"
///    }]
/// 流式时：
/// "choices":[{"delta":{"role":"assistant"},"index":0}]
/// "choices":[{"delta":{"content":"Hello"},"index":0}],
/// "choices":[{"delta":{},"index":0,"finish_reason":"stop"}],
///  额外还有 "content":"Hello","lastOne":false
///
/// 同步时usage直接有，流式时只有最后一个choices有
/// "usage":{"completion_tokens":64,"prompt_tokens":17,"total_tokens":81},
/// }
///
@JsonSerializable(explicitToJson: true)
class ComCCResp {
  // 这几个栏位虽然正常响应时都有，但流式响应时最后一条[DONE]就没有
  @JsonKey(readValue: readJsonValue)
  String? id;

  // 回包类型 chat.completion：多轮对话返回
  @JsonKey(readValue: readJsonValue)
  String? object;

  // 时间戳
  @JsonKey(readValue: readJsonValue)
  int? created;

  @JsonKey(readValue: readJsonValue)
  String? model;

  @JsonKey(readValue: readJsonValue)
  List<CCChoice>? choices;

  @JsonKey(readValue: readJsonValue)
  CCUsage? usage;
  // 流式有，同步没有(chioces中是每次输出的内容，content是叠加后的内容)

  @JsonKey(readValue: readJsonValue)
  String? content;

  // @JsonKey(name: 'lastOne')
  @JsonKey(readValue: readJsonValue)
  bool? lastOne;

  /// 自定义的返回文本
  String cusText;

  /// 【百度】的有一些自己的格式
  // 表示当前子句的序号。只有在流式接口模式下会返回该字段
  // @JsonKey(name: 'sentence_id')
  @JsonKey(readValue: readJsonValue)
  int? sentenceId;

  // 表示当前子句是否是最后一句。只有在流式接口模式下会返回该字段
  // @JsonKey(name: 'is_end')
  @JsonKey(readValue: readJsonValue)
  bool? isEnd;

  // 当前生成的结果是否被截断
  // @JsonKey(name: 'is_truncated')
  @JsonKey(readValue: readJsonValue)
  bool? isTruncated;

  // 对话返回结果
  // @JsonKey(name: 'result')
  @JsonKey(readValue: readJsonValue)
  String? result;

  // 表示用户输入是否存在安全风险，是否关闭当前会话，清理历史会话信息。
  // true：是，表示用户输入存在安全风险，建议关闭当前会话，清理历史会话信息。
  // false：否，表示用户输入无安全风险
  // @JsonKey(name: 'need_clear_history')
  @JsonKey(readValue: readJsonValue)
  bool? needClearHistory;

  // 当need_clear_history为true时，此字段会告知第几轮对话有敏感信息，
  // 如果是当前问题，ban_round=-1
  // @JsonKey(name: 'ban_round')
  @JsonKey(readValue: readJsonValue)
  int? banRound;

  // 错误码
  // @JsonKey(name: 'error_code')
  @JsonKey(readValue: readJsonValue)
  int? errorCode;

  // 错误描述信息，帮助理解和解决发生的错误
  // @JsonKey(name: 'error_msg')
  @JsonKey(readValue: readJsonValue)
  String? errorMsg;

  /// 讯飞云的错误码等稍微不同
  int? code;
  String? message;
  // 会话的唯一id，用于讯飞技术人员查询服务端会话日志使用,出现调用错误时建议留存该字段
  String? sid;

  /// 腾讯的错误还封装了一层(ModerationLevel、SearchInfo就匹配了)
  @JsonKey(name: 'ErrorMsg')
  TencentError? tencentErrorMsg;

  // 免责声明。
  @JsonKey(name: 'Note')
  String? note;

  // 唯一请求 ID，由服务端生成，每次请求都会返回
  @JsonKey(name: 'RequestId')
  String? requestId;

  /// 2024-08-27 智谱GLM引用的，还会单独返回网页搜索相关信息
  @JsonKey(name: 'web_search')
  List<GLMWebSearch>? webSearch;

  // 返回内容安全的相关信息。
  @JsonKey(name: 'content_filter')
  List<GLMContentFilter>? contentFilter;

  /// 2024-08-13 因为响应体目前只是用来接收API响应，所以暂时把所有平台的栏位放在一起即可
  ComCCResp({
    this.id,
    this.object,
    this.created,
    this.model,
    this.choices,
    this.usage,
    this.content,
    this.lastOne,
    this.sentenceId,
    this.isEnd,
    this.isTruncated,
    this.result,
    this.needClearHistory,
    this.banRound,
    this.errorCode,
    this.errorMsg,
    this.code,
    this.message,
    this.sid,
    this.tencentErrorMsg,
    this.note,
    this.requestId,
    this.webSearch,
    this.contentFilter,
    String? cusText,
  }) : cusText = cusText ?? _generatecusText(choices, result);

  // 自定义的响应文本(比如流式返回最后是个[DONE]没法转型，但可以自行设定；而正常响应时可以从其他值中得到)
  static String _generatecusText(List<CCChoice>? choices, String? result) {
    // 非流式的
    if (choices != null && choices.isNotEmpty && choices[0].message != null) {
      return choices[0].message?.content ?? "";
    }
    // 流式的
    if (choices != null && choices.isNotEmpty && choices[0].delta != null) {
      return choices[0].delta?.content ?? "";
    }

    // 百度流式非流式都放在最外层的result里面，直接获取即可
    if (result != null) {
      return result;
    }

    return '';
  }

  // 百度的流式非流式都直接在最外面放的返回结果
  ComCCResp.baidu({
    this.id,
    this.object,
    this.created,
    this.sentenceId,
    this.isEnd,
    this.isTruncated,
    this.result,
    this.needClearHistory,
    this.banRound,
    this.usage,
    this.errorCode,
    this.errorMsg,
    String? cusText,
  }) : cusText = result ?? cusText ?? "";

  // 从字符串转
  factory ComCCResp.fromRawJson(String str) =>
      ComCCResp.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory ComCCResp.fromJson(Map<String, dynamic> srcJson) =>
      _$ComCCRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$ComCCRespToJson(this);
}

///
/// 如果模型支持实时搜索信息，返回值中会有quote引用字段属性
///
@JsonSerializable(explicitToJson: true)
class CCQuote {
  // 引用编号、地址、标题
  int? num;
  String? url;
  String? title;

  CCQuote({this.num, this.url, this.title});

  // 从字符串转
  factory CCQuote.fromRawJson(String str) => CCQuote.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory CCQuote.fromJson(Map<String, dynamic> srcJson) =>
      _$CCQuoteFromJson(srcJson);

  Map<String, dynamic> toJson() => _$CCQuoteToJson(this);

  // 2024-07-22 因为ChatMessage需要从json还原为CCQuote，所以需要对应的完整方法
  factory CCQuote.fromMap(Map<String, dynamic> map) {
    return CCQuote(
      num: map['num'] as int?,
      url: map['url'] as String?,
      title: map['title'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {'num': num, 'url': url, 'title': title};
  }

  @override
  String toString() {
    // 这个对话会被作为string存入数据库，然后再被读取转型为CCQuote。
    // 所以需要是个完整的json字符串，一般fromMap时可以处理
    return '''
    {
     "num": "$num", 
     "url": "$url", 
     "title": "$title"
    }
    ''';
  }
}

/// GLM 查询如果要显示网页列表，就返回这个类
@JsonSerializable(explicitToJson: true)
class GLMWebSearch {
  // 来源网站的icon
  String? icon;
  // 搜索结果的标题
  String? title;
  // 搜索结果的网页链接
  String? link;
  // 搜索结果网页来源的名称
  String? media;
  // 从搜索结果网页中引用的文本内容
  String? content;

  GLMWebSearch({
    this.icon,
    this.title,
    this.link,
    this.media,
    this.content,
  });

  // 从字符串转
  factory GLMWebSearch.fromRawJson(String str) =>
      GLMWebSearch.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory GLMWebSearch.fromJson(Map<String, dynamic> srcJson) =>
      _$GLMWebSearchFromJson(srcJson);

  Map<String, dynamic> toJson() => _$GLMWebSearchToJson(this);

  factory GLMWebSearch.fromMap(Map<String, dynamic> map) {
    return GLMWebSearch(
      icon: map['icon'] as String?,
      title: map['title'] as String?,
      link: map['link'] as String?,
      media: map['media'] as String?,
      content: map['content'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'icon': icon,
      'title': title,
      'link': link,
      'media': media,
      'content': content,
    };
  }

  @override
  String toString() {
    // 这个对话会被作为string存入数据库，然后再被读取转型为CCQuote。
    // 所以需要是个完整的json字符串，一般fromMap时可以处理
    return '''
    {
     "icon": "$icon", 
     "title": "$title",
     "link": "$link", 
     "media": "$media", 
     "content": "$content"
    }
    ''';
  }
}

/// GLM 返回内容安全的相关信息。
@JsonSerializable(explicitToJson: true)
class GLMContentFilter {
  // 安全生效环节，包括 role = assistant 模型推理，
  // role = user 用户输入，role = history 历史上下文，role = search 联网搜索
  String? role;
  // 严重程度 level 0-3，level 0表示最严重，3表示轻微
  int? level;

  GLMContentFilter({
    this.role,
    this.level,
  });

  // 从字符串转
  factory GLMContentFilter.fromRawJson(String str) =>
      GLMContentFilter.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory GLMContentFilter.fromJson(Map<String, dynamic> srcJson) =>
      _$GLMContentFilterFromJson(srcJson);

  Map<String, dynamic> toJson() => _$GLMContentFilterToJson(this);
}

///
/// token耗费默认这几个字段都是必填
///
@JsonSerializable(explicitToJson: true)
class CCUsage {
  // 内容生成的 tokens 数量。
  // @JsonKey(name: 'completion_tokens')
  @JsonKey(readValue: readJsonValue)
  int completionTokens;
  // prompt 使用的 tokens 数量。
  // @JsonKey(name: 'prompt_tokens')
  @JsonKey(readValue: readJsonValue)
  int promptTokens;
  // 总 tokens 用量。
  // @JsonKey(name: 'total_tokens')
  @JsonKey(readValue: readJsonValue)
  int totalTokens;

  CCUsage(
    this.completionTokens,
    this.promptTokens,
    this.totalTokens,
  );

  // 从字符串转
  factory CCUsage.fromRawJson(String str) => CCUsage.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory CCUsage.fromJson(Map<String, dynamic> srcJson) =>
      _$CCUsageFromJson(srcJson);

  Map<String, dynamic> toJson() => _$CCUsageToJson(this);
}

///
/// 获取响应的正文大概就在这里了
/// 流式的从delta里取，同步的从message取
///
@JsonSerializable(explicitToJson: true)
class CCChoice {
  // 模型生成结果的序号。0 表示第一个结果。
  @JsonKey(name: 'index')
  int? index;

  // 同步时从这里取
  // @JsonKey(name: 'message')
  @JsonKey(readValue: readJsonValue)
  CCMessage? message;

  // 流式时从这里取
  // @JsonKey(name: 'delta')
  @JsonKey(readValue: readJsonValue)
  CCDelta? delta;

  // 结束原因
  //  stop：表示模型返回了完整的输出。
  //  length：由于生成长度过长导致停止生成内容.
  //  以 content_filter 开头的表示安全过滤的结果。
  // 流式的时候结束原因在delta里面
  //  此时可能未传，也可能为null
  // @JsonKey(name: 'finish_reason')
  @JsonKey(readValue: readJsonValue)
  String? finishReason;

  CCChoice(
    this.index,
    this.message,
    this.delta,
    this.finishReason,
  );

  // 从字符串转
  factory CCChoice.fromRawJson(String str) =>
      CCChoice.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory CCChoice.fromJson(Map<String, dynamic> srcJson) =>
      _$CCChoiceFromJson(srcJson);

  Map<String, dynamic> toJson() => _$CCChoiceToJson(this);
}

///
/// 通用的消息类(请求和响应时都会用到)
///
@JsonSerializable(explicitToJson: true)
class CCMessage {
  // 消息的发出者
  // 零一万物有: system, user, assistant, tool
  // @JsonKey(name: 'role')
  @JsonKey(readValue: readJsonValue)
  String role;

  // 根据不同情况，content类型不一样[String,Array],Array中的结构体也不一样
  // 调用工具函数时，此时content结构类似:
  //  "content" : "{"location": "San Francisco", "temperature": "172", "unit": null}"
  // 同样还有图片理解时content结构也有变化
  //  "content": [
  //       {
  //         "type": "image_url",
  //         "image_url": { "url": "url地址或者base64字符串"}
  //       },
  //       {
  //         "type": "text",
  //         "text": "请详细描述一下这张图片。"
  //       }
  //     ]
  // 【所以不能固定为String，vsion时就会报错】
  // @JsonKey(name: 'content')
  @JsonKey(readValue: readJsonValue)
  dynamic content;

  // 零一万物中“工具消息”时，还需要工具调用id
  // @JsonKey(name: 'tool_call_id')
  // String? toolCallId;

  CCMessage({
    required this.role,
    required this.content,
    // this.toolCallId,
  });

  // 从字符串转
  factory CCMessage.fromRawJson(String str) =>
      CCMessage.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory CCMessage.fromJson(Map<String, dynamic> srcJson) =>
      _$CCMessageFromJson(srcJson);

  Map<String, dynamic> toJson() => _$CCMessageToJson(this);
}

///
/// delta和message是否类似，不过role和content都可选
/// 第一条只有role，中间的只有content，最后一条两者都没有，就只`{}`
///
@JsonSerializable(explicitToJson: true)
class CCDelta {
  // @JsonKey(name: 'role')
  @JsonKey(readValue: readJsonValue)
  String? role;

  // @JsonKey(name: 'content')
  @JsonKey(readValue: readJsonValue)
  String? content;

  // 如果使用RAG(检索增强生成)模型，会有引用的返回
  @JsonKey(name: 'quote')
  List<CCQuote>? quote;

  CCDelta(
    this.role,
    this.content,
    this.quote,
  );

  // 从字符串转
  factory CCDelta.fromRawJson(String str) => CCDelta.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory CCDelta.fromJson(Map<String, dynamic> srcJson) =>
      _$CCDeltaFromJson(srcJson);

  Map<String, dynamic> toJson() => _$CCDeltaToJson(this);
}

class TencentError {
  String code;
  String message;

  TencentError({required this.code, required this.message});

  factory TencentError.fromJson(Map<String, dynamic> json) =>
      TencentError(code: json["Code"], message: json["Message"]);

  Map<String, dynamic> toJson() => {"Code": code, "Message": message};
}
