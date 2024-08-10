// chat_title_area.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../models/chat_competion/com_cc_state.dart';

import 'title_update_button_widget.dart';

///
/// 对话页面的标题区域
///
class ChatTitleArea extends StatelessWidget {
  final ChatSession? chatSession;
  final Function(ChatSession) onUpdate;

  const ChatTitleArea({
    super.key,
    required this.chatSession,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(1.sp),
      child: Row(
        children: [
          const Icon(Icons.title),
          SizedBox(width: 10.sp),
          Expanded(
            child: Text(
              '${(chatSession != null) ? chatSession?.title : '<暂未建立对话>'}',
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TitleUpdateButton(
            chatSession: chatSession,
            onUpdate: onUpdate,
          ),
        ],
      ),
    );
  }
}
