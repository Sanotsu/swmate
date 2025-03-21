import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ModernFeatureCard extends StatelessWidget {
  final Widget targetPage;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? accentColor;
  final bool showArrow;

  const ModernFeatureCard({
    super.key,
    required this.targetPage,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.accentColor,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.titleLarge?.color ?? Colors.black;
    final color = accentColor ?? theme.primaryColor;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.sp),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.sp),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => targetPage),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(20.sp),
          child: Row(
            children: [
              // 左侧图标
              Container(
                width: 56.sp,
                height: 56.sp,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.sp),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28.sp,
                ),
              ),
              SizedBox(width: 16.sp),

              // 中间文本
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 4.sp),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // 右侧箭头
              if (showArrow)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16.sp,
                  color: Colors.grey.shade400,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
