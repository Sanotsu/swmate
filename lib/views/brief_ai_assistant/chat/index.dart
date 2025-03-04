import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/constants/constants.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../common/llm_spec/constant_llm_enum.dart';
import '../../../common/utils/db_tools/db_brief_ai_tool_helper.dart';
import '../../../models/brief_ai_tools/chat_completions/chat_completion_response.dart';
import '../../../models/brief_ai_tools/chat_competion/com_cc_state.dart';
import '../../../services/cus_get_storage.dart';
import 'components/chat_input.dart';
import 'components/chat_message_item.dart';
import 'components/model_filter.dart';
import 'components/model_selector.dart';
import '../../../services/chat_service.dart';
import 'components/chat_history_drawer.dart';
import 'components/message_actions.dart';
import '../../../services/model_manager_service.dart';

class BriefChatScreen extends StatefulWidget {
  const BriefChatScreen({super.key});

  @override
  State<BriefChatScreen> createState() => _BriefChatScreenState();
}

class _BriefChatScreenState extends State<BriefChatScreen>
    with WidgetsBindingObserver {
  // 数据库帮助类
  final DBBriefAIToolHelper _dbHelper = DBBriefAIToolHelper();

  // 可用的模型列表
  List<CusBriefLLMSpec> _modelList = [];
  // 当前选中的模型类型
  LLModelType _selectedType = LLModelType.cc;
  // 当前选中的模型
  CusBriefLLMSpec? _selectedModel;

  // 消息列表
  List<ChatMessage> _messages = [];
  // 是否正在流式响应中
  bool _isStreaming = false;
  // 当前对话
  BriefChatHistory? _currentChat;
  // 取消响应
  VoidCallback? _cancelResponse;
  // 重新生成索引
  int? _regeneratingIndex;

  // 对话列表滚动控制器
  final ScrollController _scrollController = ScrollController();
  // 是否显示"滚动到底部"按钮
  bool _showScrollToBottom = false;
  // 是否用户手动滚动
  bool _isUserScrolling = false;
  // 最后内容高度(用于判断是否需要滚动到底部)
  double _lastContentHeight = 0;

  // 添加加载状态标记
  bool _isLoading = true;

  // 默认的页面主体的缩放比例(对话太小了就可以等比放大)
  // 直接全局缓存，所有使用ChatListArea的地方都改了
  double _textScaleFactor = 1.0;

  // 输入框高度状态(用于悬浮按钮的布局)
  // 输入框展开收起工具栏时，悬浮按钮(新加对话、滚动到底部)位置需要动态变化，始终在输入框的上方
  double _inputHeight = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();

    // 获取缓存中的正文文本缩放比例
    _textScaleFactor = MyGetStorage().getChatListAreaScale();

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

// 布局发生变化时（如键盘弹出/收起）
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    // 流式响应还未完成且不是用户手动滚动，滚动到底部
    if (_isStreaming && !_isUserScrolling) {
      _resetContentHeight();
    }
  }

  // 统一初始化方法
  Future<void> _initialize() async {
    try {
      // 1. 获取可用模型列表
      final availableModels =
          await ModelManagerService.getAvailableModelByTypes([
        LLModelType.cc,
        LLModelType.vision,
      ]);

      if (!mounted) return;
      setState(() => _modelList = availableModels);

      // 2. 初始化对话
      await _initializeChat();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 初始化对话
  Future<void> _initializeChat() async {
    final histories = await getHistoryChats();

    if (!mounted) return;
    if (histories.isNotEmpty) {
      final lastChat = histories.first;

      // 检查最后一次对话是否是今天
      final isToday = lastChat.gmtModified.day == DateTime.now().day &&
          lastChat.gmtModified.month == DateTime.now().month &&
          lastChat.gmtModified.year == DateTime.now().year;

      if (isToday) {
        // 如果是今天的对话，加载上次对话
        setState(() {
          _messages = lastChat.messages;
          _currentChat = lastChat;
          // 根据历史记录设置模型
          _selectedModel = _modelList
              .where((m) => m.cusLlmSpecId == lastChat.llmSpec.cusLlmSpecId)
              .firstOrNull;

          // 2025-03-03 如果是今天的对话，但是模型没有找到(比如刚对话完，就删除了模型)
          // 则使用默认模型，并重置对话
          if (_selectedModel == null) {
            _selectedModel = _modelList.first;
            _createNewChat();
          }

          _selectedType = _selectedModel!.modelType;
        });
      } else {
        // 如果不是今天的对话，创建新对话
        _createNewChat();
        setState(() {
          _selectedModel = _modelList.first;
          _selectedType = _selectedModel!.modelType;
        });
      }
    } else {
      // 没有历史记录时，创建新对话
      _createNewChat();
      setState(() {
        _selectedModel = _modelList.first;
        _selectedType = _selectedModel!.modelType;
      });
    }

    // 重置内容高度
    _resetContentHeight();
  }

  // 创建新对话（不用修改当前选中的平台和模型）
  void _createNewChat() {
    setState(() {
      _messages = [];
      _currentChat = null;

      // 创建新对话后，重置内容高度
      _resetContentHeight();
    });
  }

  // 切换模型
  void _handleTypeChanged(LLModelType type) {
    _createNewChat();

    setState(() {
      _selectedType = type;
      // 如果当前选中的模型不是新类型的，则清空选择
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

    // 2025-03-03 切换模型后也直接重建对话好了？？？此时就不用重置内容高度了
    _createNewChat();

    // 切换模型后，滚动到底部
    // _resetContentHeight();
  }

  // 选择历史记录
  Future<void> _handleHistorySelect(BriefChatHistory history) async {
    setState(() {
      _messages = history.messages;
      _currentChat = history;
      // 恢复使用的模型
      _selectedModel = _modelList
          .where((m) => m.cusLlmSpecId == history.llmSpec.cusLlmSpecId)
          .firstOrNull;

      // 2025-03-03 如果点击历史记录，但是模型没有找到(比如刚对话完，就删除了模型)
      // 则使用默认模型，并重置对话
      if (_selectedModel == null) {
        EasyLoading.showInfo(
          '该历史对话所用模型已被删除，将使用默认模型构建全新对话。',
          duration: const Duration(seconds: 5),
        );
        _selectedModel = _modelList.first;
        _createNewChat();
      }
      _selectedType = _selectedModel!.modelType;

      // 重置内容高度
      _resetContentHeight();
    });
  }

  // 保存或更新对话历史
  Future<void> _saveChatHistory() async {
    // 确保所有消息都包含完整信息
    final updatedMessages = _messages
        .map((m) => ChatMessage(
              messageId: m.messageId,
              dateTime: m.dateTime,
              role: m.role,
              content: m.content,
              thinkingDuration: m.thinkingDuration,
              reasoningContent: m.reasoningContent,
              imageUrl: m.imageUrl,
              contentVoicePath: m.contentVoicePath,
              modelLabel: m.modelLabel ?? _selectedModel!.name,
            ))
        .toList();

    if (_currentChat == null) {
      // 新对话，创建新记录
      var title = _messages.last.content;
      _currentChat = BriefChatHistory(
        uuid: DateTime.now().toString(),
        title: title.substring(0, title.length > 20 ? 20 : title.length),
        messages: updatedMessages, // 使用更新后的消息列表
        gmtCreate: DateTime.now(),
        gmtModified: DateTime.now(),
        modelType: _selectedModel!.modelType,
        llmSpec: _selectedModel!,
      );
      await _dbHelper.insertBriefChatHistoryList([_currentChat!]);
    } else {
      // 更新现有对话
      _currentChat!.messages = updatedMessages; // 使用更新后的消息列表
      _currentChat!.gmtModified = DateTime.now();
      await _dbHelper.updateBriefChatHistory(_currentChat!);
    }
  }

  // 处理流式响应
  Future<void> _handleStreamResponse(
    Stream<ChatCompletionResponse> stream,
  ) async {
    var startTime = DateTime.now();
    DateTime? endTime;

    try {
      stream.listen(
        (ccr) {
          // 不使用choices，使用cusText，统一处理
          final content = ccr.cusText;

          // 对于DeepSeekR系列的，还有推理过程，此时对应栏位是 reasoning_content
          String reasoningContent = ccr.choices.isNotEmpty
              ? (ccr.choices.first.delta?["reasoning_content"] ?? '')
              : '';

          // 检查是否是结束标记(正常结束应该没有DONE，手动终止应该有标识)
          if (content.contains('[手动终止]') ||
              content.toLowerCase().contains('[done]')) {
            if (!mounted) return;
            setState(() {
              _isStreaming = false;
              _cancelResponse = null;
            });
          }

          if (!mounted) return;
          setState(() {
            // 如果是深度思考模式，一开始content是没有内容的，内容在reasoning_content中
            // 直到思考完了，content才会有内容。那么从响应开始，到content开始有内容，就是整个思考时间
            // 只记录一次，结束时间不为空则已经不是深度思考的响应了
            if (endTime == null && content.trim().isNotEmpty) {
              endTime = DateTime.now();
              var duration = endTime!.difference(startTime);
              _messages.last.thinkingDuration = duration.inSeconds;
            }

            if (_messages.last.role == CusRole.assistant.name) {
              // 更新现有消息(出错也是正常流，但额外手动的cusText)
              _messages.last.content += content;
              _messages.last.reasoningContent =
                  (_messages.last.reasoningContent ?? "") + reasoningContent;
              _messages.last.promptTokens = ccr.usage?.promptTokens;
              _messages.last.completionTokens = ccr.usage?.completionTokens;
              _messages.last.totalTokens = ccr.usage?.totalTokens;
            } else {
              // 创建新的助手消息
              _messages.add(ChatMessage(
                messageId: ccr.id,
                dateTime: DateTime.now(),
                role: CusRole.assistant.name,
                content: content,
                reasoningContent: reasoningContent,
                modelLabel: _selectedModel?.name,
              ));
            }
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
        onDone: () {
          // 这里只有流式响应，流式响应正常结束直接就关闭了，没有任何返回内容
          // 流式响应结束,手动终止也会触发
          _saveChatHistory();

          if (!mounted) return;
          setState(() {
            _cancelResponse = null;
            _isStreaming = false;
          });
        },
        onError: (error) {
          // 报错时会返回错误信息，直接弹窗显示
          if (!mounted) return;
          commonExceptionDialog(context, "异常提示", error.toString());
        },
      );
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, "处理流式响应出错", e.toString());
    }
  }

  // 发送消息
  Future<void> _handleSendMessage(
    String text, {
    File? image,
    File? voice,
  }) async {
    if (!mounted) return;
    if (_selectedModel == null) {
      commonExceptionDialog(context, "异常提示", "请先选择一个模型");
      return;
    }

    // 添加用户消息
    setState(() {
      _messages.add(ChatMessage(
        messageId: DateTime.now().toString(),
        dateTime: DateTime.now(),
        role: CusRole.user.name,
        content: text,
        imageUrl: image?.path,
        contentVoicePath: voice?.path,
      ));

      // 在每次添加了对话之后，都把整个对话列表存入对话历史中去
      _saveChatHistory();
    });

    try {
      setState(() => _isStreaming = true);

      // 重置完了顺便滚动到底部
      _resetContentHeight();

      final (stream, cancelFunc) = await ChatService.sendMessage(
        _selectedModel!,
        _messages,
        image: image,
        voice: voice,
      );
      _cancelResponse = cancelFunc;
      if (!mounted) return;
      await _handleStreamResponse(stream);
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, "异常提示", "发送消息失败: $e");
    }
  }

  // 重新生成
  Future<void> _handleRegenerate(ChatMessage message) async {
    if (_isStreaming) return;

    final index = _messages.indexOf(message);
    if (index == -1) return;

    // 移除当前消息及其之后的所有消息
    setState(() {
      _messages.removeRange(index, _messages.length);
      // 记录重新生成消息的索引，如果某个大模型响应的消息索引是记录的重新生成消息的索引，
      // 则表示正在重新生成中，图标显示加载中
      _regeneratingIndex = index;
      _isStreaming = true;
    });

    // 重置内容高度
    _resetContentHeight();

    try {
      final (stream, cancelFunc) = await ChatService.sendMessage(
        _selectedModel!,
        _messages,
      );
      _cancelResponse = cancelFunc;
      if (!mounted) return;
      await _handleStreamResponse(stream);
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, "异常提示", "重新生成失败: $e");
    } finally {
      if (mounted) {
        setState(() {
          _regeneratingIndex = null;
        });
      }
    }
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

  // 调整对话列表中显示的文本大小
  void _adjustTextScale() async {
    var tempScaleFactor = _textScaleFactor;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '调整对话列表中文字大小',
            style: TextStyle(fontSize: 18.sp),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: tempScaleFactor,
                    min: 0.6,
                    max: 2.0,
                    divisions: 14,
                    label: tempScaleFactor.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        tempScaleFactor = value;
                      });
                    },
                  ),
                  Text(
                    '当前文字比例: ${tempScaleFactor.toStringAsFixed(1)}',
                    textScaler: TextScaler.linear(tempScaleFactor),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('确定'),
              onPressed: () async {
                // 点击确定时，才把缩放比例存入缓存，并更新当前比例值
                setState(() {
                  _textScaleFactor = tempScaleFactor;
                });
                await MyGetStorage().setChatListAreaScale(
                  _textScaleFactor,
                );
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 获取指定分类的历史对话
  Future<List<BriefChatHistory>> getHistoryChats() async {
    return await _dbHelper.queryBriefChatHistoryList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_modelList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('智能对话')),
        body: const Center(child: Text('暂无可用的模型')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              "${CP_NAME_MAP[_selectedModel?.platform]} > ${_selectedModel?.model}",
              style: TextStyle(fontSize: 14.sp, color: Colors.blue),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.add),
          //   onPressed: _isStreaming ? null : _createNewChat,
          // ),
          IconButton(
            icon: const Icon(Icons.format_size_outlined),
            onPressed: _isStreaming ? null : _adjustTextScale,
          ),
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.history),
                onPressed: _isStreaming
                    ? null
                    : () => Scaffold.of(context).openEndDrawer(),
              );
            },
          ),
        ],
      ),
      endDrawer: FutureBuilder<List<BriefChatHistory>>(
        future: getHistoryChats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Drawer(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return ChatHistoryDrawer(
            histories: snapshot.data!,
            currentChat: _currentChat,
            onHistorySelect: _handleHistorySelect,
            onRefresh: () async {
              // 重新加载聊天历史
              await getHistoryChats();
              if (!mounted) return;
              setState(() {});
            },
          );
        },
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 5.sp),

              /// 模型选择器
              ModelFilter(
                models: _modelList,
                selectedType: _selectedType,
                onTypeChanged: _isStreaming ? null : _handleTypeChanged,
                onModelSelect: _isStreaming ? null : _showModelSelector,
                isStreaming: _isStreaming,
                supportedTypes: [LLModelType.cc, LLModelType.vision],
              ),
              Divider(height: 10.sp),

              /// 消息列表
              Expanded(
                child:
                    _messages.isEmpty ? _buildEmptyHint() : _buildMessageList(),
              ),

              /// 流式响应时显示进度条
              if (_isStreaming)
                Padding(
                  padding: EdgeInsets.symmetric(
                    // 这里需要减去悬浮按钮的宽度，避免遮挡滚动到底部悬浮按钮；再留点间隔避免和按钮紧挨着
                    // horizontal: 48.sp + 8.sp,
                    // vertical: 5.sp,
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

                  // child: SizedBox(
                  //   height: 5.sp,
                  //   child: LinearProgressIndicator(),
                  // ),
                  // child: SizedBox(
                  //   width: 16.sp,
                  //   height: 16.sp,
                  //   child: CircularProgressIndicator(strokeWidth: 2.sp),
                  // ),
                ),

              /// 输入框
              ChatInput(
                model: _selectedModel,
                onSend: _handleSendMessage,
                onCancel: _cancelResponse,
                isStreaming: _isStreaming,
                onHeightChanged: (height) {
                  setState(() => _inputHeight = height);
                },
              ),
            ],
          ),

          // 悬浮按钮(前面是显示新加对话按钮，后面显示滚动到底部按钮)
          _buildFloatingButton(),
        ],
      ),
    );
  }

  // 构建空提示
  Widget _buildEmptyHint() {
    return Padding(
      padding: EdgeInsets.all(32.sp),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat, size: 36.sp, color: Colors.blue),
            Text(
              '嗨，我是思文',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '我可以帮您完成很多任务，让我们开始吧！',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // 构建消息列表
  Widget _buildMessageList() {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(_textScaleFactor),
      ),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          final isAssistant = message.role == CusRole.assistant.name;
          return Column(
            children: [
              ChatMessageItem(message: message, showModelLabel: true),
              // 不在流式响应时在助手消息下方显示操作按钮
              if (isAssistant && !_isStreaming)
                Padding(
                  // 底部留出一点间距，避免和悬浮按钮重叠
                  padding: EdgeInsets.only(left: 8.sp, bottom: 48.sp),
                  child: SizedBox(
                    height: 20.sp,
                    child: MessageActions(
                      content: message.content,
                      onRegenerate: () => _handleRegenerate(message),
                      // 是否正在重新生成(当前消息是否是重新生成消息)
                      isRegenerating: index == _regeneratingIndex,
                      // tokens: message.totalTokens,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
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
            if (_messages.isNotEmpty && !_isStreaming)
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelResponse?.call();
    _scrollController.dispose();
    super.dispose();
  }
}

class CustomLinearProgressIndicator extends StatelessWidget {
  final double progress; // 当前进度值（0.0 到 1.0）
  final Color backgroundColor; // 背景颜色
  final Color valueColor; // 进度条颜色
  final double height; // 进度条高度
  final BorderRadius borderRadius; // 圆角

  const CustomLinearProgressIndicator({
    super.key,
    required this.progress,
    this.backgroundColor = Colors.grey,
    this.valueColor = Colors.blue,
    this.height = 8.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius, // 设置圆角
      child: SizedBox(
        height: height, // 设置高度
        child: LinearProgressIndicator(
          value: null, // 当前进度
          backgroundColor: backgroundColor, // 背景颜色
          valueColor: AlwaysStoppedAnimation<Color>(valueColor), // 进度条颜色
        ),
      ),
    );
  }
}
