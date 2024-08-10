// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../apis/chat_completion/common_cc_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/constants.dart';
import '../../../../common/llm_spec/cc_spec.dart';
import '../../../../models/chat_competion/com_cc_resp.dart';
import '../../../../models/chat_competion/com_cc_state.dart';
import '../../_chat_screen_parts/chat_list_area.dart';
import '../../_componets/message_item.dart';
import '../../_helper/save_markdown_as_pdf.dart';
import '../../_helper/save_markdown_as_txt.dart';
import '../../_helper/save_markdown_html_as_pdf.dart';

///
/// 2027-07-17 粗略布局
/// 最上方显示左边显示拍照后或者上传的图片预览，点击可放大；右边是“拍照”、“上传”按钮
/// 紧接着是目标语言切换选择按钮，和“翻译”确认按钮
/// 中间是AI识别出的文本内容
/// 下面是AI翻译的内容
///
/// 过程中可以考虑喝后续长文本翻译，然后下载下来做复用
///
class PhotoTranslation extends StatefulWidget {
  const PhotoTranslation({super.key});

  @override
  State<PhotoTranslation> createState() => _PhotoTranslationState();
}

class _PhotoTranslationState extends State<PhotoTranslation> {
  final ScrollController _scrollController = ScrollController();

  // AI是否在思考中(如果是，则不允许再次发送)
  bool isBotThinking = false;

// 用于存储选中的图片文件
  File? _selectedImage;

  // 假设的对话数据
  List<ChatMessage> messages = [];

  // 等待AI响应时的占位的消息，在构建真实对话的list时要删除
  var placeholderMessage = ChatMessage(
    messageId: "placeholderMessage",
    role: "assistant",
    content: "正在处理中，请稍候  ",
    dateTime: DateTime.now(),
    isPlaceholder: true,
  );

  // 默认的要翻译成什么语言
  TargetLanguage targetLang = TargetLanguage.simplifiedChinese;

  // 默认的图像识别指令(这里是翻译，就暂时只有翻译)
  List<String> defaultCmds = [
    "1. 打印图片中的原文文字;\n2. 将图片中文字翻译成",
    "分析图中存在那些元素，表现了什么内容。"
  ];

  // 保存时可选择某些格式
  String selectedDLOption = 'TXT';

  // 当前正在响应的api返回流(放在全局为了可以手动取消)
  StreamWithCancel<ComCCResp>? respStream;

  ///
  /// =======================================
  ///
  // 选择图片来源
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    print("选中的图片---------$pickedFile");

