import 'package:uuid/uuid.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';

class CharacterCard {
  final String id;
  String name;
  String avatar;
  String description;
  String personality;
  String scenario;
  String firstMessage;
  String exampleDialogue;
  List<String> tags;
  CusBriefLLMSpec? preferredModel; // 角色偏好的模型
  DateTime createTime;
  DateTime updateTime;
  bool isSystem; // 是否是系统预设角色

  // 可选的额外设置
  Map<String, dynamic> additionalSettings;

  CharacterCard({
    String? id,
    required this.name,
    required this.avatar,
    required this.description,
    this.personality = '',
    this.scenario = '',
    this.firstMessage = '',
    this.exampleDialogue = '',
    List<String>? tags,
    this.preferredModel,
    DateTime? createTime,
    DateTime? updateTime,
    this.isSystem = false,
    Map<String, dynamic>? additionalSettings,
  })  : id = id ?? const Uuid().v4(),
        tags = tags ?? [],
        createTime = createTime ?? DateTime.now(),
        updateTime = updateTime ?? DateTime.now(),
        additionalSettings = additionalSettings ?? {};

  // 生成系统提示词
  String generateSystemPrompt() {
    return '''
你现在扮演角色: $name

角色描述: $description

性格特点: $personality

场景设定: $scenario

${exampleDialogue.isNotEmpty ? '对话示例:\n$exampleDialogue' : ''}

请始终保持角色设定，用第一人称回应用户的消息。不要提及你是AI或语言模型。
''';
  }

  // JSON序列化和反序列化方法
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'description': description,
      'personality': personality,
      'scenario': scenario,
      'firstMessage': firstMessage,
      'exampleDialogue': exampleDialogue,
      'tags': tags,
      'preferredModel': preferredModel?.toJson(),
      'createTime': createTime.toIso8601String(),
      'updateTime': updateTime.toIso8601String(),
      'isSystem': isSystem,
      'additionalSettings': additionalSettings,
    };
  }

  factory CharacterCard.fromJson(Map<String, dynamic> json) {
    return CharacterCard(
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
      description: json['description'],
      personality: json['personality'] ?? '',
      scenario: json['scenario'] ?? '',
      firstMessage: json['firstMessage'] ?? '',
      exampleDialogue: json['exampleDialogue'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      preferredModel: json['preferredModel'] != null
          ? CusBriefLLMSpec.fromJson(json['preferredModel'])
          : null,
      createTime: DateTime.parse(json['createTime']),
      updateTime: DateTime.parse(json['updateTime']),
      isSystem: json['isSystem'] ?? false,
      additionalSettings: json['additionalSettings'] ?? {},
    );
  }
}
