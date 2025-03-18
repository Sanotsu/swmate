import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import 'character_card.dart';
import 'character_chat_session.dart';
import 'character_chat_message.dart';

class CharacterStore {
  // 单例模式
  static final CharacterStore _instance = CharacterStore._internal();
  factory CharacterStore() => _instance;
  CharacterStore._internal();

  // 角色卡列表
  List<CharacterCard> _characters = [];
  // 对话会话列表
  List<CharacterChatSession> _sessions = [];

  // 初始化存储
  Future<void> initialize() async {
    await _loadCharacters();
    await _loadSessions();

    // 如果没有角色卡，创建默认角色卡
    if (_characters.isEmpty) {
      await _createDefaultCharacters();
    }
  }

  // 获取所有角色卡
  List<CharacterCard> get characters => List.unmodifiable(_characters);

  // 获取所有会话
  List<CharacterChatSession> get sessions => List.unmodifiable(_sessions);

  // 创建新角色卡
  Future<CharacterCard> createCharacter({
    required String name,
    required String avatar,
    required String description,
    String personality = '',
    String scenario = '',
    String firstMessage = '',
    String exampleDialogue = '',
    List<String>? tags,
    CusBriefLLMSpec? preferredModel,
    bool isSystem = false,
  }) async {
    final character = CharacterCard(
      name: name,
      avatar: avatar,
      description: description,
      personality: personality,
      scenario: scenario,
      firstMessage: firstMessage,
      exampleDialogue: exampleDialogue,
      tags: tags,
      preferredModel: preferredModel,
      isSystem: isSystem,
    );

    _characters.add(character);
    await _saveCharacters();
    return character;
  }

  // 更新角色卡
  Future<CharacterCard> updateCharacter(CharacterCard character) async {
    final index = _characters.indexWhere((c) => c.id == character.id);
    if (index >= 0) {
      character.updateTime = DateTime.now();
      _characters[index] = character;
      await _saveCharacters();
    }
    return character;
  }

  // 删除角色卡
  Future<bool> deleteCharacter(String characterId) async {
    final index = _characters.indexWhere((c) => c.id == characterId);
    if (index >= 0) {
      _characters.removeAt(index);
      await _saveCharacters();
      return true;
    }
    return false;
  }

  // 创建新会话
  Future<CharacterChatSession> createSession({
    required String title,
    required List<CharacterCard> characters,
    CusBriefLLMSpec? activeModel,
  }) async {
    final session = CharacterChatSession(
      title: title,
      characters: characters,
      activeModel: activeModel,
    );

    // 添加角色的首条消息
    for (var character in characters) {
      if (character.firstMessage.isNotEmpty) {
        session.messages.add(CharacterChatMessage(
          content: character.firstMessage,
          role: 'assistant',
          characterId: character.id,
        ));
      }
    }

    _sessions.add(session);
    await _saveSessions();
    return session;
  }

  // 更新会话
  Future<CharacterChatSession> updateSession(
      CharacterChatSession session) async {
    session.updateTime = DateTime.now();
    await saveSession(session);
    return session;
  }

