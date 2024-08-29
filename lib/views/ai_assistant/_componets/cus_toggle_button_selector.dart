import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CusToggleButtonSelector<T> extends StatefulWidget {
  // 用于选择的列表
  final List<T> items;
  // 被选中后的回调
  final Function(T) onItemSelected;
  // 用于从 T 类型的 item 中提取 label 字段
  final String Function(T) labelBuilder;

  const CusToggleButtonSelector({
    super.key,
    required this.items,
    required this.onItemSelected,
    required this.labelBuilder,
  });

  @override
  State createState() => _CusToggleButtonSelectorState<T>();
}

class _CusToggleButtonSelectorState<T>
    extends State<CusToggleButtonSelector<T>> {
  // 选中状态列表
  List<bool> _selections = [];

  @override
  void initState() {
    super.initState();

    // 传入的列表默认选中第一个
    _selections = List.generate(widget.items.length, (index) {
      if (index == 0) {
        return true;
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ToggleButtons(
            isSelected: _selections,
            onPressed: (int index) {
              setState(() {
                for (int i = 0; i < _selections.length; i++) {
                  _selections[i] = i == index;
                }

                widget.onItemSelected(widget.items[index]);
              });
            },
            // 这个是预设只有3个的情况，宽度各3分之一
            // constraints: BoxConstraints(minHeight: 36.sp, minWidth: 0.32.sw),
            // 一般长度不定，还是这个
            // 设置按钮的最小高度和最小宽度(得根据传入的label来判断)
            constraints: BoxConstraints(minHeight: 36.sp, minWidth: 80.sp),
            // 设置选中按钮的文本颜色
            selectedColor: Colors.white,
            // 设置选中按钮的边框颜色
            selectedBorderColor: Colors.blue,
            // 设置选中按钮的填充颜色
            fillColor: Colors.blue,
            // 设置按钮的圆角半径
            borderRadius: BorderRadius.circular(5.sp),
            // 设置按钮的边框宽度
            borderWidth: 1.sp,
            // 设置按钮的边框颜色
            borderColor: Colors.grey,
            children: List.generate(
              widget.items.length,
              (index) => Text(widget.labelBuilder(widget.items[index])),
            ),
          ),
        ],
      ),
    );
  }
}
