// ignore_for_file: avoid_print, constant_identifier_names

import 'dart:io';

import 'package:doc_text/doc_text.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_charset_detector/flutter_charset_detector.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../../../apis/chat_completion/common_cc_apis.dart';
import '../../../../apis/voice_recognition/xunfei_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/constants.dart';
import '../../../../common/llm_spec/cc_spec.dart';
import '../../../../common/utils/tools.dart';
import '../../../../models/chat_competion/com_cc_resp.dart';
import '../../../../models/chat_competion/com_cc_state.dart';
import '../../_chat_screen_parts/chat_list_area.dart';
import '../../_chat_screen_parts/chat_user_send_area_with_voice.dart';
import '../../_chat_screen_parts/default_agent_button_row.dart';
import '../../_componets/sounds_message_button/utils/sounds_recorder_controller.dart';
import '../../_helper/document_parser.dart';
import '../../_helper/handle_cc_response.dart';
import '../../_componets/cus_toggle_button_selector.dart';

const docHintInfo = """1. 目前仅支持上传单个文档文件;
2. 上传文档目前仅支持 pdf、txt、docx、doc 格式;
3. 上传的文档和手动输入的文档总内容不超过8000字符;
4. 如有上传文件, 点击[文档解析完成]蓝字, 可以预览解析后的文档.""";

enum CusAgent {
  doc_translator, // 翻译
  doc_summarizer, // 总结
  doc_analyzer, // 分析
  img_translator,
  img_summarizer,
  img_analyzer,
}

/// 文档解读这页面可能需要的一些栏位
class CusAgentSpec {
  // 智能体的标签
  final String label;
  // 智能体的枚举名称
  final CusAgent name;
  // 智能体的提示信息
  final String hintInfo;
  // 智能体的系统提示
  final String systemPrompt;

  CusAgentSpec({
    required this.label,
    required this.name,
    required this.hintInfo,
    required this.systemPrompt,
  });
}

///
/// 文档处理(和图片处理一样，不考虑用户自己追加的问题内容了)
///
class DocumentNewInterpret extends StatefulWidget {
  const DocumentNewInterpret({super.key});

  @override
  State createState() => _DocumentNewInterpretState();
}

class _DocumentNewInterpretState extends State<DocumentNewInterpret> {
  ///
  /// 文件上传和解析、手动输入文本 相关变量
  ///
  // 是否在解析文件中
  bool isLoadingDocument = false;
  // 上传的文件(方便显示文件相关信息)
  PlatformFile? _selectedFile;
  // 文档解析出来的内容
  String _fileContent = '';

  // 用户提问输入的文本控制器
  final _userInputController = TextEditingController();
  // 用户提问输入的内容（当不是AI在思考、且输入框有非空文字时才可以点击发送按钮）
  String userInput = "";

  ///
  /// 请求状态和配置相关
  ///
  // 是否在翻译中
  bool isBotThinking = false;

  // 是否流式响应(暂时时固定为true)
  bool isStream = true;

  // 对话列表(翻译器只保存一个消息，就是请求响应的内容)
  List<ChatMessage> messages = [];

  // 对话列表滚动控制器
  final ScrollController _scrollController = ScrollController();

  // 当前正在响应的api返回流(放在全局为了可以手动取消)
  StreamWithCancel<ComCCResp> respStream = StreamWithCancel.empty();

  // 默认的要翻译成什么语言
  TargetLanguage targetLang = TargetLanguage.simplifiedChinese;

  // 预设的文档解读的功能列表
  var items = [
    CusAgentSpec(
      label: "翻译",
      name: CusAgent.doc_translator,
      hintInfo: docHintInfo,
      systemPrompt: """您是一位精通世界上任何语言的翻译专家。将对用户输入的文本进行精准翻译。只做翻译工作，无其他行为。
      如果用户输入了多种语言的文本，统一翻译成目标语言。
      如果用户指定了翻译的目标语言，则翻译成该目标语言；如果目标语言和原版语言一致，则不做翻译直接输出原版语言。
      如果没有指定翻译的目标语言，那么默认翻译成简体中文；如果已经是简体中文了，则翻译成英文。
      翻译完成之后单独解释重难点词汇。
      如果翻译后内容很多，需要分段显示。""",
    ),
    CusAgentSpec(
      label: "总结",
      name: CusAgent.doc_summarizer,
      hintInfo: docHintInfo,
      systemPrompt: """你是一个文档分析专家，你需要根据提供的文档内容，生成一份简洁、结构化的文档摘要。
      如果原文本不是中文，总结要使用中文。""",
    ),
    CusAgentSpec(
      label: "分析",
      name: CusAgent.doc_analyzer,
      hintInfo: docHintInfo,
      systemPrompt: """你是一个文档分析专家，你需要根据提供的文档内容，回答用户输入的各种问题。""",
    ),
  ];

