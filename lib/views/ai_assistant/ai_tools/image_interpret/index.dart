// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../../../apis/chat_completion/common_cc_apis.dart';
import '../../../../apis/voice_recognition/xunfei_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/constants.dart';
import '../../../../common/llm_spec/cc_spec.dart';
import '../../../../models/chat_competion/com_cc_resp.dart';
import '../../../../models/chat_competion/com_cc_state.dart';
import '../../_chat_screen_parts/chat_list_area.dart';
import '../../_chat_screen_parts/chat_user_send_area_with_voice.dart';
import '../../_chat_screen_parts/default_agent_button_row.dart';
import '../../_componets/cus_toggle_button_selector.dart';
import '../../_componets/sounds_message_button/utils/sounds_recorder_controller.dart';
import '../../_helper/handle_cc_response.dart';
import '../document_interpret/index.dart';

const imgHintInfo = """1. 点击图片可预览、缩放
\n\n2. 支持 JPEG/PNG 格式
\n\n3. 图片最大支持 2048*1080
\n\n4. base64编码后大小不超过4M
\n\n5. 图片越大，处理耗时越久.""";

const docHintInfo = """1. 点击图片可预览、缩放
\n\n2. 支持 JPEG/PNG 格式
\n\n3. 图片最大支持 2048*1080
\n\n4. base64编码后大小不超过4M
\n\n5. 图片越大，处理耗时越久.""";

///
/// 2024-08-13 原本的拍照翻译，改动之后和智能对话结构差不多了，只不过一个支持图片上传
/// 同样的，和文档解读也差不多了，只不过一个支持文档上传，但只会显示一条响应结果
///
class ImageInterpret extends StatefulWidget {
  const ImageInterpret({super.key});

  @override
  State<ImageInterpret> createState() => _ImageInterpretState();
}

class _ImageInterpretState extends State<ImageInterpret> {
  final ScrollController _scrollController = ScrollController();

