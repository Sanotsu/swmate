import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:proste_logger/proste_logger.dart';
import 'package:uuid/uuid.dart';

import '../../../objectbox.g.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../common/llm_spec/constant_llm_enum.dart';

import 'branch_chat_export_data.dart';
import 'branch_chat_message.dart';
import 'branch_chat_session.dart';

final pl = ProsteLogger();

class BranchStore {
  /// ObjectBox 存储实例
  late final Store store;

  /// 消息 Box
  late final Box<BranchChatMessage> messageBox;

  /// 会话 Box
  late final Box<BranchChatSession> sessionBox;

  /// 单例实例
  static BranchStore? _instance;

  BranchStore._create();

  static Future<BranchStore> create() async {
    if (_instance != null) return _instance!;

    final instance = BranchStore._create();
    await instance._init();
    _instance = instance;
    return instance;
  }

  Future<void> _init() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final dbDirectory = p.join(docsDir.path, "objectbox", "branch_chat");

      // 确保目录存在
      final dir = Directory(dbDirectory);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      store = await openStore(directory: dbDirectory);
      messageBox = store.box<BranchChatMessage>();
      sessionBox = store.box<BranchChatSession>();
    } catch (e) {
      pl.e('初始化 ObjectBox 失败: $e');
      rethrow;
    }
  }

  /// 创建新会话
  Future<BranchChatSession> createSession(
    String title, {
    required CusBriefLLMSpec llmSpec,
    required LLModelType modelType,
    DateTime? createTime,
    DateTime? updateTime,
  }) async {
    final session = BranchChatSession.create(
      title: title,
      llmSpec: llmSpec,
      modelType: modelType,
      createTime: createTime,
      updateTime: updateTime,
    );

    final id = sessionBox.put(session);
    return sessionBox.get(id)!;
  }

  /// 添加消息
  Future<BranchChatMessage> addMessage({
    required BranchChatSession session,
    required String content,
    required String role,
    BranchChatMessage? parent,
    String? reasoningContent,
    int? thinkingDuration,
    String? modelLabel,
    int? branchIndex,
    String? contentVoicePath,
    String? imagesUrl,
    String? videosUrl,
    List<Map<String, dynamic>>? references,
  }) async {
    try {
      final message = BranchChatMessage(
        messageId: const Uuid().v4(),
        content: content,
        role: role,
        createTime: DateTime.now(),
        reasoningContent: reasoningContent,
        thinkingDuration: thinkingDuration,
        modelLabel: modelLabel,
        contentVoicePath: contentVoicePath,
        imagesUrl: imagesUrl,
        videosUrl: videosUrl,
        references: references,
      );

      if (parent != null) {
        message.parent.target = parent;
        message.depth = parent.depth + 1;
        message.branchIndex = branchIndex ?? parent.children.length;
        message.branchPath = '${parent.branchPath}/${message.branchIndex}';
      } else {
        message.depth = 0;
        message.branchIndex = branchIndex ?? 0;
        message.branchPath = message.branchIndex.toString();
      }

      message.session.target = session;
      session.updateTime = DateTime.now();

      // final id = messageBox.put(message);
      messageBox.put(message);
      sessionBox.put(session);

      // pl.i('添加消息 ID: $id, role: $role, 分支: ${message.branchPath}');
      return message;
    } catch (e) {
      rethrow;
    }
  }

  /// 获取会话的所有消息
  List<BranchChatMessage> getSessionMessages(int sessionId) {
    try {
      final query = messageBox
          .query(BranchChatMessage_.session.equals(sessionId))
          .build();
      final messages = query.find();
      // print('记录编号 $sessionId 找到 ${messages.length} 条消息');
      return messages;
    } catch (e) {
      pl.e('获取会话消息失败: $e');
      return [];
    }
  }

  /// 获取指定分支路径的消息
  List<BranchChatMessage> getMessagesByBranchPath(
    int sessionId,
    String branchPath,
  ) {
    final query = messageBox
        .query(BranchChatMessage_.session.equals(sessionId) &
            BranchChatMessage_.branchPath.startsWith(branchPath))
        .build();
    return query.find()..sort((a, b) => a.createTime.compareTo(b.createTime));
  }

  /// 更新消息内容
  Future<void> updateMessage(BranchChatMessage message) async {
    messageBox.put(message);
  }

  /// 删除消息及其所有子分支
  Future<void> deleteMessageWithBranches(BranchChatMessage message) async {
    final branchPath = message.branchPath;

    final branchMessages = messageBox
        .query(BranchChatMessage_.branchPath.startsWith(branchPath))
        .build()
        .find();

    messageBox.removeMany(branchMessages.map((m) => m.id).toList());

    final session = message.session.target;
    if (session != null) {
      session.updateTime = DateTime.now();
      sessionBox.put(session);
    }
  }

  /// 删除会话及其所有消息
  Future<void> deleteSession(BranchChatSession session) async {
    // 删除会话的所有消息
    final messages = messageBox
        .query(BranchChatMessage_.session.equals(session.id))
        .build()
        .find();
    messageBox.removeMany(messages.map((m) => m.id).toList());

    // 删除会话
    sessionBox.remove(session.id);
  }

  /// 导入会话历史记录
  Future<ChatHistoryImportResult> importSessionHistory(File file) async {
    try {
      // 1. 读取文件内容
      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString);

      // 2. 解析数据
      final importData = BranchChatExportData.fromJson(jsonData);

      // 3. 导入到数据库
      final store = await BranchStore.create();

      // 获取现有会话列表
      final existingSessions = store.sessionBox.getAll();
      int importedCount = 0;
      int skippedCount = 0;

      // 遍历要导入的会话
      for (final sessionExport in importData.sessions) {
        // 检查是否存在相同的会话
        final isExisting = existingSessions.any((existing) {
          return existing.createTime.toIso8601String() ==
                  sessionExport.createTime.toIso8601String() &&
              existing.title == sessionExport.title;
        });

        // 如果会话已存在，跳过
        if (isExisting) {
          skippedCount++;
          continue;
        }

        // 创建新会话(注意，因为用于判断是否重复的逻辑里面有创建时间，所以这里需要传入创建时间)
        // 不传入更新时间，因为导入会话的消息列表时，会更新会话的更新时间
        final session = await store.createSession(
          sessionExport.title,
          llmSpec: sessionExport.llmSpec,
          modelType: sessionExport.modelType,
          createTime: sessionExport.createTime,
        );

        // 创建消息映射表(用于建立父子关系)
        final messageMap = <String, BranchChatMessage>{};

        // 按深度排序消息，确保父消息先创建
        final sortedMessages = sessionExport.messages.toList()
          ..sort((a, b) => a.depth.compareTo(b.depth));

        // 创建消息
        for (final msgExport in sortedMessages) {
          final parentMsg = msgExport.parentMessageId != null
              ? messageMap[msgExport.parentMessageId]
              : null;

          // 因为对会话记录添加消息也是修改了会话，所以导入会话记录成功后，会话的修改时间也会更新
          final message = await store.addMessage(
            session: session,
            content: msgExport.content,
            role: msgExport.role,
            parent: parentMsg,
            reasoningContent: msgExport.reasoningContent,
            thinkingDuration: msgExport.thinkingDuration,
            modelLabel: msgExport.modelLabel,
            branchIndex: msgExport.branchIndex,
            contentVoicePath: msgExport.contentVoicePath,
            imagesUrl: msgExport.imagesUrl,
            videosUrl: msgExport.videosUrl,
          );

          messageMap[msgExport.messageId] = message;
        }

        importedCount++;
      }

      return ChatHistoryImportResult(
        importedCount: importedCount,
        skippedCount: skippedCount,
      );
    } catch (e) {
      pl.e('导入分支对话历史记录失败: $e');
      rethrow;
    }
  }
}

class ChatHistoryImportResult {
  final int importedCount;
  final int skippedCount;

  ChatHistoryImportResult({
    required this.importedCount,
    required this.skippedCount,
  });
}
