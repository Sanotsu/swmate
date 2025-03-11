import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../models/brief_ai_tools/chat_branch/chat_branch_session.dart';

class ChatHistoryDrawer extends StatelessWidget {
  final List<ChatBranchSession> sessions;
  final int? currentSessionId;
  final bool isNewChat;
  final Function(ChatBranchSession) onSessionSelected;
  final Function(ChatBranchSession) onSessionEdit;
  final Function(ChatBranchSession) onSessionDelete;

  const ChatHistoryDrawer({
    super.key,
    required this.sessions,
    this.currentSessionId,
    required this.isNewChat,
    required this.onSessionSelected,
    required this.onSessionEdit,
    required this.onSessionDelete,
  });

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            // DrawerHeader(
            //   decoration: BoxDecoration(
            //     color: Theme.of(context).primaryColor,
            //   ),
            //   child: Column(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: [
            //       Text(
            //         '历史对话',
            //         style: TextStyle(color: Colors.white, fontSize: 24.sp),
            //       ),
            //     ],
            //   ),
            // ),
            if (sessions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    '暂无历史对话',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              ...sessions.map((session) => GestureDetector(
                    onLongPressStart: (details) {
                      final Offset overlayPosition = details.globalPosition;

                      showMenu<String>(
                        context: context,
                        position: RelativeRect.fromLTRB(
                          overlayPosition.dx,
                          overlayPosition.dy,
                          overlayPosition.dx + 200.sp, // 菜单宽度
                          overlayPosition.dy + 100.sp, // 菜单高度
                        ),
                        items: [
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8.sp),
                                Text('修改标题'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8.sp),
                                Text(
                                  '删除对话',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ).then((value) {
                        if (value == 'edit') {
                          onSessionEdit(session);
                        } else if (value == 'delete') {
                          onSessionDelete(session);
                        }
                      });
                    },
                    child: ListTile(
                      title: Text(session.title),
                      subtitle: Text(
                        _formatDateTime(session.updateTime),
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      selected: !isNewChat &&
                          currentSessionId != null &&
                          session.id == currentSessionId,
                      onTap: () {
                        onSessionSelected(session);
                        Navigator.pop(context);
                      },
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