  // 用户输入的文本控制器
  final TextEditingController _userInputController = TextEditingController();
  // 用户输入的内容（当不是AI在思考、且输入框有非空文字时才可以点击发送按钮）
  String userInput = "";

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
    "总结图片的内容，生成摘要。",
  ];

  // 当前正在响应的api返回流(放在全局为了可以手动取消)
  StreamWithCancel<ComCCResp> respStream = StreamWithCancel.empty();

  // 预设的文档解读的功能列表
  var items = [
    CusAgentSpec(
      label: "翻译",
      name: CusAgent.img_translator,
      hintInfo: imgHintInfo,
      systemPrompt: """你是一个图片分析处理专家，你将识别出图中的所有文字，并对这些文字进行精准翻译。
      只做翻译工作，无其他行为。
      如果图片中存在多种语言的文本，统一翻译成目标语言。
      如果用户指定了翻译的目标语言，则翻译成该目标语言；如果目标语言和原版语言一致，则不做翻译直接输出原版语言。
      如果没有指定翻译的目标语言，那么默认翻译成简体中文；如果已经是简体中文了，则翻译成英文。
      翻译完成之后单独解释重难点词汇。
      如果翻译后内容很多，需要分段显示。""",
    ),
    CusAgentSpec(
      label: "总结",
      name: CusAgent.img_summarizer,
      hintInfo: imgHintInfo,
      systemPrompt: """你是一个图片分析处理专家，你将认真、准确地分析图片，总结图片的内容，生成摘要。""",
    ),
    CusAgentSpec(
      label: "分析",
      name: CusAgent.img_analyzer,
      hintInfo: imgHintInfo,
      systemPrompt: """你是一个图片分析处理专家，你将认真、准确地分析图片，并基于图片的内容，回答用户输入的各种问题。""",
    ),
  ];

  // 当前选中的文档功能
  late CusAgentSpec selectAgent;

  @override
  void initState() {
    super.initState();

    setState(() {
      selectAgent = items.first;
      renewSystemAndMessages();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _userInputController.dispose();
    super.dispose();
  }

  // 切换预设功能时，需要改变system设置，且清空对话
  renewSystemAndMessages() {
    setState(() {
      messages.clear();
      messages.add(
        ChatMessage(
          messageId: const Uuid().v4(),
          role: "system",
          content: selectAgent.systemPrompt,
          dateTime: DateTime.now(),
        ),
      );
    });
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
        renewSystemAndMessages();
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  /// 给对话列表添加对话信息
  userSendMessage(
    String text, {
    // 2024-08-07 可能text是语音转的文字，保留语音文件路径
    String? contentVoicePath,
  }) {
    setState(() {
      // 发送消息的逻辑，这里只是简单地将消息添加到列表中
      messages.add(
        ChatMessage(
          messageId: const Uuid().v4(),
          role: "user",
          content: text,
          // 没有录音文件就存空字符串，避免内部转化为“null”字符串
          contentVoicePath: contentVoicePath ?? "",
          dateTime: DateTime.now(),
        ),
      );

      _userInputController.clear();
      // 滚动到ListView的底部
      chatListScrollToBottom();

      // 用户发送之后，等待AI响应
      _getVsionLLMResponse();
    });
  }

  // 处理图像理解
  // 图像识别目前使用零一大模型的v-sion实现
  _getVsionLLMResponse() async {
    // 在调用前，不会设置响应状态
    if (isBotThinking) return;
    setState(() {
      isBotThinking = true;
    });

    print("----------${messages.length}");
    for (var e in messages) {
      print(e.content);
    }

    print("----------${messages.length}");

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
        title: const Text('图片解读'),
        actions: [
          IconButton(
            onPressed: () {
              commonMarkdwonHintDialog(
                context,
                '温馨提示',
                selectAgent.hintInfo,
                msgFontSize: 15.sp,
              );
            },
            icon: const Icon(Icons.help),
          ),
        ],
      ),
      body: GestureDetector(
        // 允许子控件（如TextField）接收点击事件
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // 点击空白处可以移除焦点，关闭键盘
          FocusScope.of(context).unfocus();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CusToggleButtonSelector<CusAgentSpec>(
                    items: items,
                    onItemSelected: (item) {
                      print('Selected item: ${item.label}');
                      setState(() {
                        selectAgent = item;
                      });
                      renewSystemAndMessages();
                    },
                    labelBuilder: (item) => item.label,
                  ),
                  SizedBox(width: 5.sp),
                ],
              ),
            ),
            const Divider(),

            /// 构建图片选择和预览行 (高度100)
            buildImagePickAndViewRow(),
            const Divider(),

            /// 如果选择的是“翻译图片”功能，才显示这个翻译功能行
            /// 切换目标翻译语言和确认翻译的行 (高度40)
            if (selectAgent.name == CusAgent.img_translator)
              DefaultAgentButtonRow(
                cusAgent: selectAgent.name,
                targetLang: targetLang,
                langLabel: langLabel,
                onLanguageChanged: (newLang) {
                  setState(() {
                    targetLang = newLang;
                    renewSystemAndMessages();
                  });
                },
                isConfirmClickable: !(isBotThinking || _selectedImage == null),
                onConfirmPressed: () {
                  setState(() {
                    renewSystemAndMessages();
                  });
                  userSendMessage("${defaultCmds[0]}${langLabel[targetLang]}.");
                },
                labelKeyword: isBotThinking ? "AI翻译中" : "AI翻译",
              ),
            if (selectAgent.name == CusAgent.img_summarizer)
              DefaultAgentButtonRow(
                cusAgent: selectAgent.name,
                targetLang: targetLang,
                langLabel: langLabel,
                onLanguageChanged: (newLang) {
                  setState(() {
                    targetLang = newLang;
                    renewSystemAndMessages();
                  });
                },
                isConfirmClickable: !(isBotThinking || _selectedImage == null),
                onConfirmPressed: () {
                  setState(() {
                    renewSystemAndMessages();
                  });
                  userSendMessage("${defaultCmds[1]}${langLabel[targetLang]}.");
                },
                labelKeyword: isBotThinking ? "AI总结中" : "AI总结",
              ),

            /// 显示对话消息主体
            /// 如果不想显示system信息，这里可以移除掉(但不能修改原消息列表)
            ChatListArea(
              messages: messages.where((e) => e.role != "system").toList(),
              scrollController: _scrollController,
              isBotThinking: isBotThinking,
              isAvatarTop: true,
              regenerateLatestQuestion: regenerateLatestQuestion,
              selectedImage: _selectedImage,
            ),

            /// 如果选择的是“分析图片”功能，才显示这个提问输入框
            /// 用户发送区域
            if (selectAgent.name == CusAgent.img_analyzer)
              ChatUserVoiceSendArea(
                controller: _userInputController,
                hintText: '询问关于上面图片的任何问题',
                isBotThinking: isBotThinking,
                isSendClickable: userInput.isNotEmpty && _selectedImage != null,
                onInpuChanged: (text) {
                  setState(() {
                    userInput = text.trim();
                  });
                },
                // onSendPressed 和 onSendSounds 理论上不会都触发的
                onSendPressed: () {
                  userSendMessage(userInput);
                  setState(() {
                    userInput = "";
                  });
                },
                // 点击了语音发送，可能是文件，也可能是语音转的文字
                onSendSounds: (type, content) async {
                  print("语音发送的玩意儿 $type $content");

                  if (type == SendContentType.text) {
                    userSendMessage(content);
                  } else if (type == SendContentType.voice) {
                    //

                    /// 同一份语言有两个部分，一个是原始录制的m4a的格式，一个是转码厚的pcm格式
                    /// 前者用于语音识别，后者用于播放
                    String fullPathWithoutExtension = path.join(
                      path.dirname(content),
                      path.basenameWithoutExtension(content),
                    );

                    var transcription = await sendAudioToServer(
                        "$fullPathWithoutExtension.pcm");
                    // 注意：语言转换文本必须pcm格式，但是需要点击播放的语音则需要原本的m4a格式
                    // 都在同一个目录下同一路径不同扩展名
                    userSendMessage(
                      transcription,
                      // contentVoicePath: "$fullPathWithoutExtension.m4a",
                    );
                  }
                },
                // 2024-08-08 手动点击了终止
                onStop: () async {
                  await respStream.cancel();
                  if (!mounted) return;
                  setState(() {
                    _userInputController.clear();
                    // 滚动到ListView的底部
                    chatListScrollToBottom();

                    isBotThinking = false;
                  });
                },
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
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(80, 36.sp),
                    padding: EdgeInsets.symmetric(horizontal: 0.sp),
                    // 修改圆角大小
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.sp),
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(
                            "选择图片来源",
                            style: TextStyle(fontSize: 18.sp),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _pickImage(ImageSource.camera);
                              },
                              child: Text(
                                "拍照",
                                style: TextStyle(fontSize: 16.sp),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _pickImage(ImageSource.gallery);
                              },
                              child: Text(
                                "从相册选择",
                                style: TextStyle(fontSize: 16.sp),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text("选择图片"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(80, 36.sp),
                    padding: EdgeInsets.all(0.sp),
                    // 修改圆角大小
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.sp),
                    ),
                  ),
                  onPressed: _selectedImage != null
                      ? () {
                          setState(() {
                            _selectedImage = null;
                            renewSystemAndMessages();
                          });
                        }
                      : null,
                  child: const Text("清除图片"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
