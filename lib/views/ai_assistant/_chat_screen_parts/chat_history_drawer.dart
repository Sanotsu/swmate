// custom_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../common/constants.dart';
import '../../../models/chat_competion/com_cc_state.dart';
import 'history_item_widget.dart';

///
/// 对话历史记录抽屉
///
class ChatHistoryDrawer extends StatelessWidget {
  final List<ChatSession> chatHistory;
  final Function(ChatSession)? onTap;
  final Function(ChatSession)? onUpdate;
  final Function(ChatSession)? onDelete;

  const ChatHistoryDrawer({
    super.key,
    required this.chatHistory,
    this.onTap,
    this.onUpdate,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          SizedBox(
            // 调整DrawerHeader的高度
            height: 100.sp,
            child: DrawerHeader(
              decoration: const BoxDecoration(color: Colors.lightGreen),
              child: Center(
                child: Text(
                  '最近对话',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          ...(chatHistory
              .map(
                (e) => ChatHistoryItem(
                  chatSession: e,
                  onTap: onTap != null ? (e) => onTap!(e) : null,
                  onUpdate: onUpdate != null
                      ? (ChatSession e) async => await onUpdate!(e)
                      : null,
                  onDelete: onDelete != null
                      ? (ChatSession e) async => await onDelete!(e)
                      : null,
                  gmtCreate:
                      DateFormat(constDatetimeFormat).format(e.gmtCreate),
                ),
              )
              .toList()),
        ],
      ),
    );
  }
}
