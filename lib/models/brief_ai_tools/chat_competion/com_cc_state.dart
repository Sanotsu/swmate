import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../../../common/constants/constants.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../common/llm_spec/constant_llm_enum.dart';
import 'com_cc_resp.dart';

part 'com_cc_state.g.dart';

// 新版本
///
/// =============
///
///
/// 这个文件是基础的文本对话相关功能会用到的【工具模型类】
///

/// 人机对话的每一条消息的结果
/// 对话页面就是包含一系列时间顺序排序后的对话消息的list
@JsonSerializable(explicitToJson: true)
class ChatMessage {
  // 每个消息有个ID方便整个对话列表的保存？？？
  String messageId;
  // 时间
  DateTime dateTime;
  // 2024-07-17 对话模型role和context都存上
  String role;
  // 2024-08-08 因为流式响应，要追加内容，所以不是final的
  String content;
  // 2025-02-25 对于DeepSeekR系列的，还有推理过程，此时对应栏位是reasoning_content
  String? reasoningContent;
  // 也一并记录思考的耗时
  int? thinkingDuration;

  // 2024-08-07 输入的文本可能是语言转的，保留语言文件地址
  String? contentVoicePath;
  // 2024-07-22 如果是rag的大模型，还会保存检索的索引
  List<CCQuote>? quotes;
  // 2024-07-17 有可能对话存在输入图片(假如后续一个用户对话中存在图片切来切去，就最后每个问答来回都存上图片)
  String? imageUrl;

  /// 记录对话耗费
  int? promptTokens;
  int? completionTokens;
  int? totalTokens;
  // 2024-07-24 如果是多个模型在一个页面同时响应的话，则需要显示每个消息对应的模型名称
  // 具体是什么文本，根据需求来定
  // 2024-08-30 就是各个api接口使用那个model字符串
  String? modelLabel;

  ChatMessage({
    required this.messageId,
    required this.dateTime,
    required this.role,
    required this.content,
    this.reasoningContent,
    this.thinkingDuration,
    this.contentVoicePath,
    this.quotes,
    this.imageUrl,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.modelLabel,
  });

  // 从字符串转
  factory ChatMessage.fromRawJson(String str) =>
      ChatMessage.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory ChatMessage.fromJson(Map<String, dynamic> srcJson) =>
      _$ChatMessageFromJson(srcJson);

  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'dateTime': dateTime,
      'role': role,
      'content': content,
      'reasoningContent': reasoningContent,
      'thinkingDuration': thinkingDuration,
      'contentVoicePath': contentVoicePath,
      'quotes': quotes.toString(),
      'imageUrl': imageUrl,
      'promptTokens': promptTokens,
      'completionTokens': completionTokens,
      'totalTokens': totalTokens,
      'modelLabel': modelLabel,
    };
  }

// fromMap 一般是数据库读取时用到
// fromJson 一般是从接口或者其他文本转换时用到
//    2024-06-03 使用parse而不是tryParse就可能会因为格式不对抛出异常
//    但是存入数据不对就是逻辑实现哪里出了问题。使用后者默认值也不知道该使用哪个。
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      messageId: map['messageId'] as String,
      dateTime: DateTime.parse(map['dateTime']),
      role: map['role'] as String,
      content: map['content'] as String,
      reasoningContent: map['reasoningContent'] as String?,
      thinkingDuration: map['thinkingDuration'] as int?,
      contentVoicePath: map['contentVoicePath'] as String?,
      quotes: map['quotes'] != null
          ? (map['quotes'] as List<dynamic>)
              .map((quoteMap) =>
                  CCQuote.fromMap(quoteMap as Map<String, dynamic>))
              .toList()
          : null,
      imageUrl: map['imageUrl'] as String?,
      promptTokens: int.tryParse(map['promptTokens'].toString()),
      completionTokens: int.tryParse(map['completionTokens'].toString()),
      totalTokens: int.tryParse(map['totalTokens'].toString()),
      modelLabel: map['modelLabel'] as String?,
    );
  }

  // @override
  // String toString() {
  //   // 2024-06-03 这个对话会被作为string存入数据库，然后再被读取转型为ChatMessage。
  //   // 所以需要是个完整的json字符串，一般fromMap时可以处理
  //   return '''
  //   {
  //    "message_id": "$messageId",
  //    "date_time": "$dateTime",
  //    "role": "$role",
  //    "content": ${jsonEncode(content)},
  //    "content_voice_path":"$contentVoicePath",
  //    "quotes": ${jsonEncode(quotes)},
  //    "image_url": "$imageUrl",
  //    "is_placeholder":"$isPlaceholder",
  //    "prompt_tokens":"$promptTokens",
  //    "completion_tokens":"$completionTokens",
  //    "total_tokens":"$totalTokens",
  //    "model_label":"$modelLabel"
  //   }
  //   ''';
  // }
}

