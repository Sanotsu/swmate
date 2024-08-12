// ignore_for_file: avoid_print

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
import 'package:logger/logger.dart';

import '../../../../apis/chat_completion/common_cc_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/constants.dart';
import '../../../../common/llm_spec/cc_spec.dart';
import '../../../../common/utils/tools.dart';
import '../../../../models/chat_competion/com_cc_resp.dart';
import '../../../../models/chat_competion/com_cc_state.dart';
import '../../_chat_screen_parts/chat_list_area.dart';
import '../../_helper/document_parser.dart';
import '../../_helper/handle_cc_response.dart';

///
/// 翻译助理
/// 核心是当个翻译器
/// 可考虑支持文档上传，然后翻译文档，再下载
///
/// 虽然看起来和“文档摘要”差不多，但传入的内容和页面布局要不同，且操作后不会清空用户输入的要翻译的内容
///
class MultiTranslator extends StatefulWidget {
  const MultiTranslator({super.key});

  @override
  State createState() => _MultiTranslatorState();
}

class _MultiTranslatorState extends State<MultiTranslator> {
  ///
  /// 文件上传和解析、手动输入文本 相关变量
  ///
  // 是否在解析文件中
  bool isLoadingDocument = false;
  // 上传的文件(方便显示文件相关信息)
  PlatformFile? _selectedFile;
  // 文档解析出来的内容
  String _fileContent = '';

  // 用户输入的文本控制器
  final _userInputController = TextEditingController();
  // 用户输入的内容（当不是AI在思考、且输入框有非空文字时才可以点击发送按钮）
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

  // AI充当的角色
  String systemPrompt = """您是一位精通世界上任何语言的翻译专家。将对用户输入的文本进行精准翻译。只做翻译工作，无其他行为。
  如果用户输入了多种语言的文本，统一翻译成目标语言。
  如果用户指定了翻译的目标语言，则翻译成该目标语言；如果目标语言和原版语言一致，则不做翻译直接输出原版语言。
  如果没有指定翻译的目标语言，那么默认翻译成简体中文；如果已经是简体中文了，则翻译成英文。
  翻译完成之后单独解释重难点词汇。
  如果翻译后内容很多，需要分段显示。""";

  // 默认的要翻译成什么语言
  TargetLanguage targetLang = TargetLanguage.simplifiedChinese;

  var l = Logger();

