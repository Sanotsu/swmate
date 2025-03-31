import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FeatureGridCard extends StatelessWidget {
  final Widget targetPage;
  final String title;
  final IconData icon;
  final Color? accentColor;
  final bool isNew;

  const FeatureGridCard({
    super.key,
    required this.targetPage,
    required this.title,
    required this.icon,
    this.accentColor,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.primaryColor;

    return Card(
      elevation: 3,
      shadowColor: color.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.sp),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.sp),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => targetPage),
          );
        },
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(16.sp),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 64.sp,
                    height: 64.sp,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16.sp),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 32.sp,
                    ),
                  ),
                  SizedBox(height: 16.sp),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (isNew)
              Positioned(
                top: 12.sp,
                right: 12.sp,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.sp,
                    vertical: 4.sp,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12.sp),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '新',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
