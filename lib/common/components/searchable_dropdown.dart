import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 可筛选的下拉框
class SearchableDropdown<T> extends StatefulWidget {
  // 列表
  final List<T> items;
  // 选中的值
  final T? value;
  // 值变化的回调
  final Function(T?)? onChanged;
  // 如何从传入的类型中获取显示的字符串
  final String Function(dynamic)? itemToString;
  // 下拉框的高度
  final double? height;
  // 选项列表的最大高度
  final double? itemMaxHeight;
  // 标签的字号
  final double? labelSize;
  // 标签对齐方式(默认居中，像模型列表靠左，方便对比)
  final AlignmentGeometry? alignment;
  // 提示字符串
  final String? hintLable;

  const SearchableDropdown({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.itemToString,
    this.height,
    this.itemMaxHeight,
    this.labelSize,
    this.alignment,
    this.hintLable,
  });

  @override
  createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  final TextEditingController textEditingController = TextEditingController();

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<T>(
        isExpanded: true,
        // 提示词
        hint: Text(
          widget.hintLable ?? '请选择',
          style: TextStyle(fontSize: 14.sp),
        ),
        items: widget.items
            .map((e) => DropdownMenuItem<T>(
                  value: e,
                  alignment: widget.alignment ?? AlignmentDirectional.center,
                  child: Text(
                    widget.itemToString != null
                        ? widget.itemToString!(e)
                        : e.toString(),
                    style: TextStyle(
                      fontSize: widget.labelSize ?? 15.sp,
                      color: Colors.blue,
                    ),
                  ),
                ))
            .toList(),
        value: widget.value,
        onChanged: widget.onChanged,
        // 默认的按钮的样式(下拉框旋转的样式)
        buttonStyleData: ButtonStyleData(
          height: widget.height ?? 30.sp,
          // width: 190.sp,
          padding: EdgeInsets.all(0.sp),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5.sp),
            border: Border.all(color: Colors.black26),
            // color: Colors.blue[50],
            color: Colors.white,
          ),
          elevation: 0,
        ),
        // 按钮后面的图标的样式(默认也有个下三角)
        iconStyleData: IconStyleData(
          icon: const Icon(Icons.arrow_drop_down),
          iconSize: 20.sp,
          iconEnabledColor: Colors.blue,
          iconDisabledColor: Colors.grey,
        ),
        // 下拉选项列表区域的样式
        dropdownStyleData: DropdownStyleData(
          maxHeight: widget.itemMaxHeight ?? 300.sp,
          // 不设置且isExpanded为true就是外部最宽
          // width: 190.sp, // 可以根据下面的offset偏移和上面按钮的长度来调整
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5.sp),
            color: Colors.white,
          ),
          // offset: const Offset(-20, 0),
          offset: const Offset(0, 0),
          scrollbarTheme: ScrollbarThemeData(
            radius: Radius.circular(40.sp),
            thickness: WidgetStateProperty.all(6.sp),
            thumbVisibility: WidgetStateProperty.all(true),
          ),
        ),
        // 下拉选项单个选项的样式
        menuItemStyleData: MenuItemStyleData(
          height: 48.sp, // 方便超过1行的模型名显示，所有设置高点
          padding: EdgeInsets.symmetric(horizontal: 5.sp),
        ),
        // 下拉搜索框的样式
        dropdownSearchData: DropdownSearchData(
          searchController: textEditingController,
          searchInnerWidgetHeight: 50.sp,
          searchInnerWidget: Container(
            height: 50.sp,
            padding: EdgeInsets.all(5.sp),
            child: TextFormField(
              expands: true,
              maxLines: null,
              controller: textEditingController,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.all(5.sp),
                hintText: '输入关键字进行筛选',
                hintStyle: TextStyle(fontSize: 12.sp),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.sp),
                ),
              ),
            ),
          ),
          searchMatchFn: (item, searchValue) {
            return item.value.toString().contains(searchValue);
          },
        ),
        // 在关闭菜单时清除搜索值
        onMenuStateChange: (isOpen) {
          if (!isOpen) {
            textEditingController.clear();
          }
        },
      ),
    );
  }
}
