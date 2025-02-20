import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:swmate/views/brief_ai_assistant/chat/index.dart';

import '../../common/components/tool_widget.dart';
import '../../common/llm_spec/cus_brief_llm_model.dart';
import '../../common/llm_spec/cus_llm_spec.dart';
import '../../common/utils/db_tools/db_helper.dart';
import '../../services/model_manager_service.dart';
import 'image/index.dart';
import 'model_config/index.dart';
import 'video/index.dart';

class BriefAITools extends StatefulWidget {
  const BriefAITools({super.key});

  @override
  State createState() => _BriefAIToolsState();
}

class _BriefAIToolsState extends State<BriefAITools> {
  final DBHelper dbHelper = DBHelper();

  @override
  Widget build(BuildContext context) {
    // 计算屏幕剩余的高度
    // 设备屏幕的总高度
    //  - 屏幕顶部的安全区域高度，即状态栏的高度
    //  - 屏幕底部的安全区域高度，即导航栏的高度或者虚拟按键的高度
    //  - 应用程序顶部的工具栏（如 AppBar）的高度
    //  - 应用程序底部的导航栏的高度
    //  - 组件的边框间隔(不一定就是2)
    double screenBodyHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom -
        kToolbarHeight -
        kBottomNavigationBarHeight;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('智能助手'),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BriefModelConfig(),
                ),
              );
            },
            icon: const Icon(Icons.import_export),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// 免责说明
          Text(
            "服务生成的所有内容均由人工智能模型生成，无法确保内容的真实性、准确性和完整性，仅供参考，且不代表开发者的态度或观点。",
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
          SizedBox(height: 10.sp),

          /// 入口按钮
          SizedBox(
            height: screenBodyHeight - 50.sp,
            child: GridView.count(
              primary: false,
              padding: EdgeInsets.symmetric(horizontal: 5.sp),
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              crossAxisCount: 1,
              childAspectRatio: 5 / 2,
              children: <Widget>[
                buildCard(
                  context,
                  '助手',
                  Icons.chat_outlined,
                  () async {
                    await navigateToToolScreen(
                      context,
                      [LLModelType.cc, LLModelType.vision],
                      (llmSpecList) => BriefChatScreen(),
                    );
                  },
                ),

                buildCard(
                  context,
                  '绘图',
                  Icons.image_outlined,
                  () async {
                    await navigateToToolScreen(
                      context,
                      [LLModelType.image, LLModelType.tti, LLModelType.iti],
                      (llmSpecList) => BriefImageScreen(),
                    );
                  },
                ),

                buildCard(
                  context,
                  '视频',
                  Icons.video_call_outlined,
                  () async {
                    await navigateToToolScreen(
                      context,
                      [LLModelType.video, LLModelType.ttv, LLModelType.itv],
                      (llmSpecList) => BriefVideoScreen(),
                    );
                  },
                ),

                // buildToolEntrance(
                //   "[测试]",
                //   icon: const Icon(Icons.chat_outlined),
                //   color: Colors.blue[100],
                //   onTap: () async {},
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

///
/// 点击智能助手的入口，跳转到子页面
///
Future<void> navigateToToolScreen(
  BuildContext context,
  List<LLModelType>? modelTypes,
  Widget Function(List<CusBriefLLMSpec>) pageBuilder,
) async {
  // 得到所有可用的模型
  final availableModels = await ModelManagerService.getAvailableModels();

  // 然后过滤出指定类型的模型
  List<CusBriefLLMSpec> llmSpecList = availableModels
      .where(
          (spec) => modelTypes == null || modelTypes.contains(spec.modelType))
      .toList();

  // 固定平台排序后模型名排序
  llmSpecList.sort((a, b) {
    // 先比较 平台名称
    int compareA = a.platform.name.compareTo(b.platform.name);
    if (compareA != 0) {
      return compareA;
    }

    // 如果 平台名称 相同，再比较 模型名称
    return a.name.compareTo(b.name);
  });

  if (!context.mounted) return;
  if (llmSpecList.isEmpty) {
    return commonHintDialog(context, "提示", "无可用的模型，该功能不可用");
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => pageBuilder(llmSpecList),
      ),
    );
  }
}

Widget buildCard(
  BuildContext context,
  String title,
  IconData icon,
  VoidCallback onTap, {
  String? subtitle,
}) {
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10.sp),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(10.sp),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 0.2.sw),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Padding(
                padding: EdgeInsets.all(5.sp),
                child: CircleAvatar(
                  backgroundColor: Colors.blue,
                  radius: 28.sp,
                  child: Icon(icon, size: 32.sp, color: Colors.white),
                ),
              ),
            ),
            // // SizedBox(width: 2.sp),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: TextStyle(fontSize: 36.sp)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
