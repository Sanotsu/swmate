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

  // 通过对已生成的token增加惩罚，减少重复生成的现象。
  //  说明：（1）值越大表示惩罚越大。（2）默认1.0，取值范围：[1.0, 2.0]。
  @JsonKey(name: 'penalty_score')
  double? penaltyScore;

  // 指定模型最大输出token数，范围[2, 2048]
  @JsonKey(name: 'max_output_tokens')
  double? maxOutputTokens;

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
    this.topP,
    this.penaltyScore,
    this.system,
    this.stop,
    this.maxOutputTokens,
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

    return json;
  }
}

/// 参数的工具函数类
@JsonSerializable(explicitToJson: true)
class CCTool {
  // 工具的类型，目前只支持 function。
  @JsonKey(name: 'type')
  String type;

  // 具体的函数描述
  @JsonKey(name: 'function')
  CCFunction function;

  CCTool(
    this.type,
    this.function,
  );

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
