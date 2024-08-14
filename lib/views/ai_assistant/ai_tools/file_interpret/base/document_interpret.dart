// ignore_for_file: avoid_print

import 'dart:io';

import 'package:doc_text/doc_text.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_charset_detector/flutter_charset_detector.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:swmate/views/ai_assistant/_helper/handle_cc_response.dart';

import '../../../../../common/components/tool_widget.dart';
import '../../../../../common/llm_spec/cc_spec.dart';

import '../../../../../common/utils/tools.dart';
import '../../../_helper/document_parser.dart';
import '../constants.dart';
import 'base_interpret_state.dart';

class DocumentNewInterpret extends StatefulWidget {
  const DocumentNewInterpret({super.key});

  @override
  State createState() => _DocumentNewInterpretState();
}

class _DocumentNewInterpretState
    extends BaseInterpretState<DocumentNewInterpret> {
  // 选中的文件
  PlatformFile? selectedDoc;
  // 文件是否在解析中
  bool isLoadingDocument = false;
  // 解析后的文件内容
  String fileContent = '';
  // 当前选中的智能体
  late CusAgentSpec selectAgent;

  @override
  void initState() {
    super.initState();
    selectAgent = DocAgentItems.first;
    renewSystemAndMessages();
  }

  /// 这一个是基类的 renewSystemAndMessages 需要
  @override
  String getSystemPrompt() => selectAgent.systemPrompt;

  /// 这几个是基类的 getProcessedResult 需要
  @override
  ApiPlatform getSelectedPlatform() => ApiPlatform.siliconCloud;
  @override
  String getSelectedModel() => CCM_SPEC_LIST
      .firstWhere((e) => e.ccm == CCM.siliconCloud_Qwen2_7B_Instruct)
      .model;
  @override
  CC_SWC_TYPE getUseType() => CC_SWC_TYPE.doc;
  @override
  String getDocContent() => fileContent;
  @override
  File? getSelectedImage() => null;

  ///
  /// 构建页面需要的几个函数
  ///
  @override
  List<CusAgentSpec> getItems() => DocAgentItems;

  @override
  void setSelectedAgent(CusAgentSpec item) {
    selectAgent = item;
  }

  @override
  CusAgent getSelectedAgentName() => selectAgent.name;

  @override
  bool getIsSendClickable() => !(fileContent.isEmpty || isBotThinking);

  @override
  Widget buildSpecificUI(BuildContext context) {
    return buildFileAndInputArea();
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
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: buildCommonUI(context),
      ),
    );
  }

  // 构建文件上传区域和手动输入区域
  Widget buildFileAndInputArea() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.sp),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 1.sp),
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
  Widget buildFileUpload() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(
          onPressed: isLoadingDocument ? null : pickAndReadFile,
          icon: const Icon(Icons.file_upload),
        ),
        Expanded(
          child: selectedDoc != null
              ? GestureDetector(
                  onTap: () {
                    previewDocumentContent();
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedDoc?.name ?? "",
                        maxLines: 2,
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      RichText(
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: formatFileSize(selectedDoc?.size ?? 0),
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
                              text: "共有 ${fileContent.length} 字符",
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
        if (selectedDoc != null)
          SizedBox(
            width: 48.sp,
            child: IconButton(
              onPressed: () {
                setState(() {
                  fileContent = "";
                  selectedDoc = null;
                });
              },
              icon: const Icon(Icons.clear),
            ),
          ),
      ],
    );
  }

  /// 选择文件，并解析出文本内容
  Future<void> pickAndReadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'docx', 'doc'],
    );

    if (result != null) {
      setState(() {
        isLoadingDocument = true;
        fileContent = '';
        selectedDoc = null;
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
          selectedDoc = file;
          fileContent = text;
          isLoadingDocument = false;
        });
      } catch (e) {
        EasyLoading.showError(e.toString());

        setState(() {
          selectedDoc = file;
          fileContent = "";
          isLoadingDocument = false;
        });
        rethrow;
      }
    }
  }

  /// 点击上传文档名称，可预览文档内容
  void previewDocumentContent() {
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
                    child: Text(fileContent),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
