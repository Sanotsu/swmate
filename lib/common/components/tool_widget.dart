import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 构建AI对话云平台入口按钮
buildToolEntrance(
  String label, {
  Icon? icon,
  Color? color,
  void Function()? onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      // padding: EdgeInsets.all(2.sp),
      decoration: BoxDecoration(
        // 设置圆角半径为10
        borderRadius: BorderRadius.all(Radius.circular(15.sp)),
        color: color ?? Colors.teal[200],
        // 添加阴影效果
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // 阴影颜色
            spreadRadius: 2, // 阴影的大小
            blurRadius: 5, // 阴影的模糊程度
            offset: Offset(0, 2.sp), // 阴影的偏移量
          ),
        ],
      ),
      child: Center(
        child: ListTile(
          leading: icon ?? const Icon(Icons.chat, color: Colors.blue),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 20.sp,
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}
