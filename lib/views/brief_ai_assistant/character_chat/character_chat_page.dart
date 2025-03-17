import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../../common/llm_spec/constant_llm_enum.dart';
import '../../../models/brief_ai_tools/character_chat/character_chat_session.dart';
import '../../../models/brief_ai_tools/character_chat/character_chat_message.dart';
import '../../../models/brief_ai_tools/character_chat/character_card.dart';
import '../../../models/brief_ai_tools/character_chat/character_store.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../services/chat_service.dart';
import '../../../services/model_manager_service.dart';
import 'components/character_message_item.dart';
import 'components/character_input_bar.dart';
import 'components/model_selector_dialog.dart';
import 'components/session_history_drawer.dart';

class CharacterChatPage extends StatefulWidget {
  final CharacterChatSession session;

  const CharacterChatPage({super.key, required this.session});

  @override
  State<CharacterChatPage> createState() => _CharacterChatPageState();
}

class _CharacterChatPageState extends State<CharacterChatPage>
    with WidgetsBindingObserver {
  final CharacterStore _store = CharacterStore();

  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late CharacterChatSession _session;
  List<CharacterChatSession> _allSessions = [];
  bool _isLoading = false;
  bool _isStreaming = false;
  CusBriefLLMSpec? _activeModel;
  VoidCallback? _cancelGeneration;

  // 标记是否是新创建的空会话
  bool _isNewEmptySession = false;

  // 编辑消息相关
  CharacterChatMessage? _editingMessage;

  // 存储点击位置
  Offset _tapPosition = Offset.zero;

  // 对话列表滚动控制器
  final ScrollController _scrollController = ScrollController();
  // 是否显示"滚动到底部"按钮
  bool showScrollToBottom = false;
  // 是否用户手动滚动
  bool isUserScrolling = false;
  // 最后内容高度(用于判断是否需要滚动到底部)
  double lastContentHeight = 0;

  // 输入框高度状态(用于悬浮按钮的布局)
  // 输入框展开收起工具栏时，悬浮按钮(新加对话、滚动到底部)位置需要动态变化，始终在输入框的上方
  double inputHeight = 0;

  @override
  void initState() {
    super.initState();

    initSession();

    // 监听滚动事件
    _scrollController.addListener(() {
      // 判断用户是否正在手动滚动
      if (_scrollController.position.userScrollDirection ==
              ScrollDirection.reverse ||
          _scrollController.position.userScrollDirection ==
              ScrollDirection.forward) {
        isUserScrolling = true;
      } else {
        isUserScrolling = false;
      }

      // 判断是否显示"滚动到底部"按钮
      setState(() {
        showScrollToBottom = _scrollController.offset <
            _scrollController.position.maxScrollExtent - 50;
      });
    });
  }

  initSession() {
    _session = widget.session;
    _activeModel =
        _session.activeModel ?? _session.characters.first.preferredModel;

    // 检查是否是新创建的空会话
    _isNewEmptySession = _session.messages.isEmpty;

    // 加载所有会话
    _loadSessions();

    // 如果没有首条消息，添加角色的首条消息
    if (_session.messages.isEmpty) {
      _addCharacterFirstMessages();
    }

    resetContentHeight();
  }

  Future<void> _loadSessions() async {
    await _store.initialize();
    setState(() {
      _allSessions = _store.sessions
          .where((s) => s.characters.isNotEmpty && s.messages.isNotEmpty)
          .toList()
        ..sort((a, b) => b.updateTime.compareTo(a.updateTime));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _inputController.dispose();
    _focusNode.dispose();

    // 如果是新创建的空会话且用户没有输入任何内容，则删除该会话
    if (_isNewEmptySession && _session.messages.isEmpty) {
      _store.deleteSession(_session.id);
    }

    super.dispose();
  }

  // 布局发生变化时（如键盘弹出/收起）
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    // 流式响应还未完成且不是用户手动滚动，滚动到底部
    if (_isStreaming && !isUserScrolling) {
      resetContentHeight();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_session.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
            tooltip: '历史记录',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSessionSettings,
          ),
        ],
      ),
      endDrawer: SessionHistoryDrawer(
        sessions: _filteredSessions,
        currentSession: _session,
        character: _currentCharacter,
        onSessionSelected: _switchSession,
        onSessionAction: _handleSessionAction,
        onNewSession: _prepareNewSession,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 消息列表
              Expanded(
                child: _session.messages.isEmpty
                    ? Center(
                        child: Text(
                          '开始与角色对话吧！',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Stack(
                        children: [
                          ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.only(bottom: 16.sp),
                            itemCount: _session.messages.length,
                            itemBuilder: (context, index) {
                              final message = _session.messages[index];
                              return _buildMessageItem(message);
                            },
                          ),
                          // 底部加载指示器
                          if (_isStreaming)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 8.sp),
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 16.sp,
                                        height: 16.sp,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.sp,
                                        ),
                                      ),
                                      SizedBox(width: 8.sp),
                                      Text(
                                        '正在生成回复...',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),

              // 输入栏
              CharacterInputBar(
                controller: _inputController,
                onSend: _handleSendMessage,
                onCancel: _editingMessage != null ? _cancelEditing : null,
                isEditing: _editingMessage != null,
                isStreaming: _isStreaming,
                onStop: _isStreaming ? _stopGeneration : null,
                focusNode: _focusNode,
                model: _activeModel,
                onHeightChanged: (height) {
                  setState(() => inputHeight = height);
                },
              ),
            ],
          ),
          buildFloatingButton(),
        ],
      ),
    );
  }

  // 获取当前角色
  CharacterCard get _currentCharacter => _session.characters.first;

  // 过滤出当前角色的所有会话
  List<CharacterChatSession> get _filteredSessions {
    return _allSessions
        .where((s) => s.characters.any((c) => c.id == _currentCharacter.id))
        .toList();
  }

  // 处理会话操作
  void _handleSessionAction(CharacterChatSession session, String action) {
    if (action == 'edit') {
      _editSessionTitle(session);
    } else if (action == 'delete') {
      _deleteSession(session);
    }
  }

  // 编辑会话标题
  Future<void> _editSessionTitle(CharacterChatSession session) async {
    final controller = TextEditingController(text: session.title);

    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑标题'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入新标题',
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

    if (newTitle != null && newTitle.isNotEmpty) {
      await _store.updateSessionTitle(session, newTitle);
      await _loadSessions();

      // 如果修改的是当前会话，更新标题
      if (session.id == _session.id) {
        setState(() {
          _session = _store.sessions.firstWhere((s) => s.id == _session.id);
        });
      }
    }
  }

  // 准备新会话（不立即创建，等待用户输入）
  void _prepareNewSession() {
    // 如果当前已经是空会话，不需要创建新的
    if (_session.messages.isEmpty ||
        (_session.messages.length == 1 &&
            _session.messages.first.role == 'assistant')) {
      return;
    }

    // 创建一个临时会话对象，但不保存到数据库
    final character = _currentCharacter;

    if (character.preferredModel == null) {
      EasyLoading.showInfo('请先为该角色设置偏好模型');
      return;
    }

    // 创建新会话
    _store
        .createSession(
      title: '与${character.name}的对话',
      characters: [character],
      activeModel: character.preferredModel,
    )
        .then((newSession) {
      // 标记为新创建的空会话
      _isNewEmptySession = true;

      // 切换到新会话
      _switchSession(newSession);
    });
  }

  // 删除会话
  Future<void> _deleteSession(CharacterChatSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除会话'),
        content: Text('确定要删除会话"${session.title}"吗？'),
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
      // 如果删除的是当前会话，需要切换到另一个会话
      final isCurrentSession = session.id == _session.id;

      print('deleteSession: ${session.id} <> ${_session.id}');

      await _store.deleteSession(session.id);
      await _loadSessions();

      if (isCurrentSession && _allSessions.isNotEmpty) {
        _switchSession(_allSessions.first);
      } else if (isCurrentSession) {
        // 如果没有其他会话，创建一个新的空会话
        _prepareNewSession();
      }

      // Navigator.pop(context); // 关闭抽屉
    }
  }

  // 切换到另一个会话
  void _switchSession(CharacterChatSession session) {
    setState(() {
      _session = session;
      _activeModel =
          session.activeModel ?? _session.characters.first.preferredModel;
      _editingMessage = null;
      _isStreaming = false;
      _isLoading = false;
      _inputController.clear();
    });

    // 滚动到底部
    resetContentHeight();
  }

  // 显示会话设置菜单
  void _showSessionSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('编辑标题'),
            onTap: () {
              Navigator.pop(context);
              _editSessionTitle(_session);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('新建对话'),
            onTap: () {
              Navigator.pop(context);
              _prepareNewSession();
            },
          ),
          ListTile(
            leading: const Icon(Icons.model_training),
            title: const Text('选择模型'),
            onTap: () {
              Navigator.pop(context);
              _selectModel();
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('添加角色'),
            onTap: () {
              Navigator.pop(context);
              _addCharacterToSession();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep),
            title: const Text('清空对话'),
            onTap: () {
              Navigator.pop(context);
              _clearMessages();
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return '今天 ${DateFormat('HH:mm').format(time)}';
    } else if (messageDate == yesterday) {
      return '昨天 ${DateFormat('HH:mm').format(time)}';
    } else {
      return DateFormat('MM-dd HH:mm').format(time);
    }
  }

  Widget _buildMessageItem(CharacterChatMessage message) {
    // 查找对应的角色
    CharacterCard? character;
    if (message.characterId != null) {
      character = _session.characters
          .where((c) => c.id == message.characterId)
          .firstOrNull;
    }

    return GestureDetector(
      onTapDown: (details) {
        _tapPosition = details.globalPosition;
      },
      child: CharacterMessageItem(
        message: message,
        character: character,
        onLongPress: _handleMessageLongPress,
      ),
    );
  }

  void _handleMessageLongPress(CharacterChatMessage message) async {
    // 只有用户消息可以编辑
    final bool canEdit = message.role == 'user';
    // 只有AI消息可以重新生成
    final bool canRegenerate = message.role == 'assistant';

    // 获取点击位置的RenderBox
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    // 显示弹出菜单
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        _tapPosition & const Size(40, 40), // 点击位置和大小
        Offset.zero & overlay.size, // 整个屏幕的大小
      ),
      items: [
        PopupMenuItem<String>(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.copy, size: 20.sp),
              SizedBox(width: 8.sp),
              const Text('复制'),
            ],
          ),
        ),
        if (canEdit)
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 20.sp),
                SizedBox(width: 8.sp),
                const Text('编辑'),
              ],
            ),
          ),
        if (canRegenerate)
          PopupMenuItem<String>(
            value: 'regenerate',
            child: Row(
              children: [
                Icon(Icons.refresh, size: 20.sp),
                SizedBox(width: 8.sp),
                const Text('重新生成'),
              ],
            ),
          ),
      ],
    );

    // 处理选择结果
    if (result == 'copy') {
      Clipboard.setData(ClipboardData(text: message.content));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已复制到剪贴板')),
      );
    } else if (result == 'edit' && canEdit) {
      _startEditing(message);
    } else if (result == 'regenerate' && canRegenerate) {
      _regenerateResponse(message);
    }
  }

  void _startEditing(CharacterChatMessage message) {
    setState(() {
      _editingMessage = message;
      _inputController.text = message.content;
    });
    _focusNode.requestFocus();
  }

  void _cancelEditing() {
    setState(() {
      _editingMessage = null;
      _inputController.clear();
    });
  }

  Future<void> _regenerateResponse(CharacterChatMessage message) async {
    if (_isLoading) return;

    // 找到对应的角色
    final character = _session.characters
        .where((c) => c.id == message.characterId)
        .firstOrNull;
    if (character == null) return;

    setState(() {
      _isLoading = true;
      _isStreaming = true;
    });

    try {
      // 更新消息内容为空
      await _store.updateMessage(
        session: _session,
        message: message,
        content: '',
      );

      setState(() {
        _session = _store.sessions.firstWhere((s) => s.id == _session.id);
      });

      // 准备聊天历史
      final history = _prepareChatHistory(character);

      // 调用AI服务生成回复
      final (stream, cancelFunc) = await ChatService.sendCharacterMessage(
        _activeModel ?? character.preferredModel!,
        history,
        stream: true,
      );

      _cancelGeneration = cancelFunc;

      String fullContent = '';

      await for (final response in stream) {
        if (response.choices.isNotEmpty) {
          final delta = response.choices[0].delta;
          if (delta != null && delta['content'] != null) {
            fullContent += delta['content']!;

            // 更新消息内容
            await _store.updateMessage(
              session: _session,
              message: message,
              content: fullContent,
            );

            // 刷新UI
            setState(() {
              _session = _store.sessions.firstWhere((s) => s.id == _session.id);
            });
          }
        }
      }

      // 刷新会话
      setState(() {
        _session = _store.sessions.firstWhere((s) => s.id == _session.id);
      });
    } catch (e) {
      EasyLoading.showError('重新生成失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isStreaming = false;
        _cancelGeneration = null;
      });
    }
  }

  void _stopGeneration() {
    if (_cancelGeneration != null) {
      _cancelGeneration!();
      _cancelGeneration = null;

      setState(() {
        _isStreaming = false;
      });

      EasyLoading.showToast('已停止生成');
    }
  }

  Future<void> _addCharacterFirstMessages() async {
    for (var character in _session.characters) {
      if (character.firstMessage.isNotEmpty) {
        await _store.addMessage(
          session: _session,
          content: character.firstMessage,
          role: 'assistant',
          characterId: character.id,
        );
      }
    }

    setState(() {
      _session = _store.sessions.firstWhere((s) => s.id == _session.id);
    });
  }

  Future<void> _addCharacterToSession() async {
    // 获取所有角色
    final allCharacters = _store.characters;

    // 过滤掉已经在会话中的角色
    final availableCharacters = allCharacters
        .where((c) => !_session.characters.any((sc) => sc.id == c.id))
        .toList();

    if (availableCharacters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可添加的角色')),
      );
      return;
    }

    final selectedCharacter = await showDialog<CharacterCard>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择角色'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableCharacters.length,
            itemBuilder: (context, index) {
              final character = availableCharacters[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: character.avatar.startsWith('assets/')
                      ? AssetImage(character.avatar)
                      : FileImage(File(character.avatar)) as ImageProvider,
                  onBackgroundImageError: (_, __) {
                    const Icon(Icons.person);
                  },
                ),
                title: Text(character.name),
                subtitle: Text(character.description,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => Navigator.pop(context, character),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (selectedCharacter != null) {
      // 添加角色到会话
      await _store.addCharacterToSession(_session, selectedCharacter);
      setState(() {
        _session = _store.sessions.firstWhere((s) => s.id == _session.id);
      });

      // 添加角色的首条消息
      if (selectedCharacter.firstMessage.isNotEmpty) {
        await _store.addMessage(
          session: _session,
          content: selectedCharacter.firstMessage,
          role: 'assistant',
          characterId: selectedCharacter.id,
        );

        setState(() {
          _session = _store.sessions.firstWhere((s) => s.id == _session.id);
        });
      }
    }
  }

  Future<void> _clearMessages() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空对话'),
        content: const Text('确定要清空所有对话消息吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _store.clearMessages(_session);
      setState(() {
        _session = _store.sessions.firstWhere((s) => s.id == _session.id);
      });

      // 添加角色的首条消息
      _addCharacterFirstMessages();
    }
  }

  // 处理发送消息
  Future<void> _handleSendMessage(MessageData messageData) async {
    print('messageData: $messageData');
    print('inputController: ${_inputController.text}');
    print('editingMessage: ${_editingMessage?.content}');
    print('isLoading: $_isLoading');
    print('isStreaming: $_isStreaming');

    if (_isLoading) return;

    // 如果是编辑模式，调用编辑处理方法
    if (_editingMessage != null) {
      await _handleEditMessage(messageData);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 添加用户消息
      await _store.addMessage(
        session: _session,
        content: messageData.text,
        role: 'user',
        contentVoicePath: messageData.audio?.path,
        imagesUrl: messageData.images?.map((img) => img.path).join(','),
      );

      // 如果是新创建的空会话，现在已经有内容了，需要刷新会话列表
      if (_isNewEmptySession) {
        _isNewEmptySession = false;
        // 延迟加载会话列表，确保数据库已更新
        Future.delayed(const Duration(milliseconds: 500), () {
          _loadSessions();
        });
      }

      setState(() {
        _session = _store.sessions.firstWhere((s) => s.id == _session.id);
        _isStreaming = true;
      });

      // 滚动到底部
      resetContentHeight();

      // 生成AI回复
      await _generateAIResponses();
    } catch (e) {
      print('发送消息失败: $e');
      EasyLoading.showError('发送消息失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isStreaming = false;
        _cancelGeneration = null;
      });

      // 清空输入框
      _inputController.clear();
    }
  }

  // 处理编辑消息
  Future<void> _handleEditMessage(MessageData messageData) async {
    if (_editingMessage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 更新消息内容
      await _store.updateMessage(
        session: _session,
        message: _editingMessage!,
        content: messageData.text,
      );

      // 找到消息在列表中的位置
      final index =
          _session.messages.indexWhere((m) => m.id == _editingMessage!.id);
      if (index >= 0) {
        // 删除该消息之后的所有AI回复
        final messagesToDelete = _session.messages
            .where((m) =>
                m.role == 'assistant' && _session.messages.indexOf(m) > index)
            .toList();

        for (var msg in messagesToDelete) {
          await _store.deleteMessage(_session, msg);
        }
      }

      setState(() {
        _session = _store.sessions.firstWhere((s) => s.id == _session.id);
        _inputController.clear();
        _isLoading = false;
        _editingMessage = null;
      });

      // 滚动到底部
      resetContentHeight();
      // 重新生成AI回复，但不添加新的用户消息
      await _generateAIResponses();
    } catch (e) {
      EasyLoading.showError('编辑消息失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _editingMessage = null;
      });

      // 清空输入框
      _inputController.clear();
    }
  }

  // 生成AI回复（不添加新的用户消息）
  Future<void> _generateAIResponses() async {
    setState(() {
      _isStreaming = true;
    });

    try {
      // 让每个角色都回复
      for (var character in _session.characters) {
        // 创建一个空消息
        final aiMessage = await _store.addMessage(
          session: _session,
          content: '',
          role: 'assistant',
          characterId: character.id,
        );

        setState(() {
          _session = _store.sessions.firstWhere((s) => s.id == _session.id);
        });

        // 准备聊天历史
        final history = _prepareChatHistory(character);

        // 调用AI服务生成回复
        final (stream, cancelFunc) = await ChatService.sendCharacterMessage(
          _activeModel ?? character.preferredModel!,
          history,
          stream: true,
        );

        _cancelGeneration = cancelFunc;

        String fullContent = '';

        await for (final response in stream) {
          if (response.choices.isNotEmpty) {
            final delta = response.choices[0].delta;
            if (delta != null && delta['content'] != null) {
              fullContent += delta['content']!;

              // 更新消息内容
              await _store.updateMessage(
                session: _session,
                message: aiMessage,
                content: fullContent,
              );

              // 刷新UI
              setState(() {
                _session =
                    _store.sessions.firstWhere((s) => s.id == _session.id);
              });

              // 自动滚动逻辑
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final currentHeight =
                    _scrollController.position.maxScrollExtent;

                print(
                    "触发响应时流式追加的滚动,currentHeight: $currentHeight,lastContentHeight: $lastContentHeight");
                if (!isUserScrolling &&
                    currentHeight - lastContentHeight > 20) {
                  // 高度增加超过 20 像素
                  _scrollController.jumpTo(currentHeight);
                  lastContentHeight = currentHeight;
                }
              });
            }
          }
        }

        // 刷新会话
        setState(() {
          _session = _store.sessions.firstWhere((s) => s.id == _session.id);
        });
      }
    } catch (e) {
      print('生成回复失败: $e');
      EasyLoading.showError('生成回复失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isStreaming = false;
        _cancelGeneration = null;
      });
    }
  }

  List<Map<String, dynamic>> _prepareChatHistory(CharacterCard character) {
    final history = <Map<String, dynamic>>[];

    // 添加系统提示词
    history.add({
      'role': 'system',
      'content': character.generateSystemPrompt(),
    });

    // 添加聊天历史
    for (var message in _session.messages) {
      // 跳过空消息
      if (message.content.isEmpty &&
          message.imagesUrl == null &&
          message.contentVoicePath == null) {
        continue;
      }

      if (message.role == 'user') {
        // 处理用户消息，可能包含多模态内容
        if ((message.imagesUrl != null && message.imagesUrl!.isNotEmpty) ||
            (message.contentVoicePath != null &&
                message.contentVoicePath!.isNotEmpty)) {
          // 多模态消息
          final contentList = <Map<String, dynamic>>[];

          // 添加文本内容
          if (message.content.isNotEmpty) {
            contentList.add({'type': 'text', 'text': message.content});
          }

          // 处理图片
          if (message.imagesUrl != null && message.imagesUrl!.isNotEmpty) {
            final imageUrls = message.imagesUrl!.split(',');
            for (final url in imageUrls) {
              try {
                final bytes = File(url.trim()).readAsBytesSync();
                final base64Image = base64Encode(bytes);
                contentList.add({
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
                });
              } catch (e) {
                print('处理图片失败: $e');
              }
            }
          }

          // 处理语音
          if (message.contentVoicePath != null &&
              message.contentVoicePath!.isNotEmpty) {
            try {
              final bytes = File(message.contentVoicePath!).readAsBytesSync();
              final base64Audio = base64Encode(bytes);
              contentList.add({
                'type': 'audio_url',
                'audio_url': {'url': 'data:audio/mp3;base64,$base64Audio'}
              });
            } catch (e) {
              print('处理音频失败: $e');
            }
          }

          history.add({
            'role': 'user',
            'content': contentList,
          });
        } else {
          // 纯文本消息
          history.add({
            'role': 'user',
            'content': message.content,
          });
        }
      } else if (message.role == 'assistant' &&
          message.characterId == character.id) {
        // AI助手的回复通常是纯文本
        history.add({
          'role': 'assistant',
          'content': message.content,
        });
      }
    }

    return history;
  }

  Widget buildFloatingButton() {
    return Positioned(
      left: 0,
      right: 0,
      // 悬浮按钮有设定上下间距，根据其他组件布局适当调整位置
      bottom: _isStreaming ? inputHeight + 5.sp : inputHeight - 5.sp,
      child: Container(
        // 新版本输入框为了更多输入内容，左右边距为0
        padding: EdgeInsets.symmetric(horizontal: 0.sp),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 图标按钮的默认尺寸是48*48,占位宽度默认48
            SizedBox(width: 48.sp),
            if (_session.messages.isNotEmpty && !_isStreaming)
              // 新加对话按钮的背景色
              Padding(
                // 这里的上下边距，和下面maxHeight的和，要等于默认图标按钮高度的48sp
                padding: EdgeInsets.symmetric(vertical: 16.sp),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14.sp),
                    //
                  ),
                  // 限制按钮的最大尺寸
                  constraints: BoxConstraints(
                    maxWidth: 124.sp,
                    maxHeight: 32.sp,
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      // 设置按钮的背景色为透明
                      backgroundColor: Colors.transparent,
                      // elevation: 0,
                      // 按钮的尺寸
                      // minimumSize: Size(52.sp, 28.sp),
                      // 按钮的圆角
                      // shape: RoundedRectangleBorder(
                      //   borderRadius: BorderRadius.circular(14.sp),
                      // ),
                    ),
                    icon: Icon(
                      Icons.add_comment_outlined,
                      size: 15.sp,
                      color: Colors.white,
                    ),
                    onPressed: _prepareNewSession,
                    label: Text(
                      '开启新对话',
                      style: TextStyle(fontSize: 12.sp, color: Colors.white),
                    ),
                  ),
                ),
              ),
            if (showScrollToBottom)
              // 按钮图标变小，但为了和下方的发送按钮对齐，所以补足占位宽度
              IconButton(
                iconSize: 24.sp,
                icon: FaIcon(
                  FontAwesomeIcons.circleArrowDown,
                  color: Colors.black,
                ),
                onPressed: resetContentHeight,
              ),
            if (!showScrollToBottom) SizedBox(width: 48.sp),
          ],
        ),
      ),
    );
  }

  // 重置对话列表内容高度(在点击了重新生成、切换了模型、点击了指定历史记录后都应该调用)
  void resetContentHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      lastContentHeight = _scrollController.position.maxScrollExtent;

      print(
          "重置对话列表内容高度,currentHeight: $lastContentHeight,lastContentHeight: $lastContentHeight");
    });

    // 重置完了顺便滚动到底部
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _selectModel() async {
    final availableModels = await ModelManagerService.getAvailableModelByTypes([
      LLModelType.cc,
      LLModelType.vision,
      LLModelType.reasoner,
    ]);

    if (!mounted) return;

    final result = await showDialog<CusBriefLLMSpec>(
      context: context,
      builder: (context) => ModelSelectorDialog(
        models: availableModels,
        selectedModel: _activeModel,
      ),
    );

    if (result != null) {
      setState(() {
        _activeModel = result;
      });

      // 更新会话的活动模型
      await _store.updateSessionModel(_session, result);
      setState(() {
        _session = _store.sessions.firstWhere((s) => s.id == _session.id);
      });
    }
  }
}
