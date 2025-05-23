import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MessageActions extends StatelessWidget {
  final String content;
  final int? tokens;
  final VoidCallback onRegenerate;
  final bool isRegenerating;

  const MessageActions({
    super.key,
    required this.content,
    this.tokens,
    required this.onRegenerate,
    this.isRegenerating = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // 复制按钮
        IconButton(
          icon: Icon(Icons.copy_outlined, size: 20.sp),
          visualDensity: VisualDensity.compact,
          tooltip: '复制内容',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: content));
            EasyLoading.showSuccess('已复制到剪贴板');
          },
        ),
        // 重新生成按钮
        IconButton(
          icon: isRegenerating
              ? SizedBox(
                  width: 20.sp,
                  height: 20.sp,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.refresh_outlined, size: 20.sp),
          visualDensity: VisualDensity.compact,
          tooltip: '重新生成',
          onPressed: isRegenerating ? null : onRegenerate,
        ),
        // token 信息
        if (tokens != null)
          Padding(
            padding: EdgeInsets.only(left: 16.sp),
            child: Text('$tokens tokens'),
          ),
      ],
    );
  }
}
