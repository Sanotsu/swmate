import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomEntranceCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget targetPage;

  const CustomEntranceCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor = Colors.blue,
    required this.targetPage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.sp), // 设置Card的圆角
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10.sp), // 设置InkWell的圆角
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => targetPage),
          );
        },
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

              // Center(
              //   child: ListTile(
              //     leading: CircleAvatar(
              //       backgroundColor: iconColor,
              //       radius: 15.sp,
              //       child: Icon(icon, size: 20.sp, color: Colors.white),
              //     ),
              //     // dense: true,
              //     title: Text(
              //       title,
              //       style: TextStyle(
              //         fontSize: 18.sp,
              //         // color: Colors.blueAccent,
              //         fontWeight: FontWeight.bold,
              //       ),
              //       maxLines: 1,
              //       softWrap: true,
              //       overflow: TextOverflow.ellipsis,
              //       textAlign: TextAlign.center,
              //     ),
              //     subtitle: subtitle != null
              //         ? Text(
              //             subtitle!,
              //             style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              //             maxLines: 10,
              //             softWrap: true,
              //             overflow: TextOverflow.ellipsis,
              //             textAlign: TextAlign.center,
              //           )
              //         : null,
              //   ),
              // ),
            ),
          ],
        ),
      ),
    );
  }
}
