// custom_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../common/constants.dart';
import 'history_item_widget.dart';

///
/// 对话历史记录抽屉
///
class ChatHistoryDrawer extends StatelessWidget {
  final List<dynamic> chatHistory;
  final Function? onTap;
  final Function? onUpdate;
  final Function? onDelete;

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
                  chatHistory: e,
                  onTap: onTap != null ? (e) => onTap!(e) : null,
                  onUpdate:
                      onUpdate != null ? (e) async => await onUpdate!(e) : null,
                  onDelete:
                      onDelete != null ? (e) async => await onDelete!(e) : null,
                  gmtCreate:
                      DateFormat(constDatetimeFormat).format(e.gmtCreate),
                  gmtModified:
                      DateFormat(constDatetimeFormat).format(e.gmtModified),
                ),
              )
              .toList()),
        ],
      ),
    );
  }
}
