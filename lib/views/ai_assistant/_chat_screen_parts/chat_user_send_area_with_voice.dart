// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/components/tool_widget.dart';
import '../../../common/utils/tools.dart';
import '../_componets/sounds_message_button/button_widget/sounds_message_button.dart';
import '../_componets/sounds_message_button/utils/sounds_recorder_controller.dart';

///
/// 用户发送区域
/// aggregate_search 和 chat_bot 都可以用
///
class ChatUserVoiceSendArea extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isBotThinking;
  final Function(String) onInpuChanged;
  // 是否可以点击发送按钮
  final bool isSendClickable;
  final VoidCallback onSendPressed;
  // 2024-08-04 添加语音输入的支持，但不一定非要传入(但只要传入了，此时上方的 onSendPressed其实也没用了)
  final Function(SendContentType, String)? onSendSounds;
  // 2024-08-08 流式响应的时候，可能手动终止
  final VoidCallback? onStop;

  const ChatUserVoiceSendArea({
    super.key,
    required this.controller,
    required this.hintText,
    required this.isBotThinking,
    required this.onInpuChanged,
    this.isSendClickable = false,
    required this.onSendPressed,
    this.onSendSounds,
    this.onStop,
  });

  @override
  State<ChatUserVoiceSendArea> createState() => _ChatUserVoiceSendAreaState();
}

class _ChatUserVoiceSendAreaState extends State<ChatUserVoiceSendArea> {
  bool isVoice = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(5.sp),
      child: Row(
        children: [
          // 在语音输入和文字输入间切换，显示不同图标
          SizedBox(
            width: 50.sp,
            child: IconButton(
              icon: Icon(isVoice ? Icons.keyboard : Icons.keyboard_voice),
              onPressed: () async {
                // 默认是文字输入，如果要切换成语音，得先获取语音权限和存储权限
                if (!(await requestMicrophonePermission())) {
                  return EasyLoading.showError("未授权语音录制权限，无法语音输入");
                }

                // 首先获取设备外部存储管理权限
                if (!(await requestStoragePermission())) {
                  return EasyLoading.showError("未授权访问设备外部存储，无法进行语音识别");
                }

                setState(() {
                  isVoice = !isVoice;
                });
              },
            ),
          ),
          if (isVoice && widget.onSendSounds != null)
            Expanded(
              child: SizedBox(
                // 高度56是和下面TextField一样高
                height: 56.sp,
                child: SoundsMessageButton(
                  onChanged: (status) {},
                  // 2024-08-18 还在响应中就算重新输入也不执行
                  onSendSounds: widget.isBotThinking
                      ? (type, msg) {
                          EasyLoading.showInfo("等待响应完成或终止后再输入");
                        }
                      : widget.onSendSounds,
                ),
              ),
            ),
          if (!isVoice)
            Expanded(
              child: TextField(
                controller: widget.controller,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                minLines: 1,
                onChanged: widget.onInpuChanged,
              ),
            ),
          // 如果是API响应中，可以点击终止
          widget.isBotThinking
              ? IconButton(
                  onPressed: widget.onStop,
                  icon: const Icon(Icons.stop),
                )
              // 不是API响应，如果是文本输入，则显示输入按钮；如果是语音输入，则占位符
              : (!isVoice)
                  ? IconButton(
                      onPressed: !widget.isSendClickable
                          ? null
                          : () {
                              unfocusHandle();
                              widget.onSendPressed();
                            },
                      icon: const Icon(Icons.send),
                    )
                  : SizedBox(width: 48.sp), // 图标按钮默认大小48*48
        ],
      ),
    );
  }
}
