import 'dart:convert';
import 'dart:io';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path_provider/path_provider.dart';
import 'package:proste_logger/proste_logger.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import 'character_card.dart';
import 'character_chat_session.dart';
import 'character_chat_message.dart';

import 'import_result.dart';

final pl = ProsteLogger();

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
  // 系统角色卡固定id，避免用户导入消息后因为角色id变化导致历史记录匹配不上
  Future<CharacterCard> createCharacter({
    required String id,
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
      id: id,
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
    String? reasoningContent,
    int? thinkingDuration,
  }) async {
    final message = CharacterChatMessage(
      content: content,
      role: role,
      characterId: characterId,
      contentVoicePath: contentVoicePath,
      imagesUrl: imagesUrl,
      reasoningContent: reasoningContent,
      thinkingDuration: thinkingDuration,
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
    String? reasoningContent,
    int? thinkingDuration,
  }) async {
    final index = session.messages.indexWhere((m) => m.id == message.id);
    if (index >= 0) {
      if (content != null) message.content = content;
      if (promptTokens != null) message.promptTokens = promptTokens;
      if (completionTokens != null) message.completionTokens = completionTokens;
      if (totalTokens != null) message.totalTokens = totalTokens;
      if (reasoningContent != null) message.reasoningContent = reasoningContent;
      if (thinkingDuration != null) message.thinkingDuration = thinkingDuration;

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
      pl.e('Error loading characters: $e');
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
      pl.e('保存角色卡失败: $e');
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
      pl.e('加载会话失败: $e');
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
      pl.e('保存会话失败: $e');
    }
  }

  // 创建默认角色卡
  Future<void> _createDefaultCharacters() async {
    // 创建工具角色
    await _createToolCharacters();

    // 创建虚拟角色
    await _createVirtualCharacters();
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

  // 创建默认角色卡
  Future<void> _createToolCharacters() async {
    // 图像识别专家
    await createCharacter(
      id: identityHashCode("图像分析师").toString(),
      name: '图像分析师',
      avatar: 'http://img.sccnn.com/bimg/337/39878.jpg',
      description: '专业的图像识别和分析专家，可以分析图片内容，识别物体、场景、文字等元素，并提供详细解释。',
      personality: '观察力敏锐、分析性强、专业、细致。我会仔细分析图像中的各种元素，并提供专业、全面的解读。',
      scenario:
          '我是一位专业的图像分析师，可以帮助你分析和理解各种图像。无论是识别图中的物体、解读场景、提取文字，还是分析图像的构图和风格，我都能提供专业的见解。',
      firstMessage:
          '你好！我是图像分析师，可以帮你分析各种图片。只需发送一张图片，我就能识别其中的内容并提供详细解读。你有什么图像需要分析吗？',
      exampleDialogue:
          '用户: [发送了一张城市街景照片]\n图像分析师: 这张照片展示了一个繁忙的城市街景。我可以看到高楼大厦、行人和车辆。照片右侧有一家咖啡店，招牌上写着"City Brew"。天空呈现蓝色，表明这是在晴天拍摄的。照片的构图采用了透视法，让街道延伸到远处，创造出深度感。你想了解这张照片的哪些具体细节？',
      tags: ['图像', '视觉', '分析'],
      isSystem: true,
    );
  }

  // 创建虚拟角色卡
  Future<void> _createVirtualCharacters() async {
    await createCharacter(
      id: identityHashCode("齐天大圣孙悟空").toString(),
      name: '齐天大圣孙悟空',
      avatar:
          'https://gd-hbimg.huaban.com/d33962e90585c683ccd513a829cfdb66ce97f951146bf-kSPhPL_fw658webp',
      description:
          '中国古典名著《西游记》中的主角，从石头中诞生的猴王，曾大闹天宫，后被如来佛祖压在五行山下。皈依佛门后，保护唐僧西行取经，历经九九八十一难。',
      personality:
          '桀骜不驯、聪明机智、忠诚、嫉恶如仇、有些自负。我性格直率，不喜欢拐弯抹角，对敌人毫不留情，对朋友却赤诚相待。我有时会耍些小聪明，但内心重情重义。',
      scenario:
          '取经归来后的我，已成为斗战胜佛，但仍保留着猴王的本性。我可能正在云游四海，或是回到花果山探望猴群，偶尔与凡人相遇，分享我的冒险故事和人生感悟。',
      firstMessage:
          '哈哈！俺老孙来也！*耳朵抖动，金箍棒在手中转了个圈* 呔！看你面相不凡，莫非是有什么妖怪缠身？还是想听俺老孙讲讲当年大闹天宫的威风事迹？',
      exampleDialogue:
          '用户: 大圣，我最近遇到了很多困难，感觉自己不够强大，不知道该怎么办。\n孙悟空: *挠挠头* 嘿，别灰心！俺老孙当年可是被压在五行山下五百年哩！*拍拍你的肩膀* 你知道俺老孙为啥厉害吗？不是因为会七十二变，也不是因为火眼金睛。是因为俺有一颗不服输的心！*指着自己的胸口* 再厉害的妖怪，再难的关卡，只要不放弃，总能找到破解之法。你现在的困难，在俺老孙眼里，不过是块绊脚石罢了。挺起胸膛，大胆向前冲！记住，困难越大，说明你越重要，不然妖怪们干嘛非跟你过不去？哈哈哈！',
      tags: ['虚拟', '神话', '中国'],
      isSystem: true,
    );
  }

  // 导出所有角色卡到用户指定位置
  Future<String> exportCharacters({String? customPath}) async {
    try {
      String filePath;
      if (customPath != null) {
        filePath =
            '$customPath/角色列表_${DateTime.now().millisecondsSinceEpoch}.json';
      } else {
        final directory = await getApplicationDocumentsDirectory();
        filePath =
            '${directory.path}/角色列表_${DateTime.now().millisecondsSinceEpoch}.json';
      }

      final file = File(filePath);

      // 只导出非系统角色
      final userCharacters = _characters.where((c) => !c.isSystem).toList();
      final jsonList = userCharacters.map((c) => c.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));

      return filePath;
    } catch (e) {
      pl.e('导出角色卡失败: $e');
      rethrow;
    }
  }

  // 导出特定会话的历史记录到用户指定位置
  Future<String> exportSessionHistory(String sessionId,
      {String? customPath}) async {
    try {
      final session = _sessions.firstWhere((s) => s.id == sessionId);

      String filePath;
      if (customPath != null) {
        filePath =
            '$customPath/角色对话记录_${session.title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.json';
      } else {
        final directory = await getApplicationDocumentsDirectory();
        filePath =
            '${directory.path}/角色对话记录_${session.title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.json';
      }

      final file = File(filePath);

      final jsonData = session.toJson();
      await file.writeAsString(jsonEncode(jsonData));

      return filePath;
    } catch (e) {
      pl.e('导出会话历史记录失败: $e');
      rethrow;
    }
  }

  // 导出所有会话历史记录到用户指定位置
  Future<String> exportAllSessionsHistory({String? customPath}) async {
    try {
      String directoryPath;
      if (customPath != null) {
        directoryPath = customPath;
      } else {
        final directory = await getApplicationDocumentsDirectory();
        directoryPath = directory.path;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$directoryPath/所有角色对话记录_$timestamp.json';
      final file = File(filePath);

      final jsonList = _sessions.map((s) => s.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));

      return filePath;
    } catch (e) {
      pl.e('导出所有会话历史记录失败: $e');
      rethrow;
    }
  }

  // 导入会话历史记录，跳过已存在的记录
  Future<ImportSessionsResult> importSessionHistory(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在');
      }

      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString);

      // 检查是单个会话还是多个会话的集合
      if (json is List) {
        // 多个会话
        return _importMultipleSessions(json);
      } else {
        // 单个会话
        final session = CharacterChatSession.fromJson(json);
        return _importSingleSession(session);
      }
    } catch (e) {
      pl.e('导入会话历史记录失败: $e');
      rethrow;
    }
  }

  // 导入单个会话
  Future<ImportSessionsResult> _importSingleSession(
    CharacterChatSession session,
  ) async {
    // 检查会话是否已存在
    final existingSessionIndex =
        _sessions.indexWhere((s) => s.id == session.id);

    // 如果会话已存在，则跳过
    if (existingSessionIndex >= 0) {
      return ImportSessionsResult(
        importedSessions: 0,
        skippedSessions: 1,
        importedCharacters: session.characters.length,
        firstSession: session,
      );
    }

    // 确保会话中的角色存在
    for (var i = 0; i < session.characters.length; i++) {
      final character = session.characters[i];
      if (!_characters.any((c) => c.id == character.id)) {
        // 如果角色不存在，添加到角色列表
        _characters.add(character);
      } else {
        // 如果角色已存在，使用现有角色
        session.characters[i] =
            _characters.firstWhere((c) => c.id == character.id);
      }
    }

    _sessions.add(session);
    await _saveCharacters();
    await _saveSessions();

    return ImportSessionsResult(
      importedSessions: 1,
      skippedSessions: 0,
      importedCharacters: session.characters.length,
      firstSession: session,
    );
  }

  // 导入多个会话
  Future<ImportSessionsResult> _importMultipleSessions(
      List<dynamic> jsonList) async {
    int importedCount = 0;
    int skippedCount = 0;
    int importedCharacters = 0;
    CharacterChatSession? firstSession;

    for (var json in jsonList) {
      try {
        final session = CharacterChatSession.fromJson(json);

        // 检查会话是否已存在
        if (_sessions.any((s) => s.id == session.id)) {
          // 会话已存在，跳过
          skippedCount++;
          continue;
        }

        // 确保会话中的角色存在
        for (var i = 0; i < session.characters.length; i++) {
          final character = session.characters[i];
          if (!_characters.any((c) => c.id == character.id)) {
            // 如果角色不存在，添加到角色列表
            _characters.add(character);
            importedCharacters++;
          } else {
            // 如果角色已存在，使用现有角色
            session.characters[i] =
                _characters.firstWhere((c) => c.id == character.id);
          }
        }

        _sessions.add(session);
        importedCount++;

        firstSession ??= session;
      } catch (e) {
        pl.e('导入会话失败: $e');
        // 继续导入其他会话
      }
    }

    if (importedCount > 0) {
      await _saveCharacters();
      await _saveSessions();
    }

    return ImportSessionsResult(
      importedSessions: importedCount,
      skippedSessions: skippedCount,
      importedCharacters: importedCharacters,
      firstSession: firstSession,
    );
  }

  // 从JSON文件导入角色卡
  Future<ImportCharactersResult> importCharacters(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在');
      }

      final jsonString = await file.readAsString();
      final jsonList = jsonDecode(jsonString) as List;

      int importedCount = 0;
      int skippedCount = 0;

      for (var json in jsonList) {
        try {
          // 角色的名称、描述不能为空
          if (json['name'] == null || json['name'].toString().trim().isEmpty) {
            EasyLoading.showToast('角色名称不能为空');
            skippedCount++;
            continue;
          }

          if (json['description'] == null ||
              json['description'].toString().trim().isEmpty) {
            EasyLoading.showToast('角色描述不能为空');
            skippedCount++;
            continue;
          }

          // 如果没有头像，默认空字符避免报错
          if (json['avatar'] == null) {
            json['avatar'] = '';
          }

          // 如果角色、描述不为空，但id为空，则生成一个id
          if (json['id'] == null || json['id'].toString().trim().isEmpty) {
            json['id'] = identityHashCode(json['name']).toString();
          }

          final character = CharacterCard.fromJson(json);

          // 检查角色是否已存在
          if (_characters.any((c) => c.id == character.id)) {
            // 角色已存在，跳过
            skippedCount++;
            continue;
          }

          // 标记为非系统角色
          character.isSystem = false;
          _characters.add(character);
          importedCount++;
        } catch (e) {
          // 继续导入其他角色
          pl.e('导入角色失败: $e');
          // rethrow;
        }
      }

      if (importedCount > 0) {
        await _saveCharacters();
      }

      return ImportCharactersResult(
        importedCount: importedCount,
        skippedCount: skippedCount,
      );
    } catch (e) {
      rethrow;
    }
  }

  // 从会话中移除角色
  Future<CharacterChatSession> removeCharacterFromSession(
    CharacterChatSession session,
    String characterId,
  ) async {
    // 创建会话的副本
    final updatedSession = CharacterChatSession(
      id: session.id,
      title: session.title,
      characters: List.from(session.characters),
      messages: List.from(session.messages),
      createTime: session.createTime,
      updateTime: DateTime.now(),
      activeModel: session.activeModel,
    );

    // 从角色列表中移除指定角色
    updatedSession.characters.removeWhere((c) => c.id == characterId);

    // 确保至少保留一个角色
    if (updatedSession.characters.isEmpty) {
      throw Exception('会话必须至少包含一个角色');
    }

    // 更新会话
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index >= 0) {
      _sessions[index] = updatedSession;
      await _saveSessions();
    }

    return updatedSession;
  }
}
