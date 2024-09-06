// delete_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

///
/// 文本对话中最近记录列表里的删除、修改按钮
/// 智能助手和智能群聊都有用，类型不同所以动态，但用于显示title栏位都有
///
class ChatHistoryDeleteButton extends StatelessWidget {
  final dynamic chatHistory;
  final Function(dynamic) onDelete;

  const ChatHistoryDeleteButton({
    super.key,
    required this.chatHistory,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40.sp,
      height: 40.sp,
      child: IconButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("确认删除对话记录:"),
                // 智能对话或者智能群聊都有title
                content: Text(chatHistory.title),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: const Text("取消"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: const Text("确定"),
                  ),
                ],
              );
            },
          ).then((value) async {
            if (value == true) {
              onDelete(chatHistory);
            }
          });
        },
        icon: Icon(Icons.delete, color: Theme.of(context).primaryColor),
        iconSize: 20.sp,
        // padding: EdgeInsets.all(0.sp),
      ),
    );
  }
}

class ChatHistoryUpdateButton extends StatefulWidget {
  final dynamic chatHistory;
  final Function(dynamic) onUpdate;

  const ChatHistoryUpdateButton({
    super.key,
    required this.chatHistory,
    required this.onUpdate,
  });

  @override
  State<ChatHistoryUpdateButton> createState() =>
      _ChatHistoryUpdateButtonState();
}

class _ChatHistoryUpdateButtonState extends State<ChatHistoryUpdateButton> {
  // 要修改最近对话列表中指定的某个对话的名称
  final _selectedTitleController = TextEditingController();

  @override
  void dispose() {
    _selectedTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40.sp,
      height: 40.sp,
      child: IconButton(
        onPressed: () {
          setState(() {
            // 智能对话和智能群聊的类型都有title
            _selectedTitleController.text = widget.chatHistory.title;
          });
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("修改对话记录标题:", style: TextStyle(fontSize: 18.sp)),
                content: TextField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  controller: _selectedTitleController,
                  maxLines: 2,
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: const Text("取消"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: const Text("确定"),
                  ),
                ],
              );
            },
          ).then((value) async {
            if (value == true) {
              var temp = widget.chatHistory;
              // 这里是单独智能对话或者群聊，对应的类都有标题和修改日期栏位
              temp.title = _selectedTitleController.text.trim();
              temp.gmtModified = DateTime.now();
              widget.onUpdate(temp);
            }
          });
        },
        icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
        iconSize: 20.sp,
      ),
    );
  }
}
