import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/constants.dart';

/// 中间弹窗的多选框
class CusMultiSelectDialog extends StatefulWidget {
  // 被选中的条目
  final List<CusLabel> selectedItems;
  // 所有的待选条目
  final List<CusLabel> items;
  // 弹窗的标题，用户可自定
  final String? title;
  const CusMultiSelectDialog({
    super.key,
    required this.selectedItems,
    required this.items,
    this.title,
  });

  @override
  State createState() => _CusMultiSelectDialogState();
}

class _CusMultiSelectDialogState extends State<CusMultiSelectDialog> {
  late List<CusLabel> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.selectedItems);
  }

  void _onItemCheckedChange(CusLabel item, bool checked) {
    setState(() {
      if (checked) {
        _selectedItems.add(item);
      } else {
        _selectedItems.remove(item);
      }
    });
  }

  void _onSubmit() {
    if (_selectedItems.isEmpty) {
      EasyLoading.showInfo("至少选择一个选项");
    } else {
      Navigator.of(context).pop(_selectedItems);
    }
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title ?? '多选'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.items.length,
          itemBuilder: (BuildContext context, int index) {
            return CheckboxListTile(
              title: Text(widget.items[index].cnLabel),
              value: _selectedItems.contains(widget.items[index]),
              dense: true,
              onChanged: (bool? value) {
                _onItemCheckedChange(widget.items[index], value!);
              },
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: _onCancel, child: const Text('取消')),
        TextButton(onPressed: _onSubmit, child: const Text('确定')),
      ],
    );
  }
}

/// 底部弹窗的多选框
class CusMultiSelectBottomSheet extends StatefulWidget {
  // 被选中的条目
  final List<CusLabel> selectedItems;
  // 所有的待选条目
  final List<CusLabel> items;
  // 弹窗的标题，用户可自定
  final String? title;
  const CusMultiSelectBottomSheet({
    super.key,
    required this.selectedItems,
    required this.items,
    this.title,
  });

  @override
  State createState() => _CusMultiSelectBottomSheetState();
}

class _CusMultiSelectBottomSheetState extends State<CusMultiSelectBottomSheet> {
  late List<CusLabel> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.selectedItems);
  }

  void _onItemCheckedChange(CusLabel item, bool checked) {
    setState(() {
      if (checked) {
        _selectedItems.add(item);
      } else {
        _selectedItems.remove(item);
      }
    });
  }

  void _onSubmit() {
    if (_selectedItems.isEmpty) {
      EasyLoading.showInfo("至少选择一个选项");
    } else {
      Navigator.of(context).pop(_selectedItems);
    }
  }

  void _onSelectAll(bool? checked) {
    setState(() {
      if (checked == true) {
        _selectedItems = List.from(widget.items);
      } else {
        _selectedItems.clear();
      }
    });
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.sp),
          topRight: Radius.circular(16.sp),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(16.sp),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title ?? '多选',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Checkbox(
                  value: _selectedItems.length == widget.items.length,
                  onChanged: _onSelectAll,
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.items.length,
              itemBuilder: (BuildContext context, int index) {
                return CheckboxListTile(
                  title: Text(widget.items[index].cnLabel),
                  value: _selectedItems.contains(widget.items[index]),
                  dense: true,
                  onChanged: (bool? value) {
                    _onItemCheckedChange(widget.items[index], value!);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.sp),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: _onCancel, child: const Text('取消')),
                SizedBox(width: 16.sp),
                TextButton(onPressed: _onSubmit, child: const Text('确定')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
