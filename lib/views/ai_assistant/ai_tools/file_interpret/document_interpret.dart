import 'dart:io';

import 'package:doc_text/doc_text.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_charset_detector/flutter_charset_detector.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../common/components/tool_widget.dart';
import '../../../../common/llm_spec/cus_llm_spec.dart';

import '../../../../common/llm_spec/cus_llm_model.dart';
import '../../../../common/utils/tools.dart';
import '../../_helper/constants.dart';
import '../../_helper/document_parser.dart';
import '../../_helper/handle_cc_response.dart';
import 'base_interpret_screen_state.dart';

class DocumentInterpret extends StatefulWidget {
  // 可供挑选的模型列表
  final List<CusLLMSpec> llmSpecList;
  // 可供挑选的预设系统角色
  final List<CusSysRoleSpec> cusSysRoleSpecs;

  const DocumentInterpret({
    super.key,
    required this.llmSpecList,
    required this.cusSysRoleSpecs,
  });

  @override
  State createState() => _DocumentInterpretState();
}

class _DocumentInterpretState extends BaseInterpretState<DocumentInterpret> {
  // 选中的文件
  PlatformFile? selectedDoc;
  // 文件是否在解析中
  bool isLoadingDocument = false;
  // 解析后的文件内容
  String fileContent = '';

  var docHintInfo = """1. 目前仅支持上传单个文档文件;
2. 上传文档目前仅支持 pdf、txt、docx、doc 格式;
3. 上传的文档和手动输入的文档总内容不超过8000字符;
4. 如有上传文件, 点击 [文档解析完成] 蓝字, 可以预览解析后的文档.""";

  @override
  void initState() {
    super.initState();

    super.initCusConfig("doc");
  }

  // 基类需要的模型类型
  @override
  LLModelType getTargetType() => LLModelType.cc;

  /// 这一个是基类的 renewSystemAndMessages 需要
  @override
  String getSystemPrompt() => selectSysRole.systemPrompt;

  /// 这几个是基类的 getProcessedResult 需要的类型、文本内容、图片内容
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
  void setSelectedSysRole(CusSysRoleSpec item) {
    selectSysRole = item;
  }

  @override
  CusSysRole getSelectedSysRoleName() =>
      selectSysRole.name ?? CusSysRole.doc_translator;

  @override
  bool getIsSendClickable() => !(fileContent.isEmpty || isBotThinking);

  @override
  Widget buildSelectionArea(BuildContext context) {
    return buildFileAndInputArea();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("文档解读"),
        actions: [
          IconButton(
            onPressed: () {
              commonMDHintModalBottomSheet(
                context,
                '温馨提示',
                docHintInfo,
                msgFontSize: 15.sp,
              );
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          unfocusHandle();
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
              : Center(
                  child: Text(
                    isLoadingDocument ? "文档解析中..." : "可点击左侧按钮上传文件",
                    // style: const TextStyle(color: Colors.grey),
                  ),
                ),
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
            debugPrint("默认的,暂时啥都不做");
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
                        unfocusHandle();
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
