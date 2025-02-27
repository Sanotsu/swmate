import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../../../../apis/video_generation/zhipuai_cogvideox_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/llm_spec/cus_llm_model.dart';
import '../../../../common/llm_spec/cus_llm_spec.dart';
import '../../../../common/utils/db_tools/db_ai_tool_helper.dart';
import '../../../../common/utils/tools.dart';
import '../../../../models/text_to_image/com_ig_state.dart';
import '../../../../models/text_to_video/cogvideox_req.dart';
import '../../../../models/text_to_video/cogvideox_resp.dart';
import '../../_componets/cus_platform_and_llm_row.dart';
import '../../_componets/cus_system_prompt_modal.dart';
import '../../_componets/loading_overlay.dart';
import '../../_componets/prompt_input.dart';
import '../../_helper/tools.dart';
import '../../_ig_screen_parts/ig_button_row_area.dart';
import '../../_ig_screen_parts/igvg_history_screen.dart';
import '../../_ig_screen_parts/image_pick_and_view_area.dart';

class CogVideoXScreen extends StatefulWidget {
  // 可供挑选的模型列表
  final List<CusLLMSpec> llmSpecList;
  // 可供挑选的预设系统角色
  final List<CusSysRoleSpec> cusSysRoleSpecs;

  const CogVideoXScreen({
    super.key,
    required this.llmSpecList,
    required this.cusSysRoleSpecs,
  });

  @override
  State<CogVideoXScreen> createState() => _CogVideoXScreenState();
}

