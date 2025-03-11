import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../objectbox.g.dart';
import 'chat_branch_message.dart';
import 'chat_branch_session.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../common/llm_spec/constant_llm_enum.dart';

class BranchStore {
  /// ObjectBox 存储实例
  late final Store store;

  /// 消息 Box
  late final Box<ChatBranchMessage> messageBox;

  /// 会话 Box
  late final Box<ChatBranchSession> sessionBox;

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
      messageBox = store.box<ChatBranchMessage>();
      sessionBox = store.box<ChatBranchSession>();
    } catch (e) {
      print('初始化 ObjectBox 失败: $e');
      rethrow;
    }
  }

  /// 创建新会话
  Future<ChatBranchSession> createSession(
    String title, {
    required CusBriefLLMSpec llmSpec,
    required LLModelType modelType,
  }) async {
    final session = ChatBranchSession.create(
      title: title,
      llmSpec: llmSpec,
      modelType: modelType,
    );
    
    final id = sessionBox.put(session);
    return sessionBox.get(id)!;
  }

  /// 添加新消息
  Future<ChatBranchMessage> addMessage({
    required ChatBranchSession session,
    required String content,
    required String role,
    ChatBranchMessage? parent,
    String? reasoningContent,
    int? thinkingDuration,
    String? modelLabel,
    int? branchIndex,
  }) async {
    try {
      final message = ChatBranchMessage(
        messageId: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        role: role,
        createTime: DateTime.now(),
        reasoningContent: reasoningContent,
        thinkingDuration: thinkingDuration,
        modelLabel: modelLabel,
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

      final id = messageBox.put(message);
      sessionBox.put(session);
      
      print('Added new message with ID: $id, role: $role, branch: ${message.branchPath}');
      return message;
    } catch (e) {
      print('Error adding message: $e');
      rethrow;
    }
  }

  /// 获取会话的所有消息
  List<ChatBranchMessage> getSessionMessages(int sessionId) {
    try {
      final query = messageBox
          .query(ChatBranchMessage_.session.equals(sessionId))
          .build();
      final messages = query.find();
      print('Found ${messages.length} messages for session $sessionId');
      return messages;
    } catch (e) {
      print('Error getting session messages: $e');
      return [];
    }
  }

  /// 获取指定分支路径的消息
  List<ChatBranchMessage> getMessagesByBranchPath(
    int sessionId,
    String branchPath,
  ) {
    final query = messageBox
        .query(ChatBranchMessage_.session.equals(sessionId) &
            ChatBranchMessage_.branchPath.startsWith(branchPath))
        .build();
    return query.find()..sort((a, b) => a.createTime.compareTo(b.createTime));
  }

  /// 更新消息内容
  Future<void> updateMessage(ChatBranchMessage message) async {
    messageBox.put(message);
  }

  /// 删除消息及其所有子分支
  Future<void> deleteMessageWithBranches(ChatBranchMessage message) async {
    final branchPath = message.branchPath;
    
    final branchMessages = messageBox
        .query(ChatBranchMessage_.branchPath.startsWith(branchPath))
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
  Future<void> deleteSession(ChatBranchSession session) async {
    // 删除会话的所有消息
    final messages = messageBox
        .query(ChatBranchMessage_.session.equals(session.id))
        .build()
        .find();
    messageBox.removeMany(messages.map((m) => m.id).toList());

    // 删除会话
    sessionBox.remove(session.id);
  }
}
