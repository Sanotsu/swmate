import 'package:flutter/material.dart';
import '../../../models/brief_ai_tools/chat_branch/chat_branch_message.dart';
import '../../../models/brief_ai_tools/chat_branch/branch_manager.dart';
import '../../../models/brief_ai_tools/chat_branch/branch_store.dart';
import '../../../models/brief_ai_tools/chat_branch/chat_branch_session.dart';
import 'components/branch_message_item.dart';
import 'components/branch_tree_dialog.dart';
import 'components/chat_input_bar.dart';
import '../../../services/ai_service.dart';
import 'components/chat_history_drawer.dart';
import 'package:flutter/services.dart';

import 'components/text_selection_dialog.dart';

class BranchChatPage extends StatefulWidget {
  const BranchChatPage({super.key});

  @override
  State<BranchChatPage> createState() => _BranchChatPageState();
}

class _BranchChatPageState extends State<BranchChatPage> {
  final TextEditingController _inputController = TextEditingController();
  final BranchManager _branchManager = BranchManager();
  late final BranchStore _store;
  final AIService _aiService = AIService();

  List<ChatBranchMessage> allMessages = [];
  List<ChatBranchMessage> displayMessages = [];
  String currentBranchPath = "0";
  ChatBranchMessage? currentEditingMessage;
  bool isLoading = true;
  bool isStreaming = false;
  String streamingContent = '';
  ChatBranchMessage? streamingMessage;
  int? _currentSessionId;
  int? regeneratingMessageId;
  bool isNewChat = false;

  @override
  void initState() {
    super.initState();
    _initStore();
  }

  Future<void> _initStore() async {
    _store = await BranchStore.create();

    // 获取今天的最后一条对话记录
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    final sessions = _store.sessionBox.getAll()
      ..sort((a, b) => b.updateTime.compareTo(a.updateTime));

    if (sessions.isEmpty) {
      setState(() {
        isNewChat = true;
        isLoading = false;
      });
      return;
    }

    final todayLastSession = sessions.firstWhere(
      (session) => session.updateTime.isAfter(todayStart),
      orElse: () => sessions.isEmpty ? throw Exception() : sessions.first,
    );

    try {
      setState(() {
        _currentSessionId = todayLastSession.id;
        isNewChat = false;
        isLoading = false;
      });
      await _loadMessages();
    } catch (e) {
      // 如果没有任何对话记录，显示新对话界面
      setState(() {
        isNewChat = true;
        isLoading = false;
      });
    }
  }

  Future<void> _loadMessages() async {
    if (_currentSessionId == null) {
      setState(() => isNewChat = true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final messages = _store.getSessionMessages(_currentSessionId!);
      if (messages.isEmpty) {
        setState(() {
          isNewChat = true;
          isLoading = false;
        });
        return;
      }

      final currentMessages = _branchManager.getMessagesByBranchPath(
        messages,
        currentBranchPath,
      );

      setState(() {
        allMessages = messages;
        displayMessages = [
          ...currentMessages,
          if (isStreaming && streamingContent.isNotEmpty)
            ChatBranchMessage(
              id: 0,
              messageId: 'streaming',
              role: 'assistant',
              content: streamingContent,
              createTime: DateTime.now(),
              branchPath: currentBranchPath,
              branchIndex: currentMessages.isEmpty
                  ? 0
                  : currentMessages.last.branchIndex,
              depth: currentMessages.isEmpty ? 0 : currentMessages.last.depth,
            ),
        ];
        isLoading = false;
      });
    } catch (e) {
      print('加载消息失败: $e');
      setState(() {
        isNewChat = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isNewChat ? '新对话' : '对话'),
        actions: [
          if (!isStreaming)
            IconButton(
              icon: const Icon(Icons.account_tree),
              onPressed: !isNewChat ? _showBranchTree : null,
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewChat,
          ),
        ],
      ),
      drawer: FutureBuilder<List<ChatBranchSession>>(
        future: _loadSessions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Drawer(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return ChatHistoryDrawer(
            sessions: snapshot.data ?? [],
            currentSessionId: _currentSessionId,
            isNewChat: isNewChat,
            onSessionSelected: (session) => _switchSession(session.id),
            onSessionEdit: _editSessionTitle,
            onSessionDelete: _deleteSession,
          );
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildChatContent(),
          ),
          ChatInputBar(
            controller: _inputController,
            onSend: _handleSendMessage,
            isEditing: currentEditingMessage != null,
            isStreaming: isStreaming,
            onStop: _handleStopStreaming,
          ),
        ],
      ),
    );
  }

