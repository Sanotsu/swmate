import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/components/voice_chat_bubble.dart';
import '../../../../common/constants/constants.dart';
import '../../../../models/brief_ai_tools/character_chat/character_chat_message.dart';
import '../../../../models/brief_ai_tools/character_chat/character_card.dart';
import '../../_chat_components/_small_tool_widgets.dart';

class CharacterMessageItem extends StatelessWidget {
  final CharacterChatMessage message;
  final CharacterCard? character;
  final Function(CharacterChatMessage)? onLongPress;

  const CharacterMessageItem({
    super.key,
    required this.message,
    this.character,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == CusRole.user.name;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.sp, horizontal: 8.sp),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // 角色头像（用户消息在右侧，不显示头像）
          if (!isUser) _buildAvatar(),

          SizedBox(width: 4.sp),

          // 消息内容
          Flexible(
            child: GestureDetector(
              onLongPress:
                  onLongPress != null ? () => onLongPress!(message) : null,
              child: Container(
                padding: EdgeInsets.all(8.sp),
                decoration: BoxDecoration(
                  color: isUser
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.sp),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 角色名称（用户消息不显示）
                    if (!isUser && character != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: 4.sp),
                        child: Text(
                          character!.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),

                    // 消息内容
                    _buildMessageContent(context),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(width: 4.sp),

          // 用户头像（角色消息在左侧，不显示用户头像）
          if (isUser)
            CircleAvatar(
              radius: 20.sp,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              child: Icon(Icons.person, color: Theme.of(context).primaryColor),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (character == null) {
      return CircleAvatar(
        radius: 20.sp,
        backgroundColor: Colors.grey.withOpacity(0.2),
        child: Icon(Icons.smart_toy, color: Colors.grey),
      );
    }

    return buildCharacterCircleAvatar(character!.avatar);
  }

  Widget _buildMessageContent(BuildContext context) {
    final isUser = message.role == CusRole.user.name;

    List<Widget> list = [];

    // 时间戳一般放在最前面
    list.add(Text(
      _formatTime(message.timestamp),
      style: TextStyle(fontSize: 10.sp),
    ));

    // 文本消息，一般都有
    list.add(
      MarkdownBody(
        data: message.content,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            fontSize: 14.sp,
            color: isUser ? Colors.blue : Colors.black,
          ),
          code: TextStyle(
            fontSize: 12.sp,
            backgroundColor: Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
    );

    // 语音消息
    if (message.contentVoicePath != null &&
        message.contentVoicePath!.isNotEmpty) {
      list.add(VoiceWaveBubble(path: message.contentVoicePath!));
    }

    // 图片消息
    if (message.imagesUrl != null && message.imagesUrl!.isNotEmpty) {
      final imageUrls = message.imagesUrl!.split(',');
      list.add(
        Wrap(
          spacing: 4.sp,
          runSpacing: 4.sp,
          children: imageUrls.map((url) {
            return Container(
              margin: EdgeInsets.only(top: 8.sp),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.sp),
                child: SizedBox(
                  width: 0.3.sw,
                  child: buildImageView(
                    url,
                    context,
                    isFileUrl: true,
                    imageErrorHint: '图片异常，请开启新对话',
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: list,
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(time);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return '昨天 ${DateFormat('HH:mm').format(time)}';
    } else {
      return DateFormat('MM-dd HH:mm').format(time);
    }
  }
}
