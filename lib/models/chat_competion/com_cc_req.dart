import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import 'com_cc_resp.dart';

part 'com_cc_req.g.dart';

/// 2024-08-17
/// 针对腾讯混元做一点修改.因为只用到了hunyuan-lite一个,所以,只处理几个必填参数就好
/// 混元也支持的其他功能,就暂时不管了
/// 【其实请求req可以不动的，主要是resp，主要改一改toJson方法支持腾讯的借口即可，这里做留存示例】

///
/// 【以零一万物的出参为基准的响应类】
///   siliconflow 完全适配
///  2024-08-12 参数是各种各样的参数，但有些是不同不太自己特有的，默认构造函数就用open ai的参数或者尽量精简的参数？？？
///
@JsonSerializable(explicitToJson: true)
class ComCCReq {
  // 选择的模型名
  @JsonKey(name: 'model')
  String? model;
  // 对话的消息体
  @JsonKey(name: 'messages')
  List<CCMessage>? messages;

  // 模型可调用的工具列表。目前只支持函数作为工具。
  @JsonKey(name: 'tools')
  List<CCTool>? tools;

  // 控制模型是否会调用某个或某些工具。
  //  none 表示模型不会调用任何工具，而是以文字形式进行回复。
  //  auto 表示模型可选择以文本进行回复或者调用一个或多个工具。
  //  在调用时也可以通过将此字段设置为 required 或  {"type": "function", "function": {"name": "some_function"} }
  //  来更强的引导模型使用工具。
  // 2024-08-09 暂时不支持传入格式化的对象(是对象的也转为json字符串)
  // 2024-08-27 GLM4 仅当工具类型为function时补充。默认为auto，当前仅支持auto
  @JsonKey(name: 'tool_choice')
  String? toolChoice;

  // 指定模型在生成内容时token的最大数量，但不保证每次都会产生到这个数量。
  @JsonKey(name: 'max_tokens')
  int? maxTokens;

  // 控制生成结果的随机性。数值越小，随机性越弱；数值越大，随机性越强。
  @JsonKey(name: 'top_p')
  double? topP;

  // 控制生成结果的发散性和集中性。数值越小，越集中；数值越大，越发散。
  @JsonKey(name: 'temperature')
  double? temperature;

  // 是否获取流式输出。
  @JsonKey(name: 'stream')
  bool? stream;

  // 2024-09-13 阿里云流式输出时，需要启用此栏位才能显示token消耗
  @JsonKey(name: 'stream_options')
  StreamOption? streamOptions;

  // aliyun 生成时使用的随机数种子，用于控制模型生成内容的随机性。seed支持无符号64位整数。
  @JsonKey(name: 'seed')
  int? seed;

  // 用户控制模型生成时整个序列中的重复度。
  // 提高presence_penalty时可以降低模型生成的重复度，取值范围[-2.0, 2.0]。
  @JsonKey(name: 'presence_penalty')
  double? presencePenalty;

  /// siliconflow 有其他几个参数
  // 生成时返回的数量(可能是文生图之类的返回的数量？)
  int? n;
  @JsonKey(name: 'top_k')
  double? topK;
  @JsonKey(name: 'frequency_penalty')
  double? frequencyPenalty;
  // 将截断（停止）推理文本输出的字符串序列列表(大概意思是遇到这些字符串就停止文本输出)。
  List<String>? stop;

  /// 百度的system放在外面，不是在message中(也有stop)
  // 模型人设，主要用于人设设定，例如：你是xxx公司制作的AI助手，
  //    说明：（1）message中的content总长度和system字段总内容不能超过24000个字符，
  //    且不能超过6144 tokens
  String? system;

  // 表示最终用户的唯一标识符，可以监视和检测滥用行为，防止接口恶意调用
  @JsonKey(name: 'user_id')
  String? userId;
  // 百度的fuyu8b也是类似的参数，但传入的不支持对话，是只有提示词和图片base64
  @JsonKey(name: 'prompt')
  String? prompt;
  @JsonKey(name: 'image')
  String? image;

  // 通过对已生成的token增加惩罚，减少重复生成的现象。
  //  说明：（1）值越大表示惩罚越大。（2）默认1.0，取值范围：[1.0, 2.0]。
  @JsonKey(name: 'penalty_score')
  double? penaltyScore;

  // 指定模型最大输出token数，范围[2, 2048]
  @JsonKey(name: 'max_output_tokens')
  int? maxOutputTokens;

  /// 智谱AI在上面没有的还有额外的参数
  // 由用户端传参，需保证唯一性；用于区分每次请求的唯一标识，用户端不传时平台会默认生成。
  @JsonKey(name: 'request_id')
  String? requestId;

  // do_sample 为 true 时启用采样策略，
  // do_sample 为 false 时采样策略 temperature、top_p 将不生效。默认值为 true。
  @JsonKey(name: 'do_sample')
  bool? doSample;

