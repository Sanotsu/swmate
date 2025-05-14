import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';

import '../../../common/constants/constants.dart';
import '../../../common/utils/tools.dart';
import '../../../services/model_manager_service.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../common/llm_spec/constant_llm_enum.dart';
import '../../../common/components/simple_marquee_or_text.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/utils/advanced_options_utils.dart';
import '../../../models/brief_ai_tools/branch_chat/branch_chat_message.dart';
import '../../../models/brief_ai_tools/branch_chat/branch_manager.dart';
import '../../../models/brief_ai_tools/branch_chat/branch_store.dart';
import '../../../models/brief_ai_tools/branch_chat/branch_chat_session.dart';
import '../../../services/chat_service.dart';
import '../../../services/cus_get_storage.dart';

import '../_chat_components/_small_tool_widgets.dart';
import '../_chat_pages/chat_export_import_page.dart';
import '../_chat_pages/chat_background_picker_page.dart';
import '../_chat_components/model_filter.dart';
import '../_chat_components/model_selector.dart';
import '../../../common/components/cus_markdown_renderer.dart';

import 'components/branch_message_item.dart';
import 'components/branch_tree_dialog.dart';
import '../_chat_components/chat_input_bar.dart';
import 'components/branch_chat_history_drawer.dart';
import '../_chat_components/text_selection_dialog.dart';
import 'components/branch_message_actions.dart';

import 'pages/add_model_page.dart';

///
/// 分支对话主页面
///
/// 除非是某个函数内部使用且不再全局其他地方也能使用的方法设为私有，其他都不加下划线
///
class BranchChatPage extends StatefulWidget {
  const BranchChatPage({super.key});

  @override
  State<BranchChatPage> createState() => _BranchChatPageState();
}

