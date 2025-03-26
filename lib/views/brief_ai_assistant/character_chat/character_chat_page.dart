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
import '../_chat_components/chat_input_bar.dart';
import '../_chat_components/text_selection_dialog.dart';
import 'components/character_message_item.dart';
import 'components/model_selector_dialog.dart';
import 'components/character_chat_history_drawer.dart';
import 'components/character_avatar_preview.dart';

///
/// 角色对话主页面
///
/// 除非是某个函数内部使用且不再全局其他地方也能使用的方法设为私有，其他都不加下划线
///
class CharacterChatPage extends StatefulWidget {
  final CharacterChatSession session;

  const CharacterChatPage({super.key, required this.session});

  @override
  State<CharacterChatPage> createState() => _CharacterChatPageState();
}

class _CharacterChatPageState extends State<CharacterChatPage>
    with WidgetsBindingObserver {
  // 角色存储器
  final CharacterStore store = CharacterStore();
  // 存储器
  final MyGetStorage storage = MyGetStorage();

  // 输入框控制器
  final TextEditingController inputController = TextEditingController();
  // 焦点节点
  final FocusNode inputFocusNode = FocusNode();
  // 全局key
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 默认的页面主体的缩放比例(对话太小了就可以等比放大)
  double textScaleFactor = 1.0;

  // 会话
  late CharacterChatSession currentSession;
  // 所有该角色为主要角色的会话
  List<CharacterChatSession> allSessions = [];
  // 是否加载中
  bool isLoading = false;
  // 是否流式加载中
  bool isStreaming = false;
  // 当前模型
  CusBriefLLMSpec? activeModel;
  // 取消生成回调
  VoidCallback? cancelResponse;

  // 标记是否是新创建的空会话
  bool isNewEmptySession = false;

  // 编辑消息相关
  CharacterChatMessage? currentEditingMessage;

  // 对话列表滚动控制器
  final ScrollController scrollController = ScrollController();
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
  String? backgroundImage;
  // 背景图片透明度
  double backgroundOpacity = 0.2;

  @override
  void initState() {
    super.initState();

    // 使用Future.microtask延迟加载非关键UI组件
    Future.microtask(() {
      loadBackgroundSettings();
    });

    // 初始化会话（这是必须立即执行的）
    initSession();

    // 获取缓存中的正文文本缩放比例
    textScaleFactor = MyGetStorage().getChatListAreaScale();

    // 监听滚动事件
    scrollController.addListener(() {
      // 判断用户是否正在手动滚动
      if (scrollController.position.userScrollDirection ==
              ScrollDirection.reverse ||
          scrollController.position.userScrollDirection ==
              ScrollDirection.forward) {
        isUserScrolling = true;
      } else {
        isUserScrolling = false;
      }

      // 判断是否显示"滚动到底部"按钮
      setState(() {
        showScrollToBottom = scrollController.offset <
            scrollController.position.maxScrollExtent - 50;
      });
    });
  }

  // 加载背景设置
  Future<void> loadBackgroundSettings() async {
    // 首先检查主角色是否有专属背景
    if (currentSession.characters.isNotEmpty) {
      final mainCharacter = currentSession.characters.first;

      if (mainCharacter.background != null) {
        setState(() {
          backgroundImage = mainCharacter.background;
          backgroundOpacity = mainCharacter.backgroundOpacity ?? 0.2;
        });
        return;
      }
    }

    // 如果没有专属背景，则加载通用背景设置
    final background = await storage.getCharacterChatBackground();
    final opacity = await storage.getCharacterChatBackgroundOpacity();

    if (mounted) {
      setState(() {
        backgroundImage = background;
        backgroundOpacity = opacity ?? 0.2;
      });
    }
  }

  // 初始化会话
  void initSession() {
    setState(() {
      currentSession = widget.session;
      activeModel = currentSession.activeModel ??
          currentSession.characters.first.preferredModel;

      // 检查是否是新创建的空会话
      isNewEmptySession = currentSession.messages.isEmpty;
    });

    // 使用Future.delayed让UI先渲染，再加载其他会话
    Future.delayed(const Duration(milliseconds: 100), () {
      loadAllSessions();
    });

    // 如果没有首条消息，添加角色的首条消息
    if (currentSession.messages.isEmpty) {
      _addCharacterFirstMessages();
    }

    // 延迟执行滚动到底部，确保UI已完全渲染
    WidgetsBinding.instance.addPostFrameCallback((_) {
      resetContentHeight(times: 2000);
    });
  }

  // 加载所有该角色为主要角色的会话
  Future<void> loadAllSessions() async {
    try {
      await store.initialize();
      if (!mounted) return;
      setState(() {
        allSessions = store.sessions
            .where((s) =>
                // 2025-03-26 不过滤消息为空的，点击新建对话时会删除为空的会话
                // s.characters.isNotEmpty &&
                // s.messages.isNotEmpty &&
                s.characters.any((c) => c.id == _currentCharacter.id) &&
                s.characters.first.id == _currentCharacter.id)
            .toList()
          ..sort((a, b) => b.updateTime.compareTo(a.updateTime));
      });
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, '加载所有会话失败', '加载所有会话失败: $e');
    }
  }

  // 重新加载当前会话
  void reloadSession() {
    setState(() {
      currentSession =
          store.sessions.firstWhere((s) => s.id == currentSession.id);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    scrollController.dispose();
    inputController.dispose();
    inputFocusNode.dispose();

    // 如果是新创建的空会话且用户没有输入任何内容，则删除该会话
    if (isNewEmptySession && currentSession.messages.isEmpty) {
      store.deleteSession(currentSession.id);
    }

    super.dispose();
  }

  // 布局发生变化时（如键盘弹出/收起）
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    // 流式响应还未完成且不是用户手动滚动，滚动到底部
    if (isStreaming && !isUserScrolling) {
      resetContentHeight();
    }
  }

  // 获取当前角色
  CharacterCard get _currentCharacter {
    return currentSession.characters.isNotEmpty
        ? currentSession.characters.first
        : CharacterCard(
            id: 'default',
            name: '智能助手',
            description: '竭尽全力解决用户提出的任何问题',
            avatar: 'assets/images/assistant.png',
            tags: [],
          );
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
          data: currentSession.title,
          velocity: 30,
          width: 0.6.sw,
          style: TextStyle(fontSize: 18.sp),
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
            icon: const Icon(Icons.more_horiz_sharp),
            onPressed: showSessionSettings,
          ),
        ],
      ),
      endDrawer: CharacterChatHistoryDrawer(
        sessions: allSessions,
        currentSession: currentSession,
        character: _currentCharacter,
        onSessionSelected: handleSessionSelected,
        onSessionAction: _handleSessionAction,
        onNewSession: prepareNewSession,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 对话列表
              Expanded(
                child: currentSession.messages.isEmpty
                    ? buildEmptyMessageHint()
                    : buildMessageList(),
              ),

              // 底部加载指示器
              if (isStreaming) buildResponseLoading(),

              // 输入栏
              ChatInputBar(
                controller: inputController,
                onSend: handleSendMessage,
                onCancel: currentEditingMessage != null
                    ? handleCancelEditUserMessage
                    : null,
                isEditing: currentEditingMessage != null,
                isStreaming: isStreaming,
                onStop: isStreaming ? handleStopStreaming : null,
                focusNode: inputFocusNode,
                model: activeModel,
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
        buildBackground(),

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
  void showSessionSettings() {
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
                  editSessionTitle(currentSession);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('新建对话'),
                onTap: () {
                  Navigator.pop(context);
                  prepareNewSession();
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
                  "${CP_NAME_MAP[activeModel?.platform]} > ${activeModel?.model}",
                  style: TextStyle(fontSize: 12.sp),
                ),
                onTap: () {
                  Navigator.pop(context);
                  selectModel();
                },
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('角色管理'),
                // 2025-03-22 改变角色后重新加载了当前会话，为什么这里的显示不会更新呢？？？
                // subtitle: Text(
                //   _session.characters.map((e) => e.name).join(', '),
                //   style: TextStyle(fontSize: 12.sp),
                // ),
                onTap: showCharacterManagementDialog,
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep),
                title: const Text('清空对话'),
                onTap: () {
                  Navigator.pop(context);
                  clearMessages();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 编辑会话标题
  Future<void> editSessionTitle(CharacterChatSession session) async {
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
      await store.updateSessionTitle(session, newTitle);
      await loadAllSessions();

      // 如果修改的是当前会话，更新标题
      if (session.id == currentSession.id) {
        reloadSession();
      }
    }
  }

  // 准备新会话
  void prepareNewSession() {
    // 如果当前已经是空会话，不需要创建新的
    if (currentSession.messages.isEmpty ||
        (currentSession.messages
            .where((m) => m.role == CusRole.user.name)
            .isEmpty)) {
      return;
    }

    // 判断当前角色是否设置了偏好模型
    final character = _currentCharacter;

    if (character.preferredModel == null) {
      EasyLoading.showInfo('请先为该角色设置偏好模型');
      return;
    }

    // 2025-03-26 如果当前角色的会话记录中有消息为空的会话，则删除该会话
    final emptySession = allSessions.where((s) => s.messages.isEmpty);
    if (emptySession.isNotEmpty) {
      for (var session in emptySession) {
        store.deleteSession(session.id);
      }
    }

    // 创建新会话
    store
        .createSession(
      title: '与${character.name}的对话',
      characters: [character],
      activeModel: character.preferredModel,
    )
        .then((newSession) {
      // 标记为新创建的空会话
      isNewEmptySession = true;

      // 切换到新会话
      handleSessionSelected(newSession);
    });

    resetContentHeight();
  }

  // 选择模型
  Future<void> selectModel() async {
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
          selectedModel: activeModel,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        activeModel = result;
      });

      // 更新会话的活动模型
      await store.updateSessionModel(currentSession, result);
      reloadSession();
    }
  }

  // 显示角色管理对话框
  void showCharacterManagementDialog() {
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
            onPressed: addCharacterToSession,
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );

    var list = currentSession.characters.map((character) {
      return ListTile(
        leading: SizedBox(
          width: 40.sp,
          height: 40.sp,
          child: buildAvatarClipOval(character.avatar),
        ),
        title: Text(character.name),
        trailing: currentSession.characters.length > 1
            ? IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red,
                ),
                onPressed: () => removeCharacterFromSession(character),
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
                        addCharacterToSession();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((value) {
      reloadSession();
    });
  }

  // 从会话中移除角色
  Future<void> removeCharacterFromSession(CharacterCard character) async {
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
      final updatedSession = await store.removeCharacterFromSession(
        currentSession,
        character.id,
      );

      // 更新当前会话
      setState(() {
        currentSession = updatedSession;

        // 如果当前活跃模型是被移除角色的偏好模型，则切换到第一个角色的偏好模型
        if (activeModel == character.preferredModel) {
          activeModel = currentSession.characters.first.preferredModel;
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
  Future<void> addCharacterToSession() async {
    // 获取所有角色
    final allCharacters = store.characters;

    // 过滤掉已经在会话中的角色
    final availableCharacters = allCharacters
        .where((c) => !currentSession.characters.any((sc) => sc.id == c.id))
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
      await store.addCharacterToSession(currentSession, selectedCharacter);
      reloadSession();

      // 添加角色的首条消息
      if (selectedCharacter.firstMessage.isNotEmpty) {
        await store.addMessage(
          session: currentSession,
          content: selectedCharacter.firstMessage,
          role: CusRole.assistant.name,
          characterId: selectedCharacter.id,
        );

        reloadSession();
      }
    }
  }

  // 清空当前对话
  Future<void> clearMessages() async {
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
      await store.clearMessages(currentSession);
      reloadSession();

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
  Future<void> handleSessionSelected(CharacterChatSession session) async {
    // 更新会话中的角色信息，确保使用最新的角色卡
    await store.updateSessionCharacters(session);

    // 重新获取更新后的会话
    session = store.sessions.firstWhere((s) => s.id == session.id);

    setState(() {
      currentSession = session;
      activeModel =
          session.activeModel ?? session.characters.first.preferredModel;
      currentEditingMessage = null;
      isStreaming = false;
      cancelResponse = null;
    });

    inputController.clear();
    resetContentHeight();
  }

  // 长按抽屉中会话列表项，处理会话操作
  void _handleSessionAction(CharacterChatSession session, String action) {
    if (action == 'edit') {
      editSessionTitle(session);
    } else if (action == 'delete') {
      deleteSession(session);
    }
  }

  // 删除会话
  Future<void> deleteSession(CharacterChatSession session) async {
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
      final isCurrentSession = session.id == currentSession.id;

      await store.deleteSession(session.id);
      await loadAllSessions();

      if (isCurrentSession && allSessions.isNotEmpty) {
        handleSessionSelected(allSessions.first);
      } else if (isCurrentSession) {
        // 如果没有其他会话，创建一个新的空会话
        prepareNewSession();
      }
    }
  }

  ///******************************************* */
  ///
  /// body 相关的内容方法
  ///
  ///******************************************* */

  /// 构建空提示
  Widget buildEmptyMessageHint() {
    // 查找对应的角色
    CharacterCard? character;
    if (currentSession.characters.isNotEmpty) {
      character = currentSession.characters.first;
    }

    return Padding(
      padding: EdgeInsets.all(8.sp),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60.sp,
              height: 60.sp,
              child: buildAvatarClipOval(character?.avatar ?? ''),
            ),
            Text(
              '嗨，我是${character?.name}',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w500),
            ),
            Text('让我们开始聊天吧！'),
          ],
        ),
      ),
    );
  }

  // 构建消息列表
  Widget buildMessageList() {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScaleFactor),
      ),
      child: ListView.builder(
        controller: scrollController,
        // 列表底部留一点高度，避免工具按钮和悬浮按钮重叠
        padding: EdgeInsets.only(bottom: 50.sp),
        itemCount: currentSession.messages.length,
        // 使用cacheExtent提前渲染一些项，使滚动更流畅
        cacheExtent: 1000.0,
        itemBuilder: (context, index) {
          final message = currentSession.messages[index];

          // 查找对应的角色
          CharacterCard? character;
          if (message.characterId != null) {
            character = currentSession.characters
                .where((c) => c.id == message.characterId)
                .firstOrNull;
          }

          return CharacterMessageItem(
            message: message,
            character: character,
            onLongPress: showMessageOptions,
          );
        },
      ),
    );
  }

  // 构建响应加载
  Widget buildResponseLoading() {
    return Container(
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
    );
  }

  // 处理消息长按事件
  void showMessageOptions(
    CharacterChatMessage message,
    LongPressStartDetails details,
  ) async {
    // 添加振动反馈
    HapticFeedback.mediumImpact();

    // 只有用户消息可以编辑
    final bool isUser = message.role == CusRole.user.name;
    // 只有AI消息可以重新生成
    final bool isAssistant = message.role == CusRole.assistant.name;

    // 获取点击位置
    final Offset overlayPosition = details.globalPosition;

    // 显示弹出菜单
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        overlayPosition.dx,
        overlayPosition.dy,
        overlayPosition.dx + 200,
        overlayPosition.dy + 100,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'copy',
          child: buildMenuItemWithIcon(
            icon: Icons.copy,
            text: '复制文本',
          ),
        ),
        PopupMenuItem<String>(
          value: 'select',
          child: buildMenuItemWithIcon(
            icon: Icons.text_fields,
            text: '选择文本',
          ),
        ),
        if (isUser)
          PopupMenuItem<String>(
            value: 'edit',
            child: buildMenuItemWithIcon(
              icon: Icons.edit,
              text: '编辑消息',
            ),
          ),
        if (isUser)
          PopupMenuItem<String>(
            value: 'resend',
            child: buildMenuItemWithIcon(
              icon: Icons.send,
              text: '重新发送',
            ),
          ),
        if (isAssistant)
          PopupMenuItem<String>(
            value: 'regenerate',
            child: buildMenuItemWithIcon(
              icon: Icons.refresh,
              text: '重新生成',
            ),
          ),
      ],
    );

    // 处理选择结果
    if (result == 'copy') {
      Clipboard.setData(ClipboardData(text: message.content));
      EasyLoading.showToast('已复制到剪贴板');
    } else if (result == 'select') {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => TextSelectionDialog(
            text: message.reasoningContent != null &&
                    message.reasoningContent!.isNotEmpty
                ? '【推理过程】\n${message.reasoningContent!}\n\n【AI响应】\n${message.content}'
                : message.content),
      );
    } else if (result == 'edit' && isUser) {
      handleUserMessageEdit(message);
    } else if (result == 'resend' && isUser) {
      handleUserMessageResend(message);
    } else if (result == 'regenerate' && isAssistant) {
      handleResponseRegenerate(message);
    }
  }

  // 开始编辑用户消息
  void handleUserMessageEdit(CharacterChatMessage message) {
    setState(() {
      currentEditingMessage = message;
      inputController.text = message.content;
    });
    inputFocusNode.requestFocus();
  }

  // 重新发送用户消息
  void handleUserMessageResend(CharacterChatMessage message) {
    setState(() {
      currentEditingMessage = message;
    });
    handleSendMessage(
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
  Future<void> handleResponseRegenerate(CharacterChatMessage message) async {
    if (isLoading) return;

    // 找到对应的角色
    final character = currentSession.characters
        .where((c) => c.id == message.characterId)
        .firstOrNull;
    if (character == null) return;

    setState(() {
      isLoading = true;
      isStreaming = true;
    });

    try {
      // 更新消息内容为空
      await store.updateMessage(
        session: currentSession,
        message: message,
        content: '',
      );

      reloadSession();

      // 处理AI响应
      await _commonGenerateResponse(character, message);
    } catch (e) {
      EasyLoading.showError('重新生成失败: $e');
    } finally {
      setState(() {
        isLoading = false;
        isStreaming = false;
        cancelResponse = null;
      });
    }
  }

  ///******************************************* */
  ///
  /// 输入区域 相关的内容方法
  ///
  ///******************************************* */

  // 处理发送消息
  Future<void> handleSendMessage(MessageData messageData) async {
    if (isLoading) return;

    // 如果是编辑模式，调用编辑处理方法
    if (currentEditingMessage != null) {
      await _processingUserMessage(messageData);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // 添加用户消息
      await store.addMessage(
        session: currentSession,
        content: messageData.text,
        role: CusRole.user.name,
        contentVoicePath: messageData.audio?.path,
        imagesUrl: messageData.images?.map((img) => img.path).join(','),
      );

      // 如果是新创建的空会话，现在已经有内容了，需要刷新会话列表
      if (isNewEmptySession) {
        isNewEmptySession = false;
      }

      // 刷新会话列表，确保UI显示最新会话(比如抽屉的最后修改时间)
      loadAllSessions();
      reloadSession();
      setState(() {
        isStreaming = true;
      });

      inputController.clear();

      // 滚动到底部
      resetContentHeight();

      // 生成AI回复
      await _generateAIResponses();
    } catch (e) {
      EasyLoading.showError('发送消息失败: $e');
    } finally {
      setState(() {
        isLoading = false;
        isStreaming = false;
        cancelResponse = null;
      });

      // 清空输入框
      inputController.clear();
    }
  }

  // 处理编辑消息
  Future<void> _processingUserMessage(MessageData messageData) async {
    if (currentEditingMessage == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      // 更新消息内容
      await store.updateMessage(
        session: currentSession,
        message: currentEditingMessage!,
        content: messageData.text,
      );

      // 找到消息在列表中的位置
      final index = currentSession.messages
          .indexWhere((m) => m.id == currentEditingMessage!.id);
      if (index >= 0) {
        // 删除该消息之后的所有回复
        final messagesToDelete = currentSession.messages
            .where((m) => currentSession.messages.indexOf(m) > index)
            .toList();

        for (var msg in messagesToDelete) {
          await store.deleteMessage(currentSession, msg);
        }
      }

      reloadSession();
      setState(() {
        inputController.clear();
        isLoading = false;
        currentEditingMessage = null;
      });

      // 滚动到底部
      resetContentHeight();
      // 重新生成AI回复，但不添加新的用户消息
      await _generateAIResponses();
    } catch (e) {
      EasyLoading.showError('编辑消息失败: $e');
    } finally {
      setState(() {
        isLoading = false;
        currentEditingMessage = null;
      });

      // 清空输入框
      inputController.clear();
    }
  }

  // 生成AI回复（不添加新的用户消息）
  Future<void> _generateAIResponses() async {
    setState(() {
      isStreaming = true;
    });

    try {
      // 创建一个列表来存储所有角色的生成任务
      final List<Future<void>> generationTasks = [];

      // 为每个角色创建一个空消息
      final Map<String, CharacterChatMessage> characterMessages = {};

      for (var character in currentSession.characters) {
        // 创建一个空消息
        final aiMessage = await store.addMessage(
          session: currentSession,
          content: '',
          role: CusRole.assistant.name,
          characterId: character.id,
        );

        // 保存消息引用，以便后续更新
        characterMessages[character.id] = aiMessage;
      }

      // 刷新会话，确保UI显示所有空消息
      reloadSession();

      // 为每个角色创建并启动生成任务
      for (var character in currentSession.characters) {
        final task = _commonGenerateResponse(
          character,
          characterMessages[character.id]!,
        );
        generationTasks.add(task);
      }

      // 等待所有生成任务完成
      await Future.wait(generationTasks);

      // 刷新会话列表，确保UI显示所有空消息
      loadAllSessions();
    } catch (e) {
      EasyLoading.showError('生成回复失败: $e');
    } finally {
      setState(() {
        isStreaming = false;
        cancelResponse = null;
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
        activeModel ?? character.preferredModel!,
        history,
        stream: true,
      );

      // 保存取消函数
      // 注意：这里只保存最后一个角色的取消函数，如果需要取消所有，需要更复杂的管理
      cancelResponse = cancelFunc;

      String fullContent = '';
      String fullReasoningContent = '';
      var startTime = DateTime.now();
      DateTime? endTime;
      var thinkingDuration = 0;

      await for (final response in stream) {
        if (response.choices.isNotEmpty) {
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
          await store.updateMessage(
            session: currentSession,
            message: aiMessage,
            content: fullContent,
            reasoningContent: fullReasoningContent,
            thinkingDuration: thinkingDuration,
          );

          // 更新UI
          if (mounted) {
            reloadSession();

            // 如果用户没有手动滚动，则自动滚动到底部
            if (!isUserScrolling) {
              resetContentHeight();
            }
          }
        }
      }
    } catch (e) {
      EasyLoading.showError('生成${character.name}的回复失败: $e');

      // 更新消息，显示错误
      await store.updateMessage(
        session: currentSession,
        message: aiMessage,
        content: '生成${character.name}的回复失败: $e',
      );

      // 刷新会话
      if (!mounted) return;
      reloadSession();
    }
  }

  // 取消编辑用户消息
  void handleCancelEditUserMessage() {
    setState(() {
      currentEditingMessage = null;
      inputController.clear();
    });
  }

  // 停止生成
  void handleStopStreaming() {
    if (cancelResponse != null) {
      cancelResponse!();
      cancelResponse = null;

      setState(() {
        isStreaming = false;
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
      bottom: isStreaming ? inputHeight + 5.sp : inputHeight - 5.sp,
      child: Container(
        // 新版本输入框为了更多输入内容，左右边距为0
        padding: EdgeInsets.symmetric(horizontal: 0.sp),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 图标按钮的默认尺寸是48*48,占位宽度默认48
            SizedBox(width: 48.sp),
            if (currentSession.messages.isNotEmpty && !isStreaming)
              // 新加对话按钮的背景色
              Padding(
                // 这里的上下边距，和下面maxHeight的和，要等于默认图标按钮高度的48sp
                padding: EdgeInsets.symmetric(vertical: 16.sp),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
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
                    onPressed: prepareNewSession,
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

  // 构建背景
  Widget buildBackground() {
    if (backgroundImage == null || backgroundImage!.isEmpty) {
      return Container(color: Colors.transparent);
    }

    return Positioned.fill(
      child: Opacity(
        opacity: backgroundOpacity,
        child: buildCusImage(backgroundImage!, fit: BoxFit.cover),
      ),
    );

    // 使用FadeInImage或Image.memory来优化图片加载
    // return Opacity(
    //   opacity: _backgroundOpacity,
    //   child: _backgroundImage!.startsWith('assets/')
    //       ? Image.asset(
    //           _backgroundImage!,
    //           fit: BoxFit.cover,
    //           width: double.infinity,
    //           height: double.infinity,
    //         )
    //       : Image.file(
    //           File(_backgroundImage!),
    //           fit: BoxFit.cover,
    //           width: double.infinity,
    //           height: double.infinity,
    //         ),
    // );
  }

  ///******************************************* */
  ///
  /// 其他相关的内容方法
  ///
  ///******************************************* */

  /// 添加角色的首条消息
  Future<void> _addCharacterFirstMessages() async {
    for (var character in currentSession.characters) {
      if (character.firstMessage.isNotEmpty) {
        await store.addMessage(
          session: currentSession,
          content: character.firstMessage,
          role: CusRole.assistant.name,
          characterId: character.id,
        );
      }
    }

    reloadSession();
  }

  /// 准备聊天历史(用于构建调用大模型API的请求参数)
  List<Map<String, dynamic>> _prepareChatHistory(CharacterCard character) {
    final history = <Map<String, dynamic>>[];

    // 添加系统提示词
    history.add({
      'role': CusRole.system.name,
      'content': character.generateSystemPrompt(),
    });

    // 添加聊天历史
    for (var message in currentSession.messages) {
      // 跳过空消息
      if (message.content.isEmpty &&
          message.imagesUrl == null &&
          message.contentVoicePath == null) {
        continue;
      }

      if (message.role == CusRole.user.name) {
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
            'role': CusRole.user.name,
            'content': contentList,
          });
        } else {
          // 纯文本消息
          history.add({
            'role': CusRole.user.name,
            'content': message.content,
          });
        }
      } else if (message.role == CusRole.assistant.name &&
          message.characterId == character.id) {
        // AI助手的回复通常是纯文本
        history.add({
          'role': CusRole.assistant.name,
          'content': message.content,
        });
      }
    }

    return history;
  }

  // 重置对话列表内容高度(在点击了重新生成、切换了模型、点击了指定历史记录后都应该调用)
  void resetContentHeight({int? times}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;

      lastContentHeight = scrollController.position.maxScrollExtent;
    });

    // 重置完了顺便滚动到底部
    _scrollToBottom(times: times);
  }

  void _scrollToBottom({int? times}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: times ?? 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
