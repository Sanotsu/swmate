// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
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
import '../../_helper/handle_cc_response.dart';
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

  // 是否流式响应(暂时时固定为true)
  bool isStream = true;

// 用于存储选中的图片文件
  File? _selectedImage;

  // 假设的对话数据
  List<ChatMessage> messages = [];

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
  StreamWithCancel<ComCCResp> respStream = StreamWithCancel.empty();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 在用户输入或者AI响应后，需要把对话列表滚动到最下面
  // 调用时放在状态改变函数中
  chatListScrollToBottom() {
    // 每收到一点新的响应文本，就都滚动到ListView的底部
    // 注意：ai响应的消息卡片下方还有一行功能按钮，这里滚动了那个还没显示的话是看不到的
    // 所以滚动到最大还加一点高度（大于实际功能按钮高度也没问题）
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 80,
      curve: Curves.easeOut,
      // 注意：sse的间隔比较短，这个滚动也要快一点
      duration: const Duration(milliseconds: 50),
    );
  }

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
      chatListScrollToBottom();

      // 用户发送之后，等待AI响应
      _getVsionLLMResponse();
    });
  }

  // 处理图像理解
  // 图像识别目前使用零一大模型的v-sion实现
  _getVsionLLMResponse() async {
    StreamWithCancel<ComCCResp> tempStream = await getCCResponseSWC(
      messages: messages,
      selectedPlatform: ApiPlatform.lingyiwanwu,
      selectedModel:
          CCM_SPEC_LIST.firstWhere((e) => e.ccm == CCM.YiVision).model,
      isVision: true,
      isStream: isStream,
      selectedImage: _selectedImage,
      onNotImageHint: (error) {
        commonExceptionDialog(context, "异常提示", error);
      },
      onImageError: (error) {
        commonExceptionDialog(context, "异常提示", error);
      },
    );

    if (!mounted) return;
    setState(() {
      respStream = tempStream;
    });

    // 在得到响应后，就直接把响应的消息加入对话列表
    // 又因为是流式的,所有需要在有更新的数据时,更新响应消息体
    // csMsg => currentStreamingMessage
    ChatMessage? csMsg = buildEmptyAssistantChatMessage();
    setState(() {
      messages.add(csMsg!);
    });

    handleCCResponseSWC(
      swc: respStream,
      onData: (crb) {
        commonOnDataHandler(
          crb: crb,
          csMsg: csMsg!,
          // 流式响应结束了，就保存数据到db，并重置流式变量和aip响应标志
          onStreamDone: () {
            if (!mounted) return;
            setState(() {
              csMsg = null;
              isBotThinking = false;
            });
          },
          // 处理流的过程中都是响应中
          // (如果不设置这个，就没办法促使SSE每有一个推送都及时更新页面了)
          setIsResponsing: () {
            setState(() {
              isBotThinking = true;
            });
          },
          scrollToBottom: chatListScrollToBottom,
        );
      },
      onDone: () {
        print("文本对话 监听的【onDone】触发了");
        // 如果是流式响应，最后一条会带有[DNOE]关键字，所以在上面处理最后响应结束的操作
        // 非流式的时候，只有一条数据，永远不会触发上面ondata监听时得到DONE的情况
        // 但是如果是流式，还在这里处理结束操作的话会出问题(实测在数据还在推送的时候，这个ondone就触发了)
        if (!isStream) {
          if (!mounted) return;
          // 流式响应结束了，就保存数据到db，并重置流式变量和aip响应标志
          setState(() {
            csMsg = null;
            isBotThinking = false;
          });
        }
      },
      onError: (error) {
        commonExceptionDialog(context, "异常提示", error.toString());
      },
    );
  }

  /// 如果对结果不满意，可以重新翻译
  regenerateLatestQuestion() {
    setState(() {
      // 将最后一条消息删除， 重新发送
      messages.removeLast();
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
              isAvatarTop: true,
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
                    "AI翻译",
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
