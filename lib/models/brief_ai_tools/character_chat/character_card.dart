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

  // 新增角色专属背景图片
  String? background;
  // 新增角色专属背景透明度
  double? backgroundOpacity;

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
    this.background,
    this.backgroundOpacity,
    Map<String, dynamic>? additionalSettings,
  })  : id = id ?? identityHashCode(name).toString(),
        tags = tags ?? [],
        createTime = createTime ?? DateTime.now(),
        updateTime = updateTime ?? DateTime.now(),
        additionalSettings = additionalSettings ?? {};

  // 生成系统提示词
  String generateSystemPrompt() {
    final buffer = StringBuffer();

    // 核心角色定义
    buffer.writeln('# 角色定义');
    buffer.writeln('你现在将扮演: $name');
    buffer.writeln('');

    // 详细描述
    buffer.writeln('## 角色背景');
    buffer.writeln(description);
    buffer.writeln('');

    // 性格特点（如果有）
    if (personality.trim().isNotEmpty) {
      buffer.writeln('## 性格特点');
      buffer.writeln(personality);
      buffer.writeln('');
    }

    // 场景设定（如果有）
    if (scenario.trim().isNotEmpty) {
      buffer.writeln('## 场景设定');
      buffer.writeln(scenario);
      buffer.writeln('');
    }

    // 对话示例（如果有）
    if (exampleDialogue.trim().isNotEmpty) {
      buffer.writeln('## 对话示例');
      buffer.writeln(exampleDialogue);
      buffer.writeln('');
    }

    // 角色行为指南
    buffer.writeln('## 行为指南');
    buffer.writeln('1. 始终保持角色一致性，不要破坏角色设定');
    buffer.writeln('2. 使用第一人称回应用户，展现出你的专业知识和个性');
    buffer.writeln('3. 不要提及你是AI、语言模型或程序，完全沉浸在角色中');
    buffer.writeln('4. 根据用户的问题和需求提供相关、有帮助的回应');
    buffer.writeln('5. 如果用户的请求超出你的角色能力范围，可以礼貌地引导话题回到你的专业领域');
    buffer.writeln('6. 保持你的性格特点和说话风格，使回应符合角色形象');
    buffer.writeln('7. 在适当的情况下使用表情、动作描述等增强角色的真实感');

    // 根据角色标签添加特定指导
    _addTagSpecificGuidelines(buffer);

    // 添加角色特定的额外指导
    _addCharacterSpecificGuidelines(buffer);

    return buffer.toString();
  }

  // 根据标签添加特定指导
  void _addTagSpecificGuidelines(StringBuffer buffer) {
    // 工具类角色的特定指导
    if (tags.contains('虚拟') || tags.contains('角色扮演')) {
      buffer.writeln('\n## 角色扮演指导');
      buffer.writeln('- 完全沉浸在角色中，保持一致的语气、用词和行为模式');
      buffer.writeln('- 使用角色特有的表达方式、习惯用语或口头禅');
      buffer.writeln('- 通过描述动作、表情和语气增强互动的沉浸感');
      buffer.writeln('- 根据角色背景做出符合逻辑的反应和决定');
      buffer.writeln('- 在角色知识范围内回应，对未知信息可以创造性地处理');
    }
  }

  // 添加角色特定的额外指导
  void _addCharacterSpecificGuidelines(StringBuffer buffer) {}

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
      'background': background,
      'backgroundOpacity': backgroundOpacity,
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
      createTime: json['createTime'] != null
          ? DateTime.parse(json['createTime'])
          : null,
      updateTime: json['updateTime'] != null
          ? DateTime.parse(json['updateTime'])
          : null,
      isSystem: json['isSystem'] ?? false,
      background: json['background'],
      backgroundOpacity: json['backgroundOpacity'] != null
          ? (json['backgroundOpacity'] as num).toDouble()
          : null,
      additionalSettings: json['additionalSettings'] ?? {},
    );
  }
}
