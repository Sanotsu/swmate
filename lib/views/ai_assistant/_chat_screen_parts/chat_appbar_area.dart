import 'package:flutter/material.dart';

class ChatAppBarArea extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showNewChatButton; // 是否显示新建对话按钮
  final bool showHistoryButton; // 是否显示历史对话按钮
  final Function? onNewChatPressed;
  final Function? onHistoryPressed;
  final bool showZoomInButton; // 是否显示放大按钮
  final Function? onZoomInPressed;
  final bool showZoomOutButton; // 是否显示缩小按钮
  final Function? onZoomOutPressed;
  // 单独放大缩小按钮占位置，只有1个缩放在几个比例中切换
  final bool showScaleButton;
  final Function? onScalePressed;

  const ChatAppBarArea({
    super.key,
    this.title,
    this.showNewChatButton = true,
    this.showHistoryButton = true,
    this.onNewChatPressed,
    this.onHistoryPressed,
    this.showZoomInButton = false,
    this.onZoomInPressed,
    this.showZoomOutButton = false,
    this.onZoomOutPressed,
    this.showScaleButton = false,
    this.onScalePressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title != null ? Text(title!) : null,
      actions: [
        if (showZoomOutButton)
          IconButton(
            onPressed: () {
              if (onZoomOutPressed != null) {
                onZoomOutPressed!();
              }
            },
            icon: const Icon(Icons.aspect_ratio),
          ),
        if (showZoomInButton)
          IconButton(
            onPressed: () {
              if (onZoomInPressed != null) {
                onZoomInPressed!();
              }
            },
            icon: const Icon(Icons.zoom_in),
          ),
        if (showScaleButton)
          IconButton(
            onPressed: () {
              if (onScalePressed != null) {
                onScalePressed!();
              }
            },
            icon: const Icon(Icons.crop_free),
          ),
        if (showNewChatButton)
          IconButton(
            onPressed: () {
              if (onNewChatPressed != null) {
                onNewChatPressed!();
              }
            },
            icon: const Icon(Icons.add),
          ),
        if (showHistoryButton)
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.history),
                onPressed: () {
                  if (onHistoryPressed != null) {
                    onHistoryPressed!(context);
                  }
                },
              );
            },
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
