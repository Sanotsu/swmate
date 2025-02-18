import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

import '../../../common/components/tool_widget.dart';
import '../../../common/constants.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../common/llm_spec/cus_llm_spec.dart';
import '../../../common/utils/tools.dart';
import '../../../services/image_generation_service.dart';
import '../../../services/model_manager_service.dart';
import '../../../common/utils/db_tools/db_helper.dart';
import '../../../models/image_generation/image_generation_history.dart';
import '../../../views/brief_ai_assistant/image/image_manager.dart';

class BriefImageScreen extends StatefulWidget {
  const BriefImageScreen({super.key});

  @override
  State<BriefImageScreen> createState() => _BriefImageScreenState();
}

class _BriefImageScreenState extends State<BriefImageScreen> {
  // 提示词输入框
  final TextEditingController _promptController = TextEditingController();
  // 模型选择
  CusBriefLLMSpec? _selectedModel;
  // 尺寸选择
  String _selectedSize = '1024x1024';
  // 模型列表
  List<CusBriefLLMSpec> _modelList = [];
  // 生成的图片列表
  final List<String> _generatedImages = [];
  // 是否正在生成
  bool _isGenerating = false;
  // 数据库帮助类
  final DBHelper _dbHelper = DBHelper();
  // 图片尺寸选项
  final List<String> _sizeOptions = [
    '1024x1024',
    '512x1024',
    '768x512',
    '768x1024',
    '1024x576',
    '576x1024',
  ];

  String note = '''
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
  void initState() {
    super.initState();
    _loadModels();
    _checkUnfinishedTasks();
  }

  // 加载可用模型
  Future<void> _loadModels() async {
    final models = await ModelManagerService.getAvailableModelByTypes([
      LLModelType.image,
    ]);

    if (mounted) {
      setState(() {
        _modelList = models;
        _selectedModel = models.isNotEmpty ? models.first : null;
      });
    }
  }

  // 检查未完成的任务
  Future<void> _checkUnfinishedTasks() async {
    // 查询未完成的任务
    final unfinishedTasks =
        await _dbHelper.queryImageGenerationHistoryByIsFinish(
      isFinish: false,
    );

    // 遍历未完成的任务
    for (final task in unfinishedTasks) {
      if (task.taskId != null) {
        try {
          final response = await ImageGenerationService.pollTaskStatus(
            _modelList.firstWhere(
                (model) => model.platform == task.llmSpec?.platform),
            task.taskId!,
          );

          if (response.output?.taskStatus == 'SUCCEEDED') {
            await _dbHelper.updateImageGenerationHistoryByRequestId(
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
            await _dbHelper.updateImageGenerationHistoryByRequestId(
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

  // 生成图片
  Future<void> _generateImage() async {
    unfocusHandle();

    if (_selectedModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请先选择模型'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请输入提示词'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // 创建历史记录
      final history = ImageGenerationHistory(
        requestId: const Uuid().v4(),
        prompt: prompt,
        // 2025-02-17 暂时没有负向提示词
        negativePrompt: '',
        // 默认没有任务ID，结果也是未完成
        taskId: null,
        isFinish: false,
        // 阿里云新版本应该没有这个字段了
        style: '',
        imageUrls: null,
        refImageUrls: [],
        gmtCreate: DateTime.now(),
        llmSpec: _selectedModel,
        modelType: LLModelType.image,
      );

      final requestId = await _dbHelper.insertImageGenerationHistory(history);

      // 如果这里有结果了，说明在service中已经轮询得到图片结果了，则需要更新isFinish为true(默认为false)
      final response = await ImageGenerationService.generateImage(
        _selectedModel!,
        prompt,
        n: 1,
        size: _selectedModel?.platform == ApiPlatform.aliyun
            ? _selectedSize.replaceAll('x', '*')
            : _selectedSize,
      );

      if (!mounted) return;

      // 如果是阿里云平台，则需要保存任务ID和已完成的标识
      if (_selectedModel?.platform == ApiPlatform.aliyun) {
        await _dbHelper.updateImageGenerationHistoryByRequestId(
          requestId,
          {
            'taskId': response.output?.taskId,
            'isFinish': 1,
            'imageUrls': jsonEncode(
              response.output?.results?.map((r) => r.url).toList() ?? [],
            ),
          },
        );
      }

      // 直接更新结果
      setState(() {
        _generatedImages.addAll(
          response.results.map((r) => r.url).toList(),
        );
      });

      await _dbHelper.updateImageGenerationHistoryByRequestId(
        requestId,
        {
          'isFinish': 1,
          'imageUrls': jsonEncode(
            response.results.map((r) => r.url).toList(),
          ),
        },
      );

      // 保存图片到本地
      for (final url in response.results.map((r) => r.url).toList()) {
        await saveImageToLocal(url, dlDir: LLM_IG_DIR_V2, showSaveHint: false);
      }
    } catch (e) {
      if (mounted) {
        print('生成失败: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('生成失败: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 绘图'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ImageManagerScreen(),
                ),
              );
            },
          ),
          IconButton(
            onPressed: () {
              commonMDHintModalBottomSheet(
                context,
                "AI绘图使用说明",
                note,
                msgFontSize: 15.sp,
              );
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          /// 模型和尺寸选择
          Padding(
            padding: EdgeInsets.all(5.sp),
            child: Row(
              children: [
                // 模型选择
                Expanded(
                  child: DropdownButton<CusBriefLLMSpec>(
                    value: _selectedModel,
                    isExpanded: true,
                    menuMaxHeight: 0.5.sh,
                    items: _modelList.map((model) {
                      return DropdownMenuItem(
                        value: model,
                        child: Text(
                          '${model.platform.name} - ${model.name}',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      );
                    }).toList(),
                    onChanged: _isGenerating
                        ? null
                        : (model) {
                            setState(() {
                              _selectedModel = model;
                              // 切换平台时重置尺寸
                              _selectedSize = _sizeOptions.first;
                            });
                          },
                  ),
                ),
                SizedBox(width: 10.sp),
                // 尺寸选择
                SizedBox(
                  width: 90.sp,
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedSize,
                    alignment: AlignmentDirectional.center,
                    items: _sizeOptions
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        alignment: AlignmentDirectional.center,
                        child: Text(value, style: TextStyle(fontSize: 12.sp)),
                      );
                    }).toList(),
                    onChanged: _isGenerating
                        ? null
                        : (size) {
                            setState(() => _selectedSize = size!);
                          },
                  ),
                ),
              ],
            ),
          ),

          /// 提示词输入
          Padding(
            padding: EdgeInsets.all(5.sp),
            child: TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: '提示词',
                hintText: '请输入图片描述',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              enabled: !_isGenerating,
            ),
          ),

          /// 生成按钮
          SizedBox(
            width: 1.sw - 10.sp,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generateImage,
              style: ElevatedButton.styleFrom(
                // shape: RoundedRectangleBorder(
                //   // 设置圆角大小
                //   borderRadius: BorderRadius.circular(10.sp),
                // ),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: _isGenerating
                  ? SizedBox(
                      width: 24.sp,
                      height: 24.sp,
                      child: CircularProgressIndicator(),
                    )
                  : const Text('生成图片'),
            ),
          ),

          /// 图片展示
          Expanded(
            child: Column(
              children: [
                /// 文生图的结果
                if (_generatedImages.isNotEmpty)
                  ...buildImageResultGrid(
                    _generatedImages,
                    "${_selectedModel?.platform.name}_${_selectedModel?.name}",
                  ),
              ],
            ),
          ),
        ],
      ),
    );
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

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }
}