  // 当前选中的文档功能
  late CusAgentSpec selectAgent;

  @override
  void dispose() {
    _scrollController.dispose();
    _userInputController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    setState(() {
      selectAgent = items.first;
      renewSystemAndMessages();
    });
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

// 因为点击预设的“文档翻译”、“文档总结”，“文档分析”提问时，都要把第一个用户输入作为文档内容+提问
// 那就需要在上传文件完成、或者用户输入文档有变化时就实时更新文档内容
  combineDocContent() {}

  /// 选择文件，并解析出文本内容
  Future<void> pickAndReadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'docx', 'doc'],
    );

    if (result != null) {
      setState(() {
        // 是否在解析文件中
        isLoadingDocument = true;
        // 新选中了文档，需要在解析前就清空旧的文档信息和旧的分析数据
        _fileContent = '';
        _selectedFile = null;
      });

      PlatformFile file = result.files.first;

      try {
        var text = "";
        switch (file.extension) {
          case 'txt':
            DecodingResult result = await CharsetDetector.autoDecode(
              File(file.path!).readAsBytesSync(),
            );
            text = result.string;

          case 'pdf':
            text = await compute(extractTextFromPdf, file.path!);
          case 'docx':
            text = docxToText(File(file.path!).readAsBytesSync());
          case 'doc':
            text = await DocText().extractTextFromDoc(file.path!) ?? "";
          default:
            print("默认的,暂时啥都不做");
        }

        if (!mounted) return;
        setState(() {
          _selectedFile = file;
          _fileContent = text;
          isLoadingDocument = false;
        });
      } catch (e) {
        EasyLoading.showError(e.toString());

        setState(() {
          _selectedFile = file;
          _fileContent = "";
          isLoadingDocument = false;
        });
        rethrow;
      }
    }
  }

  /// 用户提问(用户提问和预设的总结、翻译功能按钮不会同时出现)
  userSendMessage(
    String text, {
    // 2024-08-07 可能text是语音转的文字，保留语音文件路径
    String? contentVoicePath,
  }) {
    setState(() {
      // 发送消息的逻辑，这里只是简单地将消息添加到列表中
      // 注意，文档解析的内容，在 getCCResponseSWC 有补充发个后台接口，对话记录中不会显示
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
      getProcessedResult();
    });
  }

  ///
  /// 问答都是一次性的，不用想着多次发送的情况了
  /// 对于是否展示用户输入的内容，分为以下三种情况：
  ///   1 只上传了文档
  ///   2 只输入了文档内容
  ///   3 都有
  ///
  /// 这个按钮只要用户点击，每次点击效果是一样的
  getProcessedResult() async {
    if (isBotThinking) return;

    // 整个内容就只有翻译结果，所以每次点击翻译，都要从对话列表中清除之前的对话内容
    setState(() {
      isBotThinking = true;
    });

    StreamWithCancel<ComCCResp> tempStream = await getCCResponseSWC(
      messages: messages,
      selectedPlatform: ApiPlatform.siliconCloud,
      selectedModel: CCM_SPEC_LIST
          .firstWhere((e) => e.ccm == CCM.siliconCloud_Qwen2_7B_Instruct)
          .model,
      isDoc: true,
      isStream: isStream,
      docContent: _fileContent,
      onNotDocHint: (error) {
        commonExceptionDialog(context, "异常提示", error);
      },
    );

    if (!mounted) return;
    setState(() {
      respStream = tempStream;
    });

    // 将响应结果加入对话列表(SSE有新消息就会更新)
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
      // 非流式的时候，只有一条数据，永远不会触发上面监听时的DONE的情况
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
  regenerateLatestQuestion() {
    setState(() {
      // 将最后一条消息删除， 重新发送
      messages.removeLast();
      getProcessedResult();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("文档解读"),
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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
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

          buildFileAndInputArea(),
          SizedBox(height: 10.sp),

          if (selectAgent.name == CusAgent.doc_translator)
            DefaultAgentButtonRow(
              cusAgent: selectAgent.name,
              targetLang: targetLang,
              langLabel: langLabel,
              onLanguageChanged: (newLang) {
                setState(() {
                  targetLang = newLang;
                });
              },
              isConfirmClickable: !(_fileContent.isEmpty || isBotThinking),
              onConfirmPressed: () {
                setState(() {
                  renewSystemAndMessages();
                });

                userSendMessage(
                  "请翻译上面所有文本，目标语言是：${langLabel[targetLang]}。\n\n",
                );
              },
              labelKeyword: isBotThinking ? "AI翻译中" : "AI翻译",
            ),
          if (selectAgent.name == CusAgent.doc_summarizer)
            DefaultAgentButtonRow(
              cusAgent: selectAgent.name,
              isConfirmClickable: !(_fileContent.isEmpty || isBotThinking),
              onConfirmPressed: () {
                setState(() {
                  renewSystemAndMessages();
                });
                // 总结时，不需要额外用户内容，直接靠system设置就好，但要显示对话，所以还是要提一下
                userSendMessage("总结上面文档内容，给出摘要。");
              },
              labelKeyword: isBotThinking ? "AI总结中" : "AI总结",
            ),

          SizedBox(height: 10.sp),

          /// 显示对话消息主体
          isLoadingDocument
              ? const Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          Text("正在解析文档..."),
                        ],
                      )
                    ],
                  ),
                )
              : ChatListArea(
                  /// 如果不想显示system信息，这里可以移除掉(但不能修改原消息列表)
                  messages: messages,
                  // messages: messages.where((e) => e.role != "system").toList(),
                  scrollController: _scrollController,
                  isBotThinking: isBotThinking,
                  isAvatarTop: true,
                  regenerateLatestQuestion: regenerateLatestQuestion,
                ),

          /// 如果选择的是“分析文档”功能，才显示这个提问输入框
          /// 用户发送区域
          if (selectAgent.name == CusAgent.doc_analyzer)
            ChatUserVoiceSendArea(
              controller: _userInputController,
              hintText: '询问关于上面文档的任何问题',
              isBotThinking: isBotThinking,
              isSendClickable: userInput.isNotEmpty && _fileContent.isNotEmpty,
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

                  var transcription =
                      await sendAudioToServer("$fullPathWithoutExtension.pcm");
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

          SizedBox(height: 10.sp),
        ],
      ),
    );
  }

  // 构建文件上传区域和手动输入区域
  buildFileAndInputArea() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.sp),
      decoration: BoxDecoration(
        // 添加边框线
        border: Border.all(color: Colors.grey, width: 1.sp),
        // 添加圆角
        borderRadius: BorderRadius.circular(10.sp),
      ),
      child: Column(
        children: [
          Divider(thickness: 2.sp),
          SizedBox(
            height: 100.sp,
            child: buildFileUpload(),
          ),
        ],
      ),
    );
  }

  // 上传文件按钮和上传的文件名
  buildFileUpload() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(
          onPressed: isLoadingDocument ? null : pickAndReadFile,
          icon: const Icon(Icons.file_upload),
        ),
        Expanded(
          child: _selectedFile != null
              ? GestureDetector(
                  // 单击预览
                  onTap: () {
                    previewDocumentContent();
                  },
                  // 显示文档名称
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFile?.name ?? "",
                        maxLines: 2,
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      RichText(
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        text: TextSpan(
                          children: [
                            // 为了分类占的宽度一致才用的，只是显示的话可不必
                            TextSpan(
                              text: formatFileSize(_selectedFile?.size ?? 0),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12.sp,
                              ),
                            ),
                            TextSpan(
                              text: " 文档解析完成 ",
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 15.sp,
                              ),
                            ),
                            TextSpan(
                              text: "共有 ${_fileContent.length} 字符",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : Text(isLoadingDocument ? "文档解析中..." : "可点击左侧按钮上传文件"),
        ),
        if (_selectedFile != null)
          SizedBox(
            width: 48.sp,
            child: IconButton(
              onPressed: () {
                setState(() {
                  _fileContent = "";
                  _selectedFile = null;
                });
              },
              icon: const Icon(Icons.clear),
            ),
          ),
      ],
    );
  }

  /// 点击上传文档名称，可预览文档内容
  previewDocumentContent() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 1.sh,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.sp),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('解析后文档内容预览', style: TextStyle(fontSize: 18.sp)),
                    TextButton(
                      child: const Text('关闭'),
                      onPressed: () {
                        Navigator.pop(context);
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ],
                ),
              ),
              Divider(height: 2.sp, thickness: 2.sp),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(10.sp),
                    child: Text(_fileContent),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建对话列表主体
  buildReadSummaryChatArea() {
    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(10.sp),
          child: Column(
            children: [
              MarkdownBody(
                data: messages.isNotEmpty ? messages.first.content : '',
                selectable: true,
                // 设置Markdown文本全局样式
                styleSheet: MarkdownStyleSheet(
                  // 普通段落文本颜色(假定用户输入就是普通段落文本)
                  p: const TextStyle(color: Colors.black),
                  // ... 其他级别的标题样式
                  // 可以继续添加更多Markdown元素的样式
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
