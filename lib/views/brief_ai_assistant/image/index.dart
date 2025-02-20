import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

import '../../../common/components/tool_widget.dart';
import '../../../common/constants.dart';
import '../../../common/llm_spec/cus_llm_spec.dart';
import '../../../common/utils/tools.dart';
import '../../../models/image_generation/image_generation_history.dart';
import '../../../services/image_generation_service.dart';
import '../../../views/brief_ai_assistant/image/image_manager.dart';
import '../../../views/brief_ai_assistant/common/media_generation_base.dart';

class BriefImageScreen extends MediaGenerationBase {
  const BriefImageScreen({super.key});

  @override
  State<BriefImageScreen> createState() => _BriefImageScreenState();
}

class _BriefImageScreenState
    extends MediaGenerationBaseState<BriefImageScreen> {
  final List<String> _generatedImages = [];

  final List<CusLabel> _imageSizeOptions = [
    // 阿里通义万相：图像宽高边长的像素范围为：[768, 1440]，单位像素。可任意组合以设置不同的图像分辨率
    // 阿里Flux系列：    1024*1024 512*1024, 768*512, 768*1024, 1024*576, 576*1024,

    // 硅基流动的
    // stabilityai系列 1024x1024, 512x1024, 768x512, 768x1024, 1024x576, 576x1024
    // FLUX.1-schnell 1024x1024, 512x1024, 768x512, 768x1024, 1024x576, 576x1024
    // FLUX.1-dev     1024x1024, 960x1280, 768x1024, 720x1440, 720x1280, others
    // FLUX.1-pro     生成图像的宽度范围：[256 < x < 1440]，必须是 32 的倍数。
    CusLabel(cnLabel: "1:1", value: "1024x1024"),
    CusLabel(cnLabel: "1:2", value: "512x1024"),
    CusLabel(cnLabel: "3:2", value: "768x512"),
    CusLabel(cnLabel: "3:4", value: "768x1024"),
    CusLabel(cnLabel: "16:9", value: "1024x576"),
    CusLabel(cnLabel: "9:16", value: "576x1024"),
    // 智谱
    //  CusLabel(cnLabel: "1:1", value: "1024x1024"),
    CusLabel(cnLabel: "4:7", value: "768x1344"),
    CusLabel(cnLabel: "3:4", value: "864x1152"),
    CusLabel(cnLabel: "7:4", value: "1344x768"),
    CusLabel(cnLabel: "4:3", value: "1152x864"),
    CusLabel(cnLabel: "2:1", value: "1440x720"),
    CusLabel(cnLabel: "1:2", value: "720x1440"),
  ];

  late CusLabel _selectedImageSize;

  @override
  List<LLModelType> get mediaTypes => [
        LLModelType.image,
        LLModelType.tti,
        LLModelType.iti,
      ];

  @override
  String get title => 'AI 绘图';

  @override
  String get note => '''
- 目前只支持的以下平台的部分模型:
  - **阿里云**"通义万相-文生图V2版"、Flux系列
  - **硅基流动**文生图模型
  - **智谱AI**的文生图模型
- 先选择平台模型和图片尺寸，再输入提示词
- 文生图耗时较长，**请勿在生成过程中退出**
- 默认一次生成1张图片
- 生成的图片会保存在设备的以下目录:
  - Pictures/SWMate/image_generation
''';

  @override
  Widget buildMediaOptions() {
    return SizedBox(
      width: 90.sp,
      child: buildDropdownButton2<CusLabel?>(
        value: _selectedImageSize,
        items: _imageSizeOptions,
        hintLabel: "选择类型",
        onChanged: isGenerating
            ? null
            : (value) {
                setState(() => _selectedImageSize = value!);
              },
        itemToString: (e) => (e as CusLabel).cnLabel,
      ),

      // DropdownButton<CusLabel>(
      //   value: _selectedImageSize,
      //   isExpanded: true,
      //   items: _imageSizeOptions.map((CusLabel size) {
      //     return DropdownMenuItem(
      //       value: size,
      //       alignment: AlignmentDirectional.center,
      //       child: Text(size.cnLabel, style: TextStyle(fontSize: 12.sp)),
      //     );
      //   }).toList(),
      //   onChanged: isGenerating
      //       ? null
      //       : (value) {
      //           setState(() => _selectedImageSize = value!);
      //         },
      // ),
    );
  }

  @override
  Widget buildGeneratedList() {
    if (_generatedImages.isEmpty) {
      return const Center(child: Text('暂无生成的图片'));
    }

    /// 图片展示
    return Expanded(
      child: Column(
        children: [
          /// 文生图的结果
          if (_generatedImages.isNotEmpty)
            ...buildImageResultGrid(
              _generatedImages,
              "${selectedModel?.platform.name}_${selectedModel?.name}",
            ),
        ],
      ),
    );
  }

  @override
  Future<void> generate() async {
    if (!checkGeneratePrerequisites()) return;

    setState(() => isGenerating = true);

    try {
      // 创建历史记录
      final history = ImageGenerationHistory(
        requestId: const Uuid().v4(),
        prompt: promptController.text.trim(),
        negativePrompt: '',
        taskId: null,
        isFinish: false,
        style: '',
        imageUrls: null,
        refImageUrls: [],
        gmtCreate: DateTime.now(),
        llmSpec: selectedModel,
        modelType: LLModelType.image,
      );

      final requestId = await dbHelper.insertImageGenerationHistory(history);

      final response = await ImageGenerationService.generateImage(
        selectedModel!,
        promptController.text.trim(),
        n: 1,
        size: selectedModel?.platform == ApiPlatform.aliyun
            ? (_selectedImageSize.value as String).replaceAll('x', '*')
            : _selectedImageSize.value,
      );

      if (!mounted) return;

      // 如果是阿里云平台，则需要保存任务ID和已完成的标识
      if (selectedModel?.platform == ApiPlatform.aliyun) {
        await dbHelper.updateImageGenerationHistoryByRequestId(
          requestId,
          {
            'taskId': response.output?.taskId,
            'isFinish': 1,
            'imageUrls':
                jsonEncode(response.results.map((r) => r.url).toList()),
          },
        );
      }

      setState(() {
        _generatedImages.addAll(response.results.map((r) => r.url));
      });

      // 更新数据库历史记录
      await dbHelper.updateImageGenerationHistoryByRequestId(
        requestId,
        {
          'isFinish': 1,
          'imageUrls': jsonEncode(_generatedImages),
        },
      );

      // 保存图片到本地
      for (final url in _generatedImages) {
        await saveImageToLocal(url, dlDir: LLM_IG_DIR_V2, showSaveHint: true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('生成失败: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isGenerating = false);
      }
    }
  }

  @override
  Widget buildManagerScreen() => const ImageManagerScreen();

  @override
  void initState() {
    super.initState();

    _selectedImageSize = _imageSizeOptions.first;
    _checkUnfinishedTasks();
  }

  // 检查未完成的任务
  Future<void> _checkUnfinishedTasks() async {
    // 查询未完成的任务
    final unfinishedTasks =
        await dbHelper.queryImageGenerationHistoryByIsFinish(
      isFinish: false,
      modelTypes: [LLModelType.image, LLModelType.tti, LLModelType.iti],
    );

    // 遍历未完成的任务
    for (final task in unfinishedTasks) {
      if (task.taskId != null) {
        try {
          final response = await ImageGenerationService.pollTaskStatus(
            modelList.firstWhere(
                (model) => model.platform == task.llmSpec?.platform),
            task.taskId!,
          );

          if (response.output?.taskStatus == 'SUCCEEDED') {
            await dbHelper.updateImageGenerationHistoryByRequestId(
              task.requestId,
              {
                'isFinish': 1,
                'imageUrls': jsonEncode(
                  response.output?.results?.map((r) => r.url).toList() ?? [],
                ),
              },
            );
          } else if (response.output?.taskStatus == 'FAILED' ||
              response.output?.taskStatus == 'UNKNOWN') {
            await dbHelper.updateImageGenerationHistoryByRequestId(
              task.requestId,
              {'isFinish': 1},
            );
          }
        } catch (e) {
          print('检查任务状态失败: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('检查任务状态失败: $e'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  /// 构建生成的图片区域
  List<Widget> buildImageResultGrid(List<String> urls, String? prefix) {
    return [
      const Divider(),

      // 文生图结果提示行
      Padding(
        padding: EdgeInsets.all(5.sp),
        child: Text(
          "生成的图片(点击查看、长按保存)",
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
      ),

      // 图片展示区域
      Expanded(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(5.sp),
                child: buildNetworkImageViewGrid(
                  context,
                  urls,
                  crossAxisCount: 2,
                  prefix: prefix,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }
}
