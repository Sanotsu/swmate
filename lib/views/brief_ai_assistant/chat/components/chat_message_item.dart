import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../common/components/tool_widget.dart';
import '../../../../common/constants/constants.dart';
import '../../../../common/components/voice_chat_bubble.dart';
import '../../../../models/brief_ai_tools/chat_competion/com_cc_state.dart';

import '../../_chat_components/_small_tool_widgets.dart';
import '../../../../common/components/cus_markdown_renderer.dart';

class ChatMessageItem extends StatefulWidget {
  // 用于展示的消息
  final ChatMessage message;

  // 2025-03-25 长按消息后，点击了消息体处的回调
  final Function(ChatMessage, LongPressStartDetails)? onLongPress;

  const ChatMessageItem({
    super.key,
    required this.message,
    this.onLongPress,
  });

  @override
  State<ChatMessageItem> createState() => _ChatMessageItemState();
}

class _ChatMessageItemState extends State<ChatMessageItem>
    with AutomaticKeepAliveClientMixin {
  // 添加缓存标记，避免滚动时重建
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isUser = widget.message.role == CusRole.user.name ||
        widget.message.role == CusRole.system.name;

    // 个人更喜欢顶部头像的布局
    return buildTopAvatar(isUser, context);
  }

  // 头像在消息体顶部，Column布局，更宽点消息内容
  Widget buildTopAvatar(bool isUser, BuildContext context) {
    // 如果是用户输入，头像显示在右边
    CrossAxisAlignment crossAlignment =
        isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Container(
      margin: EdgeInsets.all(4.sp),
      child: Column(
        crossAxisAlignment: crossAlignment,
        children: [
          // 头像、模型名、时间戳(头像旁边的时间和模型名不缩放，避免显示溢出)
          // buildHorizontalAvatar 横向排版时不必，因为Flexible有缩放会换行
          MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1),
            ),
            child: _buildAvatarAndTimestamp(isUser),
          ),

          // 显示消息内容
          _buildMessageContent(isUser, true),

          // 如果是语音输入，显示语言文件，可点击播放
          if (widget.message.contentVoicePath != null &&
              widget.message.contentVoicePath!.trim() != "")
            _buildVoicePlayer(),

          // 显示图片
          if (widget.message.imageUrl != null) _buildImage(context),
        ],
      ),
    );
  }

  // Column布局时，头像和时间戳
  Widget _buildAvatarAndTimestamp(bool isUser) {
    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isUser) _buildAvatar(isUser),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.sp),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 显示模型标签
              if (!isUser && widget.message.modelLabel != null)
                Text(
                  widget.message.modelLabel!,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),

              // 显示模型响应时间
              if (widget.message.content.trim().isNotEmpty)
                Text(
                  DateFormat(constDatetimeFormat)
                      .format(widget.message.dateTime),
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
            ],
          ),
        ),
        if (isUser) _buildAvatar(isUser),
      ],
    );
  }

  // 头像
  Widget _buildAvatar(bool isUser) {
    return Container(
      margin: EdgeInsets.only(
        right: isUser ? 0 : 4.sp,
        left: isUser ? 4.sp : 0,
      ),
      child: CircleAvatar(
        radius: 15.sp,
        backgroundColor: isUser ? Colors.blue : Colors.green,
        child: Icon(
          isUser ? Icons.person : Icons.code,
          color: Colors.white,
        ),
      ),
    );
  }

  // 对话消息正文部分
  Widget _buildMessageContent(bool isUser, bool isAvatarTop) {
    Color textColor = widget.message.role == CusRole.user.name
        ? Colors.white
        : widget.message.role == CusRole.system.name
            ? Colors.grey
            : Colors.black;
    Color bgColor = isUser ? Colors.blue : Colors.grey.shade100;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.sp),
      padding: EdgeInsets.all(8.sp),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // 联网搜索参考内容
          if (widget.message.references?.isNotEmpty == true)
            buildReferencesExpansionTile(widget.message.references),

          // 深度思考
          if (widget.message.reasoningContent != null &&
              widget.message.reasoningContent!.isNotEmpty)
            _buildThinkingProcess(widget.message),

          // 常规显示内容
          GestureDetector(
            onLongPressStart: widget.onLongPress != null
                ? (details) => widget.onLongPress!(widget.message, details)
                : null,
            child: RepaintBoundary(
              child: CusMarkdownRenderer.instance.render(
                widget.message.content,
                textColor: textColor,
              ),
            ),
          ),

          if (widget.message.role != CusRole.user.name &&
              widget.message.content.isEmpty &&
              (widget.message.reasoningContent != null &&
                  widget.message.reasoningContent!.isEmpty))
            SizedBox(
              width: 16.sp,
              height: 16.sp,
              child: CircularProgressIndicator(strokeWidth: 2.sp),
            ),
        ],
      ),
    );
  }

  // DS 的 R 系列有深度思考部分，单独展示
  Widget _buildThinkingProcess(ChatMessage message) {
    return Container(
      padding: EdgeInsets.only(bottom: 8.sp),
      child: ExpansionTile(
        title: Text(
          message.content.trim().isEmpty
              ? '思考中'
              : '已深度思考(用时${message.thinkingDuration ?? 0}秒)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black54,
            fontSize: 16.sp,
          ),
        ),
        // 默认展开
        initiallyExpanded: true,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 24.sp),
            child: RepaintBoundary(
              child: CusMarkdownRenderer.instance.render(
                widget.message.reasoningContent ?? '',
                textColor: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 简单的音频播放
  Widget _buildVoicePlayer() {
    return VoiceWaveBubble(
      path: widget.message.contentVoicePath!,
    );
  }

  // 简单的图片预览
  Widget _buildImage(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8.sp),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.sp),
        child: SizedBox(
          width: 0.3.sw,
          child: buildImageView(
            widget.message.imageUrl!,
            context,
            isFileUrl: true,
            imageErrorHint: '图片异常，请开启新对话',
          ),
        ),
      ),
    );
  }
}