  @override
  void dispose() {
    _scrollController.dispose();
    _userInputController.dispose();
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
  /// ===================
  ///

  /// 选择文件，并解析出文本内容
  Future<void> _pickAndReadFile() async {
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
            print(result.charset);
            print(result.string);
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
          l.i("=========文档内容长度==========${_fileContent.length}");
          l.i('上传文档解析出来的内容：$_fileContent');
        });
      } catch (e) {
        l.e("解析文档出错:${e.toString()}");
        setState(() {
          _selectedFile = file;
          _fileContent = "";
          isLoadingDocument = false;
        });
        rethrow;
      }
    }
  }

  ///
  /// 问答都是一次性的，不用想着多次发送的情况了
  /// 对于是否展示用户输入的内容，分为以下三种情况：
  ///   1 只上传了文档：用户输入的内容只有文档名称即可
  ///   2 只复制了文档内容：显示所有用户输入的内容
  ///   3 都有：显示文档名称和用户输入的内容
  ///
  /// 这个按钮只有用户点击，每次点击效果是一样的
  ///
  getTanslatorResult() async {
    if (isBotThinking) return;

    // 整个内容就只有翻译结果，所以每次点击翻译，都要从对话列表中清除之前的对话内容
    setState(() {
      isBotThinking = true;
      messages.clear();
    });

    // 用户输入的内容不会自动清除
    var userContent = "";

    if (_selectedFile != null) {
      userContent += _fileContent;
    }

    // 理论上上传文档或用户输入为空不会都为true
    if (userInput.isNotEmpty) {
      userContent += userInput;
    }

    userContent += "\n\n翻译上述所有文本，目标语言是：${langLabel[targetLang]}";

    var contentTotalLength = _fileContent.length + userInput.length;
    // 文本太长了暂时就算了
    if (contentTotalLength > 3000) {
      print("总文档长度:======= $contentTotalLength");
      EasyLoading.showInfo(
        "文档内容太长($contentTotalLength字符)，暂不支持超过3000字符的翻译，请谅解。",
        duration: const Duration(seconds: 5),
      );
      return;
    }

    l.i(userContent);

    // ？？？具体给大模型发送的指令，就不给用户展示了(文档解析可能不正确，内容也太多)
    List<CCMessage> msgs = [
      CCMessage(
        role: "system",
        content: systemPrompt,
      ),
      CCMessage(
        role: "user",
        content: userContent,
      ),
    ];

    // 后续可手动终止响应时的写法
    StreamWithCancel<ComCCResp> tempStream = await siliconFlowCCRespWithCancel(
      msgs,
      model: CCM_SPEC_LIST
          .firstWhere((e) => e.ccm == CCM.siliconCloud_Qwen2_7B_Instruct)
          .model,
      stream: true,
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
              _userInputController.clear();
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
            _userInputController.clear();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('翻译助手'),
        actions: [
          IconButton(
            onPressed: () {
              commonHintDialog(
                context,
                '温馨提示',
                '1 目前仅支持上传单个文档文件;\n\n2 上传文档目前仅支持 pdf、txt、docx、doc 格式; \n\n3 上传的文档和手动输入的文档总内容不超过3000字符.',
                msgFontSize: 15.sp,
              );
            },
            icon: const Icon(Icons.help),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          buildLoadedFile(),
          // Expanded(child: buildUserSendArea()),
          SizedBox(height: 0.3.sh, child: buildUserSendArea()),
          SizedBox(height: 10.sp),
          buildChangeLangAndConfirmRow(),
          SizedBox(height: 10.sp),

          /// 显示对话消息主体
          isLoadingDocument
              ? const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      Text("正在解析文档..."),
                    ],
                  ),
                )
              : ChatListArea(
                  messages: messages,
                  scrollController: _scrollController,
                  isBotThinking: isBotThinking,
                  isAvatarTop: true,
                  regenerateLatestQuestion: getTanslatorResult,
                ),

          SizedBox(height: 10.sp),
        ],
      ),
    );
  }

  // 上传文件按钮和上传的文件名
  buildLoadedFile() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        SizedBox(width: 20.sp),
        IconButton(
          onPressed: isLoadingDocument ? null : _pickAndReadFile,
          icon: const Icon(Icons.file_upload),
        ),
        Expanded(
          child: _selectedFile != null
              ? GestureDetector(
                  // 单击预览
                  onTap: () {
                    previewDocumentContent();
                  },
                  // 默认显示文件图片
                  child: Column(
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
                    Text('预览文档内容', style: TextStyle(fontSize: 18.sp)),
                    TextButton(
                      child: const Text('关闭'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(height: 1.sp),
              Expanded(
                child: SingleChildScrollView(child: Text(_fileContent)),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 用户发送消息的区域
  buildUserSendArea() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.sp),
      child: TextField(
        controller: _userInputController,
        decoration: const InputDecoration(
          hintText: '上传需要翻译的文档或者手动输入',
          // 全边框线
          border: OutlineInputBorder(),
          // 取消边框线
          // border: InputBorder.none,
        ),
        maxLines: null, // 设置为 null 以支持自动换行
        minLines: null, // 设置为 null 以支持自动换行
        expands: true, // 使 TextField 扩展以填充可用空间
        onChanged: (String? text) {
          if (text != null) {
            setState(() {
              userInput = text.trim();
            });
          }
        },
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
          SizedBox(width: 10.sp),
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
                    // 如果在翻译中则不允许切换目标语言
                    onChanged: isBotThinking
                        ? null
                        : (val) {
                            setState(() {
                              targetLang = val!;
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
                  // 用户输入为空同时上传文档内容为空，或者已经在翻译中了，则不允许再点击翻译按钮
                  onPressed: (userInput.isEmpty && _fileContent.isEmpty) ||
                          isBotThinking
                      ? null
                      : () {
                          // 在当前上下文中查找最近的 FocusScope 并使其失去焦点，从而收起键盘。
                          FocusScope.of(context).unfocus();

                          // 调用文档分析总结函数
                          getTanslatorResult();
                        },
                  child: Text(
                    isBotThinking ? "翻译中..." : "AI翻译",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
