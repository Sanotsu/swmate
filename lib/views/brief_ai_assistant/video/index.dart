import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import '../../../common/components/tool_widget.dart';
import '../../../common/constants.dart';
import '../../../common/llm_spec/cus_llm_spec.dart';
import '../../../common/utils/tools.dart';
import '../../../models/image_generation/image_generation_history.dart';
import '../../../services/video_generation_service.dart';
import '../../../views/brief_ai_assistant/video/video_manager.dart';
import '../../../views/brief_ai_assistant/common/media_generation_base.dart';
import 'video_player_screen.dart';

class BriefVideoScreen extends MediaGenerationBase {
  const BriefVideoScreen({super.key});

  @override
  State<BriefVideoScreen> createState() => _BriefVideoScreenState();
}

class _BriefVideoScreenState
    extends MediaGenerationBaseState<BriefVideoScreen> {
  // 所有的视频生成任务
  final List<ImageGenerationHistory> _allTasks = [];

  ///
  /// 2025-02-19 一些视频生成配置参数选项预留，目前都用不上
  ///

  // 视频时长，各个平台目前都暂时不支持输入
  int _videoLength = 3;

  // 除了智谱其他也没有帧率选项，所以暂时也都不用
  final int fps = 24;

  /// 阿里、硅基流动的视频生成没看到分辨率选项，智谱的有一些
  late CusLabel _resolution;
  final List<CusLabel> _resolutionOptions = [
    // 智谱： 默认值: 若不指定，默认生成视频的短边为 1080，长边根据原图片比例缩放。最高支持 4K 分辨率。
    CusLabel(cnLabel: "1:1", value: "1024x1024"),
    CusLabel(cnLabel: "4:3", value: "1280x960"),
    CusLabel(cnLabel: "3:4", value: "960x1280"),
    CusLabel(cnLabel: "16:9", value: "1920x1080"),
    CusLabel(cnLabel: "9:16", value: "1080x1920"),
    CusLabel(cnLabel: "2K", value: "2048x1080"),
    CusLabel(cnLabel: "4K", value: "3840x2160"),
  ];

  // 生成的视频列表(因为视频生成耗时较长，所以这个页面不直接暂时当前任务的视频结果了)
  // final List<String> generatedVideos = [];
  // // 生成的视频封面列表
  // final List<String> generatedCovers = [];

  @override
  List<LLModelType> get mediaTypes => [
        LLModelType.video,
        LLModelType.ttv,
        LLModelType.itv,
      ];

  @override
  String get title => 'AI 视频';

  @override
  String get note => '''
- 目前支持以下平台的视频生成:
  - **阿里云**通义万相-图生视频
  - **智谱AI**的cogvideox
  - **硅基流动**的图生视频
- 可以选择是否上传参考图片
- 视频生成耗时较长，请耐心等待
- 生成的视频会保存在设备的以下目录:
  - Pictures/SWMate/video_generation
''';

  /// 2025-02-19
  /// 分辨率：阿里、硅基流动的视频生成没看到分辨率选项，智谱的有一些
  /// 生成时长：阿里固定5秒，智谱和硅基流动没有相关参数
  /// 所以视频生成，除了模型，统一暂时不配置其他内容
  ///
  @override
  Widget buildMediaOptions() {
    return SizedBox.shrink();
  }

  Widget buildMediaOptionsBak() {
    return SizedBox(
      width: 0.45.sw,
      child: Row(
        children: [
          // 分辨率选择
          Expanded(
            child: buildDropdownButton2<CusLabel?>(
              value: _resolution,
              items: _resolutionOptions,
              hintLabel: "选择类型",
              onChanged: isGenerating
                  ? null
                  : (value) {
                      setState(() => _resolution = value!);
                    },
              itemToString: (e) => (e as CusLabel).cnLabel,
            ),
          ),

          // 视频长度选择(2025-02-19 暂时统一为5秒或者模型默认)
          SizedBox(width: 8.sp),
          Expanded(
            child: DropdownButton<int>(
              value: _videoLength,
              isExpanded: true,
              items: [3, 6, 9, 12].map((length) {
                return DropdownMenuItem(
                  value: length,
                  alignment: AlignmentDirectional.center,
                  child: Text('$length秒', style: TextStyle(fontSize: 12.sp)),
                );
              }).toList(),
              onChanged: isGenerating
                  ? null
                  : (value) {
                      setState(() => _videoLength = value!);
                    },
            ),
          ),
        ],
      ),
    );
  }

  // @override
  // Widget buildGeneratedList() {
  //   if (generatedVideos.isEmpty) {
  //     return const Expanded(child: Center(child: Text('暂无生成的视频')));
  //   }

  //   return Expanded(
  //     child: Column(
  //       children: [
  //         const Divider(),
  //         Padding(
  //           padding: EdgeInsets.all(5.sp),
  //           child: Text(
  //             "生成的视频(点击播放、长按保存)",
  //             style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
  //           ),
  //         ),
  //         Expanded(
  //           child: ListView.builder(
  //             itemCount: generatedVideos.length,
  //             itemBuilder: (context, index) {
  //               return Card(
  //                 margin: EdgeInsets.all(8.sp),
  //                 child: ListTile(
  //                   leading: generatedCovers.isNotEmpty
  //                       ? Image.network(
  //                           generatedCovers[index],
  //                           width: 50.sp,
  //                           height: 50.sp,
  //                           fit: BoxFit.cover,
  //                         )
  //                       : Icon(Icons.video_file, size: 50.sp),
  //                   title: Text('视频 ${index + 1}'),
  //                   subtitle: Text('$_resolution - $_videoLength秒'),
  //                   onTap: () {
  //                     Navigator.push(
  //                       context,
  //                       MaterialPageRoute(
  //                         builder: (_) => VideoPlayerScreen(
  //                           videoUrl: generatedVideos[index],
  //                         ),
  //                       ),
  //                     );
  //                   },
  //                   onLongPress: () async {
  //                     try {
  //                       await saveVideoToLocal(
  //                         generatedVideos[index],
  //                         dlDir: LLM_VG_DIR,
  //                       );
  //                       if (!context.mounted) return;
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                         const SnackBar(content: Text('保存成功')),
  //                       );
  //                     } catch (e) {
  //                       if (!context.mounted) return;
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                         SnackBar(content: Text('保存失败: $e')),
  //                       );
  //                     }
  //                   },
  //                 ),
  //               );
  //             },
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget buildGeneratedList() {
    if (_allTasks.isEmpty) {
      return const Expanded(child: Center(child: Text('暂无视频生成任务')));
    }

    return Expanded(
      child: Column(
        children: [
          const Divider(),
          Padding(
            padding: EdgeInsets.all(5.sp),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "视频生成任务",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    if (_allTasks.isNotEmpty) {
                      for (final task in _allTasks) {
                        await dbHelper.deleteImageGenerationHistoryByRequestId(
                          task.requestId,
                        );
                      }

                      if (!mounted) return;
                      setState(() => _allTasks.clear());
                    }
                  },
                  icon: Icon(Icons.delete),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _allTasks.length,
              itemBuilder: (context, index) {
                var task = _allTasks[index];

                return Card(
                  margin: EdgeInsets.all(5.sp),
                  child: ListTile(
                    leading: Icon(Icons.video_file, size: 50.sp),
                    title: Text(task.llmSpec?.platform.name ?? ''),
                    subtitle: Text(task.prompt),
                    // 视频生成任务，虽然设计时可能有多个，但实际只是有一个元素的数组
                    trailing: task.isFinish &&
                            task.videoUrls?.first != null &&
                            task.videoUrls?.first.trim() != ''
                        ? IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NetworkVideoPlayerScreen(
                                    videoUrl: task.videoUrls!.first.trim(),
                                  ),
                                ),
                              );
                            },
                            icon: Icon(Icons.play_circle, size: 32.sp),
                          )
                        : const SizedBox.shrink(),
                    onTap: () {},
                    onLongPress: () async {},
                  ),
                );
              },
            ),
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
      // 2025-02-19 暂时只配置模型，如果是图生视频，多一个参考图，其他都不传
      // 2025-02-20 返回提交任务的响应，而不是生成结果,因为视频生成耗时较长，需要轮询任务状态
      final response = await VideoGenerationService.generateVideo(
        selectedModel!,
        promptController.text.trim(),
        referenceImagePath: referenceImage?.path,
        // fps: fps,
        // size: _resolution.value,
      );

      String taskId = "";

      switch (selectedModel!.platform) {
        case ApiPlatform.siliconCloud:
          taskId = response.requestId ?? "";
          break;
        case ApiPlatform.aliyun:
          taskId = response.output?.taskId ?? "";
          break;
        case ApiPlatform.zhipu:
          taskId = response.id ?? "";
          break;
        default:
          throw Exception('不支持的平台');
      }

      // 创建历史记录
      // 将视频生成任务提交响应保存到历史记录，后续轮询任务状态
      final history = ImageGenerationHistory(
        requestId: response.requestId ?? const Uuid().v4(),
        prompt: promptController.text.trim(),
        taskId: taskId,
        isFinish: false,
        videoUrls: null,
        refImageUrls: [],
        gmtCreate: DateTime.now(),
        llmSpec: selectedModel,
        modelType: LLModelType.video,
      );

      final requestId = await dbHelper.insertImageGenerationHistory(history);

      EasyLoading.showSuccess('视频生成任务提交成功$requestId');

      if (!mounted) return;
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
  Widget buildManagerScreen() => const VideoManagerScreen();

  @override
  void initState() {
    super.initState();

    _resolution = _resolutionOptions.first;

    _checkUnfinishedTasks();
  }

  // 检查未完成的任务
  Future<void> _checkUnfinishedTasks() async {
    // 查询所有视频生成任务
    final all = await dbHelper.queryImageGenerationHistoryByIsFinish(
      modelTypes: [LLModelType.video, LLModelType.ttv, LLModelType.itv],
    );

    print('<<<<<<<<<<<<<all: ${all.first.videoUrls}');

    // 过滤出未完成的任务
    final unfinishedTasks = all.where((e) => e.isFinish == false).toList();

    setState(() {
      // _allTasks.addAll(unfinishedTasks);
      _allTasks.addAll(all);
    });

    print(
      '所有任务: ${all.length} 未完成的任务: ${unfinishedTasks.length} ${LLModelType.video.toString()}',
    );

    // 遍历未完成的任务
    for (final task in unfinishedTasks) {
      if (task.taskId != null) {
        print('task.taskId: ${task.taskId}');
        try {
          final response = await VideoGenerationService.pollTaskStatus(
            task.taskId!,
            modelList.firstWhere(
                (model) => model.platform == task.llmSpec?.platform),
          );

          // 2025-02-20 视频生成成功,但大部分的在线地址都是临时地址，所以需要保存到本地
          // 存入数据库的就是本地地址(那就要注意，视频删除时也要更新数据库)
          // 除了智谱其他都没有封面图，所以暂时统一不处理封面图属性
          if (response.status == 'SUCCEEDED') {
            var urls = response.results?.map((r) => r.url).toList() ?? [];

            // 保存视频到本地
            var newUrls = <String>[];
            for (final url in urls) {
              var newUrl = await saveVideoToLocal(url,
                  dlDir: LLM_VG_DIR, showSaveHint: false);
              if (newUrl != null) {
                newUrls.add(newUrl);
              }
            }

            // 更新数据库视频地址
            await dbHelper.updateImageGenerationHistoryByRequestId(
              task.requestId,
              {
                'isFinish': 1,
                'videoUrls': newUrls.join(";"),
              },
            );

            // 更新UI
            if (mounted) {
              setState(() {
                _allTasks
                    .firstWhere((e) => e.requestId == task.requestId)
                    .videoUrls = newUrls;
              });
            }
          } else if (response.code == 'FAILED' || response.code == 'UNKNOWN') {
            await dbHelper.updateImageGenerationHistoryByRequestId(
              task.requestId,
              {'isFinish': 1},
            );

            // 更新UI
            if (mounted) {
              setState(() {
                _allTasks
                    .firstWhere((e) => e.requestId == task.requestId)
                    .isFinish = true;
              });
            }
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
}
