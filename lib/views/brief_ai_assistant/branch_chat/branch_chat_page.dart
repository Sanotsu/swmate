import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../common/components/simple_marquee_or_text.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/utils/advanced_options_utils.dart';
import '../../../models/brief_ai_tools/chat_branch/chat_branch_message.dart';
import '../../../models/brief_ai_tools/chat_branch/branch_manager.dart';
import '../../../models/brief_ai_tools/chat_branch/branch_store.dart';
import '../../../models/brief_ai_tools/chat_branch/chat_branch_session.dart';
import '../../../services/chat_service.dart';
import '../../../services/cus_get_storage.dart';
import '../_chat_components/small_widgets.dart';
import '../chat/components/model_filter.dart';
import '../chat/components/model_selector.dart';
import 'components/branch_message_item.dart';
import 'components/branch_tree_dialog.dart';
import 'components/chat_input_bar.dart';
import 'components/chat_history_drawer.dart';
import 'package:flutter/services.dart';

import 'components/text_selection_dialog.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../common/llm_spec/constant_llm_enum.dart';
import '../../../services/model_manager_service.dart';
import 'components/branch_message_actions.dart';

class BranchChatPage extends StatefulWidget {
  const BranchChatPage({super.key});

  @override
  State<BranchChatPage> createState() => _BranchChatPageState();
}

