import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../../../common/components/voice_chat_bubble.dart';
import '../../../../models/brief_ai_tools/character_chat/character_chat_message.dart';
import '../../../../models/brief_ai_tools/character_chat/character_card.dart';

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
    final isUser = message.role == 'user';

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 8.sp,
        horizontal: 16.sp,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // 角色头像（用户消息在右侧，不显示头像）
          if (!isUser) _buildAvatar(),

          SizedBox(width: 8.sp),

          // 消息内容
          Flexible(
            child: GestureDetector(
              onLongPress:
                  onLongPress != null ? () => onLongPress!(message) : null,
              child: Container(
                padding: EdgeInsets.all(12.sp),
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

                    // 时间戳
                    SizedBox(height: 4.sp),
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(width: 8.sp),

          // 用户头像（角色消息在左侧，不显示用户头像）
          if (isUser)
            CircleAvatar(
              radius: 20.sp,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              child: Icon(
                Icons.person,
                color: Theme.of(context).primaryColor,
              ),
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

    if (character!.avatar.startsWith('assets/')) {
      return CircleAvatar(
        radius: 20.sp,
        backgroundImage: AssetImage(character!.avatar),
        onBackgroundImageError: (_, __) {
          Icon(Icons.person, color: Colors.white);
        },
      );
    } else {
      return CircleAvatar(
        radius: 20.sp,
        backgroundImage: FileImage(File(character!.avatar)),
        onBackgroundImageError: (_, __) {
          Icon(Icons.person, color: Colors.white);
        },
      );
    }
  }

  Widget _buildMessageContent(BuildContext context) {
    // 语音消息
    if (message.contentVoicePath != null &&
        message.contentVoicePath!.isNotEmpty) {
      return VoiceWaveBubble(path: message.contentVoicePath!);
    }

    // 图片消息
    if (message.imagesUrl != null && message.imagesUrl!.isNotEmpty) {
      final imageUrls = message.imagesUrl!.split(',');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.content.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 8.sp),
              child: MarkdownBody(
                data: message.content,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(fontSize: 14.sp),
                  code: TextStyle(
                    fontSize: 12.sp,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          Wrap(
            spacing: 4.sp,
            runSpacing: 4.sp,
            children: imageUrls.map((url) {
              return GestureDetector(
                onTap: () {
                  // 查看大图
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.sp),
                  child: Image.file(
                    File(url.trim()),
                    width: 150.sp,
                    height: 150.sp,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 150.sp,
                        height: 150.sp,
                        color: Colors.grey.withOpacity(0.2),
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    }

    // 文本消息
    return MarkdownBody(
      data: message.content,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(fontSize: 14.sp),
        code: TextStyle(
          fontSize: 12.sp,
          backgroundColor: Colors.grey.withOpacity(0.2),
        ),
      ),
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