  // 默认构造函数就少量主要参数
  ComCCReq({
    this.model,
    this.messages,
    this.stream = false,
    this.maxTokens,
    this.temperature,
    this.topP,
  })  : topK = null,
        frequencyPenalty = null,
        n = null,
        tools = null,
        toolChoice = null;

  // 命名构造函数(各自完整的参数，排除其他平台的参数)
  ComCCReq.siliconflow({
    this.model,
    this.messages,
    this.stream = false,
    this.maxTokens,
    this.stop,
    this.temperature,
    this.topP,
    this.topK,
    this.frequencyPenalty,
    this.n,
  })  : tools = null,
        toolChoice = null;

  ComCCReq.lingyiwanwu({
    this.model,
    this.messages,
    this.tools,
    this.toolChoice,
    this.maxTokens,
    this.topP,
    this.temperature,
    this.stream = false,
  })  : n = null,
        topK = null,
        frequencyPenalty = null,
        stop = null;

  ComCCReq.baidu({
    this.messages,
    this.stream = false,
    this.temperature,
    this.topK,
    this.topP,
    this.penaltyScore,
    this.system,
    this.stop,
    this.maxOutputTokens,
    this.userId,
  });

  ComCCReq.baiduFuyu8B({
    this.prompt,
    this.image,
    this.stream = false,
    this.temperature,
    this.topK,
    this.topP,
    this.penaltyScore,
    this.stop,
    this.userId,
  });

  ComCCReq.xfyun({
    this.model,
    this.messages,
    this.stream = false,
    this.temperature,
    this.tools,
    this.toolChoice = "auto",
    this.maxTokens,
    this.topK,
  });

  // 2024-08-17 只用到小小lite，就最简单了
  ComCCReq.hunyuan({
    this.model,
    this.messages,
    this.stream = false,
  });

  ComCCReq.glm({
    this.model,
    this.messages,
    this.requestId,
    this.doSample,
    this.stream = false,
    this.temperature,
    this.topP,
    this.maxTokens,
    this.stop,
    this.tools,
    this.toolChoice = "auto",
    this.userId,
  });

  ComCCReq.aliyun({
    this.model,
    this.messages,
    this.topP,
    this.maxTokens,
    this.temperature,
    this.presencePenalty,
    this.seed,
    this.stream = false,
    this.stop,
    this.streamOptions,
  });

  // 从字符串转
  factory ComCCReq.fromRawJson(String str) =>
      ComCCReq.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory ComCCReq.fromJson(Map<String, dynamic> srcJson) =>
      _$ComCCReqFromJson(srcJson);

  // 2024-08-12 默认生成的tojsn把所有栏位都加上，不同的平台有特殊的栏位，可能会出现参数异常
  // 【不过实际测下来:零一万物和siliconflow传入其他参数并没有报错】
  Map<String, dynamic> toFullJson() => _$ComCCReqToJson(this);

  // 自定义tojson方法，参数为null的就不加到json中
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (model != null) json['model'] = model;
    if (messages != null) {
      json['messages'] = messages?.map((e) => e.toJson()).toList();
    }
    if (tools != null) json['tools'] = tools?.map((e) => e.toJson()).toList();
    if (toolChoice != null) json['tool_choice'] = toolChoice;
    if (maxTokens != null) json['max_tokens'] = maxTokens;
    if (topP != null) json['top_p'] = topP;
    if (temperature != null) json['temperature'] = temperature;
    if (stream != null) json['stream'] = stream;
    if (n != null) json['n'] = n;
    if (topK != null) json['top_k'] = topK;
    if (frequencyPenalty != null) json['frequency_penalty'] = frequencyPenalty;
    if (stop != null) json['stop'] = stop;
    if (system != null) json['system'] = system;
    if (userId != null) json['user_id'] = userId;
    if (penaltyScore != null) json['penalty_score'] = penaltyScore;
    if (maxOutputTokens != null) json['max_output_tokens'] = maxOutputTokens;

    if (prompt != null) json['prompt'] = prompt;
    if (image != null) json['image'] = image;

    if (requestId != null) json['request_id'] = requestId;
    if (doSample != null) json['do_sample'] = doSample;

    if (presencePenalty != null) json['presence_penalty'] = presencePenalty;
    if (seed != null) json['seed'] = seed;
    if (streamOptions != null) json['stream_options'] = streamOptions;

    return json;
  }
}

/// 参数的工具函数类
@JsonSerializable(explicitToJson: true)
class CCTool {
  // 工具的类型
  // 2024-08-27 零一万物 目前只支持 function。
  // 智谱GLM4 支持 function、retrieval、web_search
  @JsonKey(name: 'type')
  String type;

  // 具体的函数描述
  @JsonKey(name: 'function')
  CCFunction? function;

  @JsonKey(name: 'retrieval')
  CCRetrieval? retrieval;

  @JsonKey(name: 'web_search')
  CCWebSearch? webSearch;

  CCTool(
    this.type, {
    this.function,
    this.retrieval,
    this.webSearch,
  });