class _CogVideoXScreenState extends State<CogVideoXScreen>
    with WidgetsBindingObserver {
  final DBAIToolHelper dbHelper = DBAIToolHelper();

  // 所有支持文生图的模型列表(用于下拉的平台和该平台拥有的模型列表也从这里来)
  late List<CusLLMSpec> llmSpecList;

  // 所有支持文生图的系统角色(用于获取预设的system prompt的值)
  late List<CusSysRoleSpec> sysRoleList;

  // 级联选择效果：云平台-模型名
  late ApiPlatform selectedPlatform;

  // 被选中的模型信息
  late CusLLMSpec selectedModelSpec;

  // 输入的正向提示词
  final promptController = TextEditingController();
  String prompt = "";

  // 选择的参考图片文件
  File? selectedImage;

  // 是否正在生成视频
  bool isGenVideo = false;

  // 最后生成的视频封面图地址
  List<String> rstCoverImageUrls = [];
  // 最后生成的视频地址
  List<String> rstVideoUrls = [];

  @override
  void initState() {
    super.initState();

    initCommonState();

    WidgetsBinding.instance.addObserver(this);
  }

  void initCommonState() {
    setState(() {
      llmSpecList = widget.llmSpecList;
      sysRoleList = widget.cusSysRoleSpecs;
    });

    // 每次进来都随机选一个平台
    List<ApiPlatform> plats =
        llmSpecList.map((e) => e.platform).toSet().toList();
    setState(() {
      selectedPlatform = plats[Random().nextInt(plats.length)];
    });

    // 同样的，选中的平台后也随机选择一个模型
    List<CusLLMSpec> models =
        llmSpecList.where((spec) => spec.platform == selectedPlatform).toList();
    setState(() {
      selectedModelSpec = models[Random().nextInt(models.length)];
    });
  }

  /// 获取文生图的数据
  Future<void> getVideoGenerationData() async {
    if (isGenVideo) {
      return;
    }

    setState(() {
      isGenVideo = true;
      // 开始获取视频后，添加遮罩
      LoadingOverlay.show(
        context,
        onCancel: () => setState(() => isGenVideo = false),
      );
    });

    debugPrint("选择的平台 $selectedPlatform");
    debugPrint("选择的模型 ${selectedModelSpec.toRawJson()}");
    debugPrint("正向词 $prompt");
    debugPrint("选择的图片地址 $selectedImage");

    // 请求得到的封面图片和视频结果地址
    List<String> imageUrls = [];
    List<String> videoUrls = [];

    String? imageBase64String = await getImageBase64String(selectedImage);

    CogVideoXReq param = CogVideoXReq(
      model: selectedModelSpec.model,
      prompt: prompt,
      imageUrl: imageBase64String,
    );

    var jobResp = await commitZhipuCogVideoXTask(param);

    if (!mounted) return;
    if (jobResp.error?.code != null) {
      setState(() {
        isGenVideo = false;
        LoadingOverlay.hide();
      });
      return commonExceptionDialog(
        context,
        "发生异常",
        "生成视频出错:${jobResp.error?.message}",
      );
    }

    // 查询文生图任务状态
    // 理论上成功的话一定有id的，暂时不处理取值异常了
    String taskId = jobResp.id!;

    // 将任务编号存入数据库，方便后续查询(比如发起调用后task成功创建，但还没有产生结果时就关闭页面了)
    LlmIGVGResult temp = LlmIGVGResult(
      requestId: jobResp.requestId ?? const Uuid().v4(),
      prompt: prompt,
      taskId: taskId,
      isFinish: false,
      videoCoverImageUrls: null,
      videoUrls: null,
      refImageUrls: selectedImage?.path != null ? [selectedImage!.path] : null,
      gmtCreate: DateTime.now(),
      llmSpec: selectedModelSpec,
      modelType: LLModelType.ttv,
    );

    await dbHelper.insertIGVGResultList([temp]);

    // 定时查询文生视频任务
    CogVideoXResp? result = await timedVideoGenerationTaskStatus(
      taskId,
      () => setState(() {
        isGenVideo = false;
        LoadingOverlay.hide();
      }),
    );

    if (!mounted) return;
    if (result?.error?.code != null) {
      setState(() {
        isGenVideo = false;
        LoadingOverlay.hide();
      });

      return commonExceptionDialog(
        context,
        "发生异常",
        "查询文本生视频任务进度报错:${jobResp.error?.message}",
      );
    }

    // 得到视频结果，存入变量
    var a = result?.videoResult;
    if (a != null && a.isNotEmpty) {
      for (var e in a) {
        imageUrls.add(e.coverImageUrl);
        videoUrls.add(e.url);
      }

      // 正确获得文生图结果之后，将生成记录保存
      // 因为创建任务时有保存到缓存，此时更新结果即可，修改的条件是判断taskId
      temp.gmtCreate = DateTime.now();
      temp.isFinish = true;
      temp.videoCoverImageUrls = imageUrls;
      temp.videoUrls = videoUrls;
      await dbHelper.updateIGVGResultById(temp);

      if (!mounted) return;
      setState(() {
        rstCoverImageUrls = imageUrls;
        rstVideoUrls = videoUrls;
        isGenVideo = false;
        LoadingOverlay.hide();
      });
    }
  }

  // 选中预设的提示词，就代替当前输入框的值
  void onRoleSelected(CusSysRoleSpec role) {
    setState(() {
      promptController.text = role.systemPrompt;
      prompt = role.systemPrompt;
    });
  }

  /// 构建配置区域
  List<Widget> buildConfigArea({bool? isOnlySize}) {
    return [
      /// 平台和模型选择
      CusPlatformAndLlmRow(
        initialPlatform: selectedPlatform,
        initialModelSpec: selectedModelSpec,
        llmSpecList: llmSpecList,
        targetModelType: LLModelType.ttv,
        showToggleSwitch: false,
        onPlatformOrModelChanged: (cp, llmSpec) {
          setState(() {
            selectedPlatform = cp!;
            selectedModelSpec = llmSpec!;
          });
        },
      ),

      /// 正向、反向提示词
      Column(
        children: [
          PromptInput(
            label: "正向提示词",
            hintText: '视频的文本描述、最大支持500Tokens输入。\n比如：“一只展翅翱翔的狸花猫”',
            controller: promptController,
            onChanged: (text) {
              setState(() {
                prompt = text.trim();
              });
            },
            isRequired: true,
          ),
        ],
      ),

      /// 参考图
      SizedBox(
        height: 100.sp,
        child: ImagePickAndViewArea(
          imageSelectedHandle: (ImageSource source) async {
            final picker = ImagePicker();
            final pickedFile = await picker.pickImage(source: source);

            if (pickedFile != null) {
              setState(() {
                selectedImage = File(pickedFile.path);
              });
            }
          },
          imageClearHandle: () => setState(() => selectedImage = null),
          selectedImage: selectedImage,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("文生视频"),
        actions: [
          TextButton(
            onPressed: () {
              showCusSysRoleList(
                context,
                sysRoleList,
                onRoleSelected,
              );
            },
            child: const Text("预设提示词"),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const IGVGHistoryScreen(
                    lable: "文生视频",
                    modelType: LLModelType.ttv,
                  ),
                ),
              ).then((value) {
                unfocusHandle();
              });
            },
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: GestureDetector(
        // 允许子控件（如TextField）接收点击事件
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // 点击空白处可以移除焦点，关闭键盘
          unfocusHandle();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// 构建文生图配置和执行按钮区域(固定在上方，配置和生成结果可以滚动)
            ImageGenerationButtonArea(
              title: "视频生成配置",
              buttonLable: "生成视频",
              onGenerate: () async {
                unfocusHandle();
                try {
                  await getVideoGenerationData();
                } catch (e) {
                  setState(() {
                    isGenVideo = false;
                    LoadingOverlay.hide();
                    EasyLoading.showError(
                      e.toString(),
                      duration: const Duration(seconds: 5),
                    );
                  });
                }
              },
              // 提示词或者参考图不可都为空
              canGenerate: prompt.isNotEmpty || selectedImage != null,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    /// 文生视频配置折叠栏
                    ...buildConfigArea(),

                    /// 文生视频的结果
                    if (rstVideoUrls.isNotEmpty)
                      ...buildVideoResult(
                        rstVideoUrls,
                        rstCoverImageUrls,
                      ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

/// 构建生成的视频区域
/// 历史记录详情中也会用到
List<Widget> buildVideoResult(List<String> videoUrls, List<String> coverUrls) {
  return [
    /// 文生图结果提示行
    Padding(
      padding: EdgeInsets.all(5.sp),
      child: Text(
        "生成的视频(点击查看、长按保存)",
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
      ),
    ),

    /// 视频封面放一行，最多只有4张
    SizedBox(
      // 最多4张封面图，放在一排就好(高度即四分之一的宽度左右)。在最下面留点空即可
      height: 0.25.sw + 5.sp,
      child: SingleChildScrollView(
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1.0,
          ),
          itemCount: videoUrls.length,
          itemBuilder: (context, index) {
            Uri url = Uri.parse(videoUrls[index]);

            return GestureDetector(
              onTap: () {
                // 2024-09-02 没必要单独搞了好看的播放页面或者播放器，简单预览一下就好
                // 更多细节用户下载后观看

                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      content: VideoPlayerWidget(videoUrl: url),
                    );
                  },
                );
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => PlayVideoScreen(
                //       videoUrl: rstVideoUrls[index],
                //     ),
                //   ),
                // );
              },
              onLongPress: () {
                savevgVideoToLocal(videoUrls[index], prefix: "cogvideox");
              },
              child: Image.network(
                coverUrls[index],
                fit: BoxFit.scaleDown,
              ),
            );
          },
        ),
      ),
    ),
  ];
}

// 查询智谱文生视频任务的状态
Future<CogVideoXResp?> timedVideoGenerationTaskStatus(
  String taskId,
  Function onTimeOut,
) async {
  const maxWaitDuration = Duration(minutes: 10);

  return timedTaskStatus<CogVideoXResp>(
    taskId,
    onTimeOut,
    maxWaitDuration,
    getZhipuCogVideoXResult,
    (result) => result.taskStatus == "SUCCESS" || result.taskStatus == "FAIL",
  );
}

///
/// 简单的视频预览部件
///
class VideoThumbnail extends StatelessWidget {
  // 封面地址
  final String coverUrl;
  // 点击时简单播放
  final VoidCallback onTap;
  // 长按时下载到本地
  final VoidCallback onLongPress;

  const VideoThumbnail({
    super.key,
    required this.coverUrl,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Image.network(coverUrl, fit: BoxFit.cover),
    );
  }
}

///
/// 简单弹窗播放视频就好，更多让用户下载观看
///
class VideoPlayerWidget extends StatefulWidget {
  final Uri videoUrl;

  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(widget.videoUrl)
      ..initialize().then((_) {
        _controller.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: _controller.value.isInitialized
          ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
          : SizedBox(
              height: 50.sp,
              child: const Center(child: CircularProgressIndicator()),
            ),
    );
  }
}
