import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'brief_ai_assistant/branch_chat/branch_chat_page.dart';
import 'brief_ai_assistant/index.dart';
import 'life_tools/index.dart';
import 'user_and_settings/index.dart';

/// 主页面

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 全屏状态标志
  bool _isFullScreen = false;
  int _selectedIndex = 0;
  List<Widget> _widgetOptions = [];

  @override
  void initState() {
    super.initState();

    _widgetOptions = [
      // 传递切换全屏的回调
      BranchChatPage(
        onToggleFullScreen: _toggleFullScreen,
      ),
      const BriefAITools(),
      const LifeToolIndex(),
      const UserAndSettings(),
    ];
  }

  // 切换全屏状态
  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isFullScreen = false; // 切换tab时自动退出全屏
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 点击返回键时暂停返回
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        // final NavigatorState navigator = Navigator.of(context);
        // 如果确认弹窗点击确认返回true，否则返回false
        final bool? shouldPop = await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("退出确认"),
              content: const Text("确认退出思文智能助手吗？"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text("取消"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text("确认"),
                ),
              ],
            );
          },
        ); // 只有当对话框返回true 才 pop(返回上一层)
        if (shouldPop ?? false) {
          // 如果还有可以关闭的导航，则继续pop
          // if (navigator.canPop()) {
          //   navigator.pop();
          // } else {
          //   // 如果已经到头来，则关闭应用程序
          //   SystemNavigator.pop();
          // }

          // 2024-05-29 已经到首页了，直接退出
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
        bottomNavigationBar: _isFullScreen
            ? null // 全屏时隐藏导航栏
            : BottomNavigationBar(
                // 当item数量小于等于3时会默认fixed模式下使用主题色，大于3时则会默认shifting模式下使用白色。
                // 为了使用主题色，这里手动设置为fixed
                type: BottomNavigationBarType.fixed,

                /// 只显示文字时label设为空字符串，即使设置了 showSelectedLabels为false；
                /// 只显示icon时icon设为SizedBox.shrink()；
                /// 两个属性都必须有，都设置则都显示。

                selectedLabelStyle: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: TextStyle(fontSize: 16.sp),
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    // icon: Icon(Icons.chat),
                    icon: SizedBox.shrink(),
                    label: "助手",
                  ),
                  BottomNavigationBarItem(
                    // icon: Icon(Icons.android),
                    icon: SizedBox.shrink(),
                    label: "工具",
                  ),
                  BottomNavigationBarItem(
                    // icon: Icon(Icons.receipt),
                    icon: SizedBox.shrink(),
                    label: "生活",
                  ),
                  BottomNavigationBarItem(
                    // icon: Icon(Icons.person),
                    icon: SizedBox.shrink(),
                    label: "设置",
                  ),
                ],
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
              ),
      ),
    );
  }
}
