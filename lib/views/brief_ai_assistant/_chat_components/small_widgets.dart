// 构建空提示
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 构建空提示
Widget buildEmptyHint() {
  return Padding(
    padding: EdgeInsets.all(32.sp),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat, size: 36.sp, color: Colors.blue),
          Text(
            '嗨，我是思文',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '我可以帮您完成很多任务，让我们开始吧！',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    ),
  );
}

// 调整对话列表中显示的文本大小
void adjustTextScale(
  BuildContext context,
  double textScaleFactor,
  Function(double) onTextScaleChanged,
) async {
  var tempScaleFactor = textScaleFactor;
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          '调整对话列表中文字大小',
          style: TextStyle(fontSize: 18.sp),
        ),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: tempScaleFactor,
                  min: 0.6,
                  max: 2.0,
                  divisions: 14,
                  label: tempScaleFactor.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      tempScaleFactor = value;
                    });
                  },
                ),
                Text(
                  '当前文字比例: ${tempScaleFactor.toStringAsFixed(1)}',
                  textScaler: TextScaler.linear(tempScaleFactor),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            child: const Text('取消'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('确定'),
            onPressed: () async {
              // 点击确定时，才把缩放比例存入缓存，并更新当前比例值
              onTextScaleChanged(tempScaleFactor);
            },
          ),
        ],
      );
    },
  );
}
