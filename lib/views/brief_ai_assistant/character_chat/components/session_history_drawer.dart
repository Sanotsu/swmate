import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:swmate/common/components/tool_widget.dart';
import '../../../../common/utils/tools.dart';
import '../../../../models/brief_ai_tools/character_chat/character_chat_session.dart';
import '../../../../models/brief_ai_tools/character_chat/character_card.dart';
import '../../_chat_components/_small_tool_widgets.dart';
import '../../../../models/brief_ai_tools/character_chat/character_store.dart';
import 'package:file_picker/file_picker.dart';

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
      width: 0.8.sw,
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
                  SizedBox(
                    width: 60.sp,
                    height: 60.sp,
                    child: buildAvatarClipOval(
                      widget.character.avatar,
                    ),
                  ),
                  SizedBox(height: 10.sp),
                  Text(
                    '${widget.character.name}的对话历史',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload),
                  label: const Text('导出'),
                  onPressed: _showExportOptionsDialog,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('导入'),
                  onPressed: _importSessionHistory,
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.sessions.isEmpty
                ? Center(
                    child: Text(
                      '暂无对话历史',
                      style: TextStyle(fontSize: 16.sp, color: Colors.grey),
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

  // 显示导出选项对话框
  void _showExportOptionsDialog() async {
    bool isGranted = await requestStoragePermission();

    if (!mounted) return;
    if (!isGranted) {
      commonExceptionDialog(context, "异常提示", "无存储访问授权");
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出选项'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('导出当前会话'),
              onTap: () {
                Navigator.pop(context);
                _exportCurrentSessionHistory();
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('导出所有会话'),
              onTap: () {
                Navigator.pop(context);
                _exportAllSessionsHistory();
              },
            ),
          ],
        ),
      ),
    );
  }

  // 导出当前会话历史
  Future<void> _exportCurrentSessionHistory() async {
    try {
      // 先让用户选择保存位置
      final directoryResult = await FilePicker.platform.getDirectoryPath();
      if (directoryResult == null) return; // 用户取消了选择

      final store = CharacterStore();
      final filePath = await store.exportSessionHistory(
        widget.currentSession.id,
        customPath: directoryResult,
      );

      if (!mounted) return;

      commonHintDialog(context, '导出会话历史', '会话历史已导出到: $filePath');
    } catch (e) {
      if (!mounted) return;

      commonExceptionDialog(context, '导出会话历史', '导出失败: $e');
    }
  }

  // 导出所有会话历史
  Future<void> _exportAllSessionsHistory() async {
    try {
      // 先让用户选择保存位置
      final directoryResult = await FilePicker.platform.getDirectoryPath();
      if (directoryResult == null) return; // 用户取消了选择

      final store = CharacterStore();
      final filePath = await store.exportAllSessionsHistory(
        customPath: directoryResult,
      );

      if (!mounted) return;

      commonHintDialog(context, '导出会话历史', '所有会话历史已导出到: $filePath');
    } catch (e) {
      if (!mounted) return;

      commonExceptionDialog(context, '导出会话历史', '导出失败: $e');
    }
  }

  // 导入会话历史
  Future<void> _importSessionHistory() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path;
      if (filePath == null) return;

      final store = CharacterStore();
      final importResult = await store.importSessionHistory(filePath);

      if (!mounted) return;

      String message;
      if (importResult.importedSessions > 0) {
        message = '成功导入 ${importResult.importedSessions} 个会话';
        if (importResult.skippedSessions > 0) {
          message += '，跳过 ${importResult.skippedSessions} 个已存在的会话';
        }

        // 如果有导入的会话，切换到第一个导入的会话
        if (importResult.firstSession != null) {
          widget.onSessionSelected(importResult.firstSession!);
        }
      } else {
        message = '没有导入任何会话，所有会话已存在';
      }

      commonHintDialog(context, '导入会话历史', message);
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, '导入会话历史', '导入失败: $e');
    }
  }
}
