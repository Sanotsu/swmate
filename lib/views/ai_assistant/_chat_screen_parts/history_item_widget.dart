// gesture_items.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../models/chat_competion/com_cc_state.dart';
import 'history_button_widget.dart';

///
/// 文本对话中的最近对话列表
/// 后续这几个按钮可以是可选的
/// 智能助手和智能群聊都有用，类型不同所以动态，但用于显示title栏位都有
///
class ChatHistoryItem extends StatelessWidget {
  final dynamic chatHistory;
  final Function(dynamic)? onTap;
  final Function(dynamic)? onUpdate;
  final Function(dynamic)? onDelete;
  final String gmtCreate;
  final String gmtModified;

  const ChatHistoryItem({
    super.key,
    required this.chatHistory,
    this.onTap,
    this.onUpdate,
    this.onDelete,
    required this.gmtCreate,
    required this.gmtModified,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null ? () => onTap!(chatHistory) : null,
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
                      chatHistory.title,
                      style: TextStyle(fontSize: 15.sp),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (chatHistory is ChatHistory)
                      Text(
                        (chatHistory as ChatHistory).llmName,
                        style: TextStyle(fontSize: 15.sp),
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (chatHistory is GroupChatHistory)
                      Text(
                        (chatHistory as GroupChatHistory)
                            .modelMsgMap
                            .keys
                            .toList()
                            .toString(),
                        style: TextStyle(fontSize: 12.sp),
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      "上次对话: $gmtModified",
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    // Text(
                    //   "创建时间: $gmtCreate",
                    //   style: TextStyle(fontSize: 12.sp),
                    // ),
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
                      chatHistory: chatHistory,
                      onUpdate: onUpdate!,
                    ),
                  if (onDelete != null)
                    ChatHistoryDeleteButton(
                      chatHistory: chatHistory,
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
