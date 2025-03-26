import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TextSelectionDialog extends StatelessWidget {
  final String text;

  const TextSelectionDialog({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('选择文本'),
          actions: [
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: text));
                EasyLoading.showToast('已复制到剪贴板');
                Navigator.pop(context);
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.sp),
          child: SelectableText(
            text,
            style: TextStyle(fontSize: 16.sp),
          ),
        ),
      ),
    );
  }
}
