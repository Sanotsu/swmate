import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../models/chat_competion/com_cc_state.dart';

class ChatHistoryDrawer extends StatelessWidget {
  final List<ChatHistory> histories;
  final ChatHistory? currentChat;
  final ValueChanged<ChatHistory> onHistorySelect;

  const ChatHistoryDrawer({
    super.key,
    required this.histories,
    this.currentChat,
    required this.onHistorySelect,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      // 移除圆弧
      shape: RoundedRectangleBorder(
        // 设置 BorderRadius.zero 移除圆弧
        borderRadius: BorderRadius.zero,
      ),
      // 调整宽度
      width: 0.75.sw,
      child: Column(
        children: [
          // DrawerHeader(
          //   decoration: BoxDecoration(
          //     color: Theme.of(context).primaryColor.withOpacity(0.1),
          //   ),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Row(
          //         children: [
          //           Text(
          //             '对话历史',
          //             style: TextStyle(
          //               fontSize: 18.sp,
          //               fontWeight: FontWeight.bold,
          //             ),
          //           ),
          //           const Spacer(),
          //           IconButton(
          //             icon: const Icon(Icons.close),
          //             onPressed: () => Navigator.pop(context),
          //           ),
          //         ],
          //       ),
          //       const Divider(),
          //       Text(
          //         '共 ${histories.length} 条记录',
          //         style: TextStyle(
          //           fontSize: 14.sp,
          //           color: Colors.grey,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          Expanded(
            child: ListView.builder(
              itemCount: histories.length,
              itemBuilder: (context, index) {
                final history = histories[index];
                final isSelected = history.uuid == currentChat?.uuid;

                return ListTile(
                  title: Text(
                    history.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    history.gmtModified.toString().substring(0, 19),
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  selected: isSelected,
                  selectedTileColor:
                      Theme.of(context).primaryColor.withOpacity(0.1),
                  onTap: () {
                    onHistorySelect(history);
                    Navigator.pop(context);
                  },
                  trailing: isSelected ? const Icon(Icons.check) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
