import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

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
  String? id;
  String? object;
  int? created;
  String? model;
  List<CCChoice>? choices;
  CCUsage? usage;
  // 流式有，同步没有
  String? content;
  @JsonKey(name: 'lastOne')
  bool? lastOne;

  // 自定义的返回文本
  String cusText;

  ComCCResp({
    this.id,
    this.object,
    this.created,
    this.model,
    this.choices,
    this.usage,
    this.content,
    this.lastOne,
    String? cusText,
  }) : cusText = cusText ?? _generatecusText(choices);

  // 自定义的响应文本(比如流式返回最后是个[DONE]没法转型，但可以自行设定；而正常响应时可以从其他值中得到)
  static String _generatecusText(List<CCChoice>? choices) {
    // 非流式的
    if (choices != null && choices.isNotEmpty && choices[0].message != null) {
      return choices[0].message?.content ?? "";
    }
    // 流式的
    if (choices != null && choices.isNotEmpty && choices[0].delta != null) {
      return choices[0].delta?.content ?? "";
    }
    return '';
  }

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

///
/// token耗费默认这几个字段都是必填
///
@JsonSerializable(explicitToJson: true)
class CCUsage {
  // 内容生成的 tokens 数量。
  @JsonKey(name: 'completion_tokens')
  int completionTokens;
  // prompt 使用的 tokens 数量。
  @JsonKey(name: 'prompt_tokens')
  int promptTokens;
  // 总 tokens 用量。
  @JsonKey(name: 'total_tokens')
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
  int index;

  // 同步时从这里取
  @JsonKey(name: 'message')
  CCMessage? message;

  // 流式时从这里取
  @JsonKey(name: 'delta')
  CCDelta? delta;

  // 如果使用RAG(检索增强生成)模型，会有引用的返回
  @JsonKey(name: 'quote')
  List<CCQuote>? quote;

  // 结束原因
  //  stop：表示模型返回了完整的输出。
  //  length：由于生成长度过长导致停止生成内容.
  //  以 content_filter 开头的表示安全过滤的结果。
  // 流式的时候结束原因在delta里面
  //  此时可能未传，也可能为null
  @JsonKey(name: 'finish_reason')
  String? finishReason;

  CCChoice(
    this.index,
    this.message,
    this.delta,
    this.quote,
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
  @JsonKey(name: 'role')
  String role;

  @JsonKey(name: 'content')
  String content;

  // 零一万物中“工具消息”时，还需要工具调用id
  // 此时content结构类似:"content" : "{"location": "San Francisco", "temperature": "172", "unit": null}"
  // 同样还有图片理解时content结构也有变化
  //  "content": [
  //       {
  //         "type": "image_url",
  //         "image_url": {
  //           "url": "url地址或者base64字符串"
  //         }
  //       },
  //       {
  //         "type": "text",
  //         "text": "请详细描述一下这张图片。"
  //       }
  //     ]
  // 就不过多处理，直接拼成字符串传入
  @JsonKey(name: 'tool_call_id')
  String? toolCallId;

  CCMessage({
    required this.role,
    required this.content,
    this.toolCallId,
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
  @JsonKey(name: 'role')
  String? role;

  @JsonKey(name: 'content')
  String? content;

  CCDelta(
    this.role,
    this.content,
  );

  // 从字符串转
  factory CCDelta.fromRawJson(String str) => CCDelta.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory CCDelta.fromJson(Map<String, dynamic> srcJson) =>
      _$CCDeltaFromJson(srcJson);

  Map<String, dynamic> toJson() => _$CCDeltaToJson(this);
}
