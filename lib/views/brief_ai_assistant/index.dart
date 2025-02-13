import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:swmate/views/brief_ai_assistant/chat/index.dart';

import '../../apis/_default_model_list/index.dart';
import '../../common/components/tool_widget.dart';
import '../../common/llm_spec/cus_llm_model.dart';
import '../../common/llm_spec/cus_llm_spec.dart';
import '../../common/utils/db_tools/db_helper.dart';
import '../ai_assistant/_helper/tools.dart';

class BriefAITools extends StatefulWidget {
  const BriefAITools({super.key});

  @override
  State createState() => _BriefAIToolsState();
}

class _BriefAIToolsState extends State<BriefAITools> {
  final DBHelper dbHelper = DBHelper();

  // db中是否存在模型列表，不存在则自动导入免费的模型列表，已存在则忽略
  List cusModelList = [];

  @override
  void initState() {
    initModelAndSysRole();

    super.initState();
  }

  // 初始化模型和系统角色信息到数据库
  // 后续文件还是别的东西看情况放
  initModelAndSysRole() async {
    // 如果数据库中已经有模型信息了，就不用再导入了
    var ll = await dbHelper.queryCusLLMSpecList();
    if (ll.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        cusModelList = ll;
      });
      return;
    }

    // 初始化模型信息和系统角色
    // 要考虑万一用户导入收费模型使用，顶不顶得住
    await testInitModelAndSysRole(FREE_all_MODELS);
    var afterList = await dbHelper.queryCusLLMSpecList();

    if (!mounted) return;
    setState(() {
      cusModelList = afterList;
    });
  }

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
            onPressed: () async {},
            icon: const Icon(Icons.face),
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
          if (cusModelList.isNotEmpty)
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
                        (llmSpecList) => BriefChatScreen(
                          llmSpecList: llmSpecList,
                        ),
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
                        [LLModelType.cc, LLModelType.vision],
                        (llmSpecList) => BriefChatScreen(
                          llmSpecList: llmSpecList,
                        ),
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
                        [LLModelType.cc, LLModelType.vision],
                        (llmSpecList) => BriefChatScreen(
                          llmSpecList: llmSpecList,
                        ),
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
  List<LLModelType> modelTypes,
  Widget Function(List<CusLLMSpec>) pageBuilder,
) async {
  // 获取对话的模型列表(具体逻辑看函数内部)
  List<CusLLMSpec> llmSpecList = await fetchAllCusLLMSpecList(modelTypes);

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