class _BranchChatPageState extends State<BranchChatPage>
    with WidgetsBindingObserver {
  final TextEditingController _inputController = TextEditingController();
  final BranchManager _branchManager = BranchManager();
  late final BranchStore _store;

  List<ChatBranchMessage> allMessages = [];
  List<ChatBranchMessage> displayMessages = [];
  String currentBranchPath = "0";
  ChatBranchMessage? currentEditingMessage;
  bool isLoading = true;
  bool isStreaming = false;
  String streamingContent = '';
  String streamingReasoningContent = '';
  ChatBranchMessage? streamingMessage;
  int? _currentSessionId;
  int? regeneratingMessageId;
  bool isNewChat = false;

  // 添加模型相关状态
  List<CusBriefLLMSpec> _modelList = [];
  LLModelType _selectedType = LLModelType.cc;
  CusBriefLLMSpec? _selectedModel;

  // 添加高级参数状态
  bool _advancedEnabled = false;
  Map<String, dynamic>? _advancedOptions;

  // 添加焦点控制器
  final FocusNode _inputFocusNode = FocusNode();

  // 输入框高度状态(用于悬浮按钮的布局)
  // 输入框展开收起工具栏时，悬浮按钮(新加对话、滚动到底部)位置需要动态变化，始终在输入框的上方
  double _inputHeight = 0;

  // 默认的页面主体的缩放比例(对话太小了就可以等比放大)
  // 直接全局缓存，所有使用ChatListArea的地方都改了
  double _textScaleFactor = 1.0;

  // 对话列表滚动控制器
  final ScrollController _scrollController = ScrollController();
  // 是否显示"滚动到底部"按钮
  bool _showScrollToBottom = false;
  // 是否用户手动滚动
  bool _isUserScrolling = false;
  // 最后内容高度(用于判断是否需要滚动到底部)
  double _lastContentHeight = 0;

  @override
  void initState() {
    super.initState();
    _initStore();
    _initialize();

    // 获取缓存中的正文文本缩放比例
    _textScaleFactor = MyGetStorage().getChatListAreaScale();

    // 获取缓存的高级选项配置
    if (_selectedModel != null) {
      _advancedEnabled =
          MyGetStorage().getAdvancedOptionsEnabled(_selectedModel!);
      if (_advancedEnabled) {
        _advancedOptions = MyGetStorage().getAdvancedOptions(_selectedModel!);
      }
    }

    // 监听滚动事件
    _scrollController.addListener(() {
      // 判断用户是否正在手动滚动
      if (_scrollController.position.userScrollDirection ==
              ScrollDirection.reverse ||
          _scrollController.position.userScrollDirection ==
              ScrollDirection.forward) {
        _isUserScrolling = true;
      } else {
        _isUserScrolling = false;
      }

      // 判断是否显示"滚动到底部"按钮
      setState(() {
        _showScrollToBottom = _scrollController.offset <
            _scrollController.position.maxScrollExtent - 50;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inputFocusNode.dispose(); // 记得释放焦点
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

// 布局发生变化时（如键盘弹出/收起）
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    // 流式响应还未完成且不是用户手动滚动，滚动到底部
    if (isStreaming && !_isUserScrolling) {
      _resetContentHeight();
    }
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

    _resetContentHeight();
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
          if (isStreaming &&
              (streamingContent.isNotEmpty ||
                  streamingReasoningContent.isNotEmpty))
            ChatBranchMessage(
              id: 0,
              messageId: 'streaming',
              role: 'assistant',
              content: streamingContent,
              reasoningContent: streamingReasoningContent,
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

    _resetContentHeight();
  }

  Future<void> _initialize() async {
    try {
      // 获取可用模型列表
      final availableModels =
          await ModelManagerService.getAvailableModelByTypes([
        LLModelType.cc,
        LLModelType.vision,
        LLModelType.reasoner,
      ]);

      if (!mounted) return;
      setState(() {
        _modelList = availableModels;
        _selectedModel = availableModels.first;
        _selectedType = _selectedModel!.modelType;
      });

      // 初始化会话
      await _initializeSession();
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _initializeSession() async {
    if (_currentSessionId == null) {
      if (!isNewChat) {
        // 加载最近的会话
        final sessions = _store.sessionBox.getAll()
          ..sort((a, b) => b.updateTime.compareTo(a.updateTime));

        if (sessions.isNotEmpty) {
          final session = sessions.first;
          setState(() {
            _currentSessionId = session.id;
            _selectedModel = session.llmSpec;
            _selectedType = session.modelType;
          });
        } else {
          setState(() => isNewChat = true);
        }
      }
    } else {
      // 加载当前会话的模型信息
      final session = _store.sessionBox.get(_currentSessionId!);

      print("session: ${session?.llmSpec.cusLlmSpecId}");

      if (session != null) {
        setState(() {
          _selectedModel = _modelList
              .where((m) => m.cusLlmSpecId == session.llmSpec.cusLlmSpecId)
              .firstOrNull;

          if (_selectedModel == null) {
            _selectedModel = _modelList.first;
            _createNewChat();
          }

          _selectedType = _selectedModel!.modelType;
        });
      }
    }

    // 加载消息
    if (!isNewChat && _currentSessionId != null) {
      await _loadMessages();
    }

    _resetContentHeight();
  }

  // 显示高级选项弹窗
  Future<void> _showAdvancedOptions() async {
    if (_selectedModel == null) return;

    final result = await AdvancedOptionsUtils.showAdvancedOptions(
      context: context,
      platform: _selectedModel!.platform,
      modelType: _selectedModel!.modelType,
      currentEnabled: _advancedEnabled,
      currentOptions: _advancedOptions ?? {},
    );

    if (result != null) {
      setState(() {
        _advancedEnabled = result.enabled;
        _advancedOptions = result.enabled ? result.options : null;
      });

      // 保存到缓存
      await MyGetStorage()
          .setAdvancedOptionsEnabled(_selectedModel!, result.enabled);
      await MyGetStorage().setAdvancedOptions(
        _selectedModel!,
        result.enabled ? result.options : null,
      );
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
        title: SimpleMarqueeOrText(
          data:
              "${CP_NAME_MAP[_selectedModel?.platform]} > ${_selectedModel?.model}",
          velocity: 30,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        actions: [
          // if (!isStreaming)
          //   IconButton(
          //     icon: const Icon(Icons.account_tree),
          //     onPressed: !isNewChat ? _showBranchTree : null,
          //   ),
          // IconButton(
          //   icon: const Icon(Icons.add),
          //   onPressed: _createNewChat,
          // ),
          // // 更多参数按钮
          // IconButton(
          //   icon: Icon(
          //     Icons.tune,
          //     color: _advancedEnabled ? Theme.of(context).primaryColor : null,
          //   ),
          //   tooltip: '更多参数',
          //   onPressed: isStreaming ? null : _showAdvancedOptions,
          // ),

          // IconButton(
          //   icon: const Icon(Icons.format_size_outlined),
          //   onPressed: isStreaming
          //       ? null
          //       : () => adjustTextScale(
          //             context,
          //             _textScaleFactor,
          //             (value) async {
          //               setState(() => _textScaleFactor = value);
          //               await MyGetStorage().setChatListAreaScale(value);

          //               if (!context.mounted) return;
          //               Navigator.of(context).pop();

          //               unfocusHandle();
          //             },
          //           ),
          // ),

          if (!isStreaming) _buildPopupMenuButton(),
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.history),
                onPressed: isStreaming
                    ? null
                    : () => Scaffold.of(context).openEndDrawer(),
              );
            },
          ),
        ],
      ),
      endDrawer: FutureBuilder<List<ChatBranchSession>>(
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
            onSessionSelected: (session) => _switchSession(session.id),
            onRefresh: (session, type) async {
              if (type == 'edit') {
                _store.sessionBox.put(session);
              } else if (type == 'delete') {
                await _store.deleteSession(session);
                // 如果删除的是当前会话，创建新会话
                if (session.id == _currentSessionId) {
                  _createNewChat();
                }
              }
              // 刷新抽屉
              setState(() {});
            },
          );
        },
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("当前模型"),
                  SimpleMarqueeOrText(
                    data:
                        "${CP_NAME_MAP[_selectedModel?.platform]} > ${_selectedModel?.name}",
                    velocity: 30,
                    showLines: 2,
                    height: 48.sp,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),

              /// 添加模型过滤器
              ModelFilter(
                models: _modelList,
                selectedType: _selectedType,
                onTypeChanged: isStreaming ? null : _handleTypeChanged,
                onModelSelect: isStreaming ? null : _showModelSelector,
                isStreaming: isStreaming,
              ),

              /// 聊天内容
              Expanded(
                child: _buildChatContent(),
              ),

              /// 流式响应时显示进度条
              if (isStreaming)
                Padding(
                  padding: EdgeInsets.symmetric(
                    /// 调整位置之后，还是滚动条贯穿屏幕，悬浮按钮放在滚动条上方，和谐一点
                    horizontal: 8.sp,
                  ),
                  child: ClipRRect(
                    // 设置圆角
                    borderRadius: BorderRadius.all(Radius.circular(5.sp)),
                    child: SizedBox(
                      height: 5.sp, // 设置高度
                      child: LinearProgressIndicator(
                        value: null, // 当前进度(null就循环)
                        backgroundColor: Colors.grey, // 背景颜色
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue, // 进度条颜色
                        ),
                      ),
                    ),
                  ),
                ),

              /// 输入框
              ChatInputBar(
                controller: _inputController,
                focusNode: _inputFocusNode,
                onSend: _handleSendMessage,
                onCancel:
                    currentEditingMessage != null ? _handleCancelEdit : null,
                isEditing: currentEditingMessage != null,
                isStreaming: isStreaming,
                onStop: _handleStopStreaming,
                model: _selectedModel,
                onHeightChanged: (height) {
                  print('inputHeight------------: $height');
                  setState(() => _inputHeight = height);
                },
              ),
            ],
          ),

          /// 悬浮按钮(前面是显示新加对话按钮，后面显示滚动到底部按钮)
          _buildFloatingButton(),
        ],
      ),
    );
  }

  // 弹窗菜单按钮
  Widget _buildPopupMenuButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz_sharp),
      // 调整弹出按钮的位置
      position: PopupMenuPosition.under,
      // 弹出按钮的偏移
      // offset: Offset(-25.sp, 0),
      onSelected: (String value) async {
        // 处理选中的菜单项
        if (value == 'tree') {
          _showBranchTree();
        } else if (value == 'add') {
          _createNewChat();
        } else if (value == 'options') {
          _showAdvancedOptions();
        } else if (value == 'text_size') {
          adjustTextScale(
            context,
            _textScaleFactor,
            (value) async {
              setState(() => _textScaleFactor = value);
              await MyGetStorage().setChatListAreaScale(value);

              if (!mounted) return;
              Navigator.of(context).pop();

              unfocusHandle();
            },
          );
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
        buildCusPopupMenuItem(context, "tree", "对话分支", Icons.account_tree),
        buildCusPopupMenuItem(context, "add", "新加对话", Icons.add),
        buildCusPopupMenuItem(context, "options", "高级选项", Icons.tune),
        buildCusPopupMenuItem(context, "text_size", "文字大小", Icons.format_size),
      ],
    );
  }

  Widget _buildChatContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(_textScaleFactor),
      ),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: displayMessages.length,
        itemBuilder: (context, index) {
          final message = displayMessages[index];

          // 如果当前消息是流式消息，说明正在追加显示中，则不显示分支相关内容
          final isStreamingMessage = message.messageId == 'streaming';
          final hasMultipleBranches = !isStreamingMessage &&
              _branchManager.getBranchCount(allMessages, message) > 1;

          return Column(
            children: [
              BranchMessageItem(
                message: message,
                onLongPress: isStreaming ? null : _showMessageOptions,
              ),
              BranchMessageActions(
                message: message,
                messages: allMessages,
                onRegenerate: () => _handleRegenerate(message),
                hasMultipleBranches: hasMultipleBranches,
                // 2025-03-12 这里有问题，message.id始终是0。
                // 理论上，在流式生成中也就当作在重新生成中，重新生成按钮就不可用，改为加载图标
                // isRegenerating: message.id == regeneratingMessageId,
                isRegenerating: isStreaming,
                currentBranchIndex: isStreamingMessage
                    ? 0
                    : _branchManager.getBranchIndex(
                        allMessages,
                        message,
                      ),
                totalBranches: isStreamingMessage
                    ? 1
                    : _branchManager.getBranchCount(
                        allMessages,
                        message,
                      ),
                onSwitchBranch: _handleSwitchBranch,
              ),

              /// 最后一条消息留一点高度，避免工具按钮和悬浮按钮重叠
              if (index == displayMessages.length - 1) SizedBox(height: 50.sp),
            ],
          );
        },
      ),
    );
  }

  // 长按消息，显示消息选项
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
          child: Row(
            children: [
              Icon(Icons.copy),
              SizedBox(width: 8.sp),
              Text('复制文本'),
            ],
          ),
        ),
        // 选择文本按钮
        PopupMenuItem<String>(
          value: 'select',
          child: Row(
            children: [
              Icon(Icons.text_fields),
              SizedBox(width: 8.sp),
              Text('选择文本')
            ],
          ),
        ),
        if (message.role == 'user')
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit),
                SizedBox(width: 8.sp),
                Text('编辑消息'),
              ],
            ),
          ),
        if (message.role == 'assistant')
          PopupMenuItem<String>(
            value: 'regenerate',
            child: Row(
              children: [
                Icon(Icons.refresh),
                SizedBox(width: 8.sp),
                Text('重新生成')
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

  // 修改发送消息处理方法
  Future<void> _handleSendMessage(MessageData messageData) async {
    if (messageData.text.isEmpty &&
        messageData.images == null &&
        messageData.audio == null &&
        messageData.file == null) return;

    if (!mounted) return;
    if (_selectedModel == null) {
      commonExceptionDialog(context, "异常提示", "请先选择一个模型");
      return;
    }

    var content = messageData.text;

    // 处理JSON格式响应
    if (_advancedEnabled &&
        _advancedOptions?["response_format"] == "json_object") {
      content = "$content(请严格按照json格式输出)";
    }

    try {
      if (isNewChat) {
        final title = content.length > 20 ? content.substring(0, 20) : content;

        final session = await _store.createSession(
          title,
          llmSpec: _selectedModel!,
          modelType: _selectedType,
        );
        setState(() {
          _currentSessionId = session.id;
          isNewChat = false;
        });
      }

      // TODO: 处理图片、音频等媒体文件的上传

      if (currentEditingMessage != null) {
        await _handleEditMessage(currentEditingMessage!, messageData);
      } else {
        await _store.addMessage(
          session: _store.sessionBox.get(_currentSessionId!)!,
          content: content,
          role: 'user',
          parent: displayMessages.isEmpty ? null : displayMessages.last,
          contentVoicePath: messageData.audio?.path,
          imagesUrl: messageData.images?.isNotEmpty == true
              ? messageData.images?.map((i) => i.path).toList().join(',')
              : null,
          videosUrl: messageData.videos?.isNotEmpty == true
              ? messageData.videos?.map((i) => i.path).toList().join(',')
              : null,
          // TODO: 添加媒体文件的存储
        );
      }

      _inputController.clear();
      await _loadMessages();
      await _generateAIResponse();
    } catch (e) {
      print('发送消息失败: $e');
      if (!mounted) return;
      commonExceptionDialog(context, "异常提示", "发送消息失败: $e");
    }
  }

  // 重新编辑已发送的用户消息
  Future<void> _handleEditMessage(
      ChatBranchMessage message, MessageData messageData) async {
    final content = messageData.text.trim();
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

      // 更新当前分支路径并将正在编辑的消息设置为null
      setState(() {
        currentBranchPath = newPath;
        currentEditingMessage = null;
      });
    } catch (e) {
      print('编辑消息失败: $e');
      if (!mounted) return;
      commonExceptionDialog(context, "异常提示", "编辑消息失败: $e");
    }
  }

  /// 添加一个通用的AI响应生成方法
  Future<ChatBranchMessage?> _generateAIResponseCommon({
    required List<ChatBranchMessage> contextMessages,
    required String newBranchPath,
    required int newBranchIndex,
    required int depth,
    ChatBranchMessage? parentMessage,
  }) async {
    setState(() {
      isStreaming = true;
      streamingContent = '';
      streamingReasoningContent = '';
      // 创建临时的流式消息
      displayMessages = [
        ...contextMessages,
        ChatBranchMessage(
          id: 0,
          messageId: 'streaming',
          role: 'assistant',
          content: '',
          createTime: DateTime.now(),
          branchPath: newBranchPath,
          branchIndex: newBranchIndex,
          depth: depth,
        ),
      ];
    });

    String finalContent = '';
    String finalReasoningContent = '';
    var startTime = DateTime.now();
    DateTime? endTime;
    var thinkingDuration = 0;
    ChatBranchMessage? aiMessage;

    try {
      final response = await ChatService.sendBranchMessage(
        _selectedModel!,
        contextMessages,
        advancedOptions: _advancedEnabled ? _advancedOptions : null,
        stream: true,
        onStream: (chunk) {
          if (!isStreaming) return;
          setState(() {
            streamingContent += chunk.cusText;
            streamingReasoningContent += chunk.choices.isNotEmpty
                ? (chunk.choices.first.delta?["reasoning_content"] ?? '')
                : '';
            finalContent += chunk.cusText;
            finalReasoningContent += chunk.choices.isNotEmpty
                ? (chunk.choices.first.delta?["reasoning_content"] ?? '')
                : '';

            if (endTime == null && streamingContent.trim().isNotEmpty) {
              endTime = DateTime.now();
              thinkingDuration = endTime!.difference(startTime).inSeconds;
            }

            // 更新显示消息列表中的流式消息内容
            displayMessages = [
              ...contextMessages,
              ChatBranchMessage(
                id: 0,
                messageId: 'streaming',
                role: 'assistant',
                content: streamingContent,
                reasoningContent: streamingReasoningContent,
                thinkingDuration: thinkingDuration,
                createTime: DateTime.now(),
                branchPath: newBranchPath,
                branchIndex: newBranchIndex,
                depth: depth,
              ),
            ];
          });

          // 如果用户没有手动滚动或者已经在底部，则自动滚动
          // 在布局更新后检查内容高度变化
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final currentHeight = _scrollController.position.maxScrollExtent;

            if (!_isUserScrolling && currentHeight - _lastContentHeight > 20) {
              // 高度增加超过 20 像素
              _scrollController.jumpTo(currentHeight);
              _lastContentHeight = currentHeight;
            }
          });
        },
      );

      if (!isStreaming) return null;

      // 创建新的AI消息
      aiMessage = await _store.addMessage(
        session: _store.sessionBox.get(_currentSessionId!)!,
        content:
            finalContent.isNotEmpty ? finalContent : response?.cusText ?? '',
        role: 'assistant',
        parent: parentMessage,
        reasoningContent: finalReasoningContent,
        thinkingDuration: thinkingDuration,
        modelLabel: parentMessage?.modelLabel ?? _selectedModel!.name,
        branchIndex: newBranchIndex,
      );

      // 更新当前分支路径
      setState(() {
        currentBranchPath = aiMessage!.branchPath;
        isStreaming = false;
        streamingContent = '';
        streamingReasoningContent = '';
      });

      await _loadMessages();
      return aiMessage;
    } catch (e) {
      print('AI响应生成失败: $e');
      if (!mounted) return null;
      commonExceptionDialog(context, "异常提示", "AI响应生成失败: $e");
      return null;
    } finally {
      if (mounted) {
        setState(() {
          isStreaming = false;
          streamingContent = '';
          streamingReasoningContent = '';
        });
      }
    }
  }

  // 修改 _handleRegenerate 方法
  Future<void> _handleRegenerate(ChatBranchMessage message) async {
    print('点击了重新生成message: $message');

    if (isStreaming) return;

    setState(() {
      regeneratingMessageId = message.id;
      isStreaming = true;
    });

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

      await _generateAIResponseCommon(
        contextMessages: contextMessages,
        newBranchPath: newPath,
        newBranchIndex: newBranchIndex,
        depth: message.depth,
        parentMessage: message.parent.target,
      );
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, "异常提示", "重新生成失败: $e");
      setState(() {
        isStreaming = false;
      });
    } finally {
      if (mounted) {
        setState(() => regeneratingMessageId = null);
      }
    }
  }

  // 修改 _generateAIResponse 方法
  Future<void> _generateAIResponse() async {
    final currentMessages = _branchManager.getMessagesByBranchPath(
      allMessages,
      currentBranchPath,
    );

    if (currentMessages.isEmpty) {
      print('Error: No messages found for branch path: $currentBranchPath');
      return;
    }

    await _generateAIResponseCommon(
      contextMessages: currentMessages,
      newBranchPath: currentBranchPath,
      newBranchIndex:
          currentMessages.isEmpty ? 0 : currentMessages.last.branchIndex,
      depth: currentMessages.isEmpty ? 0 : currentMessages.last.depth,
      parentMessage: currentMessages.last,
    );
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
        if (isStreaming &&
            (streamingContent.isNotEmpty ||
                streamingReasoningContent.isNotEmpty))
          ChatBranchMessage(
            id: 0,
            messageId: 'streaming',
            role: 'assistant',
            content: streamingContent,
            reasoningContent: streamingReasoningContent,
            createTime: DateTime.now(),
            branchPath: newPath,
            branchIndex:
                currentMessages.isEmpty ? 0 : currentMessages.last.branchIndex,
            depth: currentMessages.isEmpty ? 0 : currentMessages.last.depth,
          ),
      ];
    });

    _resetContentHeight();
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
      // 显示键盘
      _inputFocusNode.requestFocus();
    });
  }

  void _handleStopStreaming() {
    setState(() => isStreaming = false);
  }

  // 加载历史对话列表并按更新时间排序
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
      streamingReasoningContent = '';
      currentEditingMessage = null;
      _inputController.clear();
      displayMessages.clear();

      // 开启新对话后，没有对话列表，所以不显示滚动到底部按钮
      _showScrollToBottom = false;

      // 创建新对话后，重置内容高度
      _resetContentHeight();
    });
  }

  Future<void> _switchSession(int sessionId) async {
    final session = _store.sessionBox.get(sessionId);

    if (session == null) {
      EasyLoading.showInfo(
        '该历史对话所用模型已被删除，将使用默认模型构建全新对话。',
        duration: const Duration(seconds: 5),
      );

      _selectedModel = _modelList.first;
      _selectedType = _selectedModel!.modelType;

      _createNewChat();
      return;
    }

    setState(() {
      _currentSessionId = sessionId;
      isNewChat = false;
      currentBranchPath = "0";
      isStreaming = false;
      streamingContent = '';
      streamingReasoningContent = '';
      currentEditingMessage = null;
      _inputController.clear();

      // 恢复使用的模型
      _selectedModel = _modelList
          .where((m) => m.cusLlmSpecId == session.llmSpec.cusLlmSpecId)
          .firstOrNull;

      _selectedType = _selectedModel!.modelType;
    });
    await _loadMessages();
  }

  // 切换模型类型
  void _handleTypeChanged(LLModelType type) {
    setState(() {
      _selectedType = type;

      // 如果当前选中的模型不是新类型的，则清空选择
      // 因为切换类型时，一定会触发模型选择器，在模型选择的地方有重新创建对话，所以这里不用重新创建
      if (_selectedModel?.modelType != type) {
        _selectedModel = null;
      }
    });
  }

  // 显示模型选择器
  Future<void> _showModelSelector() async {
    // 获取可用的模型列表
    final filteredModels =
        _modelList.where((m) => m.modelType == _selectedType).toList();

    if (filteredModels.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前类型没有可用的模型')),
      );
      return;
    }

    if (!mounted) return;
    final model = await showModalBottomSheet<CusBriefLLMSpec>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: ModelSelector(
          models: filteredModels,
          selectedModel: _selectedModel,
          onModelChanged: (model) => Navigator.pop(context, model),
        ),
      ),
    );

    if (!mounted) return;
    if (model != null) {
      setState(() => _selectedModel = model);
    } else {
      // 如果没有点击模型，则使用选定分类的第一个模型
      setState(() => _selectedModel = filteredModels.first);
    }

    // 选择指定模型后，加载对应类型上次缓存的高级选项配置
    _advancedEnabled =
        MyGetStorage().getAdvancedOptionsEnabled(_selectedModel!);
    _advancedOptions = _advancedEnabled
        ? MyGetStorage().getAdvancedOptions(_selectedModel!)
        : null;

    // 2025-03-03 切换模型后也直接重建对话好了？？？此时就不用重置内容高度了
    _createNewChat();
  }

  // 取消编辑
  void _handleCancelEdit() {
    setState(() {
      currentEditingMessage = null;
      _inputController.clear();
      // 收起键盘
      _inputFocusNode.unfocus();
    });
  }

  // 重置对话列表内容高度(在点击了重新生成、切换了模型、点击了指定历史记录后都应该调用)
  void _resetContentHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      _lastContentHeight = _scrollController.position.maxScrollExtent;
    });

    // 重置完了顺便滚动到底部
    _scrollToBottom();
  }

  // 滚动到底部
  void _scrollToBottom() {
    // 统一在这里等待布局更新完成，才滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      // 延迟50ms，避免内容高度还没更新
      Future.delayed(const Duration(milliseconds: 50), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      });

      setState(() {
        _isUserScrolling = false;
      });
    });
  }

  // 构建消息列表的底部
  Widget _buildFloatingButton() {
    return Positioned(
      left: 0,
      right: 0,
      // 悬浮按钮有设定上下间距，所以这里不需要加间距,甚至根据悬浮按钮内部的边距减少尺寸
      bottom: _inputHeight - 5.sp,
      child: Container(
        // 这个边距是和其他对话消息列表等逐渐的间距保持一致
        padding: EdgeInsets.symmetric(horizontal: 8.sp),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 图标按钮的默认尺寸是48*48,占位宽度默认48
            SizedBox(width: 48.sp),
            if (displayMessages.isNotEmpty && !isStreaming)
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
                    onPressed: _createNewChat,
                    label: Text(
                      '开启新对话',
                      style: TextStyle(fontSize: 12.sp, color: Colors.white),
                    ),
                  ),
                ),
              ),
            if (_showScrollToBottom)
              // 按钮图标变小，但为了和下方的发送按钮对齐，所以补足占位宽度
              IconButton(
                iconSize: 24.sp,
                icon: FaIcon(
                  FontAwesomeIcons.circleArrowDown,
                  color: Colors.black,
                ),
                onPressed: _resetContentHeight,
              ),
            if (!_showScrollToBottom) SizedBox(width: 48.sp),
          ],
        ),
      ),
    );
  }
}
