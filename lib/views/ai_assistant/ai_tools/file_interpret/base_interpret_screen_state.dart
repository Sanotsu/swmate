// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../../../apis/chat_completion/common_cc_apis.dart';
import '../../../../apis/voice_recognition/xunfei_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/constants.dart';
import '../../../../common/llm_spec/cus_llm_spec.dart';
import '../../../../models/chat_competion/com_cc_resp.dart';
import '../../../../models/chat_competion/com_cc_state.dart';
import '../../_chat_screen_parts/chat_list_area.dart';
import '../../_chat_screen_parts/chat_user_send_area_with_voice.dart';
import '../../_chat_screen_parts/default_agent_button_row.dart';
import '../../_componets/cus_toggle_button_selector.dart';
import '../../_componets/sounds_message_button/utils/sounds_recorder_controller.dart';
import '../../_helper/constants.dart';
import '../../_helper/handle_cc_response.dart';

abstract class BaseInterpretState<T extends StatefulWidget> extends State<T> {
  ///
  /// 手动输入文本 相关变量
  ///
  final TextEditingController userInputController = TextEditingController();
  String userInput = "";

  ///
  /// 请求状态和配置相关
  ///
  bool isBotThinking = false;
  bool isStream = true;
  List<ChatMessage> messages = [];
  final ScrollController scrollController = ScrollController();
  StreamWithCancel<ComCCResp> respStream = StreamWithCancel.empty();
  TargetLanguage targetLang = TargetLanguage.simplifiedChinese;

  // 默认的图像识别指令(这里是翻译，就暂时只有翻译)
  List<String> defaultCmds = [
    "1. 打印图片中的原文文字;\n2. 将图片中文字翻译成",
    "总结图片中的内容，生成摘要。输出的摘要的目标语言是",
    "请将上面所有文本翻译为",
    "总结上面文档内容，给出摘要。输出的摘要的目标语言是",
  ];

  @override
  void dispose() {
    scrollController.dispose();
    userInputController.dispose();
    super.dispose();
  }

  ///
  /// 切换预设功能时，先清空对话，再改变system设置，然后把system设置存入对话列表
  ///
  String getSystemPrompt();

  void renewSystemAndMessages() {
    setState(() {
      messages.clear();
      messages.add(
        ChatMessage(
          messageId: const Uuid().v4(),
          role: "system",
          content: getSystemPrompt(),
          dateTime: DateTime.now(),
        ),
      );
    });
  }

