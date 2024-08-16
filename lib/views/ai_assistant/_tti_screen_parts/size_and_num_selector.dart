import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

  const SizeAndNumArea({
    super.key,
    required this.selectedSize,
    required this.selectedNum,
    required this.sizeList,
    required this.numList,
    required this.onSizeChanged,
    required this.onNumChanged,
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
          Expanded(
            child: SizeAndNumSelector(
              label: "数量",
              selectedValue: selectedNum,
              items: numList,
              onChanged: onNumChanged,
              itemToString: (item) => item.toString(),
            ),
          ),
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

  const SizeAndNumSelector({
    super.key,
    required this.label,
    required this.selectedValue,
    required this.items,
    required this.onChanged,
    required this.itemToString,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 1.0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(label),
          DropdownButton<dynamic>(
            value: selectedValue,
            underline: Container(),
            alignment: AlignmentDirectional.center,
            menuMaxHeight: 300.sp,
            items: items
                .map((e) => DropdownMenuItem<dynamic>(
                      value: e,
                      alignment: AlignmentDirectional.center,
                      child: Text(
                        itemToString(e),
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
