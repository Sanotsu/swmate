import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../common/components/tool_widget.dart';
import '../../../common/utils/db_tools/db_life_tool_helper.dart';
import '../../../models/life_tools/dish_state.dart';
import 'dish_modify.dart';

class DishDetail extends StatefulWidget {
  // 这个是食物搜索页面点击食物进来详情页时传入的数据
  final Dish dishItem;

  const DishDetail({super.key, required this.dishItem});

  @override
  State<DishDetail> createState() => _DishDetailState();
}

class _DishDetailState extends State<DishDetail> {
  final DBLifeToolHelper _dbHelper = DBLifeToolHelper();

  // 构建食物的单份营养素列表，可以多选，然后进行相关操作
  // 待上传的动作数量已经每个动作的选中状态
  int servingItemsNum = 0;
  List<bool> servingSelectedList = [false];

  // 传入的食物详细数据
  late Dish dishInfo;

  // 数据是否被修改
  // (这个标志要返回，如果有被修改，返回上一页列表时要重新查询；没有被修改则不用重新查询)
  bool isModified = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      dishInfo = widget.dishItem;
    });
  }

  // 在修改了菜品基本信息后，重新查询该菜品
  refreshDishInfo() async {
    var newItem = await _dbHelper.queryDishList(
      dishId: widget.dishItem.dishId,
    );

    if (newItem.data.isNotEmpty) {
      setState(() {
        dishInfo = (newItem.data as List<Dish>)[0];
      });
    }
  }

  /// 新结构，上面是食物基本信息，下面是单份营养素详情表格；
  /// 右上角修改按钮，修改基本信息；
  /// 表格的单份营养素可选中索引进行删除，可新增；
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        // 返回上一页时，返回是否被修改标识，用于父组件判断是否需要重新查询
        Navigator.pop(context, isModified);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text("菜品详情"),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DishModify(dish: dishInfo),
                  ),
                ).then((value) {
                  // 不管是否修改成功，这里都重新加载
                  // 还是稍微判断一下吧
                  if (value != null && value == true) {
                    refreshDishInfo();
                    // 被修改的标志也改一下，传给上一层进行刷新
                    isModified = true;
                  }
                });
              },
              icon: const Icon(Icons.edit),
            ),
          ],
        ),
        body: ListView(
          children: [
            /// 展示食物基本信息表格
            ...buildDishTable(dishInfo),
          ],
        ),
      ),
    );
  }

  /// 表格显示食物基本信息
  buildDishTable(Dish dish) {
    List<String> imageList = [];
    // 先要排除image是个空字符串在分割
    if (dish.photos != null && dish.photos!.trim().isNotEmpty) {
      imageList = dish.photos!.split(",");
    }

    return [
      Text(
        dish.dishName,
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
        textAlign: TextAlign.center,
      ),

      _buildTitleText("菜品参考图片"),
      buildImageCarouselSlider(imageList),
      _buildTitleText("菜品基本信息"),
      Padding(
        padding: EdgeInsets.all(10.sp),
        child: Table(
          // 设置表格边框
          border: TableBorder.all(color: Theme.of(context).disabledColor),
          // 设置每列的宽度占比
          columnWidths: const {
            0: FlexColumnWidth(5),
            1: FlexColumnWidth(17),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            _buildTableRow("菜品名称", dish.dishName),
            _buildTableRow("菜品介绍", dish.description ?? ""),
            _buildTableRow("菜品分类", dish.tags ?? ""),
            _buildTableRow("菜品餐次", dish.mealCategories ?? ""),
            // _buildTableRow("菜谱", dish.recipe ?? ""),
            // _buildTableRow("图片地址", dish.photos ?? ""),
            _buildTableRow("视频地址", dish.videos ?? ""),
            if (dish.videos != null && dish.videos != "")
              TableRow(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.sp),
                    child: Text(
                      "视频教程",
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.sp),
                    child: TextButton(
                      onPressed: () async {
                        if (!await launchUrl(
                            Uri.parse(dish.videos!.split(",")[0]))) {
                          throw Exception('视频链接无法跳转');
                        }
                      },
                      child: const Text('点击跳转观看'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),

      /// 菜谱单独列出来
      Padding(
        padding: EdgeInsets.all(10.sp),
        child: Table(
          // 设置表格边框
          border: TableBorder.all(color: Theme.of(context).disabledColor),
          // 设置每列的宽度占比
          columnWidths: const {
            0: FlexColumnWidth(10),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.sp),
                  child: Text(
                    "菜谱及图片",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            _buildTableRow(null, dish.recipe ?? "", valueFontSize: 16.sp),
          ],
        ),
      ),

      if (dish.recipePicture != null && dish.recipePicture != "")
        buildClickImageDialog(context, dish.recipePicture!)
    ];
  }

  // 标题文字
  _buildTitleText(
    String title, {
    double? fontSize = 16,
    Color? color = Colors.black54,
    TextAlign? textAlign = TextAlign.start,
  }) {
    return Padding(
      padding: EdgeInsets.all(10.sp),
      child: Text(
        title,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: color,
        ),
        textAlign: textAlign,
      ),
    );
  }

  // 构建食物基本信息表格的行数据
  _buildTableRow(
    String? label,
    String value, {
    double? labelFontSize,
    double? valueFontSize,
  }) {
    return TableRow(
      children: [
        if (label != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.sp),
            child: Text(
              label,
              style: TextStyle(
                fontSize: labelFontSize ?? 14.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.sp),
          child: Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize ?? 14.sp,
              color: Colors.black87,
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }
}
