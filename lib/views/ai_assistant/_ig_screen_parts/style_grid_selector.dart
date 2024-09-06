import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

///
/// 文生图样式选择grid
///
class StyleGrid extends StatelessWidget {
  final List<String> imageUrls;
  final List<String> labels;
  final List<String> subLabels;
  final int selectedIndex;
  final Function(int) onTap;
  final int crossAxisCount;

  const StyleGrid({
    super.key,
    required this.imageUrls,
    required this.labels,
    required this.subLabels,
    required this.selectedIndex,
    required this.onTap,
    this.crossAxisCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(imageUrls.length, (index) {
        return GridTile(
          child: GestureDetector(
            onTap: () => onTap(index),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      selectedIndex == index ? Colors.blue : Colors.transparent,
                  width: 3.sp,
                ),
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: ImageStack(
                url: imageUrls[index],
                label: labels[index],
                subLabel: subLabels[index],
              ),
            ),
          ),
        );
      }),
    );
  }
}

///
/// 文生图每种样式展示小部件
///
class ImageStack extends StatelessWidget {
  final String url;
  final String label;
  final String subLabel;

  const ImageStack({
    super.key,
    required this.url,
    required this.label,
    required this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.asset(
            url,
            fit: BoxFit.cover,
            errorBuilder: (BuildContext context, Object exception,
                StackTrace? stackTrace) {
              return Container(color: Colors.grey.shade300);
            },
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: RichText(
            softWrap: true,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
            text: TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: "\n$subLabel",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9.sp),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