class _BranchChatPageState extends State<BranchChatPage>
    with WidgetsBindingObserver {
  // 分支管理器
  final BranchManager branchManager = BranchManager();
  // 分支存储器
  late final BranchStore store;
  // 缓存存储器
  final MyGetStorage storage = MyGetStorage();

  // 输入框控制器
  final TextEditingController inputController = TextEditingController();
  // 添加焦点控制器
  final FocusNode inputFocusNode = FocusNode();
  // 输入框高度状态(用于悬浮按钮的布局)
  // 输入框展开收起工具栏时，悬浮按钮(新加对话、滚动到底部)位置需要动态变化，始终在输入框的上方
  double inputHeight = 0;

  // 所有消息
  List<BranchChatMessage> allMessages = [];
  // 当前显示的消息
  List<BranchChatMessage> displayMessages = [];
  // 当前分支路径
  String currentBranchPath = "0";
  // 当前编辑的消息
  BranchChatMessage? currentEditingMessage;

  // 是否加载中
  bool isLoading = true;
  // 是否流式生成
  bool isStreaming = false;

  // 流式生成内容
  String streamingContent = '';
  // 流式生成推理内容(深度思考)
  String streamingReasoningContent = '';
  // 流式生成消息(追加显示的消息)
  BranchChatMessage? streamingMessage;

  // 是否新对话
  bool isNewChat = false;
  // 当前会话ID
  int? currentSessionId;
  // 重新生成消息ID
  int? regeneratingMessageId;

  // 添加模型相关状态
  List<CusBriefLLMSpec> modelList = [];
  LLModelType selectedType = LLModelType.cc;
  CusBriefLLMSpec? selectedModel;

  // 添加高级参数状态
  bool advancedEnabled = false;
  Map<String, dynamic>? advancedOptions;

  // 默认的页面主体的缩放比例(对话太小了就可以等比放大)
  // 直接全局缓存，所有使用ChatListArea的地方都改了
  double textScaleFactor = 1.0;

  // 对话列表滚动控制器
  final ScrollController scrollController = ScrollController();
  // 是否显示"滚动到底部"按钮
  bool showScrollToBottom = false;
  // 是否用户手动滚动
  bool isUserScrolling = false;
  // 最后内容高度(用于判断是否需要滚动到底部)
  double lastContentHeight = 0;

  // 添加背景图片状态
  String? backgroundImage;
  // 背景透明度,可调整
  double backgroundOpacity = 0.35;

  // 添加手动终止响应的取消回调
  VoidCallback? cancelResponse;

  // 添加会话列表状态
  List<BranchChatSession> sessionList = [];

  ///******************************************* */
  ///
  /// 在构建UI前，都是初始化和工具的方法
  ///
  ///******************************************* */

  @override
  void initState() {
    super.initState();

    // 从本地存储加载背景图片设置
    loadBackgroundSettings();

    // 初始化分支存储器
    _initStore();

    // 初始化模型列表和会话
    // (分支存储器不能重复初始化，但这个方法会重复调用，所以不放在一起)
    initialize();

    // 获取缓存中的正文文本缩放比例
    textScaleFactor = MyGetStorage().getChatListAreaScale();

    // 获取缓存的高级选项配置
    if (selectedModel != null) {
      advancedEnabled =
          MyGetStorage().getAdvancedOptionsEnabled(selectedModel!);
      if (advancedEnabled) {
        advancedOptions = MyGetStorage().getAdvancedOptions(selectedModel!);
      }
    }

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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    inputFocusNode.dispose();
    inputController.dispose();
    scrollController.dispose();
    cancelResponse?.call();

    // 清理Markdown渲染缓存，释放内存
    CusMarkdownRenderer.instance.clearCache();

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

  /// 初始化方法(初始化模型列表、最新会话)
  Future<void> initialize() async {
    try {
      // 初始化模型列表
      await initModels();

      // 初始化会话
      await _initSession();
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  initModels() async {
    // 获取可用模型列表
    final availableModels = await ModelManagerService.getAvailableModelByTypes([
      LLModelType.cc,
      LLModelType.reasoner,
      LLModelType.vision,
      LLModelType.vision_reasoner,
    ]);

    if (!mounted) return;
    setState(() {
      modelList = availableModels;
      selectedModel = availableModels.first;
      selectedType = selectedModel!.modelType;
    });
  }

  Future<void> _initStore() async {
    store = await BranchStore.create();

    // 初始化时加载会话列表
    loadSessions();
  }

  Future<void> _initSession() async {
    // 获取今天的最后一条对话记录
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    final sessions = store.sessionBox.getAll()
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
        currentSessionId = todayLastSession.id;
        selectedModel = modelList
            .where(
              (m) => m.cusLlmSpecId == todayLastSession.llmSpec.cusLlmSpecId,
            )
            .firstOrNull;
      });

      if (selectedModel == null) {
        EasyLoading.showInfo(
          '最新对话所用模型已被删除，将使用默认模型构建全新对话。',
          duration: const Duration(seconds: 5),
        );
        setState(() {
          selectedModel = modelList.first;
          selectedType = selectedModel!.modelType;
        });
        createNewChat();
      } else {
        setState(() {
          selectedType = selectedModel!.modelType;
          isNewChat = false;
          isLoading = false;
        });
        await loadMessages();
      }
    } catch (e) {
      // 如果没有任何对话记录，或者今天没有对话记录(会报错抛到这里)，显示新对话界面
      setState(() {
        isNewChat = true;
        isLoading = false;
      });
    }

    // 延迟执行滚动到底部，确保UI已完全渲染
    WidgetsBinding.instance.addPostFrameCallback((_) {
      resetContentHeight(times: 2000);
    });
  }

  /// 加载消息
  Future<void> loadMessages() async {
    if (currentSessionId == null) {
      setState(() => isNewChat = true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final messages = store.getSessionMessages(currentSessionId!);
      if (messages.isEmpty) {
        setState(() {
          isNewChat = true;
          isLoading = false;
        });
        return;
      }

      final currentMessages = branchManager.getMessagesByBranchPath(
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
            BranchChatMessage(
              id: 0,
              messageId: 'streaming',
              role: CusRole.assistant.name,
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
      pl.e('加载消息失败: $e');
      setState(() {
        isNewChat = true;
        isLoading = false;
      });
    }

    resetContentHeight();
  }

  // 加载背景设置 - 优化为异步加载并缓存结果
  Future<void> loadBackgroundSettings() async {
    // 先检查是否已有缓存的背景设置
    final cachedBackground = storage.getCachedBackground();
    final cachedOpacity = storage.getCachedBackgroundOpacity();

    if (cachedBackground != null || cachedOpacity != null) {
      // 如果有缓存，先使用缓存值快速渲染
      setState(() {
        if (cachedBackground != null) backgroundImage = cachedBackground;
        if (cachedOpacity != null) backgroundOpacity = cachedOpacity;
      });
    }

    // 然后异步加载最新设置
    final background = await storage.getBranchChatBackground();
    final opacity = await storage.getBranchChatBackgroundOpacity();

    // 只有当值不同时才更新UI
    if (background != backgroundImage || opacity != backgroundOpacity) {
      setState(() {
        backgroundImage = background;
        backgroundOpacity = opacity ?? 0.2;
      });
    }
  }

  ///******************************************* */
  ///
  /// 构建UI，从上往下放置相关内容
  ///
  ///******************************************* */
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    var mainScaffold = Scaffold(
      // 设置 Scaffold 背景色为透明，这样才能看到底层背景
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        // 设置 AppBar 背景色为半透明，保证标题文字可读
        // backgroundColor: Theme.of(context)
        //     .colorScheme
        //     .surface
        //     .withOpacity(1 - _backgroundOpacity),
        // 不管，全透明
        backgroundColor: Colors.transparent,
        title: SimpleMarqueeOrText(
          data:
              "${CP_NAME_MAP[selectedModel?.platform]} > ${selectedModel?.model}",
          velocity: 30,
          width: 0.6.sw,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        actions: [
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
          buildPopupMenuButton(),
        ],
      ),
      endDrawer: buildChatHistoryDrawer(),
      body: Stack(
        children: [
          Column(
            children: [
              /// 添加模型过滤器
              ModelFilter(
                models: modelList,
                selectedType: selectedType,
                onTypeChanged: isStreaming ? null : handleTypeChanged,
                onModelSelect: isStreaming ? null : showModelSelector,
                isStreaming: isStreaming,
                isCusChip: true,
              ),

              /// 聊天内容
              Expanded(
                child: displayMessages.isEmpty
                    ? buildEmptyHint()
                    : buildMessageList(),
              ),

              /// 流式响应时显示进度条
              if (isStreaming) buildResponseLoading(),

              /// 输入框
              ChatInputBar(
                controller: inputController,
                focusNode: inputFocusNode,
                onSend: handleSendMessage,
                onCancel: currentEditingMessage != null
                    ? handleCancelEditUserMessage
                    : null,
                isEditing: currentEditingMessage != null,
                isStreaming: isStreaming,
                onStop: handleStopStreaming,
                model: selectedModel,
                onHeightChanged: (height) {
                  setState(() => inputHeight = height);
                },
              ),
            ],
          ),

          /// 悬浮按钮(前面是显示新加对话按钮，后面显示滚动到底部按钮)
          /// 2025-03-13 不放在下面最外层的Stack，是因为如果放在那里，抽屉显示历史记录时，悬浮按钮还在其上层
          buildFloatingButton(),
        ],
      ),
    );

    return Stack(
      children: [
        // 背景图片(若不需要全屏背景，可在上方scaffold的body中覆盖背景即可)
        buildBackground(),

        // 主页面
        mainScaffold,
      ],
    );
  }

  ///******************************************* */
  ///
  /// AppBar 和 Drawer 相关的内容方法
  ///
  ///******************************************* */
  // 弹窗菜单按钮
  Widget buildPopupMenuButton() {
    return PopupMenuButton<String>(
      enabled: !isStreaming,
      icon: const Icon(Icons.more_horiz_sharp),
      // 调整弹出按钮的位置
      position: PopupMenuPosition.under,
      // 弹出按钮的偏移
      // offset: Offset(-25.sp, 0),
      onSelected: (String value) async {
        // 处理选中的菜单项
        if (value == 'add') {
          createNewChat();
        } else if (value == 'options') {
          showAdvancedOptions();
        } else if (value == 'text_size') {
          adjustTextScale(
            context,
            textScaleFactor,
            (value) async {
              setState(() => textScaleFactor = value);
              await MyGetStorage().setChatListAreaScale(value);

              if (!mounted) return;
              Navigator.of(context).pop();

              unfocusHandle();
            },
          );
        } else if (value == 'tree') {
          showBranchTree();
        } else if (value == 'background') {
          changeBackground();
        } else if (value == 'add_model') {
          handleAddModel();
        } else if (value == 'export_import') {
          navigateToExportImportPage();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
        buildCusPopupMenuItem(context, "add", "新加对话", Icons.add),
        buildCusPopupMenuItem(context, "options", "高级选项", Icons.tune),
        buildCusPopupMenuItem(context, "text_size", "文字大小", Icons.format_size),
        buildCusPopupMenuItem(context, "tree", "对话分支", Icons.account_tree),
        buildCusPopupMenuItem(context, "background", "切换背景", Icons.wallpaper),
        buildCusPopupMenuItem(
            context, "add_model", "添加模型", Icons.add_box_outlined),
        buildCusPopupMenuItem(
            context, "export_import", "对话备份", Icons.import_export),
      ],
    );
  }

  /// 显示对话分支树
  /// 2025-04-02 这个可以优化只穿当前展示会话的消息即可，而不是从所有里面取
  void showBranchTree() {
    if (allMessages.isEmpty || displayMessages.isEmpty) {
      commonHintDialog(context, "提示", "无可展示的对话消息");
      return;
    }

    showDialog(
      context: context,
      builder: (context) => BranchTreeDialog(
        messages: allMessages,
        currentPath: currentBranchPath,
        onPathSelected: (path) {
          setState(() => currentBranchPath = path);
          // 重新加载选中分支的消息
          final currentMessages = branchManager.getMessagesByBranchPath(
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

  /// 创建新对话
  void createNewChat() {
    setState(() {
      isNewChat = true;
      currentBranchPath = "0";
      isStreaming = false;
      streamingContent = '';
      streamingReasoningContent = '';
      currentEditingMessage = null;
      inputController.clear();
      displayMessages.clear();

      // 开启新对话后，没有对话列表，所以不显示滚动到底部按钮
      showScrollToBottom = false;

      // 创建新对话后，重置内容高度
      resetContentHeight();
    });
  }

  // 显示高级选项弹窗
  Future<void> showAdvancedOptions() async {
    if (selectedModel == null) return;

    final result = await AdvancedOptionsUtils.showAdvancedOptions(
      context: context,
      platform: selectedModel!.platform,
      modelType: selectedModel!.modelType,
      currentEnabled: advancedEnabled,
      currentOptions: advancedOptions ?? {},
    );

    if (result != null) {
      setState(() {
        advancedEnabled = result.enabled;
        advancedOptions = result.enabled ? result.options : null;
      });

      // 保存到缓存
      await MyGetStorage()
          .setAdvancedOptionsEnabled(selectedModel!, result.enabled);
      await MyGetStorage().setAdvancedOptions(
        selectedModel!,
        result.enabled ? result.options : null,
      );
    }
  }

  // 更换背景图片
  // Future<void> changeBackground() async {
  //   final result = await showModalBottomSheet<String>(
  //     context: context,
  //     builder: (context) => ChatBackgroundPicker(
  //       currentImage: backgroundImage,
  //       opacity: backgroundOpacity,
  //       onOpacityChanged: (value) async {
  //         setState(() => backgroundOpacity = value);
  //         await MyGetStorage().saveChatBackgroundOpacity(value);
  //       },
  //     ),
  //   );

  //   if (result != null) {
  //     setState(() => backgroundImage = result);
  //     await MyGetStorage().saveChatBackground(result);
  //   }
  // }

  void changeBackground() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatBackgroundPickerPage(
          chatType: 'branch',
          title: '切换对话背景',
        ),
      ),
    ).then((confirmed) {
      // 只有在用户点击了确定按钮时才重新加载背景设置
      if (confirmed == true) {
        loadBackgroundSettings();
      }
    });
  }

  // 添加模型按钮点击处理
  Future<void> handleAddModel() async {
    final result = await Navigator.push<CusBriefLLMSpec>(
      context,
      MaterialPageRoute(builder: (context) => const AddModelPage()),
    );

    // 1 从添加单个模型页面返回后，先重新初始化(加载之前的模型列表、会话内容等)
    await initialize();

    // 2 如果添加模型成功，则更新当前选中的模型和类型，并创建新对话
    if (result != null && mounted) {
      try {
        // 2.1 更新当前选中的模型和类型
        setState(() {
          selectedModel = modelList
              .where((m) => m.cusLlmSpecId == result.cusLlmSpecId)
              .firstOrNull;
          selectedType = result.modelType;
        });

        // 2.2. 创建新对话
        createNewChat();

        EasyLoading.showSuccess('添加模型成功');
      } catch (e) {
        if (mounted) {
          pl.e('添加模型失败: $e');
          commonExceptionDialog(context, '添加模型失败', e.toString());
        }
      }
    }
  }

  // 修改导入导出页面的跳转方法
  void navigateToExportImportPage() async {
    bool isGranted = await requestStoragePermission();

    if (!mounted) return;
    if (!isGranted) {
      commonExceptionDialog(context, "异常提示", "无存储访问授权");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatExportImportPage(
          chatType: 'branch',
        ),
      ),
    ).then((_) {
      // 返回后重新加载会话列表
      loadSessions();
    });
  }

  // 修改构建抽屉的方法
  Widget buildChatHistoryDrawer() {
    return BranchChatHistoryDrawer(
      sessions: sessionList,
      currentSessionId: currentSessionId,
      onSessionSelected: (session) async {
        await switchSession(session.id);
      },
      onRefresh: (session, action) async {
        if (action == 'edit') {
          // 更新会话
          store.sessionBox.put(session);
          loadSessions();
        } else if (action == 'delete') {
          // 删除会话
          await store.deleteSession(session);
          loadSessions();
          loadMessages();

          // 如果删除的是当前会话，创建新会话
          if (session.id == currentSessionId) {
            createNewChat();
          }
        }
      },
    );
  }

  /// 加载历史对话列表并按更新时间排序
  List<BranchChatSession> loadSessions() {
    var list = store.sessionBox.getAll()
      ..sort((a, b) => b.updateTime.compareTo(a.updateTime));

    setState(() => sessionList = list);

    return list;
  }

  /// 切换历史对话(在抽屉中点选了不同的历史记录)
  Future<void> switchSession(int sessionId) async {
    final session = store.sessionBox.get(sessionId);

    if (session == null) {
      EasyLoading.showInfo(
        '该对话记录已不存在，将使用默认模型构建全新对话。',
        duration: const Duration(seconds: 5),
      );

      selectedModel = modelList.first;
      selectedType = selectedModel!.modelType;

      createNewChat();
      return;
    }

    setState(() {
      currentSessionId = sessionId;
      isNewChat = false;
      currentBranchPath = "0";
      isStreaming = false;
      streamingContent = '';
      streamingReasoningContent = '';
      currentEditingMessage = null;
      inputController.clear();

      // 如果存在会话，但是会话使用的模型被删除了，也提示，并使用默认模型构建全新对话
      selectedModel = modelList
          .where((m) => m.cusLlmSpecId == session.llmSpec.cusLlmSpecId)
          .firstOrNull;
    });

    if (selectedModel == null) {
      EasyLoading.showInfo(
        '该历史对话所用模型已被删除，将使用默认模型构建全新对话。',
        duration: const Duration(seconds: 3),
      );
      setState(() {
        selectedModel = modelList.first;
        selectedType = selectedModel!.modelType;
      });
      createNewChat();
    } else {
      // 更新当前选中的模型和类型
      setState(() => selectedType = selectedModel!.modelType);
      await loadMessages();
    }
  }

  ///******************************************* */
  ///
  /// 模型切换和选择区域的相关方法
  ///
  ///******************************************* */
  /// 切换模型类型
  void handleTypeChanged(LLModelType type) {
    setState(() {
      selectedType = type;

      // 如果当前选中的模型不是新类型的，则清空选择
      // 因为切换类型时，一定会触发模型选择器，在模型选择的地方有重新创建对话，所以这里不用重新创建
      if (selectedModel?.modelType != type) {
        selectedModel = null;
      }
    });
  }

  /// 显示模型选择弹窗
  Future<void> showModelSelector() async {
    // 获取可用的模型列表
    final filteredModels =
        modelList.where((m) => m.modelType == selectedType).toList();

    if (filteredModels.isEmpty && mounted) {
      EasyLoading.showInfo("当前类型没有可用的模型");
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
          selectedModel: selectedModel,
          onModelChanged: (model) => Navigator.pop(context, model),
        ),
      ),
    );

    if (!mounted) return;
    if (model != null) {
      setState(() => selectedModel = model);
    } else {
      // 如果没有点击模型，则使用选定分类的第一个模型
      setState(() => selectedModel = filteredModels.first);
    }

    // 选择指定模型后，加载对应类型上次缓存的高级选项配置
    advancedEnabled = MyGetStorage().getAdvancedOptionsEnabled(selectedModel!);
    advancedOptions = advancedEnabled
        ? MyGetStorage().getAdvancedOptions(selectedModel!)
        : null;

    // 2025-03-03 切换模型后也直接重建对话好了？？？此时就不用重置内容高度了
    createNewChat();
  }

  ///******************************************* */
  ///
  /// 消息列表和消息相关的方法
  ///
  ///******************************************* */
  Widget buildMessageList() {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScaleFactor),
      ),
      child: ListView.builder(
        // 启用列表缓存
        cacheExtent: 1000.0, // 增加缓存范围
        addAutomaticKeepAlives: true,
        // 让ListView自动管理RepaintBoundary
        addRepaintBoundaries: true,
        // 使用itemCount限制构建数量
        itemCount: displayMessages.length,
        controller: scrollController,
        // 列表底部留一点高度，避免工具按钮和悬浮按钮重叠
        padding: EdgeInsets.only(bottom: 50.sp),
        itemBuilder: (context, index) {
          final message = displayMessages[index];

          // 如果当前消息是流式消息，说明正在追加显示中，则不显示分支相关内容
          final isStreamingMessage = message.messageId == 'streaming';
          final hasMultipleBranches = !isStreamingMessage &&
              branchManager.getBranchCount(allMessages, message) > 1;

          // 使用RepaintBoundary包装每个列表项
          return Column(
            children: [
              // 渲染消息体比较复杂，使用RepaintBoundary包装
              RepaintBoundary(
                child: BranchMessageItem(
                  key: ValueKey(message.messageId),
                  message: message,
                  onLongPress: isStreaming ? null : showMessageOptions,
                  isUseBgImage:
                      backgroundImage != null && backgroundImage!.isNotEmpty,
                ),
              ),
              // 为分支操作添加条件渲染，避免不必要的构建
              if (!isStreamingMessage || hasMultipleBranches)
                // 操作组件渲染不复杂，不使用RepaintBoundary包装
                BranchMessageActions(
                  key: ValueKey('actions_${message.messageId}'),
                  message: message,
                  messages: allMessages,
                  onRegenerate: () => handleResponseRegenerate(message),
                  hasMultipleBranches: hasMultipleBranches,
                  isRegenerating: isStreaming,
                  currentBranchIndex: isStreamingMessage
                      ? 0
                      : branchManager.getBranchIndex(
                          allMessages,
                          message,
                        ),
                  totalBranches: isStreamingMessage
                      ? 1
                      : branchManager.getBranchCount(
                          allMessages,
                          message,
                        ),
                  onSwitchBranch: handleSwitchBranch,
                ),
            ],
          );
        },
      ),
    );
  }

  /// 构建流式生成时的加载指示器
  Widget buildResponseLoading() {
    return Padding(
      padding: EdgeInsets.symmetric(
        /// 调整位置之后，还是滚动条贯穿屏幕，悬浮按钮放在滚动条上方，和谐一点
        horizontal: 8.sp,
      ),
      child: Row(
        children: [
          Expanded(
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.sp),
            child: SizedBox(
              width: 16.sp,
              height: 16.sp,
              child: CircularProgressIndicator(strokeWidth: 3.sp),
            ),
          ),
          Expanded(
            child: ClipRRect(
              // 设置圆角
              borderRadius: BorderRadius.all(Radius.circular(5.sp)),
              child: SizedBox(
                height: 5.sp, // 设置高度
                child: LinearProgressIndicator(
                  value: null, // 当前进度(null就循环)
                  backgroundColor: Colors.blue, // 背景颜色
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.grey, // 进度条颜色
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 长按消息，显示消息选项
  void showMessageOptions(
    BranchChatMessage message,
    LongPressStartDetails details,
  ) {
    // 添加振动反馈
    HapticFeedback.mediumImpact();

    // 只有用户消息可以编辑
    final bool isUser = message.role == CusRole.user.name;
    // 只有AI消息可以重新生成
    final bool isAssistant = message.role == CusRole.assistant.name;

    // 获取点击位置
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
          child: buildMenuItemWithIcon(
            icon: Icons.copy,
            text: '复制文本',
          ),
        ),
        // 选择文本按钮
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
        PopupMenuItem<String>(
          value: 'delete',
          child: buildMenuItemWithIcon(
            icon: Icons.delete,
            text: '删除分支',
            color: Colors.red,
          ),
        ),
      ],
    ).then((value) async {
      if (value == 'copy') {
        Clipboard.setData(ClipboardData(text: message.content));
        EasyLoading.showToast('已复制到剪贴板');
      } else if (value == 'select') {
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (context) => TextSelectionDialog(
              text: message.reasoningContent != null &&
                      message.reasoningContent!.isNotEmpty
                  ? '【推理过程】\n${message.reasoningContent!}\n\n【AI响应】\n${message.content}'
                  : message.content),
        );
      } else if (value == 'edit') {
        handleUserMessageEdit(message);
      } else if (value == 'resend') {
        handleUserMessageResend(message);
      } else if (value == 'regenerate') {
        handleResponseRegenerate(message);
      } else if (value == 'delete') {
        await handleDeleteBranch(message);
      }
    });
  }

  /// 编辑用户消息
  void handleUserMessageEdit(BranchChatMessage message) {
    setState(() {
      currentEditingMessage = message;
      inputController.text = message.content;
      // 显示键盘
      inputFocusNode.requestFocus();
    });
  }

  // 重新发送用户消息
  void handleUserMessageResend(BranchChatMessage message) {
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

  /// 重新生成AI响应内容
  Future<void> handleResponseRegenerate(BranchChatMessage message) async {
    if (isStreaming) return;

    setState(() {
      regeneratingMessageId = message.id;
      isStreaming = true;
    });

    try {
      final currentMessages = branchManager.getMessagesByBranchPath(
        allMessages,
        message.branchPath,
      );

      final messageIndex = currentMessages.indexOf(message);
      if (messageIndex == -1) return;

      final contextMessages = currentMessages.sublist(0, messageIndex);

      // 判断当前所处的分支路径是否是在修改用户消息后新创建的分支
      // 核心判断逻辑：当前分支路径与要重新生成的消息分支路径的关系
      bool isAfterUserEdit = false;

      // 获取当前分支路径的所有部分
      final List<String> currentPathParts = currentBranchPath.split('/');
      final List<String> messagePathParts = message.branchPath.split('/');

      // 情况1: 当前分支路径比消息路径长，且前缀相同，说明已经在新分支上
      if (currentPathParts.length > messagePathParts.length) {
        bool isPrefixSame = true;
        for (int i = 0; i < messagePathParts.length; i++) {
          if (messagePathParts[i] != currentPathParts[i]) {
            isPrefixSame = false;
            break;
          }
        }

        if (isPrefixSame) {
          // 检查是否是由于用户编辑创建的新分支
          final userMessages = allMessages
              .where((m) =>
                  m.role == CusRole.user.name &&
                  m.branchPath == currentBranchPath)
              .toList();

          isAfterUserEdit = userMessages.isNotEmpty;
        }
      }

      // 情况2: 分支路径不同，但共享相同父路径，检查是否已经切换到不同分支
      else if (!currentBranchPath.startsWith(message.branchPath) &&
          !message.branchPath.startsWith(currentBranchPath)) {
        // 找到最近的共同父路径
        int commonPrefixLength = 0;
        for (int i = 0;
            i < min(currentPathParts.length, messagePathParts.length);
            i++) {
          if (currentPathParts[i] == messagePathParts[i]) {
            commonPrefixLength++;
          } else {
            break;
          }
        }

        if (commonPrefixLength > 0) {
          // 如果有共同父路径，判断当前路径是否包含用户消息
          final userMessagesOnCurrentPath = allMessages
              .where((m) =>
                  m.role == CusRole.user.name &&
                  m.branchPath == currentBranchPath)
              .toList();

          isAfterUserEdit = userMessagesOnCurrentPath.isNotEmpty;
        }
      }

      // 获取重新生成位置的同级分支
      final siblings = branchManager.getSiblingBranches(allMessages, message);
      final availableSiblings = siblings
          .where((m) => allMessages.contains(m))
          .toList()
        ..sort((a, b) => a.branchIndex.compareTo(b.branchIndex));

      // 计算新的分支索引
      int newBranchIndex;
      if (isAfterUserEdit) {
        // 如果是在用户编辑后新创建的分支上，AI响应索引应该从0开始
        newBranchIndex = 0;
      } else {
        // 常规情况下，使用当前同级分支的最大索引+1
        newBranchIndex = availableSiblings.isEmpty
            ? 0
            : availableSiblings.last.branchIndex + 1;
      }

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

  /// 添加一个通用的AI响应生成方法(重新生成、正常发送消息都用这个)
  Future<BranchChatMessage?> _generateAIResponseCommon({
    required List<BranchChatMessage> contextMessages,
    required String newBranchPath,
    required int newBranchIndex,
    required int depth,
    BranchChatMessage? parentMessage,
  }) async {
    // 初始化状态
    setState(() {
      isStreaming = true;
      streamingContent = '';
      streamingReasoningContent = '';
      // 创建临时的流式消息
      displayMessages = [
        ...contextMessages,
        BranchChatMessage(
          id: 0,
          messageId: 'streaming',
          role: CusRole.assistant.name,
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
    BranchChatMessage? aiMessage;
    // 2025-03-24 联网搜索参考内容
    List<Map<String, dynamic>>? references = [];

    try {
      final (stream, cancelFunc) = await ChatService.sendBranchMessage(
        selectedModel!,
        contextMessages,
        advancedOptions: advancedEnabled ? advancedOptions : null,
        stream: true,
      );

      cancelResponse = cancelFunc;

      // 处理流式响应的内容(包括正常完成、手动终止和错误响应)
      await for (final chunk in stream) {
        // 更新流式内容和状态
        setState(() {
          // 2025-03-24 联网搜索参考内容
          if (chunk.searchResults != null) {
            references.addAll(chunk.searchResults!);
          }

          // 1. 更新内容
          streamingContent += chunk.cusText;
          streamingReasoningContent += chunk.choices.isNotEmpty
              ? (chunk.choices.first.delta?["reasoning_content"] ?? '')
              : '';
          finalContent += chunk.cusText;
          finalReasoningContent += chunk.choices.isNotEmpty
              ? (chunk.choices.first.delta?["reasoning_content"] ?? '')
              : '';

          // 计算思考时间(从发起调用开始，到当流式内容不为空时计算结束)
          if (endTime == null && streamingContent.isNotEmpty) {
            endTime = DateTime.now();
            thinkingDuration = endTime!.difference(startTime).inMilliseconds;
          }

          // 2. 更新显示消息列表
          displayMessages = [
            ...contextMessages,
            BranchChatMessage(
              id: 0,
              messageId: 'streaming',
              role: CusRole.assistant.name,
              content: streamingContent,
              reasoningContent: streamingReasoningContent,
              thinkingDuration: thinkingDuration,
              references: references,
              createTime: DateTime.now(),
              branchPath: newBranchPath,
              branchIndex: newBranchIndex,
              depth: depth,
            ),
          ];
        });

        // 如果手动停止了流式生成，提前退出循环
        if (!isStreaming) break;

        // 自动滚动逻辑
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final currentHeight = scrollController.position.maxScrollExtent;
          if (!isUserScrolling && currentHeight - lastContentHeight > 20) {
            // 高度增加超过 20 像素
            scrollController.jumpTo(currentHeight);
            lastContentHeight = currentHeight;
          }
        });
      }

      // 如果有内容则创建消息(包括正常完成、手动终止和错误响应[错误响应也是一个正常流消息])
      if (finalContent.isNotEmpty || finalReasoningContent.isNotEmpty) {
        aiMessage = await store.addMessage(
          session: store.sessionBox.get(currentSessionId!)!,
          content: finalContent,
          role: CusRole.assistant.name,
          parent: parentMessage,
          reasoningContent: finalReasoningContent,
          thinkingDuration: thinkingDuration,
          references: references,
          modelLabel: parentMessage?.modelLabel ?? selectedModel!.name,
          branchIndex: newBranchIndex,
          // 目前流式响应没有媒体资源，如果有的话，需要在这里添加
        );

        // 更新当前分支路径(其他重置在 finally 块中)
        setState(() => currentBranchPath = aiMessage!.branchPath);
      }

      return aiMessage;
    } catch (e) {
      if (!mounted) return null;
      commonExceptionDialog(context, "异常提示", "AI响应生成失败: $e");

      // 创建错误消息（？？？这个添加消息应该不需要吧）
      final errorContent = """生成失败:\n\n错误信息: $e""";

      aiMessage = await store.addMessage(
        session: store.sessionBox.get(currentSessionId!)!,
        content: errorContent,
        role: CusRole.assistant.name,
        parent: parentMessage,
        thinkingDuration: thinkingDuration,
        modelLabel: parentMessage?.modelLabel ?? selectedModel!.name,
        branchIndex: newBranchIndex,
      );

      return aiMessage;
    } finally {
      if (mounted) {
        setState(() {
          isStreaming = false;
          streamingContent = '';
          streamingReasoningContent = '';
          cancelResponse = null;
        });
        // 在 finally 块中重新加载消息，确保无论是正常完成还是手动终止都会重新加载消息
        await loadMessages();
      }
    }
  }

  /// 删除当前对话消息分支
  Future<void> handleDeleteBranch(BranchChatMessage message) async {
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
      final siblings = branchManager.getSiblingBranches(allMessages, message);
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
      await store.deleteMessageWithBranches(message);

      // 更新当前分支路径并重新加载消息
      setState(() {
        currentBranchPath = newPath;
      });
      await loadMessages();
    }
  }

  /// 切换消息分支
  void handleSwitchBranch(BranchChatMessage message, int newBranchIndex) {
    final availableBranchIndex = branchManager.getNextAvailableBranchIndex(
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
    final currentMessages = branchManager.getMessagesByBranchPath(
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
          BranchChatMessage(
            id: 0,
            messageId: 'streaming',
            role: CusRole.assistant.name,
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

    resetContentHeight();
  }

  ///******************************************* */
  ///
  /// 输入区域的相关方法
  ///
  ///******************************************* */
  // 修改发送消息处理方法
  Future<void> handleSendMessage(MessageData messageData) async {
    if (messageData.text.isEmpty &&
        messageData.images == null &&
        messageData.audio == null &&
        messageData.file == null) {
      return;
    }

    if (!mounted) return;
    if (selectedModel == null) {
      commonExceptionDialog(context, "异常提示", "请先选择一个模型");
      return;
    }

    var content = messageData.text;

    // 2025-03-22 暂时不支持文档处理，也没有将解析后的文档内容作为参数传递
    // 后续有单独上传文档的需求再更新
    if (messageData.file != null) {
      commonExceptionDialog(context, "异常提示", "暂不支持上传文档，后续有需求再更新");
      return;
    }

    // 处理JSON格式响应
    if (advancedEnabled &&
        advancedOptions?["response_format"] == "json_object") {
      content = "$content(请严格按照json格式输出)";
    }

    try {
      if (isNewChat) {
        final title = content.length > 20 ? content.substring(0, 20) : content;

        final session = await store.createSession(
          title,
          llmSpec: selectedModel!,
          modelType: selectedType,
        );
        setState(() {
          currentSessionId = session.id;
          isNewChat = false;
        });
      }

      // 如果是编译用户输入过的消息，会和直接发送消息有一些区别
      if (currentEditingMessage != null) {
        await _processingUserMessage(currentEditingMessage!, messageData);
      } else {
        await store.addMessage(
          session: store.sessionBox.get(currentSessionId!)!,
          content: content,
          role: CusRole.user.name,
          parent: displayMessages.isEmpty ? null : displayMessages.last,
          // ???添加媒体文件的存储(有更多类型时就继续处理)
          contentVoicePath: messageData.audio?.path,
          imagesUrl: messageData.images?.isNotEmpty == true
              ? messageData.images?.map((i) => i.path).toList().join(',')
              : null,
          videosUrl: messageData.videos?.isNotEmpty == true
              ? messageData.videos?.map((i) => i.path).toList().join(',')
              : null,
        );
      }

      // 不管是重新编辑还是直接发送，都有这些步骤
      inputController.clear();
      await loadMessages();
      await _generateAIResponse();
      loadSessions();
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, "异常提示", "发送消息失败: $e");
    }
  }

  // 处理重新编辑的用户消息(在发送消息调用API前，还需要创建分支等其他操作)
  Future<void> _processingUserMessage(
      BranchChatMessage message, MessageData messageData) async {
    final content = messageData.text.trim();
    if (content.isEmpty) return;

    try {
      // 获取当前分支的所有消息
      final currentMessages = branchManager.getMessagesByBranchPath(
        allMessages,
        currentBranchPath,
      );

      // 找到要编辑的消息在当前分支中的位置
      final messageIndex = currentMessages.indexOf(message);
      if (messageIndex == -1) {
        debugPrint("警告：找不到要编辑的消息在当前分支中的位置");
        return;
      }

      // 获取同级分支
      final siblings = branchManager.getSiblingBranches(allMessages, message);

      // 创建新分支索引
      final newBranchIndex =
          siblings.isEmpty ? 0 : siblings.last.branchIndex + 1;

      // 构建新的分支路径
      String newPath;
      if (message.parent.target == null) {
        // 根消息
        newPath = newBranchIndex.toString();
      } else {
        // 子消息
        final parentPath = message.branchPath.substring(
          0,
          message.branchPath.lastIndexOf('/'),
        );
        newPath = '$parentPath/$newBranchIndex';
      }

      // 创建新的用户消息
      await store.addMessage(
        session: store.sessionBox.get(currentSessionId!)!,
        content: content,
        role: CusRole.user.name,
        parent: message.parent.target,
        branchIndex: newBranchIndex,
        // ???添加媒体文件的存储(有更多类型时就继续处理)
        contentVoicePath: message.contentVoicePath,
        imagesUrl: message.imagesUrl,
        videosUrl: message.videosUrl,
      );

      // 更新当前分支路径并将正在编辑的消息设置为null
      setState(() {
        currentBranchPath = newPath;
        currentEditingMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, "异常提示", "编辑消息失败: $e");
    }
  }

  // 修改 _generateAIResponse 方法
  Future<void> _generateAIResponse() async {
    final currentMessages = branchManager.getMessagesByBranchPath(
      allMessages,
      currentBranchPath,
    );

    if (currentMessages.isEmpty) {
      pl.e('当前分支路径没有消息: $currentBranchPath');
      return;
    }

    // 获取最后一条消息
    final lastMessage = currentMessages.last;

    // 判断分支状态：三种主要情况
    // 1. 全新对话中的第一个用户消息
    // 2. 常规对话中继续发消息
    // 3. 修改用户消息后创建的新分支

    bool isFirstMessage = currentMessages.length == 1;
    bool isUserEditedBranch = false;

    // 如果是用户消息，检查是否是由于编辑创建的新分支
    if (lastMessage.role == CusRole.user.name) {
      // 获取同级的其他用户消息分支
      final siblings =
          branchManager.getSiblingBranches(allMessages, lastMessage);

      // 如果有多个同级用户消息，说明是编辑后创建的分支
      isUserEditedBranch = siblings.length > 1 || lastMessage.branchIndex > 0;
    }

    // 确定AI响应的分支索引
    int branchIndex;

    if (lastMessage.role == CusRole.user.name &&
        (isFirstMessage || isUserEditedBranch)) {
      // 如果是首条用户消息或编辑用户消息后创建的分支，AI响应索引应为0
      branchIndex = 0;
    } else {
      // 在常规对话中，使用最后一条消息的索引
      branchIndex = lastMessage.branchIndex;
    }

    await _generateAIResponseCommon(
      contextMessages: currentMessages,
      newBranchPath: currentBranchPath,
      newBranchIndex: branchIndex,
      depth: lastMessage.depth,
      parentMessage: lastMessage,
    );
  }

  // 取消编辑已发送的用户消息
  void handleCancelEditUserMessage() {
    setState(() {
      currentEditingMessage = null;
      inputController.clear();
      // 收起键盘
      inputFocusNode.unfocus();
    });
  }

  /// 停止流式生成(用户主动停止)
  void handleStopStreaming() {
    setState(() => isStreaming = false);
    cancelResponse?.call();
    cancelResponse = null;
  }

  ///******************************************* */
  ///
  /// 消息列表底部的新加对话和滚动到底部的悬浮按钮
  ///
  ///******************************************* */
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
            if (displayMessages.isNotEmpty && !isStreaming)
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
                    onPressed: createNewChat,
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
  }

  ///******************************************* */
  ///
  /// 其他相关方法
  ///
  ///******************************************* */
  // 重置对话列表内容高度(在点击了重新生成、切换了模型、点击了指定历史记录后都应该调用)
  void resetContentHeight({int? times}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;

      lastContentHeight = scrollController.position.maxScrollExtent;
    });

    // 重置完了顺便滚动到底部
    _scrollToBottom(times: times);
  }

  // 滚动到底部
  // void _scrollToBottom({int? times}) {
  //   // 统一在这里等待布局更新完成，才滚动到底部
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     if (!mounted || !scrollController.hasClients) return;

  //     // 延迟50ms，避免内容高度还没更新
  //     Future.delayed(const Duration(milliseconds: 50), () {
  //       scrollController.animateTo(
  //         scrollController.position.maxScrollExtent,
  //         duration: Duration(milliseconds: times ?? 500),
  //         curve: Curves.easeOut,
  //       );
  //     });

  //     setState(() {
  //       isUserScrolling = false;
  //     });
  //   });
  // }

  Future<void> _scrollToBottom({int? times}) async {
    if (!mounted) return;

    await Future.delayed(Duration.zero);
    if (!mounted || !scrollController.hasClients) return;

    final position = scrollController.position;
    if (!position.hasContentDimensions ||
        position.maxScrollExtent <= position.minScrollExtent) {
      return;
    }

    await scrollController.animateTo(
      position.maxScrollExtent,
      duration: Duration(milliseconds: times ?? 500),
      curve: Curves.easeOut,
    );

    if (mounted) setState(() => isUserScrolling = false);
  }
}