///
/// 2024-07-23 过滤对话列表
/// 比如百度需要role时user和assistant交替出现，那就丢弃后面不是交替出现的部分
///
List<ChatMessage> filterAlternatingRoles(List<ChatMessage> messages) {
  List<ChatMessage> filteredMessages = [];
  String expectedRole = CusRole.user.name; // 开始时期望的角色

  for (ChatMessage message in messages) {
    if (message.role == expectedRole) {
      // 如果是保存的占位回复，则直接显示重试
      if (expectedRole == CusRole.assistant.name) {
        filteredMessages.add(ChatMessage(
          messageId: "retry",
          dateTime: DateTime.now(),
          role: CusRole.assistant.name,
          content: "问题回答已遗失，请重新提问",
        ));
      } else {
        filteredMessages.add(message);
      }
      // 切换期望角色
      expectedRole = expectedRole == CusRole.user.name
          ? CusRole.assistant.name
          : CusRole.user.name;
    } else {
      // 如果角色不匹配，则停止处理并返回已过滤的消息列表
      break;
    }
  }

  return filteredMessages;
}

/// 对话记录 这个是存入sqlite的表对应的模型
// 一次对话记录需要一个标题，首次创建的时间，然后包含很多的对话消息
@JsonSerializable(explicitToJson: true)
class ChatHistory {
  final String uuid;
  // 因为该栏位需要可修改，就不能为final了
  String title;
  final DateTime gmtCreate;
  // 2024-08-30 用户对历史回话进行追问后，查看历史记录时要排在前面
  DateTime gmtModified;
  // 因为该栏位需要可修改，就不能为final了
  List<ChatMessage> messages;
  // 2024-06-01 大模型名称也要记一下，说不定后续要存API的原始返回内容复用
  // 2024-06-20 这里记录的是自定义的模型名（类似 PlatformLLM.baiduErnieSpeed8KFREE）
  // 因为后续查询历史记录可能会用此栏位来过滤
  final String llmName; // 使用的大模型名称需要记一下吗？
  // 2024-06-06 记录了大模型名称，也记一下使用在哪个云平台
  final String? cloudPlatformName;

  /// 图像理解也是对话记录，所以增加一个类别
  String chatType; // aigc\image2text\text2image
  // ？？？2024-06-14 在图像理解中可以复用对话，存放被理解的图片的base64字符串
  // base64在memoryImage中可能会因为重复渲染而一闪一闪，还是存图片地址好了
  // i2t => image to text
  String? i2tImagePath;

  ChatHistory({
    required this.uuid,
    required this.title,
    required this.gmtCreate,
    required this.gmtModified,
    required this.messages,
    required this.llmName,
    this.cloudPlatformName,
    this.i2tImagePath,
    required this.chatType,
  });

  // 从字符串转
  factory ChatHistory.fromRawJson(String str) =>
      ChatHistory.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory ChatHistory.fromJson(Map<String, dynamic> srcJson) =>
      _$ChatHistoryFromJson(srcJson);

  Map<String, dynamic> toJson() => _$ChatHistoryToJson(this);

  factory ChatHistory.fromMap(Map<String, dynamic> map) {
    return ChatHistory(
      uuid: map['uuid'] as String,
      title: map['title'] as String,
      gmtCreate: DateTime.tryParse(map['gmtCreate']) ?? DateTime.now(),
      gmtModified: DateTime.tryParse(map['gmtModified']) ?? DateTime.now(),
      messages: (jsonDecode(map['messages'] as String) as List<dynamic>)
          .map((messageMap) =>
              ChatMessage.fromMap(messageMap as Map<String, dynamic>))
          .toList(),
      llmName: map['llmName'] as String,
      cloudPlatformName: map['cloudPlatformName'] as String?,
      chatType: map['chatType'] as String,
      i2tImagePath: map['i2tImagePath'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'title': title,
      'gmtCreate': gmtCreate.toIso8601String(),
      'gmtModified': gmtModified.toIso8601String(),
      // 这样应该把List<ChatMessage> 转为了字符串数组，再转为了字符串数组字符串
      'messages': messages.map((e) => e.toRawJson()).toList().toString(),
      'llmName': llmName,
      'cloudPlatformName': cloudPlatformName,
      'chatType': chatType,
      'i2tImagePath': i2tImagePath,
    };
  }

  @override
  String toString() {
    return '''
    ChatHistory { 
      "uuid": $uuid,
      "title": $title,
      "gmtCreate": $gmtCreate,
      "llmName": $llmName,
      "cloudPlatformName": $cloudPlatformName,
      'chatType': $chatType,
      "i2tImagePath": $i2tImagePath,
      "messages": $messages
    }
    ''';
  }
}

///
/// 2025-02-25 新版本改良后的(主要是模型信息、参考图片等栏位)
/// 对话记录 这个是存入sqlite的表对应的模型
/// 需要修改的就没有加final
@JsonSerializable(explicitToJson: true)
class BriefChatHistory {
  final String uuid;
  // 对话标题
  String title;
  // 创建时间
  final DateTime gmtCreate;
  // 修改时间
  DateTime gmtModified;