  Widget _buildChatContent() {
    if (isNewChat) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '开始新的对话',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '输入消息开始对话',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: displayMessages.length,
      itemBuilder: (context, index) {
        final message = displayMessages[index];

        print("用于展示的消息: 长度${displayMessages.length} ${message.content}");

        final isStreamingMessage = message.messageId == 'streaming';
        final hasMultipleBranches = !isStreamingMessage &&
            _branchManager.getBranchCount(allMessages, message) > 1;

        return BranchMessageItem(
          message: message,
          messages: allMessages,
          onEdit: isStreaming ? null : _handleMessageEdit,
          onRegenerate: isStreaming ? null : _handleRegenerate,
          onSwitchBranch: isStreaming ? null : _handleSwitchBranch,
          hasMultipleBranches: hasMultipleBranches,
          currentBranchIndex: isStreamingMessage
              ? 0
              : _branchManager.getBranchIndex(allMessages, message),
          totalBranches: isStreamingMessage
              ? 1
              : _branchManager.getBranchCount(allMessages, message),
          onLongPress: isStreaming ? null : _showMessageOptions,
          isRegenerating: message.id == regeneratingMessageId,
        );
      },
    );
  }

  void _showMessageOptions(
    ChatBranchMessage message,
    LongPressStartDetails details,
  ) {
    // 添加振动反馈
    HapticFeedback.mediumImpact();

    final Offset overlayPosition = details.globalPosition;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        overlayPosition.dx,
        overlayPosition.dy,
        overlayPosition.dx + 200,
        overlayPosition.dy + 100,
      ),
      items: [
        // 复制按钮
        PopupMenuItem<String>(
          value: 'copy',
          child: const Row(
            children: [
              Icon(Icons.copy),
              SizedBox(width: 8),
              Text('复制文本'),
            ],
          ),
        ),
        // 选择文本按钮
        PopupMenuItem<String>(
          value: 'select',
          child: const Row(
            children: [
              Icon(Icons.text_fields),
              SizedBox(width: 8),
              Text('选择文本'),
            ],
          ),
        ),
        if (message.role == 'user')
          PopupMenuItem<String>(
            value: 'edit',
            child: const Row(
              children: [
                Icon(Icons.edit),
                SizedBox(width: 8),
                Text('编辑消息'),
              ],
            ),
          ),
        if (message.role == 'assistant')
          PopupMenuItem<String>(
            value: 'regenerate',
            child: const Row(
              children: [
                Icon(Icons.refresh),
                SizedBox(width: 8),
                Text('重新生成'),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'delete',
          child: const Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('删除分支', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    ).then((value) async {
      if (value == 'copy') {
        await Clipboard.setData(ClipboardData(text: message.content));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已复制到剪贴板')),
        );
      } else if (value == 'select') {
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (context) => TextSelectionDialog(text: message.content),
        );
      } else if (value == 'edit') {
        _handleMessageEdit(message);
      } else if (value == 'regenerate') {
        _handleRegenerate(message);
      } else if (value == 'delete') {
        await _handleDeleteBranch(message);
      }
    });
  }

  Future<void> _handleSendMessage() async {
    final content = _inputController.text.trim();
    if (content.isEmpty) return;

    try {
      if (isNewChat) {
        final title = content.length > 20 ? content.substring(0, 20) : content;
        final session = await _store.createSession(title);
        setState(() {
          _currentSessionId = session.id;
          isNewChat = false;
        });
      }

      if (currentEditingMessage != null) {
        await _handleEditMessage(currentEditingMessage!);
      } else {
        await _store.addMessage(
          session: _store.sessionBox.get(_currentSessionId!)!,
          content: content,
          role: 'user',
          parent: displayMessages.isEmpty ? null : displayMessages.last,
        );

        _inputController.clear();
        await _loadMessages();
        await _generateAIResponse();
      }
    } catch (e) {
      print('发送消息失败: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('发送消息失败: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleEditMessage(ChatBranchMessage message) async {
    final content = _inputController.text.trim();
    if (content.isEmpty) return;

    try {
      // 获取当前分支的所有消息
      final currentMessages = _branchManager.getMessagesByBranchPath(
        allMessages,
        currentBranchPath,
      );

      // 找到要编辑的消息在当前分支中的位置
      final messageIndex = currentMessages.indexOf(message);
      if (messageIndex == -1) return;

      // 获取同级分支
      final siblings = _branchManager.getSiblingBranches(allMessages, message);

      // 创建新分支
      final newBranchIndex =
          siblings.isEmpty ? 0 : siblings.last.branchIndex + 1;

      // 构建新的分支路径
      String newPath;
      if (message.parent.target == null) {
        newPath = newBranchIndex.toString();
      } else {
        final parentPath = message.branchPath.substring(
          0,
          message.branchPath.lastIndexOf('/'),
        );
        newPath = '$parentPath/$newBranchIndex';
      }

      // 创建新的用户消息
      await _store.addMessage(
        session: _store.sessionBox.get(_currentSessionId!)!,
        content: content,
        role: 'user',
        parent: message.parent.target,
        branchIndex: newBranchIndex, // 只使用 branchIndex 参数
      );

      setState(() {
        currentBranchPath = newPath;
        currentEditingMessage = null;
        _inputController.clear();
      });

      await _loadMessages();
      await _generateAIResponse();
    } catch (e) {
      print('编辑消息失败: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('编辑消息失败: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleRegenerate(ChatBranchMessage message) async {
    setState(() => regeneratingMessageId = message.id);

    try {
      final currentMessages = _branchManager.getMessagesByBranchPath(
        allMessages,
        message.branchPath,
      );

      final messageIndex = currentMessages.indexOf(message);
      if (messageIndex == -1) return;

      final contextMessages = currentMessages.sublist(0, messageIndex);

      // 获取同级分支并计算新的分支索引
      final siblings = _branchManager.getSiblingBranches(allMessages, message);
      final availableSiblings = siblings
          .where((m) => allMessages.contains(m))
          .toList()
        ..sort((a, b) => a.branchIndex.compareTo(b.branchIndex));
      final newBranchIndex = availableSiblings.isEmpty
          ? 0
          : availableSiblings.last.branchIndex + 1;

      // 构建新的分支路径
      String newPath;
      if (message.parent.target == null) {
        newPath = newBranchIndex.toString();
      } else {
        final parentPath = message.branchPath.substring(
          0,
          message.branchPath.lastIndexOf('/'),
        );
        newPath = '$parentPath/$newBranchIndex';
      }

      setState(() {
        isStreaming = true;
        streamingContent = '';
        // 创建临时的流式消息
        displayMessages = [
          ...contextMessages,
          ChatBranchMessage(
            id: 0,
            messageId: 'streaming',
            role: 'assistant',
            content: '', // 初始为空
            createTime: DateTime.now(),
            branchPath: newPath, // 使用新的分支路径
            branchIndex: newBranchIndex,
            depth: message.depth,
          ),
        ];
      });

      String finalContent = '';

      final response = await _aiService.generateResponse(
        messages: contextMessages,
        modelLabel: message.modelLabel,
        stream: true,
        onStream: (chunk) {
          if (!isStreaming) return;
          setState(() {
            streamingContent += chunk;
            finalContent += chunk;
            // 更新显示消息列表中的流式消息内容
            displayMessages = [
              ...contextMessages,
              ChatBranchMessage(
                id: 0,
                messageId: 'streaming',
                role: 'assistant',
                content: streamingContent,
                createTime: DateTime.now(),
                branchPath: newPath, // 使用新的分支路径
                branchIndex: newBranchIndex,
                depth: message.depth,
              ),
            ];
          });
        },
      );

      if (!isStreaming) return;

      // 创建新的分支消息
      final newMessage = await _store.addMessage(
        session: message.session.target!,
        content: finalContent.isNotEmpty ? finalContent : response['content'],
        role: 'assistant',
        parent: message.parent.target,
        reasoningContent: response['reasoningContent'],
        thinkingDuration: response['thinkingDuration'],
        modelLabel: message.modelLabel,
        branchIndex: newBranchIndex,
      );

      // 切换到新分支
      setState(() {
        currentBranchPath = newMessage.branchPath;
        isStreaming = false;
        streamingContent = '';
      });

      // 重新加载消息
      await _loadMessages();
    } catch (e) {
      print('重新生成失败: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('重新生成失败: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => regeneratingMessageId = null);
      }
    }
  }

  Future<void> _generateAIResponse() async {
    setState(() {
      isStreaming = true;
      streamingContent = '';
    });

    String finalContent = '';
    ChatBranchMessage? aiMessage;

    try {
      // 获取当前分支的消息，不包括之前可能存在的流式消息
      final currentMessages = _branchManager.getMessagesByBranchPath(
        allMessages,
        currentBranchPath,
      );

      if (currentMessages.isEmpty) {
        print('Error: No messages found for branch path: $currentBranchPath');
        return;
      }

      // 创建临时的流式消息
      final streamingMessage = ChatBranchMessage(
        id: 0,
        messageId: 'streaming',
        role: 'assistant',
        content: '', // 初始为空
        createTime: DateTime.now(),
        branchPath: currentBranchPath,
        branchIndex:
            currentMessages.isEmpty ? 0 : currentMessages.last.branchIndex,
        depth: currentMessages.isEmpty ? 0 : currentMessages.last.depth,
      );

      setState(() {
        displayMessages = [...currentMessages, streamingMessage];
      });

      final response = await _aiService.generateResponse(
        messages: currentMessages,
        modelLabel: 'default',
        stream: true,
        onStream: (chunk) {
          if (!isStreaming) return;
          setState(() {
            streamingContent += chunk;
            finalContent += chunk;
            // 更新流式消息的内容
            streamingMessage.content = streamingContent;
            displayMessages = [...currentMessages, streamingMessage];
          });
        },
      );

      if (!isStreaming) return;

      // 流式响应结束后，保存完整消息
      aiMessage = await _store.addMessage(
        session: _store.sessionBox.get(_currentSessionId!)!,
        content: finalContent.isNotEmpty ? finalContent : response['content'],
        role: 'assistant',
        parent: currentMessages.last,
        reasoningContent: response['reasoningContent'],
        thinkingDuration: response['thinkingDuration'],
        modelLabel: 'default',
      );

      // 更新 allMessages 和 displayMessages
      setState(() {
        // allMessages = [...allMessages, aiMessage!];
        // displayMessages = [...currentMessages, aiMessage];
        isStreaming = false;
        streamingContent = '';
        currentBranchPath = aiMessage!.branchPath;
      });

      await _loadMessages();
    } catch (e) {
      print('Error generating AI response: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI 响应生成失败: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isStreaming = false;
          streamingContent = '';
        });
      }
    }
  }

  Future<void> _handleDeleteBranch(ChatBranchMessage message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除分支'),
        content: const Text('确定要删除这个分支及其所有子分支吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 在删除前获取同级分支信息
      final siblings = _branchManager.getSiblingBranches(allMessages, message);
      final currentIndex = siblings.indexOf(message);
      final parent = message.parent.target;
      String newPath = "0";

      // 确定删除后要切换到的分支路径
      if (siblings.length > 1) {
        // 如果有其他同级分支，切换到前一个或后一个分支
        final targetIndex = currentIndex > 0 ? currentIndex - 1 : 1;
        final targetMessage = siblings[targetIndex];
        newPath = targetMessage.branchPath;
      } else if (parent != null) {
        // 如果没有其他同级分支，切换到父分支
        newPath = parent.branchPath;
      }

      // 删除分支
      await _store.deleteMessageWithBranches(message);

      // 更新当前分支路径并重新加载消息
      setState(() {
        currentBranchPath = newPath;
      });
      await _loadMessages();
    }
  }

  void _handleSwitchBranch(ChatBranchMessage message, int newBranchIndex) {
    final availableBranchIndex = _branchManager.getNextAvailableBranchIndex(
      allMessages,
      message,
      newBranchIndex,
    );

    // 如果没有可用的分支，不执行切换
    if (availableBranchIndex == -1) return;

    String newPath;
    if (message.parent.target == null) {
      // 如果是根消息，直接使用新的索引作为路径
      newPath = availableBranchIndex.toString();
    } else {
      // 非根消息，计算完整的分支路径
      final parentPath =
          message.branchPath.substring(0, message.branchPath.lastIndexOf('/'));
      newPath = parentPath.isEmpty
          ? availableBranchIndex.toString()
          : '$parentPath/$availableBranchIndex';
    }

    // 更新当前分支路径并重新加载消息
    setState(() {
      currentBranchPath = newPath;
    });

    // 重新计算当前分支的消息
    final currentMessages = _branchManager.getMessagesByBranchPath(
      allMessages,
      newPath,
    );

    // 更新显示的消息列表
    setState(() {
      displayMessages = [
        ...currentMessages,
        if (isStreaming && streamingContent.isNotEmpty)
          ChatBranchMessage(
            id: 0,
            messageId: 'streaming',
            role: 'assistant',
            content: streamingContent,
            createTime: DateTime.now(),
            branchPath: newPath,
            branchIndex:
                currentMessages.isEmpty ? 0 : currentMessages.last.branchIndex,
            depth: currentMessages.isEmpty ? 0 : currentMessages.last.depth,
          ),
      ];
    });
  }

  void _showBranchTree() {
    showDialog(
      context: context,
      builder: (context) => BranchTreeDialog(
        messages: allMessages,
        currentPath: currentBranchPath,
        onPathSelected: (path) {
          setState(() => currentBranchPath = path);
          // 重新加载选中分支的消息
          final currentMessages = _branchManager.getMessagesByBranchPath(
            allMessages,
            path,
          );
          setState(() {
            displayMessages = currentMessages;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _handleMessageEdit(ChatBranchMessage message) {
    setState(() {
      currentEditingMessage = message;
      _inputController.text = message.content;
    });
  }

  void _handleStopStreaming() {
    setState(() => isStreaming = false);
  }

  Future<void> _editSessionTitle(ChatBranchSession session) async {
    final controller = TextEditingController(text: session.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改标题'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '对话标题',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty && newTitle != session.title) {
      session.title = newTitle;
      session.updateTime = DateTime.now();
      _store.sessionBox.put(session);
      setState(() {}); // 刷新抽屉
    }
  }

  Future<List<ChatBranchSession>> _loadSessions() async {
    return _store.sessionBox.getAll()
      ..sort((a, b) => b.updateTime.compareTo(a.updateTime));
  }

  void _createNewChat() {
    setState(() {
      isNewChat = true;
      currentBranchPath = "0";
      isStreaming = false;
      streamingContent = '';
      currentEditingMessage = null;
      _inputController.clear();
      displayMessages.clear();
    });
  }

  Future<void> _switchSession(int sessionId) async {
    setState(() {
      _currentSessionId = sessionId;
      isNewChat = false;
      currentBranchPath = "0";
      isStreaming = false;
      streamingContent = '';
      currentEditingMessage = null;
      _inputController.clear();
    });
    await _loadMessages();
  }

  Future<void> _deleteSession(ChatBranchSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除对话'),
        content: const Text('确定要删除这个对话吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 删除会话及其所有消息
      await _store.deleteSession(session);

      // 如果删除的是当前会话，创建新会话
      if (session.id == _currentSessionId) {
        // final newSession = await _store.createSession('新对话');
        // await _switchSession(newSession.id);
        _createNewChat();
      }

      setState(() {}); // 刷新抽屉
    }
  }
}
