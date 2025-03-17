import 'package:uuid/uuid.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import 'character_card.dart';
import 'character_chat_message.dart';

class CharacterChatSession {
  final String id;
  String title;
  List<CharacterCard> characters; // 支持多角色
  List<CharacterChatMessage> messages;
  DateTime createTime;
  DateTime updateTime;
  CusBriefLLMSpec? activeModel; // 当前使用的模型

  CharacterChatSession({
    String? id,
    required this.title,
    required this.characters,
    List<CharacterChatMessage>? messages,
    DateTime? createTime,
    DateTime? updateTime,
    this.activeModel,
  })  : id = id ?? const Uuid().v4(),
        messages = messages ?? [],
        createTime = createTime ?? DateTime.now(),
        updateTime = updateTime ?? DateTime.now();

  // JSON序列化和反序列化方法
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'characters': characters.map((c) => c.toJson()).toList(),
      'messages': messages.map((m) => m.toJson()).toList(),
      'createTime': createTime.toIso8601String(),
      'updateTime': updateTime.toIso8601String(),
      'activeModel': activeModel?.toJson(),
    };
  }

  factory CharacterChatSession.fromJson(Map<String, dynamic> json) {
    return CharacterChatSession(
      id: json['id'],
      title: json['title'],
      characters: (json['characters'] as List)
          .map((c) => CharacterCard.fromJson(c))
          .toList(),
      messages: (json['messages'] as List)
          .map((m) => CharacterChatMessage.fromJson(m))
          .toList(),
      createTime: DateTime.parse(json['createTime']),
      updateTime: DateTime.parse(json['updateTime']),
      activeModel: json['activeModel'] != null
          ? CusBriefLLMSpec.fromJson(json['activeModel'])
          : null,
    );
  }
}
