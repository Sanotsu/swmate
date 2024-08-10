// delete_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/chat_competion/com_cc_state.dart';

///
/// 文本对话中最近记录列表里的删除、修改按钮
/// chat_bot 和 aggregate_search 都可以用
///
class ChatHistoryDeleteButton extends StatelessWidget {
  final ChatSession chatSession;
  final Function(ChatSession) onDelete;

  const ChatHistoryDeleteButton({
    super.key,
    required this.chatSession,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40.sp,
      child: IconButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("确认删除对话记录:"),
                content: Text(chatSession.title),
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
              onDelete(chatSession);
            }
          });
        },
        icon: Icon(
          Icons.delete,
          color: Theme.of(context).primaryColor,
        ),
        padding: EdgeInsets.all(0.sp),
      ),
    );
  }
}

class ChatHistoryUpdateButton extends StatefulWidget {
  final ChatSession chatSession;
  final Function(ChatSession) onUpdate;

  const ChatHistoryUpdateButton({
    super.key,
    required this.chatSession,
    required this.onUpdate,
  });

  @override
  State<ChatHistoryUpdateButton> createState() => _ChatHistoryUpdateButtonState();
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
      child: IconButton(
        onPressed: () {
          setState(() {
            _selectedTitleController.text = widget.chatSession.title;
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
              var temp = widget.chatSession;
              temp.title = _selectedTitleController.text.trim();
              widget.onUpdate(temp);
            }
          });
        },
        icon: Icon(
          Icons.edit,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
