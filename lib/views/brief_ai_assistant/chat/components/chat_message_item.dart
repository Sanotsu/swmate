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
          if (message.contentVoicePath != null &&
              message.contentVoicePath!.trim() != "")
            _buildVoicePlayer(),

          // 显示图片
          if (message.imageUrl != null) _buildImage(),
        ],
      ),
    );
  }

  // 头像消息体旁边，Row布局，显示文本内容没那么宽
  Widget buildHorizontalAvatar(bool isUser) {
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
                // 显示模型响应时间
                if (message.content.trim().isNotEmpty)
                  Text(
                    DateFormat(constDatetimeFormat).format(message.dateTime),
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                // 显示消息内容
                _buildMessageContent(isUser, false),

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

  // Column布局时，头像和时间戳
  Widget _buildAvatarAndTimestamp(bool isFromUser) {
    return Row(
      children: [
        if (!isFromUser) _buildAvatar(isFromUser),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.sp),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 显示模型标签
              if (!isFromUser && showModelLabel && message.modelLabel != null)
                Text(
                  message.modelLabel!,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),

              // 显示模型响应时间
              if (message.content.trim().isNotEmpty)
                Text(
                  DateFormat(constDatetimeFormat).format(message.dateTime),
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
            ],
          ),
        ),
        if (isFromUser) _buildAvatar(isFromUser),
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
    // 所有的文字颜色，暂定用户蓝色AI黑色(系统角色为绿色)
    // Color textColor = message.role == CusRole.user.name
    //     ? Colors.blue
    //     : message.role == CusRole.system.name
    //         ? Colors.green
    //         : Colors.black;
    // Color bgColor = isUser ? Colors.blue.shade100 : Colors.greenAccent.shade100;

    // 用户输入，蓝底白字；AI响应，灰底黑字；深度思考，灰底深灰字
    Color textColor = message.role == CusRole.user.name
        ? Colors.white
        : message.role == CusRole.system.name
            ? Colors.grey
            : Colors.black;
    Color bgColor = isUser ? Colors.blue : Colors.grey.shade100;

    return Container(
      // margin: isAvatarTop
      //     ? EdgeInsets.all(0.sp)
      //     // 34 是图标的宽度，对话正文的两边都空这个宽度，整个多轮的正文显示就是一样宽
      //     // 如果只是左右空一个，那这个margin可以省略掉(头像在上方这个地方不影响)
      //     : EdgeInsets.only(
      //         left: isUser ? 34.sp : 0,
      //         right: isUser ? 0 : 34.sp,
      //       ),
      padding: EdgeInsets.all(8.sp),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.reasoningContent != null &&
              message.reasoningContent!.isNotEmpty)
            // _buildThinkingProcess(message),
            _buildThinkingProcessText(message),
          MarkdownBody(
            data: message.content,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(color: textColor),
              // code: TextStyle(
              //   color: Colors.black,
              //   backgroundColor: Colors.grey.shade200,
              // ),
              // tableBody: TextStyle(color: Colors.black),
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
            color: Colors.blue,
            fontSize: 16.sp,
          ),
        ),
        // 默认展开
        initiallyExpanded: true,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 24.sp),
            child: Text(
              message.reasoningContent ?? '',
              style: TextStyle(color: Colors.grey, fontSize: 13.5.sp),
            ),
          ),
        ],
      ),
    );
  }

  // 2025-02-25 深度思考过程直接使用基础组件显示也可以
  Widget _buildThinkingProcessText(ChatMessage message) {
    bool isThinkingExpanded = true;
    return StatefulBuilder(builder: (context, setState) {
      return GestureDetector(
        onTap: () {
          setState(() {
            isThinkingExpanded = !isThinkingExpanded;
          });
        },
        child: Container(
          padding: EdgeInsets.only(bottom: 16.sp),
          // decoration: BoxDecoration(
          //   color: Colors.green[200],
          //   borderRadius: BorderRadius.circular(8.sp),
          // ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    message.content.trim().isEmpty
                        ? '思考中'
                        : '已深度思考(用时${message.thinkingDuration ?? 0}秒)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        isThinkingExpanded = !isThinkingExpanded;
                      });
                    },
                    icon: Icon(
                      isThinkingExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                    ),
                  ),
                ],
              ),
              if (isThinkingExpanded)
                Padding(
                  padding: EdgeInsets.only(left: 32.sp),
                  // child: Text(
                  //   message.reasoningContent ?? '',
                  //   style: TextStyle(color: Colors.black54),
                  // ),
                  child: MarkdownBody(
                    data: message.reasoningContent ?? '',
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(color: Colors.black54, fontSize: 13.sp),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  // 如果联网搜索有联网部分，展示链接
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

  // 简单的音频播放
  Widget _buildVoicePlayer() {
    return VoiceWaveBubble(
      path: message.contentVoicePath!,
    );
  }

  // 简单的图片预览
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
