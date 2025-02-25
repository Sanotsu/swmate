import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../common/constants.dart';
import '../../common/llm_spec/cus_brief_llm_model.dart';
import '../../common/llm_spec/cus_llm_spec.dart';

part 'media_generation_history.g.dart';

///
/// 大模型多种媒体资源生成，通用的历史记录保存
/// 这里不是各个大模型的返回，就是本地逻辑处理用到的，主要是媒体资源生成历史记录用到，多合一
///

@JsonSerializable(explicitToJson: true)
class MediaGenerationHistory {
  // 大模型API调用请求ID
  String requestId;

  // 正向提示词
  String prompt;

  // 消极提示词
  String? negativePrompt;

  // 文生图或文生视频可能会有参考图
  List<String>? refImageUrls;

  // 模型的类型，查询历史时可以区分ig、vg、ag等
  LLModelType modelType;

  // 用来资源生成的模型信息
  CusBriefLLMSpec llmSpec;

  // 如果先提交任务，后查询任务状态，那么taskId不为空，
  String? taskId;

  // 也要保持任务状态，尤其是出错的，方便指定平台指定删除
  String? taskStatus;

  // isSuccess + isProcessing + isFailed ，都是前端根据taskStatus来判断，方便直接查询
  bool isSuccess;
  bool isProcessing;
  bool isFailed;

  // 图片地址,数据库存分号连接的字符串(一般都在平台的oss中，有超时设定)
  List<String>? imageUrls;

  // 文生视频时视频地址,数据库存分号连接的字符串(一般都在平台的oss中，有超时设定)
  List<String>? videoUrls;

  // 音频地址,数据库存分号连接的字符串(一般都在平台的oss中，有超时设定)
  List<String>? audioUrls;

  // 其他参数，json字符串(比如style、coverImageUrl等，不是所有平台和模型都有返回的)
  String? otherParams;

  // 创建时间
  DateTime gmtCreate;

  // 修改时间(任务状态更新等，可能一并修改)
  DateTime? gmtModified;

  MediaGenerationHistory({
    required this.requestId,
    required this.prompt,
    this.negativePrompt,
    this.refImageUrls,
    required this.modelType,
    required this.llmSpec,
    this.taskId,
    this.taskStatus,
    this.isSuccess = false,
    this.isProcessing = false,
    this.isFailed = false,
    this.imageUrls,
    this.videoUrls,
    this.audioUrls,
    this.otherParams,
    required this.gmtCreate,
    this.gmtModified,
  });

  // 从字符串转
  factory MediaGenerationHistory.fromRawJson(String str) =>
      MediaGenerationHistory.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory MediaGenerationHistory.fromJson(Map<String, dynamic> srcJson) =>
      _$MediaGenerationHistoryFromJson(srcJson);

  Map<String, dynamic> toJson() => _$MediaGenerationHistoryToJson(this);

  // 2024-09-02 数据库栏位已改为驼峰命名方式
  factory MediaGenerationHistory.fromMap(Map<String, dynamic> map) {
    return MediaGenerationHistory(
      requestId: map['requestId'] as String,
      prompt: map['prompt'] as String,
      negativePrompt: map['negativePrompt'] as String?,
      refImageUrls: (map['refImageUrls'] as String?)?.split(";").toList(),
      modelType: LLModelType.values
          .firstWhere((e) => e.toString() == map['modelType']),
      llmSpec: CusBriefLLMSpec.fromJson(json.decode(map['llmSpec'])),
      taskId: map['taskId'] as String?,
      taskStatus: map['taskStatus'] as String?,
      isSuccess: map['isSuccess'] == 1 ? true : false,
      isProcessing: map['isProcessing'] == 1 ? true : false,
      isFailed: map['isFailed'] == 1 ? true : false,
      imageUrls: (map['imageUrls'] as String?)?.split(";").toList(),
      videoUrls: (map['videoUrls'] as String?)?.split(";").toList(),
      audioUrls: (map['audioUrls'] as String?)?.split(";").toList(),
      otherParams: map['otherParams'] as String?,
      gmtCreate: DateTime.tryParse(map['gmtCreate']) ?? DateTime.now(),
      gmtModified:
          DateTime.tryParse(map['gmtModified'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'prompt': prompt,
      'negativePrompt': negativePrompt,
      'refImageUrls': refImageUrls?.join(";"),
      'modelType': modelType.toString(),
      'llmSpec': llmSpec.toRawJson(),
      'taskId': taskId,
      'taskStatus': taskStatus,
      'isSuccess': isSuccess ? 1 : 0,
      'isProcessing': isProcessing ? 1 : 0,
      'isFailed': isFailed ? 1 : 0,
      'imageUrls': imageUrls?.join(";"), // 存入数据库用分号分割，取的时候也一样
      'videoUrls': videoUrls?.join(";"),
      'audioUrls': audioUrls?.join(";"),
      'otherParams': otherParams,
      'gmtCreate': DateFormat(constDatetimeFormat).format(gmtCreate),
      'gmtModified': gmtModified != null
          ? DateFormat(constDatetimeFormat).format(gmtModified!)
          : null,
    };
  }
}
