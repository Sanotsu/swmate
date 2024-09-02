// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import '../../../../apis/text_to_image/aliyun_tti_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/llm_spec/cus_llm_model.dart';
import '../../../../common/llm_spec/cus_llm_spec.dart';
import '../../../../common/utils/db_tools/db_helper.dart';
import '../../../../models/text_to_image/aliyun_tti_resp.dart';
import '../../../../models/text_to_image/com_ig_state.dart';
import '../../_componets/cus_platform_and_llm_row.dart';
import '../../_componets/cus_system_prompt_modal.dart';
import '../../_helper/tools.dart';
import '../../_ig_screen_parts/ig_button_row_area.dart';
import '../../_helper/constants.dart';
import '../../_componets/loading_overlay.dart';
import '../../_ig_screen_parts/size_and_num_selector.dart';
import '../../_ig_screen_parts/igvg_history_screen.dart';

///
/// 文生图、图生图大体结构是一样的，不再单独出来，统一为IG(Image Generation)
///
abstract class BaseIGScreenState<T extends StatefulWidget> extends State<T>
    with WidgetsBindingObserver {
  ///
  /// 统一显示的平台、模型、生成数量、生成尺寸的变量
  /// 在init时需要重新设置
  ///
  // 所有支持文生图的模型列表(用于下拉的平台和该平台拥有的模型列表也从这里来)
  late List<CusLLMSpec> llmSpecList;

  // 所有支持文生图的系统角色(用于获取预设的system prompt的值)
  late List<CusSysRoleSpec> sysRoleList;

  // 级联选择效果：云平台-模型名
  late ApiPlatform selectedPlatform;

  // 被选中的模型信息
  late CusLLMSpec selectedModelSpec;

  // 被选中的生成尺寸
  String selectedSize = '';
  // 被选中的生成数量
  int selectedNum = ImageNumList.first;

  ///
  /// 用户输入的提示词
  ///
  final promptController = TextEditingController();
  final negativePromptController = TextEditingController();

  // 描述画面的提示词信息。支持中英文，长度不超过500个字符，超过部分会自动截断。
  String prompt = "";
  // 画面中不想出现的内容描述词信息。支持中英文，长度不超过500个字符，超过部分会自动截断。
  String negativePrompt = "";

  ///
  /// 一些tti任务调用中或者结束后的操作
  ///
  // 是否正在生成图片
  bool isGenImage = false;

  // 最后生成的图片地址
  List<String> rstImageUrls = [];

  final DBHelper dbHelper = DBHelper();

  // 被选中的风格
  String selectedStyle = "";

  /// 下面主要是文生图的高级选项相关参数
  // 不同的模型，这两个值的取值范围不同，lighting和turbo会小很多
  // 但这个取值范围就不设为API参数支持了，而设置成体验中心的那个
  List lightingCus = [
    CusLLM.siliconCloud_StableDiffusionXL_Lighting_ITI,
    CusLLM.siliconCloud_StableDiffusionXL_Lighting_TTI,
  ];

  List turborCus = [
    CusLLM.siliconCloud_StableDiffusion_Turbo_TTI,
    CusLLM.siliconCloud_StableDiffusionXL_Turbo_TTI,
  ];

  // 初始值也不太一样
  double inferenceStepsValue = 1;
  double guidanceScaleValue = 1;

  double initInferenceSteps() {
    return lightingCus.contains(selectedModelSpec.cusLlm)
        ? 1
        : turborCus.contains(selectedModelSpec.cusLlm)
            ? 2
            : 25;
  }

  double getInferenceSteps() {
    return lightingCus.contains(selectedModelSpec.cusLlm)
        ? 4
        : turborCus.contains(selectedModelSpec.cusLlm)
            ? 10
            : 50;
  }

  double initGuidanceScale() {
    return (lightingCus + turborCus).contains(selectedModelSpec.cusLlm)
        ? 1
        : 7.5;
  }

  double getGuidanceScale() {
    return (lightingCus + turborCus).contains(selectedModelSpec.cusLlm)
        ? 2
        : 20;
  }

  bool _isExpanded = false;
  final TextEditingController seedController = TextEditingController();

  void _generateRandomSeed() {
    setState(() {
      seedController.text = (Random().nextInt(4000000000)).toString();
    });
  }

  @override
  void initState() {
    super.initState();

    initCommonState();

    inferenceStepsValue = initInferenceSteps();
    guidanceScaleValue = initGuidanceScale();
    _generateRandomSeed();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("当前页面状态--$state");

    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      LoadingOverlay.hide();
    }
  }

  void initCommonState() {
    // 赋值模型列表、角色列表
    final widget = this.widget as dynamic;
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

    // 选中了平台和模型之后，才能初始化对应的尺寸和样式
    setState(() {
      selectedSize = getInitialSize();
      selectedStyle = getInitialStyle();
    });
  }

  /// 各个平台图片生成支持的尺寸列表
  List<String> getSizeList();

  /// 各个平台图片生成支持的样式列表
  List<String> getStyleList();

  // 各个平台的默认尺寸
  String getInitialSize() => getSizeList().first;

  // 各个平台的默认样式
  String getInitialStyle() =>
      getStyleList().isNotEmpty ? getStyleList().first : "";

  /// 文生图支持的模型类型
  LLModelType getModelType();

  // 平台和模型选择切换后的回调
  // tti和wordard要执行的不一样
  cpModelChangedCB(ApiPlatform? cp, CusLLMSpec? llmSpec) {
    setState(() {
      selectedPlatform = cp!;
      selectedModelSpec = llmSpec!;
      // 模型可供输出的图片尺寸列表、样式、预选字体也要更新
      getSizeList();
      selectedSize = getInitialSize();
      getStyleList();
      selectedStyle = getInitialStyle();

      // 高级选项的重置
      getInferenceSteps();
      getGuidanceScale();
      inferenceStepsValue = initInferenceSteps();
      guidanceScaleValue = initGuidanceScale();
    });
  }

  // 文生图页面的标题
  String getAppBarTitle();

  // 文生图历史记录页面的标签关键字
  String getHistoryLabel();

  // 点击了还原配置按钮
  // 图生图时，还需要额外清除图片的操作
  void resetConfig() {
    unfocusHandle();
    setState(() {
      prompt = "";
      negativePrompt = "";
      promptController.text = "";
      negativePromptController.text = "";
      selectedSize = getInitialSize();
      selectedNum = ImageNumList.first;
    });
  }

  // 是否可以点击生成按钮
  bool isCanGenerate() {
    return prompt.isNotEmpty && isGenImage == false;
  }

  ///
  /// 获取文生图数据，阿里云的是提交job、查询job状态
  /// 而sf和讯飞云是直接得到响应结果.
  /// 如果获取tti job返回的是空，表示是直接得到结果的方式，那么会执行 getDirectTTIResult 函数
  /// 如果获取tti job返回的不是空，那就定时查询job进度，而 getDirectTTIResult 传一个空函数即可
  Future<AliyunTtiResp?> commitImageGenerationJob();

  // 直接得到结果的tti方式，处理完之后返回tti结果，方便存入db;
  // 阿里云那种提交jb的，直接返回null就好了
  Future<List<String>?>? getDirectImageGenerationResult();

  /// 获取文生图的数据
  Future<void> getImageGenerationData() async {
    if (isGenImage) {
      return;
    }

    setState(() {
      isGenImage = true;
      // 开始获取图片后，添加遮罩
      LoadingOverlay.show(
        context,
        onCancel: () => setState(() => isGenImage = false),
      );
    });

    print("选择的平台 $selectedPlatform");
    print("选择的模型 ${selectedModelSpec.toRawJson()}");
    print("尺寸 $selectedSize");
    print("张数 $selectedNum");
    print("正向词 $prompt");
    print("消极词 $negativePrompt");

    // 请求得到的图片结果
    List<String> imageUrls = [];

    // 如阿里云这种先生成任务后查询状态的，就需要保存任务编号；直接返回结果的就存null即可
    String? taskId;

    // 初始化的文生图的历史记录，后面根据不同情况进行一些修改
    LlmIGVGResult temp = LlmIGVGResult(
      requestId: const Uuid().v4(),
      prompt: prompt,
      negativePrompt: negativePrompt,
      taskId: null,
      isFinish: false,
      style: selectedPlatform == ApiPlatform.aliyun
          ? "<${WANX_StyleMap[selectedStyle]}>"
          : '默认',
      imageUrls: null,
      gmtCreate: DateTime.now(),
      llmSpec: selectedModelSpec,
      modelType: getModelType(),
    );

    // 提交文生图任务,如果不是null，则说明是阿里云先有job，再查询job状态的方式
    // 如果是null，说明是sf、讯飞这种直接返回tti结果的方式
    var jobResp = await commitImageGenerationJob();

    if (jobResp != null) {
      if (!mounted) return;
      if (jobResp.code != null) {
        setState(() {
          isGenImage = false;
          LoadingOverlay.hide();
        });
        return commonExceptionDialog(
          context,
          "发生异常",
          "生成图片出错:${jobResp.message}",
        );
      }

      // 查询文生图任务状态
      taskId = jobResp.output.taskId;

      // 将job任务存入数据库，方便后续查询(比如发起调用后job成功创建，但还没有产生结果时就关闭页面了)
      temp.requestId = jobResp.requestId;
      temp.taskId = taskId;

      await dbHelper.insertIGVGResultList([temp]);

      // 定时查询任务状态
      AliyunTtiResp? result = await timedImageGenerationTaskStatus(
        taskId,
        () => setState(() {
          isGenImage = false;
          LoadingOverlay.hide();
        }),
      );

      if (!mounted) return;
      if (result?.code != null) {
        setState(() {
          isGenImage = false;
          LoadingOverlay.hide();
        });

        return commonExceptionDialog(
          context,
          "发生异常",
          "查询文本生图任务进度报错:${jobResp.message}",
        );
      }

      // 得到图片结构，存入变量
      var a = result?.output.results;
      if (a != null && a.isNotEmpty) {
        for (var e in a) {
          if (e.url != null) imageUrls.add(e.url!);
          if (e.pngUrl != null) imageUrls.add(e.pngUrl!);
          // 2024-08-21 svg的预览报错？？？变形会有svg和png两个，没有直接url
          // if (e.svgUrl != null) imageUrls.add(e.svgUrl!);
        }
      }
    } else {
      imageUrls = (await getDirectImageGenerationResult()) ?? [];
    }

    // 正确获得文生图结果之后，将生成记录保存
    if (taskId != null) {
      temp.isFinish = true;
      temp.imageUrls = imageUrls;

      await dbHelper.updateIGVGResultById(temp);
    } else {
      temp.taskId = null;
      temp.isFinish = true;
      temp.imageUrls = imageUrls;
      await dbHelper.insertIGVGResultList([temp]);
    }

    if (!mounted) return;
    setState(() {
      rstImageUrls = imageUrls;
      isGenImage = false;
      LoadingOverlay.hide();
    });
  }

  // 选中预设的提示词，就代替当前输入框的值
  void onRoleSelected(CusSysRoleSpec role) {
    setState(() {
      promptController.text = role.systemPrompt;
      prompt = role.systemPrompt;

      if (role.negativePrompt != null) {
        negativePromptController.text = role.negativePrompt!;
        negativePrompt = role.negativePrompt!;
      }
    });

    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('Selected: ${role.systemPrompt}')),
    // );
  }

  Widget _buildPanel() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ExpansionTile(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [Text('高级选项')],
        ),
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (bool expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: [
          // 2024-09-01 虽然seed这里有了，但是没有作为参数，感觉用处不大
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: seedController,
                  decoration: const InputDecoration(labelText: 'Seed'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.casino),
                onPressed: _generateRandomSeed,
              ),
            ],
          ),
          Row(
            children: [
              const Text('Inference Steps:'),
              Tooltip(
                // ？？？改为tap不显示
                // triggerMode: TooltipTriggerMode.tap,
                showDuration: const Duration(seconds: 5),
                message:
                    'Number of inference/sampling steps . More steps produce higher quality but take longer.',
                child: IconButton(
                  icon: const Icon(Icons.info),
                  onPressed: () {},
                ),
              ),
              Text(inferenceStepsValue.toStringAsFixed(0)),
            ],
          ),
          Slider(
            value: inferenceStepsValue,
            min: 1,
            max: getInferenceSteps(),
            divisions: (getInferenceSteps() - 1).toInt(),
            label: inferenceStepsValue.toStringAsFixed(0),
            onChanged: (value) {
              setState(() {
                inferenceStepsValue = value;
              });
            },
          ),
          Row(
            children: [
              const Text('Guidance Scale:'),
              Tooltip(
                showDuration: const Duration(seconds: 5),
                message:
                    'Classifier Free Guidance. How close you want the model to stick to your prompt when looking for a related image to show you.',
                child: IconButton(
                  icon: const Icon(Icons.info),
                  onPressed: () {},
                ),
              ),
              Text(guidanceScaleValue.toStringAsFixed(1)),
            ],
          ),
          Slider(
            value: guidanceScaleValue,
            min: 1,
            max: getGuidanceScale(),
            divisions: ((getGuidanceScale() - 1) * 5).toInt(),
            label: guidanceScaleValue.toStringAsFixed(1),
            onChanged: (value) {
              setState(() {
                guidanceScaleValue = value;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getAppBarTitle()),
        actions: [
          if (selectedModelSpec.modelType != LLModelType.tti_word)
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
                  builder: (context) => IGVGHistoryScreen(
                    lable: getHistoryLabel(),
                    modelType: getModelType(),
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
              title: "图片生成配置",
              onReset: resetConfig,
              onGenerate: () async {
                unfocusHandle();
                try {
                  await getImageGenerationData();
                } catch (e) {
                  setState(() {
                    isGenImage = false;
                    LoadingOverlay.hide();
                    EasyLoading.showError(
                      e.toString(),
                      duration: const Duration(seconds: 5),
                    );
                  });
                }
              },
              canGenerate: isCanGenerate(),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    /// 文生图配置折叠栏
                    ...buildConfigArea(),

                    // 2024-09-01 之前的其他不知道，但智谱的文生图这个肯定没用
                    if (selectedPlatform != ApiPlatform.zhipu) _buildPanel(),

                    /// 文生图的结果
                    if (rstImageUrls.isNotEmpty)
                      ...buildImageResult(
                        context,
                        rstImageUrls,
                        "${selectedPlatform.name}_${selectedModelSpec.name}",
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

  ///
  /// 页面布局从上往下
  ///

  /// 构建文生图的配置区域
  /// 这两个是都用的，其他不同的子类去重载
  List<Widget> buildConfigArea({bool? isOnlySize}) {
    return [
      /// 平台和模型选择
      CusPlatformAndLlmRow(
        initialPlatform: selectedPlatform,
        initialModelSpec: selectedModelSpec,
        llmSpecList: llmSpecList,
        targetModelType: getModelType(),
        showToggleSwitch: false,
        onPlatformOrModelChanged: cpModelChangedCB,
      ),

      /// 尺寸、张数选择

      if (isOnlySize != false)
        SizeAndNumArea(
          selectedSize: selectedSize,
          selectedNum: selectedNum,
          sizeList: getSizeList(),
          numList: ImageNumList,
          onSizeChanged: (val) => setState(() => selectedSize = val),
          onNumChanged: (val) => setState(() => selectedNum = val),
        ),
    ];
  }
}

// 查询阿里云文生图任务的状态
Future<AliyunTtiResp?> timedImageGenerationTaskStatus(
  String taskId,
  Function onTimeOut,
) async {
  const maxWaitDuration = Duration(minutes: 10);

  return timedTaskStatus<AliyunTtiResp>(
    taskId,
    onTimeOut,
    maxWaitDuration,
    getAliyunText2ImgJobResult,
    (result) =>
        result.output.taskStatus == "SUCCEEDED" ||
        result.output.taskStatus == "FAILED",
  );
}

/// 构建生成的图片区域
List<Widget> buildImageResult(
  BuildContext context,
  List<String> urls,
  String? prefix,
) {
  return [
    const Divider(),

    /// 文生图结果提示行
    Padding(
      padding: EdgeInsets.all(5.sp),
      child: Text(
        "生成的图片(点击查看、长按保存)",
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
      ),
    ),

    /// 图片放一行，最多只有4张
    SizedBox(
      // 最多4张图片，放在一排就好(高度即四分之一的宽度左右)。在最下面留点空即可
      height: 0.25.sw + 5.sp,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.sp),
              child: buildNetworkImageViewGrid(
                context,
                urls,
                crossAxisCount: 4,
                // 模型名有空格或斜线，等后续更新spec，用name来
                prefix: prefix,
              ),
            ),
          ],
        ),
      ),
    ),
  ];
}
