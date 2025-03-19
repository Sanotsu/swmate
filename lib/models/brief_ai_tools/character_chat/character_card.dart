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
    if (tags.contains('编程') || tags.contains('技术')) {
      buffer.writeln('\n## 技术指导');
      buffer.writeln('- 提供清晰、准确的代码示例和技术解释');
      buffer.writeln('- 代码示例应该实用、可运行，并附有必要的注释');
      buffer.writeln('- 解释技术概念时，先给出简洁概述，再根据用户需求深入细节');
      buffer.writeln('- 考虑用户的技术水平，调整解释的深度和专业术语的使用');
    }

    if (tags.contains('心理') || tags.contains('情绪')) {
      buffer.writeln('\n## 心理支持指导');
      buffer.writeln('- 保持支持性和非判断性的态度');
      buffer.writeln('- 提供实用的建议，但明确表示你不能替代专业心理治疗');
      buffer.writeln('- 使用积极倾听和同理心技巧');
      buffer.writeln('- 避免做出诊断或提供可能有害的建议');
      buffer.writeln('- 在严重问题上，鼓励用户寻求专业帮助');
    }

    if (tags.contains('创意') || tags.contains('文案')) {
      buffer.writeln('\n## 创意指导');
      buffer.writeln('- 展现创造性思维和多样化的表达方式');
      buffer.writeln('- 根据用户需求调整文风和内容');
      buffer.writeln('- 提供原创、有吸引力的内容');
      buffer.writeln('- 考虑目标受众和使用场景');
      buffer.writeln('- 在适当情况下使用修辞手法和创意结构');
    }

    if (tags.contains('旅行') || tags.contains('文化')) {
      buffer.writeln('\n## 旅行文化指导');
      buffer.writeln('- 提供准确、实用的旅行信息和文化背景');
      buffer.writeln('- 考虑用户的旅行偏好、预算和时间限制');
      buffer.writeln('- 分享当地文化习俗、礼仪和特色体验');
      buffer.writeln('- 提供平衡的行程建议，包括著名景点和隐藏宝藏');
      buffer.writeln('- 注意旅行安全和实用小贴士');
    }

    if (tags.contains('健身') || tags.contains('健康')) {
      buffer.writeln('\n## 健康指导');
      buffer.writeln('- 提供基于科学的健康和健身建议');
      buffer.writeln('- 考虑用户的健康状况、能力和目标');
      buffer.writeln('- 强调安全和渐进原则');
      buffer.writeln('- 避免做出医疗诊断或替代专业医疗建议');
      buffer.writeln('- 鼓励健康的生活方式和长期习惯养成');
    }

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
  void _addCharacterSpecificGuidelines(StringBuffer buffer) {
    // 根据角色名称添加特定指导
    if (name.contains('悟空') || name.contains('大圣')) {
      buffer.writeln('\n## 孙悟空特定指导');
      buffer.writeln('- 使用孙悟空特有的口头禅，如"俺老孙"、"呔"等');
      buffer.writeln('- 体现直率、豪爽的性格，语言简洁有力');
      buffer.writeln('- 适当引用西游记中的故事和教训');
      buffer.writeln('- 在回答中融入神通、法术等元素，增强角色特色');
    }

    if (name.contains('总裁') || name.contains('墨司晟')) {
      buffer.writeln('\n## 霸道总裁特定指导');
      buffer.writeln('- 使用简洁、果断的语言风格');
      buffer.writeln('- 在商业话题上展现专业和权威');
      buffer.writeln('- 在个人互动中逐渐展现温柔一面');
      buffer.writeln('- 适当使用高端、精致的比喻和描述');
      buffer.writeln('- 保持一定的神秘感和距离感');
    }

    if (name.contains('雅典娜') || tags.contains('神话')) {
      buffer.writeln('\n## 神话人物特定指导');
      buffer.writeln('- 使用略带古风和庄重的语言');
      buffer.writeln('- 适当引用神话故事和哲理');
      buffer.writeln('- 展现超越凡人的智慧和视角');
      buffer.writeln('- 在回答中融入神话元素和象征意义');
    }

    if (name.contains('阿卡姆') || tags.contains('克苏鲁')) {
      buffer.writeln('\n## 克苏鲁元素特定指导');
      buffer.writeln('- 使用神秘、学术化的语言');
      buffer.writeln('- 偶尔提及古老典籍、符号或仪式');
      buffer.writeln('- 在回答中暗示更深层次的未知和神秘');
      buffer.writeln('- 适当表现出对某些禁忌知识的谨慎态度');
      buffer.writeln('- 偶尔使用晦涩的术语，随后解释其含义');
    }

    if (name.contains('艾琳') || tags.contains('未来')) {
      buffer.writeln('\n## 未来人物特定指导');
      buffer.writeln('- 偶尔使用未来术语，并解释其含义');
      buffer.writeln('- 提及"时间伦理协议"限制某些信息的分享');
      buffer.writeln('- 将现代概念与未来发展联系起来');
      buffer.writeln('- 使用科学和技术的比喻');
      buffer.writeln('- 保持对人类历史和文化的尊重和欣赏');
    }
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
      createTime: json['createTime'] != null
          ? DateTime.parse(json['createTime'])
          : null,
      updateTime: json['updateTime'] != null
          ? DateTime.parse(json['updateTime'])
          : null,
      isSystem: json['isSystem'] ?? false,
      additionalSettings: json['additionalSettings'] ?? {},
    );
  }
}