  // 删除会话
  Future<bool> deleteSession(String sessionId) async {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index >= 0) {
      _sessions.removeAt(index);
      await _saveSessions();
      return true;
    }
    return false;
  }

  // 添加消息到会话
  Future<CharacterChatMessage> addMessage({
    required CharacterChatSession session,
    required String content,
    required String role,
    String? characterId,
    String? contentVoicePath,
    String? imagesUrl,
  }) async {
    final message = CharacterChatMessage(
      content: content,
      role: role,
      characterId: characterId,
      contentVoicePath: contentVoicePath,
      imagesUrl: imagesUrl,
    );

    session.messages.add(message);
    session.updateTime = DateTime.now();
    await updateSession(session);
    return message;
  }

  // 更新消息
  Future<CharacterChatMessage> updateMessage({
    required CharacterChatSession session,
    required CharacterChatMessage message,
    String? content,
    int? promptTokens,
    int? completionTokens,
    int? totalTokens,
  }) async {
    final index = session.messages.indexWhere((m) => m.id == message.id);
    if (index >= 0) {
      if (content != null) message.content = content;
      if (promptTokens != null) message.promptTokens = promptTokens;
      if (completionTokens != null) message.completionTokens = completionTokens;
      if (totalTokens != null) message.totalTokens = totalTokens;

      session.messages[index] = message;
      session.updateTime = DateTime.now();
      await updateSession(session);
    }
    return message;
  }

  // 加载角色卡
  Future<void> _loadCharacters() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/character_cards.json');

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonList = jsonDecode(jsonString) as List;
        _characters =
            jsonList.map((json) => CharacterCard.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error loading characters: $e');
      _characters = [];
    }
  }

  // 保存角色卡
  Future<void> _saveCharacters() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/character_cards.json');

      final jsonList = _characters.map((c) => c.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      print('Error saving characters: $e');
    }
  }

  // 加载会话
  Future<void> _loadSessions() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/character_sessions.json');

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonList = jsonDecode(jsonString) as List;
        _sessions = jsonList
            .map((json) => CharacterChatSession.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('Error loading sessions: $e');
      _sessions = [];
    }
  }

  // 保存会话
  Future<void> _saveSessions() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/character_sessions.json');

      final jsonList = _sessions.map((s) => s.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      print('Error saving sessions: $e');
    }
  }

  // 创建默认角色卡
  Future<void> _createDefaultCharacters() async {
    // 创建几个预设角色
    await createCharacter(
      name: '智能助手',
      avatar: 'assets/character_avatars/assistant.png',
      description: '一个乐于助人的AI助手，可以回答各种问题并提供帮助。',
      personality: '友好、耐心、知识渊博',
      firstMessage: '你好！我是你的智能助手，有什么我可以帮助你的吗？',
      isSystem: true,
    );

    await createCharacter(
      name: '哲学家',
      avatar: 'assets/character_avatars/philosopher.png',
      description: '一位深思熟虑的哲学家，喜欢探讨人生、存在和道德等深刻问题。',
      personality: '沉思、理性、博学',
      scenario: '在一个安静的图书馆或咖啡馆中，与你进行深度的哲学对话。',
      firstMessage: '思考是存在的证明。你想探讨什么哲学问题呢？',
      isSystem: true,
    );

    await createCharacter(
      name: '故事讲述者',
      avatar: 'assets/character_avatars/storyteller.png',
      description: '一位富有想象力的故事讲述者，可以创作各种类型的故事。',
      personality: '创造性、生动、富有表现力',
      scenario: '坐在篝火旁，准备讲述一个引人入胜的故事。',
      firstMessage: '从前有个故事，等待被讲述...你想听什么类型的故事呢？',
      isSystem: true,
    );
  }

  // 更新会话标题
  Future<CharacterChatSession> updateSessionTitle(
      CharacterChatSession session, String title) async {
    session.title = title;
    session.updateTime = DateTime.now();
    return await updateSession(session);
  }

  // 清空会话消息
  Future<CharacterChatSession> clearMessages(
      CharacterChatSession session) async {
    session.messages = [];
    session.updateTime = DateTime.now();
    return await updateSession(session);
  }

  // 更新会话使用的模型
  Future<CharacterChatSession> updateSessionModel(
      CharacterChatSession session, CusBriefLLMSpec model) async {
    session.activeModel = model;
    session.updateTime = DateTime.now();
    return await updateSession(session);
  }

  // 删除消息
  Future<CharacterChatSession> deleteMessage(
      CharacterChatSession session, CharacterChatMessage message) async {
    session.messages.removeWhere((m) => m.id == message.id);
    session.updateTime = DateTime.now();
    return await updateSession(session);
  }

  // 添加角色到会话
  Future<CharacterChatSession> addCharacterToSession(
      CharacterChatSession session, CharacterCard character) async {
    if (!session.characters.any((c) => c.id == character.id)) {
      session.characters.add(character);
      session.updateTime = DateTime.now();
      return await updateSession(session);
    }
    return session;
  }

  // 更新会话中的角色信息
  Future<void> updateSessionCharacters(CharacterChatSession session) async {
    bool hasChanges = false;
    final updatedCharacters = <CharacterCard>[];

    for (final character in session.characters) {
      // 查找角色的最新信息
      final latestCharacter = characters.firstWhere(
        (c) => c.id == character.id,
        orElse: () => character, // 如果找不到，保留原始角色信息
      );

      // 检查角色是否有变化
      if (_isCharacterChanged(character, latestCharacter)) {
        hasChanges = true;
      }

      updatedCharacters.add(latestCharacter);
    }

    // 只有在角色确实有变化时才更新会话
    if (hasChanges) {
      // 更新会话中的角色信息
      session.characters = updatedCharacters;

      // 保存更新后的会话，但不更新时间戳
      await _saveSessionWithoutUpdatingTimestamp(session);
    }
  }

  // 检查角色是否有变化
  bool _isCharacterChanged(
      CharacterCard oldCharacter, CharacterCard newCharacter) {
    // 比较关键属性
    return oldCharacter.name != newCharacter.name ||
        oldCharacter.avatar != newCharacter.avatar ||
        oldCharacter.description != newCharacter.description ||
        oldCharacter.personality != newCharacter.personality ||
        oldCharacter.scenario != newCharacter.scenario ||
        oldCharacter.firstMessage != newCharacter.firstMessage ||
        oldCharacter.exampleDialogue != newCharacter.exampleDialogue ||
        !_areTagsEqual(oldCharacter.tags, newCharacter.tags) ||
        !_areModelsEqual(
            oldCharacter.preferredModel, newCharacter.preferredModel);
  }

  // 比较两个标签列表是否相等
  bool _areTagsEqual(List<String> tags1, List<String> tags2) {
    if (tags1.length != tags2.length) return false;
    for (int i = 0; i < tags1.length; i++) {
      if (tags1[i] != tags2[i]) return false;
    }
    return true;
  }

  // 比较两个模型是否相等
  bool _areModelsEqual(CusBriefLLMSpec? model1, CusBriefLLMSpec? model2) {
    if (model1 == null && model2 == null) return true;
    if (model1 == null || model2 == null) return false;
    return model1.cusLlmSpecId == model2.cusLlmSpecId;
  }

  // 保存会话但不更新时间戳
  Future<void> _saveSessionWithoutUpdatingTimestamp(
      CharacterChatSession session) async {
    // 查找会话在列表中的索引
    final index = _sessions.indexWhere((s) => s.id == session.id);

    // 如果找到会话，更新它，但保留原始更新时间
    if (index >= 0) {
      final originalUpdateTime = _sessions[index].updateTime;
      session.updateTime = originalUpdateTime; // 保留原始更新时间
      _sessions[index] = session;
    } else {
      // 如果没有找到，添加为新会话
      _sessions.add(session);
    }

    // 保存所有会话
    await _saveSessions();
  }

  // 保存单个会话
  Future<void> saveSession(CharacterChatSession session) async {
    // 查找会话在列表中的索引
    final index = _sessions.indexWhere((s) => s.id == session.id);

    // 如果找到会话，更新它
    if (index >= 0) {
      session.updateTime = DateTime.now();
      _sessions[index] = session;
    } else {
      // 如果没有找到，添加为新会话
      session.updateTime = DateTime.now();
      _sessions.add(session);
    }

    // 保存所有会话
    await _saveSessions();
  }
}
