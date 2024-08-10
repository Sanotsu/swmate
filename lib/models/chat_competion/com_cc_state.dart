import 'dart:convert';

import 'package:intl/intl.dart';

import '../../common/constants.dart';
import 'com_cc_resp.dart';

///
/// 这个文件是基础的文本对话相关功能会用到的【工具模型类】
///

/// 人机对话的每一条消息的结果
/// 对话页面就是包含一系列时间顺序排序后的对话消息的list
class ChatMessage {
  String messageId; // 每个消息有个ID方便整个对话列表的保存？？？
  DateTime dateTime; // 时间
  // 2024-07-17 对话模型role和context都存上
  // 之前有个isFromUser来区分用户和AI助手，但没法保存system，所以直接改为role
  String role;
  // 2024-07-17 之前是text，现在改为content
  // 2024-08-08 因为流式响应，要追加内容，所以不是final的
  String content; // 文本内容
  // 2024-08-07 输入的文本可能是语言转的，保留语言文件地址
  String? contentVoicePath;
  // 2024-07-22 如果是rag的大模型，还会保存检索的索引
  List<CCQuote>? quotes;
  // 2024-07-17 有可能对话存在输入图片(假如后续一个用户对话中存在图片切来切去，就最后每个问答来回都存上图片)
  String? imageUrl;
  bool? isPlaceholder; // 是否是等待响应时的占位消息
  /// 记录对话耗费
  int? promptTokens;
  int? completionTokens;
  int? totalTokens;
  // 2024-07-24 如果是多个模型在一个页面同时响应的话，则需要显示每个消息对应的模型名称
  // 具体是什么文本，根据需求来定
  String? modelLabel;

  ChatMessage({
    required this.messageId,
    required this.dateTime,
    required this.role,
    required this.content,
    this.contentVoicePath,
    this.quotes,
    this.imageUrl,
    this.isPlaceholder,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.modelLabel,
  });

  Map<String, dynamic> toMap() {
    return {
      'message_id': messageId,
      'date_time': dateTime,
      'role': role,
      'content': content,
      'content_voice_path': contentVoicePath,
      'quotes': quotes.toString(),
      'image_url': imageUrl,
      'is_placeholder': isPlaceholder,
      'prompt_tokens': promptTokens,
      'completion_tokens': completionTokens,
      'total_tokens': totalTokens,
      'model_label': modelLabel,
    };
  }

// fromMap 一般是数据库读取时用到
// fromJson 一般是从接口或者其他文本转换时用到
//    2024-06-03 使用parse而不是tryParse就可能会因为格式不对抛出异常
//    但是存入数据不对就是逻辑实现哪里出了问题。使用后者默认值也不知道该使用哪个。
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      messageId: map['message_id'] as String,
      dateTime: DateTime.parse(map['date_time']),
      role: map['role'] as String,
      content: map['content'] as String,
      contentVoicePath: map['content_voice_path'] as String?,
      quotes: map['quotes'] != null
          ? (map['quotes'] as List<dynamic>)
              .map((quoteMap) =>
                  CCQuote.fromMap(quoteMap as Map<String, dynamic>))
              .toList()
          : null,
      imageUrl: map['image_url'] as String?,
      isPlaceholder: bool.tryParse(map['is_placeholder']),
      promptTokens: int.tryParse(map['prompt_tokens']),
      completionTokens: int.tryParse(map['completion_tokens']),
      totalTokens: int.tryParse(map['total_tokens']),
      modelLabel: map['model_label'] as String?,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        messageId: json["message_id"],
        dateTime: DateTime.parse(json["date_time"]),
        role: json["role"],
        content: json["content"],
        contentVoicePath: json["content_voice_path"],
        quotes: json["quotes"] == null
            ? []
            : List<CCQuote>.from(
                json["quotes"]!.map((x) => CCQuote.fromJson(x)),
              ),
        imageUrl: json["image_url"],
        isPlaceholder: bool.tryParse(json["is_placeholder"]),
        promptTokens: int.tryParse(json["prompt_tokens"]),
        completionTokens: int.tryParse(json["completion_tokens"]),
        totalTokens: int.tryParse(json["total_tokens"]),
        modelLabel: json["model_label"],
      );

  Map<String, dynamic> toJson() => {
        "message_id": messageId,
        "date_time": dateTime.toIso8601String(),
        'role': role,
        "content": content,
        "content_voice_path": contentVoicePath,
        "quotes": quotes == null
            ? []
            : List<dynamic>.from(quotes!.map((x) => x.toJson())),
        "image_url": imageUrl,
        "is_placeholder": isPlaceholder,
        "prompt_tokens": promptTokens,
        "completion_tokens": completionTokens,
        "total_tokens": totalTokens,
        "model_label": modelLabel,
      };

  @override
  String toString() {
    // 2024-06-03 这个对话会被作为string存入数据库，然后再被读取转型为ChatMessage。
    // 所以需要是个完整的json字符串，一般fromMap时可以处理
    return '''
    {
     "message_id": "$messageId", 
     "date_time": "$dateTime", 
     "role": "$role", 
     "content": ${jsonEncode(content)}, 
     "content_voice_path":"$contentVoicePath",
     "quotes": ${jsonEncode(quotes)}, 
     "image_url": "$imageUrl", 
     "is_placeholder":"$isPlaceholder",
     "prompt_tokens":"$promptTokens",
     "completion_tokens":"$completionTokens",
     "total_tokens":"$totalTokens",
     "model_label":"$modelLabel"
    }
    ''';
  }
}