  // 对话历史的消息列表
  // (视觉模型可以有参考图、参考视频等，但应该放在多轮对话中某一次消息中
  // 2025-02-25 目前只支持1张图片，没有视频，后续根据API再看情况)
  List<ChatMessage> messages;

  // 选用对话的模型信息
  CusBriefLLMSpec llmSpec;

  // 模型的类型，查询历史时可以区分cc、vison等
  LLModelType modelType;

  BriefChatHistory({
    required this.uuid,
    required this.title,
    required this.gmtCreate,
    required this.gmtModified,
    required this.messages,
    required this.llmSpec,
    required this.modelType,
  });

  // 从字符串转
  factory BriefChatHistory.fromRawJson(String str) =>
      BriefChatHistory.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory BriefChatHistory.fromJson(Map<String, dynamic> srcJson) =>
      _$BriefChatHistoryFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BriefChatHistoryToJson(this);

  factory BriefChatHistory.fromMap(Map<String, dynamic> map) {
    return BriefChatHistory(
      uuid: map['uuid'] as String,
      title: map['title'] as String,
      gmtCreate: DateTime.tryParse(map['gmtCreate']) ?? DateTime.now(),
      gmtModified: DateTime.tryParse(map['gmtModified']) ?? DateTime.now(),
      messages: (jsonDecode(map['messages'] as String) as List<dynamic>)
          .map((messageMap) =>
              ChatMessage.fromMap(messageMap as Map<String, dynamic>))
          .toList(),
      modelType: LLModelType.values
          .firstWhere((e) => e.toString() == map['modelType']),
      llmSpec: CusBriefLLMSpec.fromJson(json.decode(map['llmSpec'])),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'title': title,
      'gmtCreate': gmtCreate.toIso8601String(),
      'gmtModified': gmtModified.toIso8601String(),
      // 这样应该把List<ChatMessage> 转为了字符串数组，再转为了字符串数组字符串
      'messages': messages.map((e) => e.toRawJson()).toList().toString(),
      'llmSpec': llmSpec.toRawJson(),
      'modelType': modelType.toString(),
    };
  }

  @override
  String toString() {
    return '''
    BriefChatHistory { 
      "uuid": $uuid,
      "title": $title,
      "gmtCreate": $gmtCreate,
      "gmtModified": $gmtModified,
      "llmSpec": $llmSpec,
      "modelType": $modelType,
      "messages": $messages
    }
    ''';
  }
}

/// 2024-08-30 智能群聊存入数据库
/// 这个是存入sqlite的表对应的模型,基本同单个模型对话相似，
/// 只不过把msgMap和messages全部转为string存数据库，用的时候再转回来
@JsonSerializable(explicitToJson: true)
class GroupChatHistory {
  final String uuid;
  String title;
  List<ChatMessage> messages;
  Map<String, List<ChatMessage>> modelMsgMap;
  final DateTime gmtCreate;
  DateTime gmtModified;

  GroupChatHistory({
    required this.uuid,
    required this.title,
    required this.messages,
    required this.modelMsgMap,
    required this.gmtCreate,
    required this.gmtModified,
  });

  // 从字符串转
  factory GroupChatHistory.fromRawJson(String str) =>
      GroupChatHistory.fromJson(json.decode(str));

  // 转为字符串
  String toRawJson() => json.encode(toJson());

  // 从Json转
  factory GroupChatHistory.fromJson(Map<String, dynamic> json) =>
      _$GroupChatHistoryFromJson(json);

  // 转为Json
  Map<String, dynamic> toJson() => _$GroupChatHistoryToJson(this);

  // 添加 fromMap 方法
  factory GroupChatHistory.fromMap(Map<String, dynamic> map) {
    return GroupChatHistory(
      uuid: map['uuid'],
      title: map['title'],
      messages: (json.decode(map['messages']) as List<dynamic>)
          .map((messageMap) => ChatMessage.fromJson(messageMap))
          .toList(),
      modelMsgMap: (json.decode(map['modelMsgMap']) as Map<String, dynamic>)
          .map((key, value) => MapEntry(
                key,
                (value as List<dynamic>)
                    .map((e) => ChatMessage.fromJson(e))
                    .toList(),
              )),
      gmtCreate: DateTime.parse(map['gmtCreate']),
      gmtModified: DateTime.parse(map['gmtModified']),
    );
  }

  // 添加 toMap 方法
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'title': title,
      'messages': json.encode(messages.map((e) => e.toJson()).toList()),
      'modelMsgMap': json.encode(modelMsgMap.map((key, value) =>
          MapEntry(key, value.map((e) => e.toJson()).toList()))),
      'gmtCreate': gmtCreate.toIso8601String(),
      'gmtModified': gmtModified.toIso8601String(),
    };
  }
}
