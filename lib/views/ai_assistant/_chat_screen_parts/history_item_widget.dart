// gesture_items.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../models/chat_competion/com_cc_state.dart';
import 'history_button_widget.dart';

///
/// 文本对话中的最近对话列表
/// 后续这几个按钮可以是可选的
///
class ChatHistoryItem extends StatelessWidget {
  final ChatSession chatSession;
  final Function(ChatSession)? onTap;
  final Function(ChatSession)? onUpdate;
  final Function(ChatSession)? onDelete;
  final String gmtCreate;

  const ChatHistoryItem({
    super.key,
    required this.chatSession,
    this.onTap,
    this.onUpdate,
    this.onDelete,
    required this.gmtCreate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null ? () => onTap!(chatSession) : null,
      child: Card(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 5.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chatSession.title,
                      style: TextStyle(fontSize: 15.sp),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      chatSession.llmName,
                      style: TextStyle(fontSize: 15.sp),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      gmtCreate,
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 80.sp,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onUpdate != null)
                    ChatHistoryUpdateButton(
                      chatSession: chatSession,
                      onUpdate: onUpdate!,
                    ),
                  if (onDelete != null)
                    ChatHistoryDeleteButton(
                      chatSession: chatSession,
                      onDelete: onDelete!,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