///
/// 2024-07-23 过滤对话列表
/// 比如百度需要role时user和assistant交替出现，那就丢弃后面不是交替出现的部分
///
List<ChatMessage> filterAlternatingRoles(List<ChatMessage> messages) {
  List<ChatMessage> filteredMessages = [];
  String expectedRole = "user"; // 开始时期望的角色

  for (ChatMessage message in messages) {
    if (message.role == expectedRole) {
      // 如果是保存的占位回复，则直接显示重试
      if (expectedRole == "assistant" && message.isPlaceholder == true) {
        filteredMessages.add(ChatMessage(
          messageId: "retry",
          dateTime: DateTime.now(),
          role: "assistant",
          content: "问题回答已遗失，请重新提问",
          isPlaceholder: false,
        ));
      } else {
        filteredMessages.add(message);
      }
      // 切换期望角色
      expectedRole = expectedRole == "user" ? "assistant" : "user";
    } else {
      // 如果角色不匹配，则停止处理并返回已过滤的消息列表
      break;
    }
  }

  return filteredMessages;
}

/// 对话记录 这个是存入sqlite的表对应的模型
// 一次对话记录需要一个标题，首次创建的时间，然后包含很多的对话消息
class ChatSession {
  final String uuid;
  // 因为该栏位需要可修改，就不能为final了
  String title;
  final DateTime gmtCreate;
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

  ChatSession({
    required this.uuid,
    required this.title,
    required this.gmtCreate,
    required this.messages,
    required this.llmName,
    this.cloudPlatformName,
    this.i2tImagePath,
    required this.chatType,
  });

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      uuid: map['uuid'] as String,
      title: map['title'] as String,
      gmtCreate: DateTime.tryParse(map['gmt_create']) ?? DateTime.now(),
      messages: (jsonDecode(map['messages'] as String) as List<dynamic>)
          .map((messageMap) =>
              ChatMessage.fromMap(messageMap as Map<String, dynamic>))
          .toList(),
      llmName: map['llm_name'] as String,
      cloudPlatformName: map['yun_platform_name'] as String?,
      i2tImagePath: map['i2t_image_path'] as String?,
      chatType: map['chat_type'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'title': title,
      'gmt_create': DateFormat(constDatetimeFormat).format(gmtCreate),
      'messages': messages.toString(),
      'llm_name': llmName,
      'yun_platform_name': cloudPlatformName,
      'chat_type': chatType,
      'i2t_image_path': i2tImagePath,
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        uuid: json["uuid"],
        messages: List<ChatMessage>.from(
          json["messages"].map((x) => ChatMessage.fromJson(x)),
        ),
        title: json["title"],
        gmtCreate: json["gmt_create"],
        llmName: json["llm_name"],
        cloudPlatformName: json["yun_platform_name"],
        chatType: json["chat_type"],
        i2tImagePath: json["i2t_image_path"],
      );

  Map<String, dynamic> toJson() => {
        "uuid": uuid,
        "messages": List<dynamic>.from(messages.map((x) => x.toJson())),
        "title": title,
        "gmt_create": gmtCreate,
        "llm_name": llmName,
        "yun_platform_name": cloudPlatformName,
        "i2t_image_path": i2tImagePath,
        'chat_type': chatType,
      };

  @override
  String toString() {
    return '''
    ChatSession { 
      "uuid": $uuid,
      "title": $title,
      "gmtCreate": $gmtCreate,
      "llmName": $llmName,
      "cloudPlatformName": $cloudPlatformName,
      'chatType': $chatType,
      "i2tImageBase64": ${(i2tImagePath != null && i2tImagePath!.length > 10) ? i2tImagePath?.substring(0, 10) : i2tImagePath},
      "messages": $messages
    }
    ''';
  }
}
