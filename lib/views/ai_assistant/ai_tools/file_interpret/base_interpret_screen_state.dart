// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../../../apis/chat_completion/common_cc_apis.dart';
import '../../../../apis/voice_recognition/xunfei_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/constants.dart';
import '../../../../common/llm_spec/cus_llm_spec.dart';
import '../../../../common/llm_spec/cus_llm_model.dart';
import '../../../../common/utils/db_tools/db_helper.dart';
import '../../../../models/chat_competion/com_cc_resp.dart';
import '../../../../models/chat_competion/com_cc_state.dart';
import '../../_chat_screen_parts/chat_list_area.dart';
import '../../_chat_screen_parts/chat_user_send_area_with_voice.dart';
import '../../_chat_screen_parts/default_system_role_button_row.dart';
import '../../_componets/cus_platform_and_llm_row.dart';
import '../../_componets/cus_toggle_button_selector.dart';
import '../../_componets/sounds_message_button/utils/sounds_recorder_controller.dart';
import '../../_helper/constants.dart';
import '../../_helper/handle_cc_response.dart';

abstract class BaseInterpretState<T extends StatefulWidget> extends State<T> {
  final DBHelper dbHelper = DBHelper();

  ///
  /// 手动输入文本 相关变量
  ///
  final TextEditingController userInputController = TextEditingController();
  String userInput = "";

  // 所有支持文生图的模型列表(用于下拉的平台和该平台拥有的模型列表也从这里来)
  late List<CusLLMSpec> llmSpecList;

  /// 级联选择效果：云平台-模型名
  ApiPlatform selectedPlatform = ApiPlatform.siliconCloud;

  // 被选中的模型信息
  late CusLLMSpec selectedModelSpec;

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

  // 当前选中的系统角色
  late CusSysRoleSpec selectSysRole;

  // 可供选择的系统角色列表
  late List<CusSysRoleSpec> sysRoleList;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    userInputController.dispose();
    super.dispose();
  }

  LLModelType getTargetType();

  // 初始化获取可筛选的模型列表、当前选中的平台模型、当前可供选择的系统角色等
  initCusConfig(String roleName) async {
    // 赋值模型列表、角色列表
    final widget = this.widget as dynamic;
    setState(() {
      llmSpecList = widget.llmSpecList;
    });

    // 每次进来都随机选一个平台
    List<ApiPlatform> plats =
        llmSpecList.map((e) => e.platform).toSet().toList();
    setState(() {
      selectedPlatform = plats[Random().nextInt(plats.length)];
    });

    // 同样的，选中的平台后也随机选择一个模型
    List<CusLLMSpec> models =
        llmSpecList.where((spec) => spec.platform == selectedPlatform).toList();
    setState(() {
      selectedModelSpec = models[Random().nextInt(models.length)];
    });

    setState(() {
      sysRoleList = (widget.cusSysRoleSpecs as List<CusSysRoleSpec>)
          .where((spec) =>
              spec.name?.name.toLowerCase().startsWith(roleName) ?? false)
          .toList();

      selectSysRole = sysRoleList.first;
      renewSystemAndMessages();
    });
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
  /// 获取AI响应略有不同，需要子类传入是图片还是文件、文档内容或选中的图片
  ///
  CC_SWC_TYPE getUseType();
  String getDocContent();
  File? getSelectedImage();

  Future<void> getProcessedResult() async {
    if (isBotThinking) return;
    setState(() {
      isBotThinking = true;
    });

    StreamWithCancel<ComCCResp> tempStream;
    // 2024-08-27 如果是使用百度的Fuyu8B，则无法像下面的通用
    if (selectedModelSpec.cusLlm == CusLLM.baidu_Fuyu_8B) {
      // 如果是图像理解、但没有传入图片，模拟模型返回异常信息
      if (getSelectedImage() == null) {
        EasyLoading.showError("图像理解模式下，必须选择图片");
        setState(() {
          isBotThinking = false;
        });
        return;
      }

      tempStream = await baiduCCRespWithCancel(
        [],
        prompt: messages.where((e) => e.role == "user").last.content,
        image: base64Encode((await getSelectedImage()!.readAsBytes())),
        model: selectedModelSpec.model,
        stream: isStream,
      );
    } else {
      tempStream = await getCCResponseSWC(
        messages: messages,
        selectedPlatform: selectedPlatform,
        selectedModel: selectedModelSpec.model,
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
    }

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

  // 预设功能列表切换时要更新当前选中的角色信息
  void setSelectedASysRole(CusSysRoleSpec item);
  // 当前选中的提示词角色名称
  CusSysRole getSelectedSysRoleName();

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
        // 2024-08-27 这里如果手机太小，打字键盘弹出来可能会出现溢出的问题
        // 虽然固定高度，放在SizedBox中添加SingleChildScrollView和Column可以解决，但不好看
        /// 构建可切换云平台和模型的行
        Container(
          color: Colors.grey[300],
          child: Padding(
            padding: EdgeInsets.only(left: 10.sp),
            child: CusPlatformAndLlmRow(
              initialPlatform: selectedPlatform,
              initialModelSpec: selectedModelSpec,
              llmSpecList: llmSpecList,
              targetModelType: getTargetType(),
              showToggleSwitch: true,
              isStream: isStream,
              onToggle: (index) {
                setState(() {
                  isStream = index == 0 ? true : false;
                });
              },
              onPlatformOrModelChanged: (ApiPlatform? cp, CusLLMSpec? llmSpec) {
                setState(() {
                  selectedPlatform = cp!;
                  selectedModelSpec = llmSpec!;
                });
              },
            ),
          ),
        ),

        /// 可切换的预设功能
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CusToggleButtonSelector<CusSysRoleSpec>(
                items: sysRoleList,
                onItemSelected: (item) {
                  print('Selected item: ${item.label}');
                  setState(() {
                    setSelectedASysRole(item);
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
        buildDefaultSysRoleButtonRow(context),
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
        if (getSelectedSysRoleName() == CusSysRole.doc_analyzer ||
            getSelectedSysRoleName() == CusSysRole.img_analyzer)
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

  Widget buildDefaultSysRoleButtonRow(BuildContext context) {
    if (getSelectedSysRoleName() == CusSysRole.img_translator) {
      return DefaultSysRoleButtonRow(
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
    } else if (getSelectedSysRoleName() == CusSysRole.img_summarizer) {
      return DefaultSysRoleButtonRow(
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
    } else if (getSelectedSysRoleName() == CusSysRole.doc_translator) {
      return DefaultSysRoleButtonRow(
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
    } else if (getSelectedSysRoleName() == CusSysRole.doc_summarizer) {
      return DefaultSysRoleButtonRow(
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
