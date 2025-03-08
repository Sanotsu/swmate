import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/constants/constants.dart';
import '../../../../models/brief_ai_tools/chat_competion/com_cc_state.dart';

import '../../../../common/components/voice_chat_bubble.dart';
import 'package:flutter/services.dart';

class ChatMessageItem extends StatefulWidget {
  // 用于展示的消息
  final ChatMessage message;
  // 长按消息后，点击了编辑按钮的回调
  final Function(String)? onEdit;
  // 长按消息后，点击了重新生成按钮的回调
  final VoidCallback? onRegenerate;

  const ChatMessageItem({
    super.key,
    required this.message,
    this.onEdit,
    this.onRegenerate,
  });

  @override
  State<ChatMessageItem> createState() => _ChatMessageItemState();
}

class _ChatMessageItemState extends State<ChatMessageItem> {
  @override
  Widget build(BuildContext context) {
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

    return GestureDetector(
      onLongPressStart: (LongPressStartDetails details) {
        HapticFeedback.mediumImpact();
        _showMessageOptions(context, details.globalPosition, isUser);
      },
      child: Container(
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
            if (widget.message.reasoningContent != null &&
                widget.message.reasoningContent!.isNotEmpty)
              _buildThinkingProcess(widget.message),
            MarkdownBody(
              data: widget.message.content,
              // selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(color: textColor),
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
            if (widget.message.quotes?.isNotEmpty == true) ..._buildQuotes(),
          ],
        ),
      ),
    );
  }

  // DS 的 R 系列有深度思考部分，单独展示
  Widget _buildThinkingProcess(ChatMessage message) {
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

  // 如果联网搜索有联网部分，展示链接
  List<Widget> _buildQuotes() {
    return widget.message.quotes!.map((quote) {
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

  void _showMessageOptions(
      BuildContext context, Offset tapPosition, bool isUser) {
    final size = MediaQuery.of(context).size;
    final menuWidth = 150.sp;
    final menuHeight = isUser ? 144.sp : 144.sp;

    double left = tapPosition.dx;
    double top = tapPosition.dy;

    if (left + menuWidth > size.width) {
      left = size.width - menuWidth;
    }
    if (left < 0) {
      left = 0;
    }

    if (top + menuHeight > size.height) {
      top = top - menuHeight;
    }

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        left,
        top,
        left + menuWidth,
        top + menuHeight,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.sp),
      ),
      elevation: 8,
      items: [
        PopupMenuItem(
          height: 40.sp,
          child: _buildMenuItemWithIcon(
            icon: Icons.copy,
            text: '复制',
            color: Colors.grey,
          ),
          onTap: () {
            Clipboard.setData(ClipboardData(text: widget.message.content));
            EasyLoading.showToast('已复制到剪贴板');
          },
        ),
        PopupMenuItem(
          height: 40.sp,
          child: _buildMenuItemWithIcon(
            icon: Icons.text_fields,
            text: '选择文本',
            color: Colors.blue,
          ),
          onTap: () {
            _showFullScreenText(context);
          },
        ),
        if (isUser)
          PopupMenuItem(
            height: 40.sp,
            child: _buildMenuItemWithIcon(
              icon: Icons.edit,
              text: '编辑',
              color: Colors.orange,
            ),
            onTap: () {
              if (widget.onEdit != null) {
                widget.onEdit!(widget.message.content);
              }
            },
          )
        else
          PopupMenuItem(
            height: 40.sp,
            child: _buildMenuItemWithIcon(
              icon: Icons.refresh,
              text: '重新生成',
              color: Colors.green,
            ),
            onTap: () {
              if (widget.onRegenerate != null) {
                widget.onRegenerate!();
              }
            },
          ),
      ],
    );
  }

  // 优化菜单项样式
  Widget _buildMenuItemWithIcon({
    required IconData icon,
    required String text,
    Color? color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center, // 居中对齐
      children: [
        Icon(icon, size: 16.sp, color: color),
        SizedBox(width: 8.sp),
        Text(
          text,
          style: TextStyle(
            fontSize: 14.sp,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showFullScreenText(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Container(
              alignment: Alignment.centerRight,
              child: Text('选择文本', style: TextStyle(fontSize: 18.sp)),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16.sp),
            child: SelectableText(
              widget.message.content,
              style: TextStyle(fontSize: 16.sp),
            ),
          ),
        ),
      ),
    );
  }
}
