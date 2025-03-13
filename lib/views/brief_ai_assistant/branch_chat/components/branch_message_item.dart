import 'package:flutter/material.dart';

import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/components/voice_chat_bubble.dart';
import '../../../../common/constants/constants.dart';
import '../../../../models/brief_ai_tools/chat_branch/chat_branch_message.dart';

class BranchMessageItem extends StatelessWidget {
  // 用于展示的消息
  final ChatBranchMessage message;
  final bool? isUseBgImage;

  // 长按消息后，点击了消息体处的回调
  final Function(ChatBranchMessage, LongPressStartDetails)? onLongPress;

  const BranchMessageItem({
    super.key,
    required this.message,
    this.onLongPress,
    this.isUseBgImage = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == CusRole.user.name ||
        message.role == CusRole.system.name;

    return Container(
      margin: EdgeInsets.all(4.sp),
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
          _buildMessageContent(isUser),

          // 如果是语音输入，显示语言文件，可点击播放
          if (message.contentVoicePath != null &&
              message.contentVoicePath!.trim() != "")
            _buildVoicePlayer(),

          // 显示图片
          if (message.imagesUrl != null) _buildImage(context),
        ],
      ),
    );
  }

  // 头像和时间戳
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
              if (!isUser && message.modelLabel != null)
                Text(
                  message.modelLabel!,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),

              // 显示模型响应时间
              if (message.content.trim().isNotEmpty)
                Text(
                  DateFormat(constDatetimeFormat).format(message.createTime),
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
  Widget _buildMessageContent(bool isUser) {
    Color textColor = message.role == CusRole.user.name
        ? isUseBgImage == true
            ? Colors.blue
            : Colors.white
        : message.role == CusRole.system.name
            ? Colors.grey
            : Colors.black;
    Color bgColor = isUser ? Colors.blue : Colors.grey.shade100;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.sp),
      padding: EdgeInsets.all(8.sp),
      decoration: BoxDecoration(
        color: isUseBgImage == true ? Colors.transparent : bgColor,
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(
          color: isUseBgImage == true ? textColor : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.reasoningContent != null &&
              message.reasoningContent!.isNotEmpty)
            _buildThinkingProcess(message),
          GestureDetector(
            onLongPressStart: onLongPress != null
                ? (details) => onLongPress!(message, details)
                : null,
            child: MarkdownBody(
              data: message.content,
              // selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(color: textColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // DS 的 R 系列有深度思考部分，单独展示
  Widget _buildThinkingProcess(ChatBranchMessage message) {
    // 创建一个基础的 TextStyle，深度思考的文字颜色和大小
    final tempStyle = TextStyle(color: Colors.black54, fontSize: 13.5.sp);

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
            // child: Text(
            //   message.reasoningContent ?? '',
            //   style: TextStyle(color: Colors.black54, fontSize: 13.5.sp),
            // ),

            /// 使用 MarkdownBody 显示深度思考内容
            child: MarkdownBody(
              data: message.reasoningContent ?? '',
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                // 复用 tempStyle
                p: tempStyle,
                h1: tempStyle,
                h2: tempStyle,
                h3: tempStyle,
                h4: tempStyle,
                h5: tempStyle,
                h6: tempStyle,
                strong: tempStyle,
                em: tempStyle,
                blockquote: tempStyle,
                listBullet: tempStyle,
                tableHead: tempStyle,
                tableBody: tempStyle,
                // 隐藏换行线
                horizontalRuleDecoration: BoxDecoration(
                  color: Colors.transparent,
                ),
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
      path: message.contentVoicePath!,
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
            message.imagesUrl!.split(',')[0],
            context,
            isFileUrl: true,
            imageErrorHint: '图片异常，请开启新对话',
          ),
        ),
      ),
    );
  }
}
