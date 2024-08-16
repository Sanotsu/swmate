import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';

import '../../common/constants.dart';
import '../../common/llm_spec/cus_llm_spec.dart';

part 'com_tti_state.g.dart';

///
/// 大模型文生图，保存历史记录时，可能用到
/// 这里不是各个大模型的返回，就是本地逻辑处理用到的，主要是文生图历史记录用到
///
@JsonSerializable(explicitToJson: true)
class LlmTtiResult {
  final String requestId; // 每个消息有个ID方便整个对话列表的保存？？？
  final String prompt; // 正向提示词
  String? negativePrompt; // 消极提示词
  final String style; // 图片风格
  List<String>? imageUrls; // 图片地址,数据库存分号连接的字符串(一般都在平台的oss中，有超时设定)
  DateTime gmtCreate; // 创建时间
  CusLLMSpec? llmSpec; // 用来文生图的模型信息

  LlmTtiResult({
    required this.requestId,
    required this.prompt,
    this.negativePrompt,
    required this.style,
    this.imageUrls,
    required this.gmtCreate,
    this.llmSpec,
  });

  // 从字符串转
  factory LlmTtiResult.fromRawJson(String str) =>
      LlmTtiResult.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory LlmTtiResult.fromJson(Map<String, dynamic> srcJson) =>
      _$LlmTtiResultFromJson(srcJson);

  Map<String, dynamic> toJson() => _$LlmTtiResultToJson(this);

  factory LlmTtiResult.fromMap(Map<String, dynamic> map) {
    return LlmTtiResult(
      requestId: map['request_id'] as String,
      prompt: map['prompt'] as String,
      negativePrompt: map['negative_prompt'] as String?,
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
      'style': style,
      'image_urls': imageUrls?.join(";"), // 存入数据库用分号分割，取的时候也一样
      'gmt_create': DateFormat(constDatetimeFormat).format(gmtCreate),
      'llm_spec': llmSpec?.toRawJson(),
    };
  }
}