  ///
  /// 在用户输入或者AI响应后，需要把对话列表滚动到最下面
  ///
  void chatListScrollToBottom() {
    scrollController.animateTo(
      scrollController.position.maxScrollExtent + 80,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 50),
    );
  }

  ///
  /// 文档解读、图片解读的用户发送消息
  /// 用户发送消息的操作是一样的：将消息存入对话列表、滚动到底部、调用AI响应
  ///
  void userSendMessage(
    String text, {
    String? contentVoicePath,
  }) {
    setState(() {
      messages.add(
        ChatMessage(
          messageId: const Uuid().v4(),
          role: "user",
          content: text,
          contentVoicePath: contentVoicePath ?? "",
          dateTime: DateTime.now(),
        ),
      );
      userInputController.clear();
      chatListScrollToBottom();
      getProcessedResult();
    });
  }

  ///
  /// 获取AI响应
  /// 获取AI响应略有不同，需要子类传入平台和模型、是图片还是文件
  ///
  ApiPlatform getSelectedPlatform();
  String getSelectedModel();
  CC_SWC_TYPE getUseType();
  String getDocContent();
  File? getSelectedImage();

  Future<void> getProcessedResult() async {
    if (isBotThinking) return;
    setState(() {
      isBotThinking = true;
    });

    StreamWithCancel<ComCCResp> tempStream = await getCCResponseSWC(
      messages: messages,
      selectedPlatform: getSelectedPlatform(),
      selectedModel: getSelectedModel(),
      isStream: isStream,
      useType: getUseType(),
      selectedImage: getSelectedImage(),
      docContent: getDocContent(),
      onNotImageHint: (error) {
        commonExceptionDialog(context, "异常提示", error);
      },
      onImageError: (error) {
        commonExceptionDialog(context, "异常提示", error);
      },
      onNotDocHint: (error) {
        commonExceptionDialog(context, "异常提示", error);
      },
    );

    if (!mounted) return;
    setState(() {
      respStream = tempStream;
    });

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
          onStreamDone: () {
            if (!mounted) return;
            setState(() {
              csMsg = null;
              isBotThinking = false;
            });
          },
          setIsResponsing: () {
            setState(() {
              isBotThinking = true;
            });
          },
          scrollToBottom: chatListScrollToBottom,
        );
      },
      onDone: () {
        if (!isStream) {
          if (!mounted) return;
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
  void regenerateLatestQuestion() {
    setState(() {
      messages.removeLast();
      getProcessedResult();
    });
  }

  ///
  /// 构建页面公共的UI部分
  ///
  // 用于构建预设功能的智能体信息列表
  List<CusAgentSpec> getItems();
  // 预设功能列表切换时要更新当前选中的智能体信息
  void setSelectedAgent(CusAgentSpec item);
  // 当前选中的智能体名称
  CusAgent getSelectedAgentName();

  // 是否可以点击发送按钮
  bool getIsSendClickable();

  // 构建选择文档或者图片的文件选择区域
  Widget buildSelectionArea(BuildContext context);

  // 构建页面主体的UI
  Widget buildCommonUI(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        /// 可切换的预设功能
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CusToggleButtonSelector<CusAgentSpec>(
                items: getItems(),
                onItemSelected: (item) {
                  print('Selected item: ${item.label}');
                  setState(() {
                    setSelectedAgent(item);
                  });
                  renewSystemAndMessages();
                },
                labelBuilder: (item) => item.label,
              ),
              SizedBox(width: 5.sp),
            ],
          ),
        ),

        /// 自定义的选择组件(文档解析是上传文档框，图片解读是图片选择框)
        SizedBox(height: 5.sp),
        buildSelectionArea(context),
        SizedBox(height: 10.sp),

        /// 根据“文档解读”、“图片解读”不同，选中的预设功能不同，显示不同的按钮
        buildDefaultAgentButtonRow(context),
        Divider(height: 10.sp),

        /// 对话列表区域
        ChatListArea(
          /// 如果不想显示system信息，这里可以移除掉(但不能修改原消息列表)
          // messages: messages,
          messages: messages.where((e) => e.role != "system").toList(),
          scrollController: scrollController,
          isBotThinking: isBotThinking,
          isAvatarTop: true,
          regenerateLatestQuestion: regenerateLatestQuestion,
          selectedImage: getSelectedImage(),
        ),

        /// 如果指定的是“文档分析”或图片分析，还可以(文字或语音输入)多轮提问
        if (getSelectedAgentName() == CusAgent.doc_analyzer ||
            getSelectedAgentName() == CusAgent.img_analyzer)
          ChatUserVoiceSendArea(
            controller: userInputController,
            hintText: '询问关于选中文件的任何问题',
            isBotThinking: isBotThinking,
            isSendClickable: getIsSendClickable() && userInput.isNotEmpty,
            onInpuChanged: (text) {
              setState(() {
                userInput = text.trim();
              });
            },
            onSendPressed: () {
              userSendMessage(userInput);
              setState(() {
                userInput = "";
              });
            },
            onSendSounds: (type, content) async {
              if (type == SendContentType.text) {
                // 如果输入的是语音转换后的文字，直接发送文字
                userSendMessage(content);
              } else if (type == SendContentType.voice) {
                // 如果直接输入的语音，要显示转换后的文本，也要保留语音文件
                String tempPath = path.join(
                  path.dirname(content),
                  path.basenameWithoutExtension(content),
                );

                var transcription = await sendAudioToServer("$tempPath.pcm");
                userSendMessage(
                  transcription,
                  contentVoicePath: "$tempPath.m4a",
                );
              }
            },
            onStop: () async {
              await respStream.cancel();
              if (!mounted) return;
              setState(() {
                userInputController.clear();
                chatListScrollToBottom();
                isBotThinking = false;
              });
            },
          ),
      ],
    );
  }

  Widget buildDefaultAgentButtonRow(BuildContext context) {
    if (getSelectedAgentName() == CusAgent.img_translator) {
      return DefaultAgentButtonRow(
        isShowLanguageSwitch: true,
        targetLang: targetLang,
        langLabel: LangLabelMap,
        onLanguageChanged: (newLang) {
          setState(() {
            targetLang = newLang;
            renewSystemAndMessages();
          });
        },
        isConfirmClickable: !(isBotThinking || getSelectedImage() == null),
        onConfirmPressed: () {
          setState(() {
            renewSystemAndMessages();
          });
          userSendMessage("${defaultCmds[0]}${LangLabelMap[targetLang]}.");
        },
        labelKeyword: isBotThinking ? "AI翻译中…" : "AI翻译",
      );
    } else if (getSelectedAgentName() == CusAgent.img_summarizer) {
      return DefaultAgentButtonRow(
        isShowLanguageSwitch: true,
        targetLang: targetLang,
        langLabel: LangLabelMap,
        onLanguageChanged: (newLang) {
          setState(() {
            targetLang = newLang;
            renewSystemAndMessages();
          });
        },
        isConfirmClickable: !(isBotThinking || getSelectedImage() == null),
        onConfirmPressed: () {
          setState(() {
            renewSystemAndMessages();
          });
          userSendMessage("${defaultCmds[1]}${LangLabelMap[targetLang]}.");
        },
        labelKeyword: isBotThinking ? "AI总结中…" : "AI总结",
      );
    } else if (getSelectedAgentName() == CusAgent.doc_translator) {
      return DefaultAgentButtonRow(
        isShowLanguageSwitch: true,
        targetLang: targetLang,
        langLabel: LangLabelMap,
        onLanguageChanged: (newLang) {
          setState(() {
            targetLang = newLang;
          });
        },
        isConfirmClickable: !(getDocContent().isEmpty || isBotThinking),
        onConfirmPressed: () {
          setState(() {
            renewSystemAndMessages();
          });

          userSendMessage("${defaultCmds[2]}${LangLabelMap[targetLang]}.");
        },
        labelKeyword: isBotThinking ? "AI翻译中…" : "AI翻译",
      );
    } else if (getSelectedAgentName() == CusAgent.doc_summarizer) {
      return DefaultAgentButtonRow(
        isShowLanguageSwitch: true,
        targetLang: targetLang,
        langLabel: LangLabelMap,
        onLanguageChanged: (newLang) {
          setState(() {
            targetLang = newLang;
          });
        },
        isConfirmClickable: !(getDocContent().isEmpty || isBotThinking),
        onConfirmPressed: () {
          setState(() {
            renewSystemAndMessages();
          });
          userSendMessage("${defaultCmds[3]}${LangLabelMap[targetLang]}.");
        },
        labelKeyword: isBotThinking ? "AI总结中…" : "AI总结",
      );
    } else {
      return Container();
    }
  }
}
