import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomEntranceCard extends StatelessWidget {
  final String title;
  final TextStyle? titleStyle;
  final String? subtitle;
  final TextStyle? subtitleStyle;
  final IconData icon;
  final Color iconColor;
  final double? cardElevation;
  final Widget? targetPage;
  final void Function()? onTap;

  const CustomEntranceCard({
    super.key,
    required this.title,
    this.titleStyle,
    this.subtitle,
    this.subtitleStyle,
    required this.icon,
    this.iconColor = Colors.blue,
    this.cardElevation,
    this.targetPage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      // color: Colors.white,
      elevation: cardElevation ?? 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.sp), // 设置Card的圆角
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10.sp), // 设置InkWell的圆角
        // 如果有传目标页面，直接跳转，不管有没有onTap函数；如果没有目标页面，再执行onTap操作
        onTap: (targetPage != null)
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => targetPage!),
                );
              }
            : onTap,
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.all(5.sp),
              child: CircleAvatar(
                backgroundColor: iconColor,
                radius: 18.sp,
                child: Icon(icon, size: 24.sp, color: Colors.white),
              ),
            ),
            // // SizedBox(width: 2.sp),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: titleStyle ??
                        TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4.sp),
                  Text(
                    subtitle ?? "",
                    style: subtitleStyle ??
                        TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 生活日常工具的，因为在折叠栏中，稍微修改一下
class LifeToolEntranceCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget? targetPage;
  final void Function()? onTap;

  const LifeToolEntranceCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor = Colors.blue,
    this.targetPage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).canvasColor, // Colors.white
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.sp),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10.sp),
        // 如果有传目标页面，直接跳转，不管有没有onTap函数；如果没有目标页面，再执行onTap操作
        onTap: (targetPage != null)
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => targetPage!),
                );
              }
            : onTap,
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.all(2.sp),
              child: CircleAvatar(
                backgroundColor: iconColor,
                radius: 16.sp,
                child: Icon(icon, size: 22.sp, color: Colors.white),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.sp),
                  Text(
                    subtitle ?? "",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
