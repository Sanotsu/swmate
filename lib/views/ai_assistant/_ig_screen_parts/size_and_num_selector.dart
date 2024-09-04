import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/components/tool_widget.dart';

///
/// 图片的尺寸和数量选择区域部件
///
class SizeAndNumArea extends StatelessWidget {
  final String? selectedSize;
  final int? selectedNum;
  final List<String> sizeList;
  final List<int> numList;
  final Function(dynamic) onSizeChanged;
  final Function(dynamic) onNumChanged;
  // 很多文生图不支持多个图片生成，所以放这个数量就会有干扰
  final bool? isOnlySize;

  const SizeAndNumArea({
    super.key,
    required this.selectedSize,
    required this.selectedNum,
    required this.sizeList,
    required this.numList,
    required this.onSizeChanged,
    required this.onNumChanged,
    this.isOnlySize = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32.sp,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(width: 5.sp),
          Expanded(
            child: SizeAndNumSelector(
              label: "尺寸",
              selectedValue: selectedSize,
              items: sizeList,
              onChanged: onSizeChanged,
              itemToString: (item) => item,
            ),
          ),
          SizedBox(width: 5.sp),
          if (isOnlySize == false)
            Expanded(
              child: SizeAndNumSelector(
                label: "数量",
                selectedValue: selectedNum,
                items: numList,
                onChanged: onNumChanged,
                itemToString: (item) => item.toString(),
              ),
            ),
          if (isOnlySize == false) SizedBox(width: 5.sp),
        ],
      ),
    );
  }
}

class SizeAndNumSelector extends StatelessWidget {
  final String label;
  final dynamic selectedValue;
  final List<dynamic> items;
  final Function(dynamic) onChanged;
  final String Function(dynamic) itemToString;

  final double? labelSize;

  const SizeAndNumSelector({
    super.key,
    required this.label,
    required this.selectedValue,
    required this.items,
    required this.onChanged,
    required this.itemToString,
    this.labelSize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(width: 10.sp),
        Expanded(
          child: buildDropdownButton2<dynamic>(
            items: items,
            value: selectedValue,
            onChanged: onChanged,
            itemToString: (e) => itemToString(e),
          ),
        ),
      ],
    );
  }
}
