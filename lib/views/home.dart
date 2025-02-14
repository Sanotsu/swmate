// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ai_assistant/index.dart';
import 'brief_ai_assistant/chat/index.dart';
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
  int _selectedIndex = 0;

  List<Widget> _widgetOptions = [];

  @override
  void initState() {
    super.initState();

    _widgetOptions = [
      const BriefChatScreen(),
      const BriefAITools(),
      const AIToolIndex(),
      const LifeToolIndex(),
      const UserAndSettings(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 点击返回键时暂停返回
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        print("didPop-----------$didPop");
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
        bottomNavigationBar: BottomNavigationBar(
          // 当item数量小于等于3时会默认fixed模式下使用主题色，大于3时则会默认shifting模式下使用白色。
          // 为了使用主题色，这里手动设置为fixed
          type: BottomNavigationBarType.fixed,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: "直接对话",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.android),
              label: "新的助手",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bolt),
              label: "智能助手",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt),
              label: "日常工具",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "用户设置",
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
