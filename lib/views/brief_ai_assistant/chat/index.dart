// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../common/constants.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../common/llm_spec/cus_llm_spec.dart';
import '../../../common/utils/db_tools/db_helper.dart';
import '../../../models/chat_competion/com_cc_state.dart';
import 'components/chat_input.dart';
import 'components/chat_message_item.dart';
import 'components/model_filter.dart';
import 'components/model_selector.dart';
import '../../../services/chat_service.dart';
import 'components/chat_history_drawer.dart';
import 'components/message_actions.dart';
import '../../../services/model_manager_service.dart';

class BriefChatScreen extends StatefulWidget {
  final List<CusBriefLLMSpec> llmSpecList;

  const BriefChatScreen({
    super.key,
    required this.llmSpecList,
  });

  @override
  State<BriefChatScreen> createState() => _BriefChatScreenState();
}

class _BriefChatScreenState extends State<BriefChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final DBHelper _dbHelper = DBHelper();

  LLModelType _selectedType = LLModelType.cc;
  CusBriefLLMSpec? _selectedModel;
  List<ChatMessage> _messages = [];
  bool _isStreaming = false;
  ChatHistory? _currentChat;
  VoidCallback? _cancelResponse;
  int? _regeneratingIndex; // 添加重新生成索引

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final histories = await _dbHelper.queryChatList();

    if (!mounted) return;
    if (histories.isNotEmpty) {
      final lastChat = histories.first;
      setState(() {
        _messages = lastChat.messages;
        _currentChat = lastChat;
        // 根据历史记录设置模型
        _selectedModel = widget.llmSpecList.firstWhere(
          (m) =>
              m.name == lastChat.llmName &&
              m.platform.name == lastChat.cloudPlatformName,
          orElse: () => widget.llmSpecList.first,
        );
        _selectedType = _selectedModel!.modelType;
      });
    } else {
      // 没有历史记录时，使用默认值
      setState(() {
        _messages = [];
        _currentChat = null;
        _selectedModel = widget.llmSpecList.first;
        _selectedType = _selectedModel!.modelType;
      });
    }
  }

  void _createNewChat() {
    setState(() {
      _messages = [];
      _currentChat = null;
      // 保持当前选中的平台和模型不变
    });
  }

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

  Future<void> _showModelSelector() async {
// 获取可用的模型列表
    final availableModels = await ModelManagerService.getAvailableModels();

    final filteredModels =
        availableModels.where((m) => m.modelType == _selectedType).toList();

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
      builder: (context) => ModelSelector(
        models: filteredModels,
        selectedModel: _selectedModel,
        onModelChanged: (model) => Navigator.pop(context, model),
      ),
    );

    if (!mounted) return;
    if (model != null) {
      setState(() => _selectedModel = model);
    } else {
      // 如果没有点击模型，则使用选定分类的第一个模型
      setState(() => _selectedModel = filteredModels.first);
    }
  }

  void _handleHistorySelect(ChatHistory history) {
    setState(() {
      _messages = history.messages;
      _currentChat = history;
      // 恢复使用的模型
      _selectedModel = widget.llmSpecList.firstWhere(
        (m) =>
            m.name == history.llmName &&
            m.platform.name == history.cloudPlatformName,
        orElse: () => _selectedModel!,
      );
      _selectedType = _selectedModel!.modelType;
    });
  }

  // 保存或更新对话历史
  Future<void> _saveChatHistory(String title) async {
    // 确保所有消息都包含完整信息
    final updatedMessages = _messages
        .map((m) => ChatMessage(
              messageId: m.messageId,
              dateTime: m.dateTime,
              role: m.role,
              content: m.content,
              imageUrl: m.imageUrl,
              contentVoicePath: m.contentVoicePath,
              modelLabel: m.modelLabel ?? _selectedModel!.name,
            ))
        .toList();

    if (_currentChat == null) {
      // 新对话，创建新记录
      _currentChat = ChatHistory(
        uuid: DateTime.now().toString(),
        title: title.substring(0, title.length > 20 ? 20 : title.length),
        messages: updatedMessages, // 使用更新后的消息列表
        gmtCreate: DateTime.now(),
        gmtModified: DateTime.now(),
        llmName: _selectedModel!.name,
        cloudPlatformName: _selectedModel!.platform.name,
        chatType: LLModelType.cc.name,
      );
      await _dbHelper.insertChatList([_currentChat!]);
    } else {
      // 更新现有对话
      _currentChat!.messages = updatedMessages; // 使用更新后的消息列表
      _currentChat!.gmtModified = DateTime.now();
      await _dbHelper.updateChatHistory(_currentChat!);
    }
  }

  // 统一处理流式响应
  Future<void> _handleStreamResponse(Stream<String> stream) async {
    final assistantMessage = ChatMessage(
      messageId: DateTime.now().toString(),
      dateTime: DateTime.now(),
      role: CusRole.assistant.name,
      content: '',
      modelLabel: _selectedModel!.name,
    );

    setState(() => _messages.add(assistantMessage));

    try {
      await for (final chunk in stream) {
        if (!mounted) break;
        setState(() {
          assistantMessage.content += chunk;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('流式响应错误: $e');
      // 如果是用户取消导致的错误，不显示错误提示
      if (!e.toString().contains('用户取消') && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('响应错误: $e')),
        );
      }
    }
  }

  Future<void> _handleSendMessage(String text,
      {File? image, File? voice}) async {
    if (!mounted) return;

    if (_selectedModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择模型')),
      );
      return;
    }

    // 构建用户消息，确保包含所有必要信息
    final userMessage = ChatMessage(
      messageId: DateTime.now().toString(),
      dateTime: DateTime.now(),
      role: CusRole.user.name,
      content: text,
      imageUrl: image?.path,
      contentVoicePath: voice?.path,
      modelLabel: _selectedModel!.name, // 添加模型标签
    );

    setState(() => _messages.add(userMessage));
    _scrollToBottom();

    try {
      setState(() => _isStreaming = true);
      final (stream, cancelFunc) = await ChatService.sendMessage(
        _selectedModel!,
        _messages,
        image: image,
        voice: voice,
      );
      _cancelResponse = cancelFunc;
      if (!mounted) return;
      await _handleStreamResponse(stream);
      await _saveChatHistory(text);

      print('发送成功，_isStreaming: $_isStreaming');

      print('发送成功，消息列表: ${_messages.map((m) => {
            'role': m.role,
            'content': m.content,
            'imageUrl': m.imageUrl,
            'contentVoicePath': m.contentVoicePath,
            'modelLabel': m.modelLabel,
          }).toList()}');
    } catch (e) {
      if (!mounted) return;
      print('发送失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败: $e')),
      );
    } finally {
      _cancelResponse = null;
      if (mounted) {
        setState(() => _isStreaming = false);
      }
    }
  }

  // 处理重新生成
  Future<void> _handleRegenerate(ChatMessage message) async {
    final index = _messages.indexOf(message);
    if (index == -1) return;

    setState(() => _regeneratingIndex = index);

    try {
      // 获取到此消息之前的对话历史(不包含当前消息)
      final messages = _messages.sublist(0, index);

      setState(() => _isStreaming = true);
      final (stream, cancelFunc) = await ChatService.sendMessage(
        _selectedModel!,
        messages,
      );
      _cancelResponse = cancelFunc;

      if (!mounted) return;
      // 移除此消息及之后的所有消息
      setState(() {
        _messages = messages;
      });

      await _handleStreamResponse(stream);
      await _saveChatHistory(_messages.last.content);
    } catch (e) {
      if (!mounted) return;
      print('重新生成失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('重新生成失败: $e')),
      );
    } finally {
      _cancelResponse = null;
      if (mounted) {
        setState(() {
          _regeneratingIndex = null;
          _isStreaming = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
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
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _isStreaming ? null : _createNewChat,
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
      endDrawer: FutureBuilder<List<ChatHistory>>(
        future: _dbHelper.queryChatList(chatType: LLModelType.cc.name),
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
          );
        },
      ),
      body: Column(
        children: [
          SizedBox(height: 5.sp),
          ModelFilter(
            models: widget.llmSpecList,
            selectedType: _selectedType,
            onTypeChanged: _isStreaming ? null : _handleTypeChanged,
            onModelSelect: _isStreaming ? null : _showModelSelector,
            isStreaming: _isStreaming,
            supportedTypes: [LLModelType.cc, LLModelType.vision],
          ),
          Divider(height: 10.sp),
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyHint()
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isAssistant =
                          message.role == CusRole.assistant.name;
                      return Column(
                        children: [
                          ChatMessageItem(
                            message: message,
                            showModelLabel: true,
                          ),
                          // 在助手消息下方显示操作按钮
                          if (isAssistant)
                            Padding(
                              padding: EdgeInsets.only(right: 8.sp),
                              child: MessageActions(
                                content: message.content,
                                onRegenerate: () => _handleRegenerate(message),
                                isRegenerating: index == _regeneratingIndex,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
          if (_isStreaming) const LinearProgressIndicator(),
          ChatInput(
            model: _selectedModel,
            onSend: _handleSendMessage,
            onCancel: _cancelResponse,
            isStreaming: _isStreaming,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHint() {
    return Padding(
      padding: EdgeInsets.all(32.sp),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat, size: 36.sp),
            Text(
              '嗨，我是思文智能助手',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '我可以帮你完成很多任务，让我们开始吧！',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cancelResponse?.call();
    _scrollController.dispose();
    super.dispose();
  }
}
