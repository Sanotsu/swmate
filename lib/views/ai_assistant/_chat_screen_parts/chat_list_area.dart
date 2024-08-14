// chat_list_area.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart'; // 确保你已经导入了flutter_easyloading包
import 'package:flutter/services.dart';

import '../../../models/chat_competion/com_cc_state.dart';

import '../../../services/cus_get_storage.dart';
import '../_componets/message_item.dart';
import '../_helper/save_markdown_as_pdf.dart';
import '../_helper/save_markdown_as_txt.dart';
import '../_helper/save_markdown_html_as_pdf.dart';

///
/// 对话主页面
/// 注意：这个如果复用，messages可能是
///
class ChatListArea extends StatefulWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final Function()? regenerateLatestQuestion;
  // 2024-08-08 由于流式返回的原因，这里如果还是机器思考的情况就不显示重新生成等功能按钮
  final bool? isBotThinking;
  // 头像位置是在两侧还是在上方
  final bool isAvatarTop;
  // 如果是图片理解(目前只有翻译)，还可以保存为其他文本
  final File? selectedImage;

  // 目前默认都显示，后续可以按需设定控制
  // 是否显示复制按钮
  // 是否显示重新生成按钮(有传函数就算需要)
  // 是否显示token消耗

  const ChatListArea({
    super.key,
    required this.messages,
    required this.scrollController,
    this.regenerateLatestQuestion,
    this.isBotThinking = false,
    this.isAvatarTop = false,
    this.selectedImage,
  });

  @override
  State<ChatListArea> createState() => _ChatListAreaState();
}

class _ChatListAreaState extends State<ChatListArea> {
  // 2024-07-26
  // 默认的页面主体的缩放比例(对话太小了就可以等比放大)
  // 这里直接把连续对话的文本进行缩放，所有用到的都会生效
  double _textScaleFactor = 1.0;

  @override
  void initState() {
    super.initState();

    _textScaleFactor = MyGetStorage().getChatListAreaScale();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(_textScaleFactor),
        ),
        child: ListView.builder(
          controller: widget.scrollController,
          itemCount: widget.messages.length,
          itemBuilder: (context, index) {
            var msg = widget.messages[index];

            return Padding(
              padding: EdgeInsets.all(5.sp),
              child: Column(
                children: [
                  // 构建每个对话消息
                  MessageItem(
                    message: msg,
                    // 只有最后一个才显示
                    isBotThinking: index == widget.messages.length - 1
                        ? widget.isBotThinking
                        : false,
                    isAvatarTop: widget.isAvatarTop,
                  ),

                  /// 如果是大模型回复\且已经回复完了，可以有一些功能按钮
                  if (msg.role == 'assistant' && widget.isBotThinking != true)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        /// 排除占位消息后，是大模型最后一条回复，则可以重新生成
                        if ((index == widget.messages.length - 1))
                          TextButton(
                            onPressed: widget.regenerateLatestQuestion,
                            child: const Text("重新生成"),
                          ),

                        IconButton(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: msg.content),
                            );
                            EasyLoading.showToast(
                              "已复制到剪贴板",
                              duration: const Duration(seconds: 3),
                              toastPosition: EasyLoadingToastPosition.center,
                            );
                          },
                          icon: const Icon(Icons.copy),
                        ),

                        // 保存最后一条对话和图片(2024-08-13 目前就拍照翻译会用到)
                        if (widget.selectedImage != null)
                          buildDLPopupMenuButton(),

                        SizedBox(width: 10.sp),

                        /// 如果不是等待响应才显示token数量
                        /// 2024-07-24 如果是特别大字模式，token就不显示了，可能会溢出
                        if (_textScaleFactor <= 1.6)
                          Text(
                            "token总计: ${msg.totalTokens}\n 输入: ${msg.promptTokens} 输出: ${msg.completionTokens}",
                            style: TextStyle(fontSize: 10.sp),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        SizedBox(width: 10.sp),
                      ],
                    )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // 保存最后一条对话和图片(2024-08-13 目前就拍照翻译会用到)
  buildDLPopupMenuButton() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.download_outlined, size: 20.sp),
      // 调整弹出按钮的位置
      position: PopupMenuPosition.under,
      offset: Offset(25.sp, 0),
      onSelected: (String value) async {
        // 处理选中的菜单项
        // 之前还有个预览页面，现在直接保存了
        if (value == 'txt') {
          saveMarkdownAsTxt(widget.messages.last.content);
        } else if (value == 'pdf') {
          saveMarkdownHtmlAsPdf(
            widget.messages.last.content,
            widget.selectedImage!,
          );
        } else {
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => SaveMarkdownToPdf(
          //       messages.last.content,
          //       imageFile: _selectedImage!,
          //     ),
          //   ),
          // );
          saveMarkdownAsPdf(
            widget.messages.last.content,
            widget.selectedImage!,
          );
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
        const PopupMenuItem(value: 'txt', child: Text('保存为txt')),
        const PopupMenuItem(value: 'pdf', child: Text('保存为pdf')),
        const PopupMenuItem(value: 'pdf-test', child: Text('保存为pdf(测试)')),
      ],
    );
  }
}