  // 从字符串转
  factory CCTool.fromRawJson(String str) => CCTool.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory CCTool.fromJson(Map<String, dynamic> srcJson) =>
      _$CCToolFromJson(srcJson);

  Map<String, dynamic> toJson() => _$CCToolToJson(this);
}

/// 使用工具函数时对函数的描述
@JsonSerializable(explicitToJson: true)
class CCFunction {
  // 要调用的工具函数的名称。必须是 a-z、A-Z、0-9，或包含下划线和破折号，最大长度为 64。
  @JsonKey(name: 'name')
  String name;

  // 对工具函数作用的描述，用于帮助模型理解工具的调用时机和方式。
  @JsonKey(name: 'description')
  String? description;

  // 工具函数可接受的参数，需以 JSON 模式对象的形式进行描述。
  // 因为是json对象，不好控制，传入json字符串即可
  // 类似：
  //   "parameters": {
  //       "type": "object",
  //       "properties": {
  //           "time": {"type": "string","description": "数据的日期、月份或年份"},
  //           "type": {"type": "string","enum": ["同比","环比"]},
  //           "pre_value": {"type": "string","description": "前值"},
  //           "current_value": {"type": "string","description": "现值"}
  //       },
  //       "required": ["time", "type","pre_value","current_value"]
  //   }
  @JsonKey(name: 'parameters')
  String? parameters;

  CCFunction(
    this.name, {
    this.description,
    this.parameters,
  });

  // 从字符串转
  factory CCFunction.fromRawJson(String str) =>
      CCFunction.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory CCFunction.fromJson(Map<String, dynamic> srcJson) =>
      _$CCFunctionFromJson(srcJson);

  Map<String, dynamic> toJson() => _$CCFunctionToJson(this);
}

/// 仅当工具类型为retrieval时补充
@JsonSerializable(explicitToJson: true)
class CCRetrieval {
  // 当涉及到知识库ID时，请前往开放平台的知识库模块进行创建或获取。
  @JsonKey(name: 'knowledge_id')
  String knowledgeId;

  // 请求模型时的知识库模板，默认模板：
  // 从文档
  // """
  // {{ knowledge}}
  // """
  // 中找问题
  // """
  // {{question}}
  // """
  // 的答案，找到答案就仅使用文档语句回答问题，找不到答案就用自身知识回答并且告诉用户该信息不是来自文档。
  // 不要复述问题，直接开始回答
  //
  // 注意：用户自定义模板时，知识库内容占位符
  // 和用户侧问题占位符必是{{ knowledge}} 和{{question}}，其他模板内容用户可根据实际场景定义
  @JsonKey(name: 'prompt_template')
  String? promptTemplate;

  CCRetrieval(
    this.knowledgeId, {
    this.promptTemplate,
  });

  // 从字符串转
  factory CCRetrieval.fromRawJson(String str) =>
      CCRetrieval.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory CCRetrieval.fromJson(Map<String, dynamic> srcJson) =>
      _$CCRetrievalFromJson(srcJson);

  Map<String, dynamic> toJson() => _$CCRetrievalToJson(this);
}

/// 仅当工具类型为web_search时补充，如果tools中存在类型retrieval，此时web_search不生效。
@JsonSerializable(explicitToJson: true)
class CCWebSearch {
  // 网络搜索功能：默认为关闭状态（False）
  // 说明：启用搜索后，系统会自动判断是否需要进行网络检索，调用搜索引擎获取相关信息。
  // 检索成功后，搜索结果将作为输入背景信息提供给大模型进行进一步处理。
  // 每次网络搜索大约会增加1000 tokens 的消耗。
  @JsonKey(name: 'enable')
  bool? enable;

  // 强制搜索自定义关键内容，此时模型会根据自定义搜索关键内容返回的结果作为背景知识来回答用户发起的对话。
  @JsonKey(name: 'search_query')
  String? searchQuery;

  // 获取详细的网页搜索来源信息，包括来源网站的图标、标题、链接、来源名称以及引用的文本内容。默认为关闭。
  @JsonKey(name: 'search_result')
  bool? searchResult;

  CCWebSearch({
    this.enable,
    this.searchQuery,
    this.searchResult,
  });

  // 从字符串转
  factory CCWebSearch.fromRawJson(String str) =>
      CCWebSearch.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory CCWebSearch.fromJson(Map<String, dynamic> srcJson) =>
      _$CCWebSearchFromJson(srcJson);

  Map<String, dynamic> toJson() => _$CCWebSearchToJson(this);
}

///
///
///  "stream_options":{"include_usage":true}
@JsonSerializable(explicitToJson: true)
class StreamOption {
  @JsonKey(name: 'include_usage')
  bool? includeUsage;

  StreamOption({
    this.includeUsage = true,
  });

  // 从字符串转
  factory StreamOption.fromRawJson(String str) =>
      StreamOption.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory StreamOption.fromJson(Map<String, dynamic> srcJson) =>
      _$StreamOptionFromJson(srcJson);

  Map<String, dynamic> toJson() => _$StreamOptionToJson(this);
}
