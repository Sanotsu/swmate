// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../common/components/tool_widget.dart';
import '../../services/cus_get_storage.dart';
import '_bak_stream_chat/index.dart';
import 'ai_tools/chat_bot/index.dart';

///
/// 规划一系列有AI加成的使用工具，这里是主入口
/// 可使用tab或者其他方式分类为：对话、图生文、文生图/图生图等
///
class AIToolIndex extends StatefulWidget {
  const AIToolIndex({super.key});

  @override
  State createState() => _AIToolIndexState();
}

class _AIToolIndexState extends State<AIToolIndex> {
  // 部分花费大的工具，默认先不开启了
  bool isEnableMyCose = false;

  // 2024-07-26
  // 默认的页面主体的缩放比例(对话太小了就可以等比放大)
  // 暂时就在“你问我答”页面测试，且只缩放问答列表(因为其他布局放大可能会有溢出问题)
  // ？？？后续可能作为配置，直接全局缓存，所有使用ChatListArea的地方都改了(现在不是所有地方都用的这个部件)
  double _textScaleFactor = 1.0;

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
        title: GestureDetector(
          onLongPress: () async {
            // 长按之后，先改变是否使用作者应用的标志
            setState(() {
              isEnableMyCose = !isEnableMyCose;
            });
            EasyLoading.showInfo("${isEnableMyCose ? "已启用" : "已关闭"}作者API Key");
          },
          child: const Text('AI 智能助手'),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              if (!mounted) return;
              setState(() {
                if (_textScaleFactor < 2.2) {
                  _textScaleFactor += 0.2;
                } else if (_textScaleFactor == 2.2) {
                  _textScaleFactor = 0.6; // 循环回最小值
                } else if (_textScaleFactor < 0.6) {
                  _textScaleFactor = 0.6; // 如果不小心越界，纠正回最小值
                }

                // 使用了数学取余运算 (remainder) 来确保 _textScaleFactor 总是在 [0.6 ,2.2) 的范围(闭开区间)内循环，
                // 即使在多次连续点击的情况下也能保持正确的值。
                _textScaleFactor =
                    (_textScaleFactor - 0.6).remainder(1.6) + 0.6;

                EasyLoading.showInfo(
                  "连续对话文本缩放 ${_textScaleFactor.toStringAsFixed(1)} 倍",
                );
              });
              // 缩放比例存入缓存
              await MyGetStorage().setChatListAreaScale(
                _textScaleFactor,
              );
            },
            icon: const Icon(Icons.crop_free),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "服务生成的所有内容均由人工智能模型生成，无法确保内容的真实性、准确性和完整性，仅供参考，且不代表开发者的态度或观点。",
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
          SizedBox(height: 10.sp),
          // 入口按钮
          SizedBox(
            height: screenBodyHeight - 50.sp,
            child: GridView.count(
              primary: false,
              padding: EdgeInsets.symmetric(horizontal: 5.sp),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              crossAxisCount: 2,
              childAspectRatio: 2 / 1,
              children: <Widget>[
                ///
                /// 使用的对话模型，可以连续问答对话
                ///
                buildToolEntrance(
                  "你问我答",
                  icon: const Icon(Icons.chat_outlined),
                  color: Colors.blue[100],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatBat(),
                      ),
                    );
                  },
                ),
                buildToolEntrance(
                  "[测试页]",
                  icon: const Icon(Icons.chat_outlined),
                  color: Colors.blue[100],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatPage(),
                      ),
                    );
                  },
                ),

                // buildAIToolEntrance(
                //   "功能\n占位(TODO)",
                //   icon: const Icon(Icons.search),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
