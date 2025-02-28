import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../common/constants/constants.dart';

///
/// 横向滚动选择新闻分类列表
///
class CusScrollableCategoryList extends StatelessWidget {
  final ScrollController scrollController;
  final List<CusLabel> categories;
  final int selectedIndex;
  final Function(int) onCategorySelected;

  const CusScrollableCategoryList({
    super.key,
    required this.scrollController,
    required this.categories,
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  // 是否可以向左滚动
  bool get canScrollLeft =>
      scrollController.positions.isNotEmpty &&
      scrollController.position.pixels > 0;

  // 是否可以向右滚动
  bool get canScrollRight =>
      scrollController.positions.isNotEmpty &&
      scrollController.position.pixels <
          scrollController.position.maxScrollExtent;

  // 向左滚动
  void _scrollLeft() {
    scrollController.animateTo(
      // 每次点击滚动一个60
      scrollController.position.pixels - 60.sp,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // 向右滚动
  void _scrollRight() {
    scrollController.animateTo(
      // 每次点击滚动一个60
      scrollController.position.pixels + 60.sp,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35.sp,
      child: Row(
        children: [
          if (canScrollLeft)
            IconButton(
              icon: const Icon(Icons.arrow_left),
              onPressed: _scrollLeft,
            ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.sp),
                  // 使用 InkWell 可以比较容易自定义样式
                  child: InkWell(
                    onTap: () => onCategorySelected(index),
                    child: Container(
                      width: 60.sp,
                      height: 30.sp,
                      padding: EdgeInsets.all(1.sp),
                      decoration: BoxDecoration(
                        color: selectedIndex == index
                            ? Colors.blue[100]
                            : Colors.white,
                        borderRadius: BorderRadius.circular(5.sp),
                        border: Border.all(color: Colors.grey, width: 1.sp),
                      ),
                      child: Center(
                        child: Text(
                          categories[index].cnLabel,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (canScrollRight)
            IconButton(
              icon: const Icon(Icons.arrow_right),
              onPressed: _scrollRight,
            ),
        ],
      ),
    );
  }
}
