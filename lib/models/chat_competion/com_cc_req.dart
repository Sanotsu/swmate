import 'package:json_annotation/json_annotation.dart';

import 'com_cc_resp.dart';

part 'com_cc_req.g.dart';

///
/// 【以零一万物的出参为基准的响应类】
///   siliconflow 完全适配
///

@JsonSerializable(explicitToJson: true)
class ComCCReq {
  // 选择的模型名
  @JsonKey(name: 'model')
  String? model;
  // 对话的消息体
  @JsonKey(name: 'messages')
  List<CCMessage>? messages;

  // 	模型可调用的工具列表。目前只支持函数作为工具。
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

  ComCCReq({
    this.model,
    this.messages,
    this.tools,
    this.toolChoice,
    this.maxTokens,
    this.topP,
    this.temperature,
    this.stream = false,
    this.n,
    this.topK,
    this.frequencyPenalty,
    this.stop,
  });

  factory ComCCReq.fromJson(Map<String, dynamic> srcJson) =>
      _$ComCCReqFromJson(srcJson);

  Map<String, dynamic> toJson() => _$ComCCReqToJson(this);
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

  factory CCFunction.fromJson(Map<String, dynamic> srcJson) =>
      _$CCFunctionFromJson(srcJson);

  Map<String, dynamic> toJson() => _$CCFunctionToJson(this);
}
