import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

///
/// 文生图\图生图页面上方的按钮行
///
class ImageGenerationButtonArea extends StatelessWidget {
  final String title;
  final VoidCallback onReset;
  final VoidCallback onGenerate;
  final bool canGenerate;

  const ImageGenerationButtonArea({
    super.key,
    required this.title,
    required this.onReset,
    required this.onGenerate,
    required this.canGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(5.sp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onReset,
                child: const Text("还原配置"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(80.sp, 32.sp),
                  padding: EdgeInsets.symmetric(horizontal: 10.sp),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.sp),
                  ),
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                ),
                onPressed: canGenerate ? onGenerate : null,
                child: const Text(
                  "生成图片",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
