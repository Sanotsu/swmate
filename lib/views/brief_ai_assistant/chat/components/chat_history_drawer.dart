import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../common/llm_spec/constant_llm_enum.dart';
import '../../../../common/utils/db_tools/db_brief_ai_tool_helper.dart';
import '../../../../models/brief_ai_tools/chat_competion/com_cc_state.dart';

class ChatHistoryDrawer extends StatelessWidget {
  final List<BriefChatHistory> histories;
  final BriefChatHistory? currentChat;
  final ValueChanged<BriefChatHistory> onHistorySelect;
  final VoidCallback onRefresh;

  const ChatHistoryDrawer({
    super.key,
    required this.histories,
    this.currentChat,
    required this.onHistorySelect,
    required this.onRefresh,
  });

  Future<void> _renameChat(BuildContext context, BriefChatHistory chat) async {
    final controller = TextEditingController(text: chat.title);

    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名对话'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '对话标题',
            hintText: '请输入新的标题',
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

    if (newTitle != null && newTitle.isNotEmpty) {
      final dbHelper = DBBriefAIToolHelper();

      // 更新标题
      chat.title = newTitle;
      // 更新修改时间(对话内容没更新，所以修改时间不要改，否则历史记录修改个标题就排序不对了)
      // chat.gmtModified = DateTime.now();

      await dbHelper.updateBriefChatHistory(chat);
      onRefresh();
    }
  }

  Future<void> _deleteChat(BuildContext context, BriefChatHistory chat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条对话记录吗？'),
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

    if (confirm == true) {
      final dbHelper = DBBriefAIToolHelper();
      await dbHelper.deleteBriefChatHistoryById(chat.uuid);
      onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      width: 0.75.sw,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: histories.length,
                itemBuilder: (context, index) {
                  final history = histories[index];
                  final isSelected = history.uuid == currentChat?.uuid;

                  return _buildChatHistoryItem(history, isSelected);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHistoryItem(BriefChatHistory history, bool isSelected) {
    return Builder(
      builder: (context) => ListTile(
        title: Text(
          history.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          "${history.gmtModified.toString().substring(0, 19)}\n${CP_NAME_MAP[history.llmSpec.platform]!} > ${history.llmSpec.name}",
          style: TextStyle(fontSize: 12.sp),
        ),
        selected: isSelected,
        selectedTileColor:
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
        onTap: () {
          onHistorySelect(history);
          Navigator.pop(context);
        },
        // 长按显示删除和重命名菜单
        onLongPress: () {
          final RenderBox button = context.findRenderObject() as RenderBox;
          final position = button.localToGlobal(Offset.zero);

          showMenu(
            context: context,
            position: RelativeRect.fromRect(
              Rect.fromLTWH(
                position.dx,
                position.dy,
                button.size.width,
                button.size.height,
              ),
              Offset.zero & MediaQuery.of(context).size,
            ),
            items: [
              PopupMenuItem(
                child: _buildTextWithIcon(Icons.edit, '重命名', Colors.blue),
                onTap: () {
                  Future.delayed(Duration.zero, () {
                    if (!context.mounted) return;
                    _renameChat(context, history);
                  });
                },
              ),
              PopupMenuItem(
                child: _buildTextWithIcon(Icons.delete, '删除', Colors.red),
                onTap: () {
                  Future.delayed(Duration.zero, () {
                    if (!context.mounted) return;
                    _deleteChat(context, history);
                  });
                },
              ),
            ],
          );
        },
        trailing: isSelected ? const Icon(Icons.check) : null,
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
}
