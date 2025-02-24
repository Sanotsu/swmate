import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../common/constants.dart';
import '../../../../models/chat_competion/com_cc_state.dart';
import 'dart:io';

import '../../../ai_assistant/_componets/voice_chat_bubble.dart';

class ChatMessageItem extends StatelessWidget {
  final ChatMessage message;
  final bool showModelLabel;

  const ChatMessageItem({
    super.key,
    required this.message,
    this.showModelLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == CusRole.user.name ||
        message.role == CusRole.system.name;

    return Container(
      margin: EdgeInsets.all(4.sp),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(isUser),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 显示模型标签
                if (!isUser && showModelLabel && message.modelLabel != null)
                  Text(
                    message.modelLabel!,
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),

                Text(
                  DateFormat(constDatetimeFormat).format(message.dateTime),
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),

                // 显示消息内容
                _buildMessageContent(isUser),

                // 如果是语音输入，显示语言文件，可点击播放
                if (message.contentVoicePath != null &&
                    message.contentVoicePath!.trim() != "")
                  _buildVoicePlayer(),

                // 显示图片
                if (message.imageUrl != null) _buildImage(),
              ],
            ),
          ),
          if (isUser) _buildAvatar(isUser),
        ],
      ),
    );
  }

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

  Widget _buildMessageContent(bool isUser) {
    // 所有的文字颜色，暂定用户蓝色AI黑色(系统角色为绿色)
    Color textColor = message.role == CusRole.user.name
        ? Colors.blue
        : message.role == CusRole.system.name
            ? Colors.green
            : Colors.black;

    return Container(
      margin: EdgeInsets.only(
        left: isUser ? 34.sp : 0,
        right: isUser ? 0 : 34.sp,
      ),
      padding: EdgeInsets.all(8.sp),
      decoration: BoxDecoration(
        color: isUser ? Colors.blue.shade100 : Colors.greenAccent.shade100,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          MarkdownBody(
            data: message.content,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(color: textColor),
              code: TextStyle(
                color: Colors.black,
                backgroundColor: Colors.grey.shade200,
              ),
              tableBody: TextStyle(color: Colors.black),
            ),
          ),
          // 如果是流式加载中(还没有输出内容)，显示一个加载圈
          if (message.role != CusRole.user.name && message.content.isEmpty)
            SizedBox(
              width: 16.sp,
              height: 16.sp,
              child: CircularProgressIndicator(strokeWidth: 2.sp),
            ),
          if (message.quotes?.isNotEmpty == true) ..._buildQuotes(),
        ],
      ),
    );
  }

  List<Widget> _buildQuotes() {
    return message.quotes!.map((quote) {
      return Container(
        margin: EdgeInsets.only(top: 8.sp),
        padding: EdgeInsets.all(8.sp),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8.sp),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '引用来源: ${quote.title}',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              quote.url ?? '',
              style: TextStyle(fontSize: 14.sp),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildVoicePlayer() {
    return VoiceWaveBubble(
      path: message.contentVoicePath!,
    );
  }

  Widget _buildImage() {
    return Container(
      margin: EdgeInsets.only(top: 8.sp),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.sp),
        child: message.imageUrl!.startsWith('http')
            ? Image.network(
                message.imageUrl!,
                width: 0.25.sw,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(child: CircularProgressIndicator());
                },
              )
            : Image.file(
                File(message.imageUrl!),
                width: 0.25.sw,
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}