    if (pickedFile != null) {
      setState(() {
        // 重新选择了图片，就要清空之前的对话列表(如果有打开选文件框但没有选择任何图片，则无动作)
        messages.clear();
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  /// 给对话列表添加对话信息
  userSendMessage(String text) {
    setState(() {
      // 发送消息的逻辑，这里只是简单地将消息添加到列表中
      messages.add(ChatMessage(
        messageId: const Uuid().v4(),
        dateTime: DateTime.now(),
        content: text,
        role: "user",
        promptTokens: 0,
        completionTokens: 0,
        totalTokens: 0,
      ));

      // AI思考和用户输入是相反的(如果用户输入了，就是在等到机器回答了)
      isBotThinking = true;

      // [2024-07-17暂时不做] 注意，在每次添加了对话之后，都把整个对话列表存入对话历史中去
      // 当然，要在占位消息之前

      // 滚动到ListView的底部
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 300),
      );

      // 如果是用户发送了消息，则开始等到AI响应(如果不是用户提问，则不会去调用接口)

      // 如果是用户输入时，在列表中添加一个占位的消息，以便思考时的装圈和已加载的消息可以放到同一个list进行滑动
      // 一定注意要记得AI响应后要删除此占位的消息
      placeholderMessage.dateTime = DateTime.now();
      messages.add(placeholderMessage);

      // 用户发送之后，等待AI响应
      _getVsionLLMResponse();
    });
  }

  // 图像识别目前使用零一大模型的v-sion实现
  _getVsionLLMResponse() async {
    // 将已有的消息处理成大模型的消息列表格式(构建查询条件时要删除占位的消息)
    // 2024-07-17 在翻译功能时只有3个发送消息：
    //  1 用户点了“翻译按钮”或者“重新翻译”，2 等待占位 3 AI大模型/模拟大模型报错返回数据
    //    其中1和2不会同时存在，所以这个消息列表只有2条
    List<CCMessage> msgs = messages
        .where((e) => e.isPlaceholder != true)
        .map((e) => CCMessage(
              content: e.content,
              role: e.role,
            ))
        .toList();

    // 如果请求是没有图片，模拟模型返回异常信息(理论上能点击翻译按钮不会出现这个)
    if (_selectedImage == null) {
      setState(() {
        isBotThinking = false;
        messages.removeWhere((e) => e.isPlaceholder == true);
        messages.add(ChatMessage(
          messageId: const Uuid().v4(),
          role: "assistant",
          content: "图片数据异常",
          dateTime: DateTime.now(),
        ));
      });

      return;
    }

    // 可能会出现不存在的图片路径，那边这里转base64就会报错，那么就弹窗提示一下
    try {
      var tempBase64Str = base64Encode((await _selectedImage!.readAsBytes()));
      var imageBase64String = "data:image/jpeg;base64,$tempBase64Str";

      // yi-vision 暂不支持设置系统消息。
      msgs = messages
          .where((e) => e.isPlaceholder != true)
          .map((e) => CCMessage(
                content: (e.role == "assistant")
                    ? e.content
                    // 2024-07-12 这里就不使用VisionContent，直接拼接json
                    : jsonEncode([
                        {
                          "type": "image_url",
                          "image_url": {"url": imageBase64String}
                        },
                        {"type": "text", "text": e.content},
                      ]),
                role: e.role,
              ))
          .toList();

      // 在请求前创建当前响应的消息和文本内容，当前请求完之后，就重置为空
      // csMsg => currentStreamingMessage
      ChatMessage? csMsg;
      final StringBuffer messageBuffer = StringBuffer();

      StreamWithCancel<ComCCResp> tempStream =
          await lingyiwanwuCCRespWithCancel(
        msgs,
        model: CCM_SPEC_LIST.firstWhere((e) => e.ccm == CCM.YiVision).model,
        stream: true,
      );

      if (!mounted) return;
      setState(() {
        respStream = tempStream;
      });

      // 上面赋值了，这里应该可以监听到新的流了
      respStream?.stream.listen(
        (crb) {
          // 得到回复后要删除表示加载中的占位消息
          if (!mounted) return;
          setState(() {
            messages.removeWhere((e) => e.isPlaceholder == true);
          });

          // 当前响应流处理完了，就不是AI响应中了
          if (crb.cusText == '[DONE]') {
            if (!mounted) return;
            setState(() {
              csMsg = null;
              isBotThinking = false;
            });
          } else {
            setState(() {
              isBotThinking = true;
              messageBuffer.write(crb.cusText);
              // 只有第一次响应时才创建消息体，后续接收的响应流数据只更新当前的
              if (csMsg == null) {
                csMsg = ChatMessage(
                  messageId: const Uuid().v4(),
                  role: "assistant",
                  content: messageBuffer.toString(),
                  contentVoicePath: "",
                  dateTime: DateTime.now(),
                  promptTokens: crb.usage?.promptTokens ?? 0,
                  completionTokens: crb.usage?.completionTokens ?? 0,
                  totalTokens: crb.usage?.totalTokens ?? 0,
                );

                messages.add(csMsg!);
              } else {
                csMsg!.content = messageBuffer.toString();
                // token的使用就是每条返回的就是当前使用的结果，所以最后一条就是最终结果，实时更新到最后一条
                csMsg!.promptTokens = crb.usage?.promptTokens ?? 0;
                csMsg!.completionTokens = crb.usage?.completionTokens ?? 0;
                csMsg!.totalTokens = (crb.usage?.totalTokens ?? 0);
              }
            });
          }
        },
        // 非流式的时候，只有一条数据，永远不会触发上面监听时的DONE的情况
        onDone: () {
          if (!mounted) return;
          setState(() {
            csMsg = null;
            isBotThinking = false;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, "异常提示", e.toString());
    }
  }

  /// 如果对结果不满意，可以重新翻译
  regenerateLatestQuestion() {
    setState(() {
      // 将最后一条消息删除，并添加占位消息，重新发送
      messages.removeLast();
      placeholderMessage.dateTime = DateTime.now();
      messages.add(placeholderMessage);

      _getVsionLLMResponse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('拍照翻译'),
      ),
      body: GestureDetector(
        // 允许子控件（如TextField）接收点击事件
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // 点击空白处可以移除焦点，关闭键盘
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            /// 构建图片选择和预览行 (高度100)
            buildImagePickAndViewRow(),
            const Divider(),

            /// 切换目标翻译语言和确认翻译的行 (高度40)
            buildChangeLangAndConfirmRow(),
            const Divider(),

            /// 显示对话消息主体
            ChatListArea(
              messages: messages,
              scrollController: _scrollController,
              isBotThinking: isBotThinking,
              regenerateLatestQuestion: regenerateLatestQuestion,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建图片选择和预览行
  buildImagePickAndViewRow() {
    return SizedBox(
      height: 100.sp,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 5.sp),
          // 图片预览
          Expanded(
            flex: 3,
            // 图片显示限定个高度，避免压缩下发正文内容
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1.0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: buildImageView(_selectedImage, context),
            ),
          ),

          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    commonHintDialog(
                      context,
                      "说明",
                      "1. 点击图片可预览、缩放\n2. 支持 JPEG/PNG 格式\n3. 图片最大支持 2048*1080\n4. base64编码后大小不超过4M\n5. 图片越大，处理耗时越久",
                      msgFontSize: 15.sp,
                    );
                  },
                  child: const Text("提示"),
                ),
                TextButton(
                  onPressed: _selectedImage != null
                      ? () {
                          setState(() {
                            _selectedImage = null;
                            messages.clear();
                          });
                        }
                      : null,
                  child: const Text("清除"),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.all(5.sp),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.sp),
                    ),
                  ),
                  onPressed: () {
                    _pickImage(ImageSource.camera);
                  },
                  child: const Text("拍照"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.all(5.sp),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.sp),
                    ),
                  ),
                  onPressed: () {
                    _pickImage(ImageSource.gallery);
                  },
                  child: const Text("上传"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 切换目标翻译语言和确认翻译的行
  buildChangeLangAndConfirmRow() {
    return SizedBox(
      height: 32.sp,
      // 下拉框有个边框，需要放在容器中
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(width: 5.sp),
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1.0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Icon(Icons.swap_vert),
                  DropdownButton<TargetLanguage?>(
                    value: targetLang,
                    // isDense: true,
                    underline: Container(),
                    alignment: AlignmentDirectional.center,
                    menuMaxHeight: 300.sp,
                    items: TargetLanguage.values
                        .map((e) => DropdownMenuItem<TargetLanguage>(
                              value: e,
                              alignment: AlignmentDirectional.center,
                              child: Text(
                                langLabel[e]!,
                                style: const TextStyle(color: Colors.blue),
                              ),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        targetLang = val!;
                        // 2024-06-15 切换模型应该新建对话，因为上下文丢失了。
                        messages.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    // minimumSize: Size.zero,
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.sp, vertical: 5.sp),
                    // 修改圆角大小
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.sp),
                    ),
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                  ),
                  // 如果没有选中图片或AI正在响应，则不让点击发送
                  onPressed: isBotThinking || _selectedImage == null
                      ? null
                      : () {
                          // 在当前上下文中查找最近的 FocusScope 并使其失去焦点，从而收起键盘。
                          FocusScope.of(context).unfocus();

                          // 2024-07-17 翻译图片不进行多轮对话，每次点翻译按钮，都重构对话
                          setState(() {
                            messages.clear();
                          });

                          // 用户发送消息
                          userSendMessage(
                            "${defaultCmds[0]}${langLabel[targetLang]!}.",
                          );
                        },
                  child: const Text(
                    "翻译",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建对话主体内容
  buildChatListArea() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        // 构建MessageItem
        return Padding(
          padding: EdgeInsets.all(5.sp),
          child: Column(
            children: [
              MessageItem(message: messages[index]),
              // 如果是大模型回复，可以有一些功能按钮
              if (messages[index].role == "assistant")
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 最左边空一个图像的大小
                    SizedBox(width: 39.sp), // 18*2+3
                    // 其中，是大模型最后一条回复，则可以重新生成
                    // 注意，还要排除占位消息
                    if ((index == messages.length - 1) &&
                        messages[index].isPlaceholder != true) ...[
                      TextButton(
                        onPressed: () {
                          regenerateLatestQuestion();
                        },
                        child: const Text("重新翻译"),
                      ),
                      // 点击复制该条回复
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: messages[index].content),
                          );

                          EasyLoading.showToast(
                            "已复制到剪贴板",
                            duration: const Duration(seconds: 3),
                            toastPosition: EasyLoadingToastPosition.center,
                          );
                        },
                        icon: Icon(Icons.copy, size: 20.sp),
                      ),
                      // 点击下载翻译结果
                      buildDLPopupMenuButton(),

                      // // 其他功能(占位)
                      // IconButton(
                      //   onPressed: null,
                      //   icon: Icon(Icons.thumb_down_outlined, size: 20.sp),
                      // ),
                      SizedBox(width: 10.sp),
                      // 如果不是等待响应才显示token数量
                      Expanded(
                        child: Text(
                          "tokens 总计: ${messages[index].totalTokens}\n输入: ${messages[index].promptTokens} 输出: ${messages[index].completionTokens}",
                          style: TextStyle(fontSize: 10.sp),
                          maxLines: 2,
                        ),
                      ),
                    ],
                    SizedBox(width: 10.sp),
                  ],
                )
            ],
          ),
        );
      },
    );
  }

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
          saveMarkdownAsTxt(messages.last.content);
        } else if (value == 'pdf') {
          saveMarkdownHtmlAsPdf(messages.last.content, _selectedImage!);
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
          saveMarkdownAsPdf(messages.last.content, _selectedImage!);
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
