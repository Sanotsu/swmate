import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomEntranceCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget? targetPage;
  final void Function()? onTap;

  const CustomEntranceCard({
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
                    style:
                        TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4.sp),
                  Text(
                    subtitle ?? "",
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
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
