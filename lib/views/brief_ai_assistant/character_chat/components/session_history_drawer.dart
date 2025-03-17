import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../models/brief_ai_tools/character_chat/character_chat_session.dart';
import '../../../../models/brief_ai_tools/character_chat/character_card.dart';

class SessionHistoryDrawer extends StatefulWidget {
  final List<CharacterChatSession> sessions;
  final CharacterChatSession currentSession;
  final CharacterCard character;
  final Function(CharacterChatSession) onSessionSelected;
  final Function(CharacterChatSession, String) onSessionAction;
  final VoidCallback onNewSession;

  const SessionHistoryDrawer({
    super.key,
    required this.sessions,
    required this.currentSession,
    required this.character,
    required this.onSessionSelected,
    required this.onSessionAction,
    required this.onNewSession,
  });

  @override
  State<SessionHistoryDrawer> createState() => _SessionHistoryDrawerState();
}

class _SessionHistoryDrawerState extends State<SessionHistoryDrawer> {
  // 存储点击位置
  Offset _tapPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(16.sp),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30.sp,
                    backgroundImage:
                        widget.character.avatar.startsWith('assets/')
                            ? AssetImage(widget.character.avatar)
                            : FileImage(File(widget.character.avatar))
                                as ImageProvider,
                    onBackgroundImageError: (_, __) {
                      const Icon(Icons.person);
                    },
                  ),
                  SizedBox(height: 10.sp),
                  Text(
                    '${widget.character.name}的对话历史',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: widget.sessions.isEmpty
                ? Center(
                    child: Text(
                      '暂无对话历史',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.sessions.length,
                    itemBuilder: (context, index) {
                      final session = widget.sessions[index];
                      final isCurrentSession =
                          session.id == widget.currentSession.id;

                      // 获取最后一条消息
                      String lastMessage = '无消息';
                      if (session.messages.isNotEmpty) {
                        final lastMsg = session.messages.last;
                        lastMessage = lastMsg.content.length > 30
                            ? '${lastMsg.content.substring(0, 30)}...'
                            : lastMsg.content;
                      }

                      return GestureDetector(
                        onTapDown: (details) {
                          // 存储点击位置，用于长按菜单
                          _tapPosition = details.globalPosition;
                        },
                        onLongPress: () {
                          _showSessionMenu(session);
                        },
                        child: ListTile(
                          title: Text(
                            session.title,
                            style: TextStyle(
                              fontWeight: isCurrentSession
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _formatTime(session.updateTime),
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          selected: isCurrentSession,
                          onTap: () {
                            if (!isCurrentSession) {
                              widget.onSessionSelected(session);
                            }
                            Navigator.pop(context); // 关闭抽屉
                          },
                        ),
                      );
                    },
                  ),
          ),
          Divider(),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('新建对话'),
            onTap: () {
              Navigator.pop(context); // 关闭抽屉
              widget.onNewSession();
            },
          ),
        ],
      ),
    );
  }

  // 显示会话操作菜单
  void _showSessionMenu(CharacterChatSession session) async {
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        _tapPosition.dx,
        _tapPosition.dy,
        _tapPosition.dx + 1,
        _tapPosition.dy + 1,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20.sp),
              SizedBox(width: 8.sp),
              const Text('编辑标题'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20.sp, color: Colors.red),
              SizedBox(width: 8.sp),
              const Text('删除', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );

    if (result != null) {
      widget.onSessionAction(session, result);
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return '今天 ${DateFormat('HH:mm').format(time)}';
    } else if (messageDate == yesterday) {
      return '昨天 ${DateFormat('HH:mm').format(time)}';
    } else {
      return DateFormat('MM-dd HH:mm').format(time);
    }
  }
}
