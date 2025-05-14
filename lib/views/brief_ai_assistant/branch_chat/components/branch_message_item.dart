import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/components/voice_chat_bubble.dart';
import '../../../../common/constants/constants.dart';
import '../../../../models/brief_ai_tools/branch_chat/branch_chat_message.dart';
import '../../_chat_components/_small_tool_widgets.dart';
import '../../../../common/components/cus_markdown_renderer.dart';

class BranchMessageItem extends StatefulWidget {
  // 用于展示的消息
  final BranchChatMessage message;
  final bool? isUseBgImage;

  // 长按消息后，点击了消息体处的回调
  final Function(BranchChatMessage, LongPressStartDetails)? onLongPress;

  const BranchMessageItem({
    super.key,
    required this.message,
    this.onLongPress,
    this.isUseBgImage = false,
  });

  @override
  State<BranchMessageItem> createState() => _BranchMessageItemState();
}

class _BranchMessageItemState extends State<BranchMessageItem>
    with AutomaticKeepAliveClientMixin {
  // 添加缓存标记，避免滚动时重建
  @override
  bool get wantKeepAlive => true;

  // 添加状态缓存变量，避免重复计算
  late final bool _isUser;

  @override
  void initState() {
    super.initState();
    _isUser = widget.message.role == CusRole.user.name ||
        widget.message.role == CusRole.system.name;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      margin: EdgeInsets.all(4.sp),
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment:
            _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // 头像、模型名、时间戳(头像旁边的时间和模型名不缩放，避免显示溢出)
          // buildHorizontalAvatar 横向排版时不必，因为Flexible有缩放会换行
          MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1),
            ),
            child: _buildAvatarAndTimestamp(),
          ),

          // 显示消息内容
          _buildMessageContent(context),

          // 如果是语音输入，显示语言文件，可点击播放
          if (widget.message.contentVoicePath != null &&
              widget.message.contentVoicePath!.trim() != "")
            _buildVoicePlayer(),

          // 显示图片
          if (widget.message.imagesUrl != null) _buildImage(context),
        ],
      ),
    );
  }

  // 头像和时间戳
  Widget _buildAvatarAndTimestamp() {
    return Row(
      mainAxisAlignment:
          _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!_isUser) _buildAvatar(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.sp),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 显示模型标签
              if (!_isUser && widget.message.modelLabel != null)
                Text(
                  widget.message.modelLabel!,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),

              // 显示模型响应时间
              if (widget.message.content.trim().isNotEmpty)
                Text(
                  DateFormat(constDatetimeFormat)
                      .format(widget.message.createTime),
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
            ],
          ),
        ),
        if (_isUser) _buildAvatar(),
      ],
    );
  }

  // 头像
  Widget _buildAvatar() {
    return Container(
      margin: EdgeInsets.only(
        right: _isUser ? 0 : 4.sp,
        left: _isUser ? 4.sp : 0,
      ),
      child: CircleAvatar(
        radius: 15.sp,
        backgroundColor: _isUser ? Colors.blue : Colors.green,
        child: Icon(
          _isUser ? Icons.person : Icons.code,
          color: Colors.white,
        ),
      ),
    );
  }

  // 对话消息正文部分
  Widget _buildMessageContent(BuildContext context) {
    Color textColor = widget.message.role == CusRole.user.name
        ? widget.isUseBgImage == true
            ? Colors.blue
            : Colors.white
        : widget.message.role == CusRole.system.name
            ? Colors.grey
            : Colors.black;
    Color bgColor = _isUser ? Colors.blue : Colors.grey.shade100;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.sp),
      padding: EdgeInsets.all(8.sp),
      decoration: BoxDecoration(
        color: widget.isUseBgImage == true ? Colors.transparent : bgColor,
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(
          color: widget.isUseBgImage == true ? textColor : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // 联网搜索结果 - 懒加载，只在有引用时才构建
          if (widget.message.references?.isNotEmpty == true)
            buildReferencesExpansionTile(widget.message.references),

          // 深度思考 - 懒加载，只在有思考内容时才构建
          if (widget.message.reasoningContent != null &&
              widget.message.reasoningContent!.isNotEmpty)
            _buildThinkingProcess(),

          GestureDetector(
            onLongPressStart: widget.onLongPress != null
                ? (details) => widget.onLongPress!(widget.message, details)
                : null,
            child: RepaintBoundary(
              child: buildCusMarkdown(widget.message.content),
            ),
          ),
        ],
      ),
    );
  }

  // DS 的 R 系列有深度思考部分，单独展示
  Widget _buildThinkingProcess() {
    return Container(
      padding: EdgeInsets.only(bottom: 8.sp),
      child: ExpansionTile(
        title: Text(
          widget.message.content.trim().isEmpty
              ? '思考中'
              : '已深度思考(用时${(widget.message.thinkingDuration ?? 0) / 1000}秒)',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 24.sp),
            // 使用高性能MarkdownRenderer来渲染深度思考内容，可以利用缓存机制
            child: RepaintBoundary(
              child: buildCusMarkdown(
                widget.message.reasoningContent ?? '',
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
          // 添加RepaintBoundary，避免图片重绘影响其他元素
          child: RepaintBoundary(
            child: buildImageView(
              widget.message.imagesUrl!.split(',')[0],
              context,
              isFileUrl: true,
              imageErrorHint: '图片异常，请开启新对话',
            ),
          ),
        ),
      ),
    );
  }
}
