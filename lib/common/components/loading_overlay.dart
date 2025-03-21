import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoadingOverlay {
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context, {VoidCallback? onCancel}) {
    if (_overlayEntry != null) return;

    OverlayState overlayState = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withValues(alpha: 0.8),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 10.sp),
                Text(
                  "图片或视频生成中",
                  style: TextStyle(fontSize: 16.sp, color: Colors.white),
                ),
                Text(
                  "请耐心等待一会儿",
                  style: TextStyle(fontSize: 16.sp, color: Colors.white),
                ),
                Text(
                  "请勿退出当前页面",
                  style: TextStyle(fontSize: 16.sp, color: Colors.white),
                ),
                SizedBox(height: 16.sp),
                ElevatedButton(
                  onPressed: () {
                    hide();
                    onCancel?.call();
                  },
                  child: const Text("取消"),
                ),
              ],
            ),
          ),
        );
      },
    );
    overlayState.insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
