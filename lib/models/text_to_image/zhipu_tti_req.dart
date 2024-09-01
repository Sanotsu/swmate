import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'zhipu_tti_req.g.dart';

///
/// 智谱AI的 CogView文生图的请求
/// 请求参数和响应内容相较其他比较少一点
///
@JsonSerializable(explicitToJson: true)
class CogViewReq {
  // 模型名称
  @JsonKey(name: 'model')
  String model;

  // 所需图像的文本描述
  @JsonKey(name: 'prompt')
  String? prompt;

  // 图片尺寸，仅 cogview-3-plus 支持该参数。
  // 可选范围：[1024x1024,768x1344,864x1152,1344x768,1152x864,1440x720,720x1440]，默认是1024x1024。
  @JsonKey(name: 'size')
  String? size;

  // 终端用户的唯一ID，协助平台对终端用户的违规行为、生成违法及不良信息或其他滥用行为进行干预。
  // ID长度要求：最少6个字符，最多128个字符。
  @JsonKey(name: 'user_id')
  String? userId;

  CogViewReq({
    required this.model,
    required this.prompt,
    this.size = "1024x1024",
    this.userId,
  });

  // 从字符串转
  factory CogViewReq.fromRawJson(String str) =>
      CogViewReq.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory CogViewReq.fromJson(Map<String, dynamic> srcJson) =>
      _$CogViewReqFromJson(srcJson);

  Map<String, dynamic> toJson() => _$CogViewReqToJson(this);
}
