import 'package:intl/intl.dart';

import '../../common/constants.dart';

///
/// 2024-06-13
/// 大模型文生图，也把url存到数据库中，超时没法下载那也是用户的问题
/// ??? 占位用的，还没做
///

class TextToImageResult {
  final String requestId; // 每个消息有个ID方便整个对话列表的保存？？？
  final String prompt; // 正向提示词
  String? negativePrompt; // 消极提示词
  final String style; // 图片风格
  List<String>? imageUrls; // 图片地址,数据库存分号连接的字符串(一般都在平台的oss中，有超时设定)
  DateTime gmtCreate; // 创建时间

  TextToImageResult({
    required this.requestId,
    required this.prompt,
    this.negativePrompt,
    required this.style,
    this.imageUrls,
    required this.gmtCreate,
  });

  factory TextToImageResult.fromMap(Map<String, dynamic> map) {
    return TextToImageResult(
      requestId: map['request_id'] as String,
      prompt: map['prompt'] as String,
      negativePrompt: map['negative_prompt'] as String?,
      style: map['style'] as String,
      imageUrls: (map['image_urls'] as String?)?.split(";").toList(),
      gmtCreate: DateTime.tryParse(map['gmt_create']) ?? DateTime.now(),
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
    };
  }
}
