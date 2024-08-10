// update_title_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/chat_competion/com_cc_state.dart';

///
/// 对话页面中的修改标题按钮
///
class TitleUpdateButton extends StatefulWidget {
  final ChatSession? chatSession;
  final Function(ChatSession) onUpdate;

  const TitleUpdateButton({
    super.key,
    required this.chatSession,
    required this.onUpdate,
  });

  @override
  State<TitleUpdateButton> createState() => _TitleUpdateButtonState();
}

class _TitleUpdateButtonState extends State<TitleUpdateButton> {
  final TextEditingController _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56.sp,
      child: IconButton(
        onPressed: () {
          if (widget.chatSession != null) {
            setState(() {
              _titleController.text = widget.chatSession!.title;
            });
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text("修改对话标题:", style: TextStyle(fontSize: 20.sp)),
                  content: TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    controller: _titleController,
                    maxLines: 3,
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
                var temp = widget.chatSession!;
                temp.title = _titleController.text.trim();
                widget.onUpdate(temp);
              }
            });
          }
        },
        icon: Icon(
          Icons.edit,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
