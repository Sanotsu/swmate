import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../common/constants.dart';
import '../../common/llm_spec/cus_brief_llm_model.dart';
import '../../common/llm_spec/cus_llm_spec.dart';

part 'image_generation_history.g.dart';

///
/// 大模型文生图，保存历史记录时，可能用到
/// 这里不是各个大模型的返回，就是本地逻辑处理用到的，主要是文生图历史记录用到
///

@JsonSerializable(explicitToJson: true)
class ImageGenerationHistory {
  String requestId; // 每个消息有个ID方便整个对话列表的保存？？？
  // 2024-08-25 如阿里云这种先提交job，后查询job的，如果在用户异常取消遮罩或者退出页面后，
  // 只要job成功提交得到taskId，还能再查一下子
  // 配合isFinish栏位:job提交时，存入taskId，isFinish默认为false；成功查询job结果后，
  // 【修改】该taskId的记录的imageUrls和isFinish栏位
  String? taskId;
  bool isFinish;
  String prompt; // 正向提示词
  String? negativePrompt; // 消极提示词
  String? style; // 图片风格
  List<String>? imageUrls; // 图片地址,数据库存分号连接的字符串(一般都在平台的oss中，有超时设定)

  // 2024-09-02 文生视频时视频地址,数据库存分号连接的字符串(一般都在平台的oss中，有超时设定)
  List<String>? videoUrls;
  // 文生视频可能会有封面图
  List<String>? videoCoverImageUrls;

  // 文生图或文生视频可能会有参考图
  List<String>? refImageUrls;

  DateTime gmtCreate; // 创建时间
  CusBriefLLMSpec? llmSpec; // 用来文生图的模型信息

  // 模型的类型，查询历史时可以区分ig和vg
  LLModelType modelType;

  ImageGenerationHistory({
    required this.requestId,
    this.taskId,
    this.isFinish = false,
    required this.prompt,
    this.negativePrompt,
    this.style,
    this.imageUrls,
    required this.gmtCreate,
    this.llmSpec,
    this.videoUrls,
    this.videoCoverImageUrls,
    this.refImageUrls,
    required this.modelType,
  });

  // 从字符串转
  factory ImageGenerationHistory.fromRawJson(String str) =>
      ImageGenerationHistory.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory ImageGenerationHistory.fromJson(Map<String, dynamic> srcJson) =>
      _$ImageGenerationHistoryFromJson(srcJson);

  Map<String, dynamic> toJson() => _$ImageGenerationHistoryToJson(this);

  // 2024-09-02 数据库栏位已改为驼峰命名方式
  factory ImageGenerationHistory.fromMap(Map<String, dynamic> map) {
    return ImageGenerationHistory(
      requestId: map['requestId'] as String,
      prompt: map['prompt'] as String,
      negativePrompt: map['negativePrompt'] as String?,
      taskId: map['taskId'] as String?,
      isFinish: map['isFinish'] == 1 ? true : false,
      style: map['style'] as String?,
      imageUrls: (map['imageUrls'] as String?)?.split(";").toList(),
      videoUrls: (map['videoUrls'] as String?)?.split(";").toList(),
      videoCoverImageUrls:
          (map['videoCoverImageUrls'] as String?)?.split(";").toList(),
      refImageUrls: (map['refImageUrls'] as String?)?.split(";").toList(),
      gmtCreate: DateTime.tryParse(map['gmtCreate']) ?? DateTime.now(),
      llmSpec: map['llmSpec'] != null
          ? CusBriefLLMSpec.fromJson(json.decode(map['llmSpec']))
          : null,
      modelType: LLModelType.values
          .firstWhere((e) => e.toString() == map['modelType']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'prompt': prompt,
      'negativePrompt': negativePrompt,
      'taskId': taskId,
      'isFinish': isFinish ? 1 : 0,
      'style': style,
      'imageUrls': imageUrls?.join(";"), // 存入数据库用分号分割，取的时候也一样
      'videoUrls': videoUrls?.join(";"),
      'videoCoverImageUrls': videoCoverImageUrls?.join(";"),
      'refImageUrls': refImageUrls?.join(";"),
      'gmtCreate': DateFormat(constDatetimeFormat).format(gmtCreate),
      'llmSpec': llmSpec?.toRawJson(),
      'modelType': modelType.toString(),
    };
  }
}
