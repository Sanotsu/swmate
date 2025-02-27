import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import '../../../common/components/tool_widget.dart';
import '../../../common/constants.dart';
import '../../../common/llm_spec/cus_llm_spec.dart';
import '../../../common/utils/tools.dart';
import '../../../models/media_generation_history/media_generation_history.dart';
import '../../../services/image_generation_service.dart';
import '../../../views/brief_ai_assistant/common/media_generation_base.dart';
import 'mime_image_manager.dart';

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
    // 智谱(传参时修改为比例接近的尺寸)
    //  CusLabel(cnLabel: "1:1", value: "1024x1024"),
    // CusLabel(cnLabel: "4:7", value: "768x1344"),
    // CusLabel(cnLabel: "3:4", value: "864x1152"),
    // CusLabel(cnLabel: "7:4", value: "1344x768"),
    // CusLabel(cnLabel: "4:3", value: "1152x864"),
    // CusLabel(cnLabel: "2:1", value: "1440x720"),
    // CusLabel(cnLabel: "1:2", value: "720x1440"),
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
- 先选择平台模型和图片比例，再输入提示词
  - 智谱支持的尺寸与众不同，故用近似比例
- 文生图耗时较长，**请勿在生成过程中退出**
- 默认一次生成1张图片
- 生成的图片会保存在设备的以下目录:
  - /SWMate/brief_image_generation
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
    );
  }

  @override
  Widget buildGeneratedList() {
    if (_generatedImages.isEmpty) {
      return const Expanded(child: Center(child: Text('暂无生成的图片')));
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
      final history = MediaGenerationHistory(
        requestId: const Uuid().v4(),
        prompt: promptController.text.trim(),
        negativePrompt: '',
        taskId: null,
        imageUrls: null,
        refImageUrls: [],
        gmtCreate: DateTime.now(),
        llmSpec: selectedModel!,
        modelType: selectedModel!.modelType,
      );

      final requestId = await dbHelper.insertMediaGenerationHistory(history);

      // 生成图片(这里返回的就已经是生成图片的结果了)
      // 2025-02-20 因为智谱的文生图比例和其他的差异过大，所以这里特殊处理
      // 使用比例接近的尺寸
      String tempSize = _selectedImageSize.value;

      if (selectedModel?.platform == ApiPlatform.zhipu) {
        switch (_selectedImageSize.cnLabel) {
          case "1:1":
            tempSize = "1024x1024";
            break;
          case "1:2":
            tempSize = "720x1440";
            break;
          case "3:2":
            tempSize = "1344x768";
            break;
          case "3:4":
            tempSize = "864x1152";
            break;
          case "16:9":
            tempSize = "1440x720";
            break;
          case "9:16":
            tempSize = "768x1344";
            break;
          default:
            tempSize = "1024x1024";
            break;
        }
      }

      final response = await ImageGenerationService.generateImage(
        selectedModel!,
        promptController.text.trim(),
        n: 1,
        size: selectedModel?.platform == ApiPlatform.aliyun
            ? tempSize.replaceAll('x', '*')
            : tempSize,
      );

      if (!mounted) return;

      // 保存返回的网络图片到本地
      var imageUrls = response.results.map((r) => r.url).toList();
      List<String> newUrls = [];
      for (final url in imageUrls) {
        var localPath = await saveImageToLocal(
          url,
          dlDir: LLM_IG_DIR_V2,
          showSaveHint: false,
        );

        if (localPath != null) {
          newUrls.add(localPath);
        }
      }

      // 更新UI(这里使用网络地址或本地地址没差，毕竟历史记录在其他页面，这里只有当前页面还在时才有图片展示)
      if (!mounted) return;
      setState(() {
        _generatedImages.addAll(newUrls);
      });

      // 更新数据库历史记录。如果是阿里云平台，则需要保存任务ID和已完成的标识
      await dbHelper.updateMediaGenerationHistoryByRequestId(
        requestId,
        {
          'taskId': selectedModel?.platform == ApiPlatform.aliyun
              ? response.output?.taskId
              : null,
          'isSuccess': 1,
          'imageUrls': _generatedImages.join(','),
        },
      );
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
  // Widget buildManagerScreen() => const ImageManagerScreen();

  // 2025-02-26 ??? 多次测试，在生成图片并保存后，
  // 使用photo_manager搜索定位到指定AI生成图片文件夹，并看不到所有的图片。
  // 可能实际有10张，photo_manager得到6张，原因还在探索。
  // 暂时使用遍历文件夹中的File List，通过mime库区分媒体资源内容，然后简单预览
  // 但是媒体资源的信息就差很多，只能得到File的信息而不是原始媒体资源的信息
  Widget buildManagerScreen() => const MimeImageManager();

  @override
  void initState() {
    super.initState();

    _selectedImageSize = _imageSizeOptions.first;
    _checkUnfinishedTasks();
  }

  // 检查未完成的任务
  // 2025-02-20 和视频生成中不一样，图片生成目前就阿里云的通义万相-文生图V2版需要任务查询，其他直接返回的
  // 耗时不会特别长，所以这里调用轮询
  Future<void> _checkUnfinishedTasks() async {
    // 查询未完成的任务
    final all = await dbHelper.queryMediaGenerationHistory(
      modelTypes: [LLModelType.image, LLModelType.tti, LLModelType.iti],
    );

    // 过滤出未完成的任务
    final unfinishedTasks = all.where((e) => e.isProcessing == true).toList();

    // 遍历未完成的任务
    for (final task in unfinishedTasks) {
      if (task.taskId != null) {
        try {
          final response = await ImageGenerationService.pollTaskStatus(
            modelList.firstWhere(
              (model) => model.platform == task.llmSpec.platform,
            ),
            task.taskId!,
          );

          if (response.output?.taskStatus == 'SUCCEEDED') {
            await dbHelper.updateMediaGenerationHistoryByRequestId(
              task.requestId,
              {
                'isSuccess': 1,
                'imageUrls': response.output?.results
                        ?.map((r) => r.url)
                        .toList()
                        .join(',') ??
                    '',
              },
            );
          } else if (response.output?.taskStatus == 'FAILED' ||
              response.output?.taskStatus == 'UNKNOWN') {
            await dbHelper.updateMediaGenerationHistoryByRequestId(
              task.requestId,
              {'isFailed': 1},
            );
          }
        } catch (e) {
          // print('检查任务状态失败: $e');
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
