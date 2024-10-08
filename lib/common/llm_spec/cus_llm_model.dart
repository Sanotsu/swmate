import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../../views/ai_assistant/_helper/constants.dart';
import 'cus_llm_spec.dart';

part 'cus_llm_model.g.dart';

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
      this.modelType = LLModelType.tti,
      this.costPer = 0.5,
      this.gmtCreate});

  CusLLMSpec.iti(this.platform, this.cusLlm, this.model, this.name, this.isFree,
      {this.cusLlmSpecId,
      this.feature,
      this.useCase,
      this.modelType = LLModelType.iti,
      this.costPer = 0.5,
      this.gmtCreate});

  CusLLMSpec.ttv(this.platform, this.cusLlm, this.model, this.name, this.isFree,
      {this.cusLlmSpecId,
      this.feature,
      this.useCase,
      this.modelType = LLModelType.ttv,
      this.costPer = 0.5,
      this.gmtCreate});

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
      'feature': feature,
      'useCase': useCase,
      'modelType': modelType.toString(),
      'costPer': costPer,
      'gmtCreate': gmtCreate?.toIso8601String(),
    };
  }

  ///
  /// 2024-08-29
  /// 在 Dart 中，默认的对象比较是基于实例的引用，而不是对象的内容。
  /// 比如在平台和模型下拉框的时候，如果有更新当前选中的平台和模型，会判断是否在预选列表中
  /// 虽然看起来在(比如selectedModelSpec.name相等)，但可能引用不同，
  /// 两个CusLLMSpec实例判等就失败了
  /// 之前没注意是因为平台列表是enum，不存在这个问题
  ///
  ///
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CusLLMSpec &&
          runtimeType == other.runtimeType &&
          cusLlmSpecId == other.cusLlmSpecId &&
          platform == other.platform &&
          model == other.model &&
          cusLlm == other.cusLlm &&
          name == other.name &&
          contextLength == other.contextLength &&
          isFree == other.isFree &&
          inputPrice == other.inputPrice &&
          outputPrice == other.outputPrice &&
          feature == other.feature &&
          useCase == other.useCase &&
          modelType == other.modelType &&
          costPer == other.costPer &&
          gmtCreate == other.gmtCreate;

  @override
  int get hashCode =>
      cusLlmSpecId.hashCode ^
      platform.hashCode ^
      model.hashCode ^
      cusLlm.hashCode ^
      name.hashCode ^
      contextLength.hashCode ^
      isFree.hashCode ^
      inputPrice.hashCode ^
      outputPrice.hashCode ^
      feature.hashCode ^
      useCase.hashCode ^
      modelType.hashCode ^
      costPer.hashCode ^
      gmtCreate.hashCode;
}

/// 文档解读这页面可能需要的一些栏位
/// 2024-08-23 简单了解后，这可能不是智能体，只是系统角色而已
@JsonSerializable(explicitToJson: true)
class CusSysRoleSpec {
  String? cusSysRoleSpecId;
  // 系统角色的标签
  final String label;
  // 一句话简介
  String? subtitle;
  // 系统角色的枚举名称
  CusSysRole? name;
  // 系统角色的提示信息
  String? hintInfo;
  // 系统角色的系统提示
  final String systemPrompt;

  // 系统角色图片地址
  String? imageUrl;
  // 类别(后续区分文本对话的系统角色、图片生成的系统角色等)
  LLModelType? sysRoleType;

  // 数据创建的时候(一般排序用)
  DateTime? gmtCreate;

  // 因为示例的文生图也用这个，所以加上可能有的消极提示词
  // 正向提示词就 systemPrompt
  String? negativePrompt;

  CusSysRoleSpec({
    this.cusSysRoleSpecId,
    required this.label,
    this.subtitle,
    this.name,
    this.hintInfo = "",
    required this.systemPrompt,
    this.negativePrompt,
    this.imageUrl,
    this.sysRoleType,
    this.gmtCreate,
  });

  CusSysRoleSpec.defaultType({
    required this.label,
    required this.name,
    this.hintInfo = "",
    required this.systemPrompt,
    this.sysRoleType = LLModelType.vision,
  });

  CusSysRoleSpec.chat({
    required this.label,
    this.subtitle,
    required this.systemPrompt,
    this.imageUrl,
    this.sysRoleType = LLModelType.cc,
  });

  // 文本生成图片
  CusSysRoleSpec.tti({
    required this.label,
    this.subtitle,
    required this.systemPrompt,
    this.negativePrompt,
    this.imageUrl,
    this.sysRoleType = LLModelType.tti,
  });

  // 图片生成图片
  CusSysRoleSpec.iti({
    required this.label,
    this.subtitle,
    required this.systemPrompt,
    this.negativePrompt,
    this.imageUrl,
    this.sysRoleType = LLModelType.iti,
  });

  CusSysRoleSpec.ttv({
    required this.label,
    this.subtitle,
    required this.systemPrompt,
    this.negativePrompt,
    this.imageUrl,
    this.sysRoleType = LLModelType.ttv,
  });

  // 从字符串转
  factory CusSysRoleSpec.fromRawJson(String str) =>
      CusSysRoleSpec.fromJson(json.decode(str));

  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory CusSysRoleSpec.fromJson(Map<String, dynamic> json) =>
      _$CusSysRoleSpecFromJson(json);

  Map<String, dynamic> toJson() => _$CusSysRoleSpecToJson(this);

  // 从Map创建对象
  factory CusSysRoleSpec.fromMap(Map<String, dynamic> map) {
    return CusSysRoleSpec(
      label: map['label'],
      name: map['name'] != null
          ? CusSysRole.values.firstWhere((e) => e.name == map['name'])
          : null,
      hintInfo: map['hintInfo'],
      systemPrompt: map['systemPrompt'],
    )
      ..cusSysRoleSpecId = map['cusSysRoleSpecId']
      ..negativePrompt = map['negativePrompt']
      ..subtitle = map['subtitle']
      ..imageUrl = map['imageUrl']
      ..sysRoleType = map['sysRoleType'] != null
          ? LLModelType.values.firstWhere((e) => e.name == map['sysRoleType'])
          : null
      ..gmtCreate =
          map['gmtCreate'] != null ? DateTime.parse(map['gmtCreate']) : null;
  }
  // 将对象转换为Map
  Map<String, dynamic> toMap() {
    return {
      'cusSysRoleSpecId': cusSysRoleSpecId,
      'label': label,
      'subtitle': subtitle,
      'name': name?.name.toString(),
      'hintInfo': hintInfo,
      'systemPrompt': systemPrompt,
      'negativePrompt': negativePrompt,
      'imageUrl': imageUrl,
      'sysRoleType': sysRoleType?.name.toString(),
      'gmtCreate': gmtCreate?.toIso8601String(),
    };
  }
}
