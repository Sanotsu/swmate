// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../common/components/tool_widget.dart';
import '../../../../common/llm_spec/cus_llm_spec.dart';
import '../../../../common/llm_spec/cus_llm_model.dart';
import '../../_helper/constants.dart';
import '../../_helper/handle_cc_response.dart';
import '../../_ig_screen_parts/image_pick_and_view_area.dart';
import 'base_interpret_screen_state.dart';

class ImageInterpret extends StatefulWidget {
  // 可供挑选的模型列表
  final List<CusLLMSpec> llmSpecList;
  // 可供挑选的预设系统角色
  final List<CusSysRoleSpec> cusSysRoleSpecs;

  const ImageInterpret({
    super.key,
    required this.llmSpecList,
    required this.cusSysRoleSpecs,
  });

  @override
  State<ImageInterpret> createState() => _ImageInterpretState();
}

class _ImageInterpretState extends BaseInterpretState<ImageInterpret> {
  // 选择的图片文件
  File? selectedImage;

  @override
  void initState() {
    super.initState();

    super.initCusConfig("img");
  }

  // 基类需要的模型类型
  @override
  LLModelType getTargetType() => LLModelType.vision;

  /// 这一个是基类的 renewSystemAndMessages 需要
  @override
  String getSystemPrompt() => selectSysRole.systemPrompt;

  /// 这几个是基类的 getProcessedResult 需要的类型、文本内容、图片内容
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
  void setSelectedASysRole(CusSysRoleSpec item) {
    selectSysRole = item;
  }

  @override
  bool getIsSendClickable() => userInput.isNotEmpty && selectedImage != null;

  @override
  CusSysRole getSelectedSysRoleName() =>
      selectSysRole.name ?? CusSysRole.img_translator;

  /// 构建图片选择和预览行
  @override
  Widget buildSelectionArea(BuildContext context) {
    return ImagePickAndViewArea(
      imageSelectedHandle: _pickImage,
      imageClearHandle: () => setState(() => selectedImage = null),
      selectedImage: selectedImage,
    );
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
                selectSysRole.hintInfo ?? "",
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
          unfocusHandle();
        },
        child: buildCommonUI(context),
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
