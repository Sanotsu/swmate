import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../common/llm_spec/cus_llm_spec.dart';
import '../../../common/utils/db_tools/db_helper.dart';
import '../../../common/components/tool_widget.dart';
import '../../../services/model_manager_service.dart';

abstract class MediaGenerationBase extends StatefulWidget {
  const MediaGenerationBase({super.key});
}

abstract class MediaGenerationBaseState<T extends MediaGenerationBase>
    extends State<T> {
  // 提示词控制器
  final TextEditingController promptController = TextEditingController();
  // 数据库帮助类
  final DBHelper dbHelper = DBHelper();
  // 模型列表
  List<CusBriefLLMSpec> modelList = [];
  // 选中的模型
  CusBriefLLMSpec? selectedModel;
  // 参考图片
  File? referenceImage;
  // 是否正在生成
  bool isGenerating = false;

  // 子类需要实现的方法
  List<LLModelType> get mediaTypes;
  String get title;
  String get note;
  Future<void> generate();
  Widget buildMediaOptions();
  Widget buildGeneratedList();

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  // 是否显示选择参考图片按钮和参考图片预览
  bool _isShowImageRef() {
    return [
      LLModelType.image,
      LLModelType.iti,
      LLModelType.video,
      LLModelType.itv
    ].contains(selectedModel?.modelType);
  }

  // 加载可用模型
  Future<void> _loadModels() async {
    final models = await ModelManagerService.getAvailableModelByTypes(
      mediaTypes,
    );

    if (!mounted) return;
    setState(() {
      modelList = models;
      selectedModel = models.isNotEmpty ? models.first : null;
    });
  }

  Future<void> pickReferenceImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => referenceImage = File(image.path));
    }
  }

  // 检查生成前的必要条件
  bool checkGeneratePrerequisites() {
    if (selectedModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先选择模型'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    final prompt = promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入提示词'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }

  // 参考图片和生成按钮布局
  Widget buildReferenceImageAndButton() {
    return Row(
      children: [
        // 选择参考图片按钮
        if (_isShowImageRef()) ...[
          ElevatedButton.icon(
            onPressed: isGenerating ? null : pickReferenceImage,
            icon: const Icon(Icons.image),
            label: const Text('选择参考图片'),
          ),
          SizedBox(width: 8.sp),
        ],
        // 生成按钮
        Expanded(
          child: ElevatedButton(
            onPressed: isGenerating ? null : generate,
            style: ElevatedButton.styleFrom(
              // shape: RoundedRectangleBorder(
              //   // 设置圆角大小
              //   borderRadius: BorderRadius.circular(10.sp),
              // ),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            // child: Text(isGenerating ? '生成中...' : '生成'),
            child: isGenerating
                ? SizedBox(
                    width: 24.sp,
                    height: 24.sp,
                    child: CircularProgressIndicator(),
                  )
                : const Text('生成'),
          ),
        ),
      ],
    );
  }

  // 显示参考图片预览
  Widget buildReferenceImagePreview() {
    if (referenceImage == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.all(8.sp),
      child: Stack(
        children: [
          Image.file(
            referenceImage!,
            height: 100.sp,
            width: 100.sp,
            fit: BoxFit.cover,
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => referenceImage = null),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: buildAppBarActions(),
      ),
      body: Padding(
        padding: EdgeInsets.all(8.sp),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 8.sp),
              child: Row(
                children: [
                  // 模型选择
                  buildModelSelector(),

                  // 媒体选项(由子类实现)
                  buildMediaOptions()
                ],
              ),
            ),

            Row(
              children: [
                // 参考图片预览(如果子类没有图片预览，可以重写一个空box)
                if (_isShowImageRef()) buildReferenceImagePreview(),

                // 提示词输入
                buildPromptInput(),
              ],
            ),

            // 参考图片和生成按钮
            Padding(
              padding: EdgeInsets.only(top: 8.sp),
              child: buildReferenceImageAndButton(),
            ),

            // 生成的媒体列表(由子类实现)
            buildGeneratedList(),
          ],
        ),
      ),
    );
  }

  /// 子类可以覆盖的方法，不需覆盖就用父类的

  // 顶部栏按钮
  List<Widget> buildAppBarActions() {
    return [
      IconButton(
        icon: const Icon(Icons.photo_library_outlined),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => buildManagerScreen(),
            ),
          );
        },
      ),
      IconButton(
        onPressed: () {
          commonMDHintModalBottomSheet(
            context,
            "$title使用说明",
            note,
            msgFontSize: 15.sp,
          );
        },
        icon: const Icon(Icons.info_outline),
      ),
    ];
  }

  // 媒体管理页面
  Widget buildManagerScreen();

  // 模型选择器
  Widget buildModelSelector() {
    return Expanded(
      child: buildDropdownButton2<CusBriefLLMSpec?>(
        value: selectedModel,
        items: modelList,
        hintLabel: "选择模型",
        alignment: Alignment.centerLeft,
        // labelSize: 12.sp,
        onChanged: isGenerating
            ? null
            : (value) {
                setState(() => selectedModel = value!);
              },
        itemToString: (e) =>
            "${CP_NAME_MAP[(e as CusBriefLLMSpec).platform]} - ${e.name}",
      ),
    );
  }

  // 提示词输入框
  Widget buildPromptInput() {
    return Expanded(
      child: TextField(
        controller: promptController,
        maxLines: 5,
        decoration: const InputDecoration(
          labelText: '提示词',
          hintText: '请输入描述',
          border: OutlineInputBorder(),
        ),
        enabled: !isGenerating,
      ),
    );
  }

  @override
  void dispose() {
    promptController.dispose();
    super.dispose();
  }
}
