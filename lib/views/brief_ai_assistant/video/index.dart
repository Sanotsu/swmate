import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import '../../../common/components/tool_widget.dart';
import '../../../common/constants/constants.dart';
import '../../../common/llm_spec/constant_llm_enum.dart';
import '../../../common/utils/tools.dart';
import '../../../models/brief_ai_tools/media_generation_history/media_generation_history.dart';
import '../../../services/video_generation_service.dart';
import '../../../views/brief_ai_assistant/common/media_generation_base.dart';
import 'mime_video_manager.dart';
import 'video_player_screen.dart';

class BriefVideoScreen extends MediaGenerationBase {
  const BriefVideoScreen({super.key});

  @override
  State<BriefVideoScreen> createState() => _BriefVideoScreenState();
}

class _BriefVideoScreenState
    extends MediaGenerationBaseState<BriefVideoScreen> {
  // 所有的视频生成任务
  final List<MediaGenerationHistory> _allTasks = [];

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
  - **阿里云**通义万相-文/图生视频
  - **智谱AI**的cogvideox
  - **硅基流动**的视频生成
- 部分模型可以选择是否上传参考图片
- 视频生成耗时较长，可稍后查询任务状态
- 生成的视频会自动保存在设备的以下目录:
  - /SWMate/brief_video_generation
- 视频生成任务记录可以长按删除
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

  @override
  Widget buildGeneratedList() {
    if (_allTasks.isEmpty) {
      return const Expanded(child: Center(child: Text('暂无视频生成任务')));
    }

    return Expanded(
      child: Column(
        children: [
          Divider(height: 5.sp),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.sp),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "视频生成任务",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                IconButton(
                  onPressed: () => _checkUnfinishedTasks(),
                  icon: Icon(Icons.refresh, color: Colors.blue),
                ),
              ],
            ),
          ),
          Divider(height: 5.sp),
          Expanded(
            child: ListView.builder(
              itemCount: _allTasks.length,
              itemBuilder: (context, index) {
                var task = _allTasks[index];

                return Card(
                  margin: EdgeInsets.all(5.sp),
                  child: ListTile(
                    leading: Icon(Icons.video_file, size: 48.sp),
                    title: Text(CP_NAME_MAP[task.llmSpec.platform] ?? ''),
                    subtitle: Text(
                      task.prompt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    // 视频生成任务，虽然设计时可能有多个，但实际只是有一个元素的数组
                    trailing: task.isSuccess &&
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
                            icon: Icon(
                              Icons.play_circle,
                              size: 36.sp,
                              color: Colors.blue,
                            ),
                          )
                        : Icon(Icons.hourglass_empty, size: 36.sp),
                    // 长按删除
                    onLongPress: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('删除视频生成任务'),
                          content: Text(
                            '删除后，视频生成任务记录将不再显示，但不会影响已保存的视频文件。',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context, false);
                              },
                              child: Text('取消'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context, true);
                              },
                              child: Text('确定'),
                            ),
                          ],
                        ),
                      );

                      if (result == true) {
                        await dbHelper.deleteMediaGenerationHistoryByRequestId(
                          task.requestId,
                        );
                      }

                      if (!mounted) return;
                      await _queryAllTasks();
                    },
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
      final history = MediaGenerationHistory(
        requestId: response.requestId ?? const Uuid().v4(),
        prompt: promptController.text.trim(),
        refImageUrls: [],
        taskId: taskId,
        isSuccess: false,
        isProcessing: true,
        isFailed: false,
        videoUrls: null,
        gmtCreate: DateTime.now(),
        llmSpec: selectedModel!,
        modelType: LLModelType.video,
      );

      await dbHelper.insertMediaGenerationHistory(history);

      EasyLoading.showSuccess('视频生成任务已提交成功');

      // 提交新任务之后，重新查询所有任务并更新UI
      await _queryAllTasks();
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
  // Widget buildManagerScreen() => const VideoManagerScreen();

  // ？？？2025-02-26 参考图片管理的备注
  Widget buildManagerScreen() => const MimeVideoManager();

  @override
  void initState() {
    super.initState();

    _resolution = _resolutionOptions.first;

    _checkUnfinishedTasks();
  }

  // 查询所有视频生成任务
  Future<void> _queryAllTasks() async {
    final all = await dbHelper.queryMediaGenerationHistory(
      modelTypes: [LLModelType.video, LLModelType.ttv, LLModelType.itv],
    );

    if (!mounted) return;
    setState(() {
      _allTasks.clear();
      _allTasks.addAll(all);
    });
  }

  // 检查未完成的任务
  Future<void> _checkUnfinishedTasks() async {
    try {
      // 查询所有视频生成任务
      await _queryAllTasks();

      // 过滤出未完成的任务
      final unfinishedTasks =
          _allTasks.where((e) => e.isProcessing == true).toList();

      if (unfinishedTasks.isEmpty) return;

      // 并行处理未完成的任务，查询任务状态(不轮询，让用户手动刷新)
      await Future.wait(unfinishedTasks.map((task) async {
        if (task.taskId != null) {
          final model = modelList.firstWhere(
            (m) => m.platform == task.llmSpec.platform,
          );

          final response = await VideoGenerationService.queryTaskStatus(
            task.taskId!,
            model,
          );

          // 使用查询到的任务状态更新数据库(大体栏位是一样的，就更新部分状态和结果栏位)
          var item = MediaGenerationHistory.fromMap(task.toMap());

          // 统一状态，然后在实际响应的状态的再次更新
          item.taskStatus = response.taskStatus;

          // 如果有成功或者失败的，视频地址栏位也要更新

          // 2025-02-20 视频生成成功,但大部分的在线地址都是临时地址，所以需要保存到本地
          // 存入数据库的就是本地地址(那就要注意，视频删除时也要更新数据库)
          List<String> newUrls = [];

          switch (model.platform) {
            case ApiPlatform.siliconCloud:
              if (response.taskStatus == 'Succeed') {
                item.isSuccess = true;
                item.isProcessing = false;
                item.isFailed = false;

                newUrls = await _saveNetworkVideosToLocal(
                  response.results?.videos?.map((e) => e.url).toList() ?? [],
                );
                item.videoUrls = newUrls;
              }
              break;
            case ApiPlatform.aliyun:
              if (response.output?.taskStatus == 'SUCCEEDED') {
                item.isSuccess = true;
                item.isProcessing = false;
                item.isFailed = false;

                newUrls = await _saveNetworkVideosToLocal(
                  [response.output?.videoUrl ?? ''],
                );
                item.videoUrls = newUrls;
              }
              if (response.output?.taskStatus == 'FAILED' ||
                  response.output?.taskStatus == 'UNKNOWN') {
                item.isSuccess = false;
                item.isProcessing = false;
                item.isFailed = true;
              }
              break;
            case ApiPlatform.zhipu:
              if (response.taskStatus == 'SUCCESS') {
                item.isSuccess = true;
                item.isProcessing = false;
                item.isFailed = false;

                newUrls = await _saveNetworkVideosToLocal(
                  response.videoResult?.map((e) => e.url).toList() ?? [],
                );
                item.videoUrls = newUrls;
              }
              if (response.output?.taskStatus == 'FAIL') {
                item.isSuccess = false;
                item.isProcessing = false;
                item.isFailed = true;
              }
              break;
            default:
              throw Exception('不支持的平台');
          }

          await dbHelper.updateMediaGenerationHistory(item);

          // 更新UI
          // if (mounted) {
          //   setState(() {
          //     _allTasks
          //         .firstWhere((e) => e.requestId == task.requestId)
          //         .videoUrls = newUrls;
          //   });
          // }
        }
      }));

      // 未完成任务查询完之后，重新更新UI
      await _queryAllTasks();
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

  // 保存视频到本地
  Future<List<String>> _saveNetworkVideosToLocal(List<String> urls) async {
    final localUrls = <String>[];
    for (final url in urls) {
      final localUrl = await saveVideoToLocal(
        url,
        dlDir: LLM_VG_DIR_V2,
        showSaveHint: false,
      );
      if (localUrl != null) {
        localUrls.add(localUrl);
      }
    }
    return localUrls;
  }
}
