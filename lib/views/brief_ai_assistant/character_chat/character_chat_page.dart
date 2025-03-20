import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../common/components/simple_marquee_or_text.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/constants/constants.dart';
import '../../../common/llm_spec/constant_llm_enum.dart';
import '../../../models/brief_ai_tools/character_chat/character_chat_session.dart';
import '../../../models/brief_ai_tools/character_chat/character_chat_message.dart';
import '../../../models/brief_ai_tools/character_chat/character_card.dart';
import '../../../models/brief_ai_tools/character_chat/character_store.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../services/chat_service.dart';
import '../../../services/model_manager_service.dart';
import '../../../../services/cus_get_storage.dart';

import '../_chat_components/_small_tool_widgets.dart';
import 'components/character_message_item.dart';
import 'components/character_input_bar.dart';
import 'components/model_selector_dialog.dart';
import 'components/session_history_drawer.dart';
import 'components/character_chat_background_picker.dart';
import 'components/character_avatar_preview.dart';

class CharacterChatPage extends StatefulWidget {
  final CharacterChatSession session;

  const CharacterChatPage({super.key, required this.session});

  @override
  State<CharacterChatPage> createState() => _CharacterChatPageState();
}

class _CharacterChatPageState extends State<CharacterChatPage>
    with WidgetsBindingObserver {
  // 角色存储器
  final CharacterStore _store = CharacterStore();
  // 存储器
  final MyGetStorage _storage = MyGetStorage();

  // 输入框控制器
  final TextEditingController _inputController = TextEditingController();
  // 焦点节点
  final FocusNode _focusNode = FocusNode();
  // 全局key
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 默认的页面主体的缩放比例(对话太小了就可以等比放大)
  double textScaleFactor = 1.0;

  // 会话
  late CharacterChatSession _session;
  // 所有会话
  List<CharacterChatSession> _allSessions = [];
  // 是否加载中
  bool _isLoading = false;
  // 是否流式加载中
  bool _isStreaming = false;
  // 当前模型
  CusBriefLLMSpec? _activeModel;
  // 取消生成回调
  VoidCallback? _cancelGeneration;

  // 标记是否是新创建的空会话
  bool _isNewEmptySession = false;

  // 编辑消息相关
  CharacterChatMessage? _editingMessage;

  // 消息体长按位置
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

  // 背景图片
  String? _backgroundImage;
  // 背景图片透明度
  double _backgroundOpacity = 0.2;

  @override
  void initState() {
    super.initState();

    // 使用Future.microtask延迟加载非关键UI组件
    Future.microtask(() {
      _loadBackgroundSettings();
    });

    // 初始化会话（这是必须立即执行的）
    initSession();

    // 获取缓存中的正文文本缩放比例
    textScaleFactor = MyGetStorage().getChatListAreaScale();

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

  // 加载背景设置 - 优化为异步加载并缓存结果
  Future<void> _loadBackgroundSettings() async {
    // 先检查是否已有缓存的背景设置
    final cachedBackground = _storage.getCachedBackground();
    final cachedOpacity = _storage.getCachedBackgroundOpacity();

    if (cachedBackground != null || cachedOpacity != null) {
      // 如果有缓存，先使用缓存值快速渲染
      setState(() {
        if (cachedBackground != null) _backgroundImage = cachedBackground;
        if (cachedOpacity != null) _backgroundOpacity = cachedOpacity;
      });
    }

    // 然后异步加载最新设置
    final background = await _storage.getCharacterChatBackground();
    final opacity = await _storage.getCharacterChatBackgroundOpacity();

    // 只有当值不同时才更新UI
    if (background != _backgroundImage || opacity != _backgroundOpacity) {
      setState(() {
        _backgroundImage = background;
        _backgroundOpacity = opacity ?? 0.2;
      });
    }
  }

  // 初始化会话 - 优化为分步加载
  void initSession() {
    _session = widget.session;
    _activeModel =
        _session.activeModel ?? _session.characters.first.preferredModel;

    // 检查是否是新创建的空会话
    _isNewEmptySession = _session.messages.isEmpty;

    // 使用Future.delayed让UI先渲染，再加载其他会话
    Future.delayed(const Duration(milliseconds: 100), () {
      _loadAllSessions();
    });

    // 如果没有首条消息，添加角色的首条消息
    if (_session.messages.isEmpty) {
      _addCharacterFirstMessages();
    }

    // 延迟执行滚动到底部，确保UI已完全渲染
    WidgetsBinding.instance.addPostFrameCallback((_) {
      resetContentHeight(times: 2000);
    });
  }

  // 异步加载所有会话（可能较慢）
  Future<void> _loadAllSessions() async {
    try {
      await _store.initialize();
      setState(() {
        _allSessions = _store.sessions
            .where((s) => s.characters.isNotEmpty && s.messages.isNotEmpty)
            .toList()
          ..sort((a, b) => b.updateTime.compareTo(a.updateTime));
      });
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, '加载所有会话失败', '加载所有会话失败: $e');
    }
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

  // 获取当前角色
  CharacterCard get _currentCharacter {
    return _session.characters.isNotEmpty
        ? _session.characters.first
        : CharacterCard(
            id: 'default',
            name: '智能助手',
            description: '竭尽全力解决用户提出的任何问题',
            avatar: 'assets/images/assistant.png',
            tags: [],
          );
  }

  // 过滤出当前角色的所有会话
  List<CharacterChatSession> get _filteredSessions {
    return _allSessions
        .where((s) => s.characters.any((c) => c.id == _currentCharacter.id))
        .toList();
  }

  ///******************************************* */
  ///
  /// 构建UI，从上往下放置相关内容
  ///
  ///******************************************* */
  @override
  Widget build(BuildContext context) {
    var mainScaffold = Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: SimpleMarqueeOrText(
          data: _session.title,
          velocity: 30,
          width: 0.6.sw,
          style: TextStyle(
            fontSize: 18.sp,
          ),
        ),
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
        onSessionSelected: _handleSessionSelected,
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
                          style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                        ),
                      )
                    : Stack(
                        children: [
                          _buildMessageList(),

                          // 底部加载指示器
                          if (_isStreaming) buildResponseLoading(),
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

    return Stack(
      children: [
        // 背景图片
        _buildBackground(),

        // 主页面
        mainScaffold,

        // 角色头像预览 - 使用可复用的组件
        if (_currentCharacter.avatar.isNotEmpty)
          CharacterAvatarPreview(character: _currentCharacter),
      ],
    );
  }

  ///******************************************* */
  ///
  /// AppBar 相关的内容方法
  ///
  ///******************************************* */

  // 显示会话设置菜单
  void _showSessionSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(20.sp),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "更多设置",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      child: const Text('关闭'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
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
                leading: const Icon(Icons.wallpaper),
                title: const Text('更换背景'),
                onTap: () {
                  Navigator.pop(context);
                  _showBackgroundPicker();
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: const Text('文字大小'),
                onTap: () {
                  adjustTextScale(
                    context,
                    textScaleFactor,
                    (value) async {
                      setState(() => textScaleFactor = value);
                      await MyGetStorage().setChatListAreaScale(value);

                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.model_training),
                title: const Text('选择模型'),
                subtitle: Text(
                  _activeModel?.model ?? '未设置',
                  style: TextStyle(fontSize: 12.sp),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _selectModel();
                },
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('角色管理'),
                onTap: _showCharacterManagementDialog,
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
        ),
      ),
    );
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
      await _loadAllSessions();

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
      _handleSessionSelected(newSession);
    });

    resetContentHeight();
  }

  // 选择模型
  Future<void> _selectModel() async {
    final availableModels = await ModelManagerService.getAvailableModelByTypes([
      LLModelType.cc,
      LLModelType.vision,
      LLModelType.reasoner,
    ]);

    if (!mounted) return;

    final result = await showModalBottomSheet<CusBriefLLMSpec>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: ModelSelectorDialog(
          models: availableModels,
          selectedModel: _activeModel,
        ),
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

  // 显示角色管理对话框
  void _showCharacterManagementDialog() {
    var title = Padding(
      padding: EdgeInsets.all(20.sp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "当前对话中的角色",
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.green),
            onPressed: _addCharacterToSession,
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );

    var list = _session.characters.map((character) {
      return ListTile(
        leading: SizedBox(
          width: 40.sp,
          height: 40.sp,
          child: buildAvatarClipOval(character.avatar),
        ),
        title: Text(character.name),
        trailing: _session.characters.length > 1
            ? IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red,
                ),
                onPressed: () => _removeCharacterFromSession(character),
              )
            : null, // 如果只有一个角色，不显示移除按钮
      );
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            title,
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 8.sp),
                    ...list,
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.green,
                      ),
                      title: const Text('添加角色'),
                      onTap: () {
                        _addCharacterToSession();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 从会话中移除角色
  Future<void> _removeCharacterFromSession(CharacterCard character) async {
    try {
      // 确认对话框
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('移除角色'),
          content: Text(
              '确定要从当前对话中移除角色"${character.name}"吗？\n\n注意：已有的对话记录不会受影响，但后续对话将不再包含此角色。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('移除'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // 关闭角色管理对话框
      if (mounted) Navigator.pop(context);

      // 显示加载指示器
      EasyLoading.show(status: '移除中...');

      // 从会话中移除角色
      final updatedSession = await _store.removeCharacterFromSession(
        _session,
        character.id,
      );

      // 更新当前会话
      setState(() {
        _session = updatedSession;

        // 如果当前活跃模型是被移除角色的偏好模型，则切换到第一个角色的偏好模型
        if (_activeModel == character.preferredModel) {
          _activeModel = _session.characters.first.preferredModel;
        }
      });

      // 显示成功提示
      EasyLoading.showSuccess('已移除角色"${character.name}"');
    } catch (e) {
      // 显示错误提示
      EasyLoading.showError('移除角色失败: $e');
    } finally {
      EasyLoading.dismiss();
    }
  }

  // 添加角色到会话
  Future<void> _addCharacterToSession() async {
    // 获取所有角色
    final allCharacters = _store.characters;

    // 过滤掉已经在会话中的角色
    final availableCharacters = allCharacters
        .where((c) => !_session.characters.any((sc) => sc.id == c.id))
        .toList();

    if (availableCharacters.isEmpty) {
      commonHintDialog(context, '添加角色', '没有可添加的角色');
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
                leading: SizedBox(
                  width: 40.sp,
                  height: 40.sp,
                  child: buildAvatarClipOval(character.avatar),
                ),
                title: Text(character.name),
                subtitle: Text(
                  character.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
      // 关闭角色管理对话框
      if (mounted) Navigator.pop(context);

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

  // 显示背景选择器
  void _showBackgroundPicker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CharacterChatBackgroundPicker(),
      ),
    ).then((confirmed) {
      // 只有在用户点击了确定按钮时才重新加载背景设置
      if (confirmed == true) {
        _loadBackgroundSettings();
      }
    });
  }

  // 清空当前对话
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

  ///******************************************* */
  ///
  /// Drawer 相关的内容方法
  ///
  ///******************************************* */

  // 切换到另一个会话
  Future<void> _handleSessionSelected(CharacterChatSession session) async {
    // 更新会话中的角色信息，确保使用最新的角色卡
    await _store.updateSessionCharacters(session);

    // 重新获取更新后的会话
    session = _store.sessions.firstWhere((s) => s.id == session.id);

    setState(() {
      _session = session;
      _activeModel =
          session.activeModel ?? session.characters.first.preferredModel;
      _editingMessage = null;
      _isStreaming = false;
      _cancelGeneration = null;
    });

    _inputController.clear();
    resetContentHeight();
  }

  // 长按抽屉中会话列表项，处理会话操作
  void _handleSessionAction(CharacterChatSession session, String action) {
    if (action == 'edit') {
      _editSessionTitle(session);
    } else if (action == 'delete') {
      _deleteSession(session);
    }
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

      await _store.deleteSession(session.id);
      await _loadAllSessions();

      if (isCurrentSession && _allSessions.isNotEmpty) {
        _handleSessionSelected(_allSessions.first);
      } else if (isCurrentSession) {
        // 如果没有其他会话，创建一个新的空会话
        _prepareNewSession();
      }
    }
  }

  ///******************************************* */
  ///
  /// body 相关的内容方法
  ///
  ///******************************************* */

  // 构建消息列表
  Widget _buildMessageList() {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScaleFactor),
      ),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.only(bottom: 60.sp, top: 16.sp),
        itemCount: _session.messages.length,
        // 使用cacheExtent提前渲染一些项，使滚动更流畅
        cacheExtent: 1000.0,
        itemBuilder: (context, index) {
          final message = _session.messages[index];
          return _buildMessageItem(message);
        },
      ),
    );
  }

  // 构建响应加载
  Widget buildResponseLoading() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.sp),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16.sp,
                height: 16.sp,
                child: CircularProgressIndicator(strokeWidth: 2.sp),
              ),
              SizedBox(width: 8.sp),
              Text(
                '正在生成回复...',
                style: TextStyle(fontSize: 12.sp, color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建消息列表项
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

  // 处理消息长按事件
  void _handleMessageLongPress(CharacterChatMessage message) async {
    // 只有用户消息可以编辑
    final bool canEdit = message.role == CusRole.user.name;
    // 只有AI消息可以重新生成
    final bool canRegenerate = message.role == CusRole.assistant.name;

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
        if (canEdit)
          PopupMenuItem<String>(
            value: 'resend',
            child: Row(
              children: [
                Icon(Icons.send, size: 20.sp),
                SizedBox(width: 8.sp),
                const Text('重新发送'),
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
      EasyLoading.showToast('已复制到剪贴板');
    } else if (result == 'edit' && canEdit) {
      _startEditing(message);
    } else if (result == 'resend' && canEdit) {
      _resendMessage(message);
    } else if (result == 'regenerate' && canRegenerate) {
      _regenerateResponse(message);
    }
  }

  // 开始编辑用户消息
  void _startEditing(CharacterChatMessage message) {
    setState(() {
      _editingMessage = message;
      _inputController.text = message.content;
    });
    _focusNode.requestFocus();
  }

  // 重新发送用户消息
  void _resendMessage(CharacterChatMessage message) {
    setState(() {
      _editingMessage = message;
    });
    _handleSendMessage(
      MessageData(
        text: message.content,
        audio: message.contentVoicePath != null
            ? XFile(message.contentVoicePath!)
            : null,
        images: message.imagesUrl?.split(',').map((img) => XFile(img)).toList(),
      ),
    );
  }

  // 重新生成AI消息
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

      // 处理AI响应
      await _commonGenerateResponse(character, message);
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

  ///******************************************* */
  ///
  /// 输入区域 相关的内容方法
  ///
  ///******************************************* */

  // 处理发送消息
  Future<void> _handleSendMessage(MessageData messageData) async {
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
          _loadAllSessions();
        });
      }

      setState(() {
        _session = _store.sessions.firstWhere((s) => s.id == _session.id);
        _isStreaming = true;
      });

      _inputController.clear();

      // 滚动到底部
      resetContentHeight();

      // 生成AI回复
      await _generateAIResponses();
    } catch (e) {
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
        // 删除该消息之后的所有回复
        final messagesToDelete = _session.messages
            .where((m) => _session.messages.indexOf(m) > index)
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
      // 创建一个列表来存储所有角色的生成任务
      final List<Future<void>> generationTasks = [];

      // 为每个角色创建一个空消息
      final Map<String, CharacterChatMessage> characterMessages = {};

      for (var character in _session.characters) {
        // 创建一个空消息
        final aiMessage = await _store.addMessage(
          session: _session,
          content: '',
          role: 'assistant',
          characterId: character.id,
        );

        // 保存消息引用，以便后续更新
        characterMessages[character.id] = aiMessage;
      }

      // 刷新会话，确保UI显示所有空消息
      setState(() {
        _session = _store.sessions.firstWhere((s) => s.id == _session.id);
      });

      // 为每个角色创建并启动生成任务
      for (var character in _session.characters) {
        final task = _commonGenerateResponse(
            character, characterMessages[character.id]!);
        generationTasks.add(task);
      }

      // 等待所有生成任务完成
      await Future.wait(generationTasks);
    } catch (e) {
      EasyLoading.showError('生成回复失败: $e');
    } finally {
      setState(() {
        _isStreaming = false;
        _cancelGeneration = null;
      });

      // 滚动到底部
      resetContentHeight();
    }
  }

  // 通用的AI回复生成方法(为单个角色生成回复也是这个)
  Future<void> _commonGenerateResponse(
    CharacterCard character,
    CharacterChatMessage aiMessage,
  ) async {
    try {
      // 准备聊天历史
      final history = _prepareChatHistory(character);

      // 调用AI服务生成回复
      final (stream, cancelFunc) = await ChatService.sendCharacterMessage(
        _activeModel ?? character.preferredModel!,
        history,
        stream: true,
      );

      // 保存取消函数
      // 注意：这里只保存最后一个角色的取消函数，如果需要取消所有，需要更复杂的管理
      _cancelGeneration = cancelFunc;

      String fullContent = '';
      String fullReasoningContent = '';
      var startTime = DateTime.now();
      DateTime? endTime;
      var thinkingDuration = 0;

      await for (final response in stream) {
        if (response.choices.isNotEmpty) {
          final delta = response.choices[0].delta;
          if (delta != null && delta['content'] != null) {
            // fullContent += delta['content']!;

            fullContent += response.cusText;
            fullReasoningContent += response.choices.isNotEmpty
                ? (response.choices.first.delta?["reasoning_content"] ?? '')
                : '';

            // 计算思考时间(从发起调用开始，到当流式内容不为空时计算结束)
            if (endTime == null && fullContent.isNotEmpty) {
              endTime = DateTime.now();
              thinkingDuration = endTime.difference(startTime).inMilliseconds;
            }

            // 更新消息内容
            await _store.updateMessage(
              session: _session,
              message: aiMessage,
              content: fullContent,
              reasoningContent: fullReasoningContent,
              thinkingDuration: thinkingDuration,
            );

            // 更新UI
            if (mounted) {
              setState(() {
                _session =
                    _store.sessions.firstWhere((s) => s.id == _session.id);
              });

              // 如果用户没有手动滚动，则自动滚动到底部
              if (!isUserScrolling) {
                resetContentHeight();
              }
            }
          }
        }
      }
    } catch (e) {
      EasyLoading.showError('生成${character.name}的回复失败: $e');

      // 更新消息，显示错误
      await _store.updateMessage(
        session: _session,
        message: aiMessage,
        content: '生成${character.name}的回复失败: $e',
      );

      // 刷新会话
      if (!mounted) return;
      setState(() {
        _session = _store.sessions.firstWhere((s) => s.id == _session.id);
      });
    }
  }

  // 取消编辑用户消息
  void _cancelEditing() {
    setState(() {
      _editingMessage = null;
      _inputController.clear();
    });
  }

  // 停止生成
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

  ///******************************************* */
  ///
  /// 悬浮按钮相关的内容方法
  ///
  ///******************************************* */
  /// 构建悬浮按钮
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

  ///******************************************* */
  ///
  /// 其他相关的内容方法
  ///
  ///******************************************* */

  /// 添加角色的首条消息
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

  /// 准备聊天历史(用于构建调用大模型API的请求参数)
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
        // if ((message.imagesUrl != null && message.imagesUrl!.isNotEmpty) ||
        //     (message.contentVoicePath != null &&
        //         message.contentVoicePath!.isNotEmpty)) {

        // 2025-03-18 语音消息暂时不使用
        if ((message.imagesUrl != null && message.imagesUrl!.isNotEmpty)) {
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
                commonExceptionDialog(context, '处理图片失败', '处理图片失败: $e');
              }
            }
          }

          // // 处理语音
          // 2025-03-18 语音消息暂时不使用
          // if (message.contentVoicePath != null &&
          //     message.contentVoicePath!.isNotEmpty) {
          //   try {
          //     final bytes = File(message.contentVoicePath!).readAsBytesSync();
          //     final base64Audio = base64Encode(bytes);
          //     contentList.add({
          //       'type': 'audio_url',
          //       'audio_url': {'url': 'data:audio/mp3;base64,$base64Audio'}
          //     });
          //   } catch (e) {
          //     print('处理音频失败: $e');
          //   }
          // }

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

  // 重置对话列表内容高度(在点击了重新生成、切换了模型、点击了指定历史记录后都应该调用)
  void resetContentHeight({int? times}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      lastContentHeight = _scrollController.position.maxScrollExtent;
    });

    // 重置完了顺便滚动到底部
    _scrollToBottom(times: times);
  }

  void _scrollToBottom({int? times}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: times ?? 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 构建背景
  Widget _buildBackground() {
    if (_backgroundImage == null) {
      return Container(color: Colors.transparent);
    }

    // 使用FadeInImage或Image.memory来优化图片加载
    return Opacity(
      opacity: _backgroundOpacity,
      child: _backgroundImage!.startsWith('assets/')
          ? Image.asset(
              _backgroundImage!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              // 使用缓存图片
              cacheWidth: MediaQuery.of(context).size.width.toInt(),
              cacheHeight: MediaQuery.of(context).size.height.toInt(),
            )
          : Image.file(
              File(_backgroundImage!),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              // 使用缓存图片
              cacheWidth: MediaQuery.of(context).size.width.toInt(),
              cacheHeight: MediaQuery.of(context).size.height.toInt(),
            ),
    );
  }
}
