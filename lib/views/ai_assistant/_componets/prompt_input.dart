import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PromptInput extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final Function(String) onChanged;
  final bool isRequired;
  final int? maxLines;
  final int? minLines;

  const PromptInput({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.onChanged,
    this.isRequired = false,
    this.maxLines = 5,
    this.minLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(5.sp),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label${isRequired ? '(不可为空)' : '(可以不填)'}",
            style: TextStyle(color: isRequired ? Colors.green : null),
          ),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(fontSize: 12.sp),
              border: const OutlineInputBorder(), // 添加边框
            ),
            maxLines: maxLines,
            minLines: minLines,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
