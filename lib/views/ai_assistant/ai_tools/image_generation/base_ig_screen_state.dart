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
import '../../_ig_screen_parts/ig_history_screen.dart';

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

  // 阿里云有选择的样式编号
  int selectedStyleIndex = 0;

  // 是否初始化完成(选择的对话和支持的对话列表，没从数据库获取到就不要加载页面)
  bool isInited = false;

  @override
  void initState() {
    super.initState();
    initModelInfo();

    WidgetsBinding.instance.addObserver(this);
  }

  initModelInfo() async {
    // 获取对话的模型列表(具体逻辑看函数内部)
    var tempList = await fetchCusLLMSpecList(getModelType());
    setState(() {
      llmSpecList = tempList;
    });

    // 2024-07-14 每次进来都随机选一个
    List<ApiPlatform> values =
        llmSpecList.map((e) => e.platform).toSet().toList();
    // 不能放在下面一起，因为选中的平台要先生效，才能构建该平台下的模型
    setState(() {
      selectedPlatform = values[Random().nextInt(values.length)];
    });

    // 2024-07-14 同样的，选中的平台后也随机选择一个模型
    List<CusLLMSpec> models =
        llmSpecList.where((spec) => spec.platform == selectedPlatform).toList();
    setState(() {
      selectedModelSpec = models[Random().nextInt(models.length)];
    });

    // 获取系统角色列表
    var sysRoles = await dbHelper.queryCusSysRoleSpecList();
    setState(() {
      selectedSize = getInitialSize();

      // 暂时父组件就把图片相关的都带出来，当然其实子组件各带各的最好，这省事
      sysRoleList = sysRoles
          .where((role) =>
              role.sysRoleType == LLModelType.tti ||
              role.sysRoleType == LLModelType.iti)
          .toList();

      isInited = true;
    });
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

  // 文生图时，默认选中一个模型
  CusLLMSpec getRandomModel() {
    List<CusLLMSpec> models = llmSpecList
        .where((spec) =>
            spec.platform == selectedPlatform &&
            spec.modelType == getModelType())
        .toList();
    return models[Random().nextInt(models.length)];
  }

  /// 文生图支持的尺寸列表
  List<String> getSizeList();

  // 各个平台的默认尺寸
  String getInitialSize();

  // 文生图默认选中的平台
  ApiPlatform getInitialPlatform();

  /// 文生图支持的模型类型
  LLModelType getModelType();

  // 平台和模型选择切换后的回调
  // tti和wordard要执行的不一样
  cpModelChangedCB(ApiPlatform? cp, CusLLMSpec? llmSpec);

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

      AliyunTtiResp? result = await timedImageGenerationJobStatus(
        taskId,
        () => setState(() {
          isGenImage = false;
          LoadingOverlay.hide();
        }),
      );

      await dbHelper.insertImageGenerationResultList([
        LlmIGResult(
          requestId: const Uuid().v4(),
          prompt: prompt,
          negativePrompt: negativePrompt,
          taskId: taskId,
          isFinish: false,
          style: selectedPlatform == ApiPlatform.aliyun
              ? "<${WANX_StyleMap.values.toList()[selectedStyleIndex]}>"
              : '默认',
          imageUrls: null,
          gmtCreate: DateTime.now(),
          llmSpec: selectedModelSpec,
        )
      ]);

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
      await dbHelper.updateImageGenerationResultById(
        LlmIGResult(
          requestId: const Uuid().v4(),
          prompt: prompt,
          negativePrompt: negativePrompt,
          taskId: taskId,
          isFinish: true,
          style: selectedPlatform == ApiPlatform.aliyun
              ? "<${WANX_StyleMap.values.toList()[selectedStyleIndex]}>"
              : '默认',
          imageUrls: imageUrls,
          gmtCreate: DateTime.now(),
          llmSpec: selectedModelSpec,
        ),
      );
    } else {
      await dbHelper.insertImageGenerationResultList([
        LlmIGResult(
          requestId: const Uuid().v4(),
          prompt: prompt,
          negativePrompt: negativePrompt,
          taskId: null,
          isFinish: true,
          style: selectedPlatform == ApiPlatform.aliyun
              ? "<${WANX_StyleMap.values.toList()[selectedStyleIndex]}>"
              : '默认',
          imageUrls: imageUrls,
          gmtCreate: DateTime.now(),
          llmSpec: selectedModelSpec,
        )
      ]);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getAppBarTitle()),
        actions: [
          if (isInited && selectedModelSpec.modelType != LLModelType.tti_word)
            TextButton(
              onPressed: () {
                showCusSysRoleList(
                  context,
                  sysRoleList,
                  isInited,
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
                  builder: (context) => ImageGenerationHistoryScreen(
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
      body: !isInited
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
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

                          /// 文生图的结果
                          if (rstImageUrls.isNotEmpty) ...buildImageResult(),
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
  List<Widget> buildConfigArea() {
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

  /// 构建生成的图片区域
  List<Widget> buildImageResult() {
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
                  rstImageUrls,
                  crossAxisCount: 4,
                  // 模型名有空格或斜线，等后续更新spec，用name来
                  prefix: "${selectedPlatform.name}_${selectedModelSpec.name}",
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }
}

// 查询阿里云文生图任务的状态
Future<AliyunTtiResp?> timedImageGenerationJobStatus(
  String taskId,
  Function onTimeOut,
) async {
  bool isMaxWaitTimeExceeded = false;

  const maxWaitDuration = Duration(minutes: 10);

  Timer timer = Timer(maxWaitDuration, () {
    // setState(() {
    //   isGenImage = false;
    //   LoadingOverlay.hide();
    // });

    onTimeOut();

    EasyLoading.showError(
      "生成图片超时，请稍候重试！",
      duration: const Duration(seconds: 10),
    );

    isMaxWaitTimeExceeded = true;

    print('文生图任务处理耗时，状态查询终止。');
  });

  bool isRequestSuccessful = false;
  while (!isRequestSuccessful && !isMaxWaitTimeExceeded) {
    try {
      var result = await getAliyunText2ImgJobResult(taskId);

      var boolFlag = result.output.taskStatus == "SUCCEEDED" ||
          result.output.taskStatus == "FAILED";

      if (boolFlag) {
        isRequestSuccessful = true;
        print('文生图任务处理完成!');
        timer.cancel();

        return result;
      } else {
        print('文生图任务还在处理中，请稍候重试……');
        await Future.delayed(const Duration(seconds: 5));
      }
    } catch (e) {
      print('发生异常: $e');
      await Future.delayed(const Duration(seconds: 5));
    }
  }
  return null;
}
