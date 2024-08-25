import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';

import '../../common/constants.dart';
import '../../common/llm_spec/cus_llm_spec.dart';

part 'com_ig_state.g.dart';

///
/// 大模型文生图\图生图，保存历史记录时，可能用到
/// 这里不是各个大模型的返回，就是本地逻辑处理用到的，主要是文生图历史记录用到
/// 2024-08-23 tti和iti 历史记录合并为ig
///
@JsonSerializable(explicitToJson: true)
class LlmIGResult {
  final String requestId; // 每个消息有个ID方便整个对话列表的保存？？？
  // 2024-08-25 如阿里云这种先提交job，后查询job的，如果在用户异常取消遮罩或者退出页面后，
  // 只要job成功提交得到taskId，还能再查一下子
  // 配合isFinish栏位:job提交时，存入taskId，isFinish默认为false；成功查询job结果后，
  // 【修改】该taskId的记录的imageUrls和isFinish栏位
  String? taskId;
  bool isFinish;
  final String prompt; // 正向提示词
  String? negativePrompt; // 消极提示词
  final String style; // 图片风格
  List<String>? imageUrls; // 图片地址,数据库存分号连接的字符串(一般都在平台的oss中，有超时设定)
  DateTime gmtCreate; // 创建时间
  CusLLMSpec? llmSpec; // 用来文生图的模型信息

  LlmIGResult({
    required this.requestId,
    this.taskId,
    this.isFinish = false,
    required this.prompt,
    this.negativePrompt,
    required this.style,
    this.imageUrls,
    required this.gmtCreate,
    this.llmSpec,
  });

  // 从字符串转
  factory LlmIGResult.fromRawJson(String str) =>
      LlmIGResult.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory LlmIGResult.fromJson(Map<String, dynamic> srcJson) =>
      _$LlmIGResultFromJson(srcJson);

  Map<String, dynamic> toJson() => _$LlmIGResultToJson(this);

  factory LlmIGResult.fromMap(Map<String, dynamic> map) {
    return LlmIGResult(
      requestId: map['request_id'] as String,
      prompt: map['prompt'] as String,
      negativePrompt: map['negative_prompt'] as String?,
      taskId: map['task_id'] as String?,
      isFinish: map['is_finish'] == 1 ? true : false,
      style: map['style'] as String,
      imageUrls: (map['image_urls'] as String?)?.split(";").toList(),
      gmtCreate: DateTime.tryParse(map['gmt_create']) ?? DateTime.now(),
      llmSpec: map['llm_spec'] != null
          ? CusLLMSpec.fromJson(json.decode(map['llm_spec']))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'request_id': requestId,
      'prompt': prompt,
      'negative_prompt': negativePrompt,
      'task_id': taskId,
      'is_finish': isFinish ? 1 : 0,
      'style': style,
      'image_urls': imageUrls?.join(";"), // 存入数据库用分号分割，取的时候也一样
      'gmt_create': DateFormat(constDatetimeFormat).format(gmtCreate),
      'llm_spec': llmSpec?.toRawJson(),
    };
  }
}

///
/// 通用自定义模型规格
///
@JsonSerializable(explicitToJson: true)
class CusLLMSpec {
  // 唯一编号
  String? cusLlmSpecId;
  // 模型字符串(平台API参数的那个model的值)、模型名称、上下文长度数值，
  /// 是否免费，收费输入时百万token价格价格，输出时百万token价格(免费没写价格就先写0)
  ApiPlatform platform;
  String model;
  // 随便带上模型枚举名称，方便过滤筛选
  CusLLM cusLlm;
  String name;
  int? contextLength;
  bool isFree;
  // 每百万token单价
  double? inputPrice;
  double? outputPrice;

  // 是否支持索引用实时全网检索信息服务
  bool? isQuote;
  // 模型特性
  String? feature;
  // 使用场景
  String? useCase;

  // 模型类型(visons 视觉模型可以解析图片、分析图片内容，然后进行对话,使用时需要支持上传图片，
  // 但也能持续对话，和cc分开)
  LLModelType modelType;
  // 每张图、每个视频等单个的花费
  double? costPer;

  // 数据创建的时候(一般排序用)
  DateTime? gmtCreate;

// 默认是对话模型的构造函数
  CusLLMSpec(this.platform, this.cusLlm, this.model, this.name,
      this.contextLength, this.isFree, this.inputPrice, this.outputPrice,
      {this.cusLlmSpecId,
      this.isQuote = false,
      this.feature,
      this.useCase,
      this.modelType = LLModelType.cc,
      this.gmtCreate,
      this.costPer});

// 文生图的栏位稍微不一样
  CusLLMSpec.tti(this.platform, this.cusLlm, this.model, this.name, this.isFree,
      {this.cusLlmSpecId,
      this.feature,
      this.useCase,
      this.modelType = LLModelType.cc,
      this.costPer = 0.5,
      this.gmtCreate});

  CusLLMSpec.iti(this.platform, this.cusLlm, this.model, this.name, this.isFree,
      {this.cusLlmSpecId,
      this.feature,
      this.useCase,
      this.modelType = LLModelType.iti,
      this.costPer = 0.5,
      this.gmtCreate});

  CusLLMSpec.init(
    this.platform,
    this.cusLlm, {
    this.model = "",
    this.name = "",
    this.isFree = false,
    this.modelType = LLModelType.iti,
  });

  // 从字符串转
  factory CusLLMSpec.fromRawJson(String str) =>
      CusLLMSpec.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory CusLLMSpec.fromJson(Map<String, dynamic> srcJson) =>
      _$CusLLMSpecFromJson(srcJson);

  Map<String, dynamic> toJson() => _$CusLLMSpecToJson(this);

  factory CusLLMSpec.fromMap(Map<String, dynamic> map) {
    return CusLLMSpec(
      ApiPlatform.values.firstWhere((e) => e.toString() == map['platform']),
      CusLLM.values.firstWhere((e) => e.toString() == map['cusLlm']),
      map['model'],
      map['name'],
      map['contextLength'],
      map['isFree'] == 1 ? true : false,
      map['inputPrice'],
      map['outputPrice'],
      cusLlmSpecId: map['cusLlmSpecId'],
      isQuote: map['isQuote'] == 1 ? true : false,
      feature: map['feature'],
      useCase: map['useCase'],
      modelType: LLModelType.values
          .firstWhere((e) => e.toString() == map['modelType']),
      gmtCreate:
          map['gmtCreate'] != null ? DateTime.parse(map['gmtCreate']) : null,
      costPer: map['costPer'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cusLlmSpecId': cusLlmSpecId,
      'platform': platform.toString(),
      'model': model,
      'cusLlm': cusLlm.toString(),
      'name': name,
      'contextLength': contextLength,
      'isFree': isFree ? 1 : 0,
      'inputPrice': inputPrice,
      'outputPrice': outputPrice,
      'isQuote': (isQuote != null && isQuote == true) ? 1 : 0,
      'feature': feature,
      'useCase': useCase,
      'modelType': modelType.toString(),
      'costPer': costPer,
      'gmtCreate': gmtCreate?.toIso8601String(),
    };
  }
}
