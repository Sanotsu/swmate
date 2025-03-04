import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import 'constant_llm_enum.dart';

part 'cus_brief_llm_model.g.dart';

///
/// 通用自定义模型规格
///
@JsonSerializable(explicitToJson: true)
class CusBriefLLMSpec {
  // 唯一编号
  String cusLlmSpecId;
  // 模型所在的云平台
  ApiPlatform platform;
  // 模型字符串(平台API参数的那个model的值)、
  String model;
  // 模型类型(cc、vision、audio、tti、iti、ttv……)
  LLModelType modelType;
  // 用于显示的模型名称
  String name;
  // 是否免费
  bool isFree;
  // 每百万token单价，免费没写价格就先写0
  double? inputPrice;
  double? outputPrice;
  // 每张图、每个视频等单个的花费
  double? costPer;
  // 上下文长度数值
  int? contextLength;
  // 模型发布时间
  DateTime? gmtRelease;
  // 数据创建的时候(一般排序用)
  DateTime? gmtCreate;
  // 是否是内置模型(内置模型不允许删除)
  bool isBuiltin;

  CusBriefLLMSpec(
    this.platform,
    this.model,
    this.modelType,
    this.name,
    this.isFree, {
    this.inputPrice,
    this.outputPrice,
    this.costPer,
    this.contextLength,
    required this.cusLlmSpecId,
    this.gmtRelease,
    this.gmtCreate,
    this.isBuiltin = false,
  });

  // 从字符串转
  factory CusBriefLLMSpec.fromRawJson(String str) =>
      CusBriefLLMSpec.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory CusBriefLLMSpec.fromJson(Map<String, dynamic> srcJson) =>
      _$CusBriefLLMSpecFromJson(srcJson);

  Map<String, dynamic> toJson() => _$CusBriefLLMSpecToJson(this);

  factory CusBriefLLMSpec.fromMap(Map<String, dynamic> map) {
    return CusBriefLLMSpec(
      ApiPlatform.values.firstWhere((e) => e.toString() == map['platform']),
      map['model'],
      LLModelType.values.firstWhere((e) => e.toString() == map['modelType']),
      map['name'],
      map['isFree'] == 1 ? true : false,
      inputPrice: map['inputPrice'],
      outputPrice: map['outputPrice'],
      costPer: map['costPer'],
      contextLength: map['contextLength'],
      cusLlmSpecId: map['cusLlmSpecId'],
      gmtRelease:
          map['gmtRelease'] != null ? DateTime.parse(map['gmtRelease']) : null,
      gmtCreate:
          map['gmtCreate'] != null ? DateTime.parse(map['gmtCreate']) : null,
      isBuiltin: map['isBuiltin'] == 1 ? true : false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cusLlmSpecId': cusLlmSpecId,
      'platform': platform.toString(),
      'model': model,
      'modelType': modelType.toString(),
      'name': name,
      'isFree': isFree ? 1 : 0,
      'inputPrice': inputPrice,
      'outputPrice': outputPrice,
      'costPer': costPer,
      'contextLength': contextLength,
      'gmtRelease': gmtRelease?.toIso8601String(),
      'gmtCreate': gmtCreate?.toIso8601String(),
      'isBuiltin': isBuiltin ? 1 : 0,
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
      other is CusBriefLLMSpec &&
          runtimeType == other.runtimeType &&
          cusLlmSpecId == other.cusLlmSpecId &&
          platform == other.platform &&
          model == other.model &&
          modelType == other.modelType &&
          name == other.name &&
          isFree == other.isFree &&
          inputPrice == other.inputPrice &&
          outputPrice == other.outputPrice &&
          costPer == other.costPer &&
          contextLength == other.contextLength &&
          gmtRelease == other.gmtRelease &&
          gmtCreate == other.gmtCreate &&
          isBuiltin == other.isBuiltin;

  @override
  int get hashCode =>
      cusLlmSpecId.hashCode ^
      platform.hashCode ^
      model.hashCode ^
      modelType.hashCode ^
      name.hashCode ^
      isFree.hashCode ^
      inputPrice.hashCode ^
      outputPrice.hashCode ^
      costPer.hashCode ^
      contextLength.hashCode ^
      gmtRelease.hashCode ^
      gmtCreate.hashCode ^
      isBuiltin.hashCode;
}
