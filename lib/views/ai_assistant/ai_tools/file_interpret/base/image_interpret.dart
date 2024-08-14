// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../common/components/tool_widget.dart';
import '../../../../../common/llm_spec/cus_llm_spec.dart';
import '../../../_helper/handle_cc_response.dart';
import '../constants.dart';
import 'base_interpret_state.dart';

class ImageNewInterpret extends StatefulWidget {
  const ImageNewInterpret({super.key});

  @override
  State<ImageNewInterpret> createState() => _ImageNewInterpretState();
}

class _ImageNewInterpretState extends BaseInterpretState<ImageNewInterpret> {
  // 选择的图片文件
  File? selectedImage;

  // 当前选中的智能体
  late CusAgentSpec selectAgent;

  @override
  void initState() {
    super.initState();
    selectAgent = ImgAgentItems.first;
    renewSystemAndMessages();
  }

  /// 这一个是基类的 renewSystemAndMessages 需要
  @override
  String getSystemPrompt() => selectAgent.systemPrompt;

  /// 这几个是基类的 getProcessedResult 需要
  @override
  ApiPlatform getSelectedPlatform() => ApiPlatform.lingyiwanwu;
  @override
  String getSelectedModel() =>
      CusLLM_SPEC_LIST.firstWhere((e) => e.cusLlm == CusLLM.YiVision).model;
  @override
  CC_SWC_TYPE getUseType() => CC_SWC_TYPE.image;
  @override
  String getDocContent() => "";
  @override
  File? getSelectedImage() => selectedImage;

  ///
  /// 构建页面需要的几个函数
  ///
  @override
  List<CusAgentSpec> getItems() => ImgAgentItems;
  @override
  void setSelectedAgent(CusAgentSpec item) {
    selectAgent = item;
  }

  @override
  bool getIsSendClickable() => userInput.isNotEmpty && selectedImage != null;

  @override
  CusAgent getSelectedAgentName() => selectAgent.name;
  @override
  Widget buildSpecificUI(BuildContext context) {
    return buildImagePickAndViewRow();
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
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: buildCommonUI(context),
      ),
    );
  }

  /// 构建图片选择和预览行
  Widget buildImagePickAndViewRow() {
    return SizedBox(
      height: 100.sp,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 5.sp),
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1.0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: buildImageView(selectedImage, context),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.sp),
                    ),
                  ),
                  onPressed: selectedImage != null
                      ? () {
                          setState(() {
                            selectedImage = null;
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

  /// 选择图片来源
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    print("选中的图片---------$pickedFile");

    if (pickedFile != null) {
      setState(() {
        renewSystemAndMessages();
        selectedImage = File(pickedFile.path);
      });
    }
  }
}
