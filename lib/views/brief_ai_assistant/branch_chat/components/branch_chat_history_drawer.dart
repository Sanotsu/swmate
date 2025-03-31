import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../common/llm_spec/constant_llm_enum.dart';
import '../../../../models/brief_ai_tools/branch_chat/branch_chat_session.dart';

class BranchChatHistoryDrawer extends StatelessWidget {
  // 历史对话列表
  final List<BranchChatSession> sessions;
  // 当前选中的对话
  final int? currentSessionId;
  // 选中对话的回调
  final Function(BranchChatSession) onSessionSelected;
  // 删除或重命名对话后，要刷新对话列表
  final Function(BranchChatSession, String) onRefresh;

  const BranchChatHistoryDrawer({
    super.key,
    required this.sessions,
    this.currentSessionId,
    required this.onSessionSelected,
    required this.onRefresh,
  });

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
              Padding(
                padding: EdgeInsets.all(16.sp),
                child: Center(
                  child: Text(
                    '暂无历史对话',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              )
            else
              ...sessions.map((session) {
                final isSelected = session.id == currentSessionId;
                return _buildChatHistoryItem(session, isSelected);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHistoryItem(BranchChatSession session, bool isSelected) {
    return GestureDetector(
      child: Builder(
        builder: (context) => GestureDetector(
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
                PopupMenuItem(
                  child: _buildTextWithIcon(Icons.edit, '重命名', Colors.blue),
                  onTap: () {
                    Future.delayed(Duration.zero, () {
                      if (!context.mounted) return;
                      _editSessionTitle(context, session);
                    });
                  },
                ),
                PopupMenuItem(
                  child: _buildTextWithIcon(Icons.delete, '删除', Colors.red),
                  onTap: () {
                    Future.delayed(Duration.zero, () {
                      if (!context.mounted) return;
                      _deleteSession(context, session);
                    });
                  },
                ),
              ],
            );
          },
          child: ListTile(
            title: Text(
              session.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              "${session.updateTime.toString().substring(0, 19)}\n${CP_NAME_MAP[session.llmSpec.platform]!} > ${session.llmSpec.name}",
              style: TextStyle(fontSize: 12.sp),
            ),
            selected: isSelected,
            selectedTileColor:
                Theme.of(context).primaryColor.withValues(alpha: 0.1),
            onTap: () {
              onSessionSelected(session);
              Navigator.pop(context);
            },
            trailing: isSelected ? const Icon(Icons.check) : null,
          ),
        ),
      ),
    );
  }

  // 重命名、删除按钮，改为带有图标的文本
  Widget _buildTextWithIcon(IconData icon, String text, Color? color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 16.sp, color: color),
        SizedBox(width: 8.sp), // 添加一些间距
        Text(text, style: TextStyle(fontSize: 14.sp, color: color)),
      ],
    );
  }

  // 修改标题
  Future<void> _editSessionTitle(
    BuildContext context,
    BranchChatSession session,
  ) async {
    final controller = TextEditingController(text: session.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改标题'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '对话标题',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty && newTitle != session.title) {
      session.title = newTitle;
      session.updateTime = DateTime.now();

      onRefresh(session, 'edit');
    }
  }

  // 删除对话
  Future<void> _deleteSession(
    BuildContext context,
    BranchChatSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除对话'),
        content: const Text('确定要删除这个对话吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onRefresh(session, 'delete');
    }
  }
}
