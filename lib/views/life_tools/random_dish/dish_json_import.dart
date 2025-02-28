import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import '../../../common/components/tool_widget.dart';
import '../../../common/utils/db_tools/db_life_tool_helper.dart';
import '../../../models/life_tools/dish_state.dart';

/// 只支持导入json文件，不再支持文件夹
class DishJsonImport extends StatefulWidget {
  const DishJsonImport({super.key});

  @override
  State<DishJsonImport> createState() => _DishJsonImportState();
}

class _DishJsonImportState extends State<DishJsonImport> {
  final DBLifeToolHelper _dbHelper = DBLifeToolHelper();

  // 是否在解析json中或导入数据库中
  bool isLoading = false;
  // 文件解析后的菜品信息
  List<JsonFileDish> dishes = [];

  // 构建json文件加载成功后的锻炼数据表格要用到
  // 待上传的动作数量已经每个动作的选中状态
  int dishItemsNum = 0;
  List<bool> dishSelectedList = [false];

  // 用户可以选择多个json文件
  Future<void> _openJsonFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ["json", "JSON"],
    );
    if (result != null) {
      setState(() {
        isLoading = true;
      });

      for (File file in result.files.map((file) => File(file.path!))) {
        try {
          String jsonData = await file.readAsString();

          // 如果一个json文件只是一个动作，那就加上中括号；如果本身就是带了中括号的多个，就不再加
          List dishMapList =
              jsonData.trim().startsWith("[") && jsonData.trim().endsWith("]")
                  ? json.decode(jsonData)
                  : json.decode("[$jsonData]");

          var temp = dishMapList.map((e) => JsonFileDish.fromJson(e)).toList();

          setState(() {
            dishes.addAll(temp);
            // 更新需要构建的表格的长度和每条数据的可选中状态
            dishItemsNum = dishes.length;
            dishSelectedList =
                List<bool>.generate(dishItemsNum, (int index) => false);
          });
        } catch (e) {
          // 弹出报错提示框
          if (!mounted) return;

          commonExceptionDialog(
            context,
            "导入json文件错误",
            "错误文件${file.path},\n 错误信息${e.toString}",
          );

          setState(() {
            isLoading = false;
          });
          // 中止操作
          return;
        }
      }
      setState(() {
        isLoading = false;
      });
    } else {
      // User canceled the picker
      return;
    }
  }

  // 讲json数据保存到数据库中
  _saveToDb() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });
    // 这里导入去重的工作要放在上面解析文件时，这里就全部保存了。
    // 而且id自增，食物或者编号和数据库重复，这里插入数据库中也不会报错。
    for (var e in dishes) {
      var tempDish = Dish(
        // 转型会把前面的0去掉(让id自增，否则下面serving的id也要指定)
        dishId: const Uuid().v1(),
        dishName: e.dishName ?? "",
        description: e.description ?? "",
        tags: e.tags ?? "",
        mealCategories: e.mealCategories ?? "",
        // ？？？这里假设传入的图片是完整的
        photos: e.images?.join(","),
        videos: e.videos?.join(","),
        // json描述是字符串数组，直接用换行符拼接
        recipe: e.recipe?.join("\n\n"),
        recipePicture: e.recipePicture,
      );

      try {
        await _dbHelper.insertDishList([tempDish]);
      } on Exception catch (e) {
        // 将错误信息展示给用户
        if (!mounted) return;
        commonExceptionDialog(context, "异常提醒", e.toString());

        setState(() {
          isLoading = false;
        });
        return;
      }
    }
    // 保存完了，情况数据，并弹窗提示。
    setState(() {
      setState(() {
        dishes = [];
        // 更新需要构建的表格的长度和每条数据的可选中状态
        dishItemsNum = 0;
        dishSelectedList = [false];

        isLoading = false;
      });
    });

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("菜品导入"),
          content: const Text("菜品已成功导入！"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("确定"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "导入菜品",
          style: TextStyle(fontSize: 20.sp),
        ),
        actions: [
          IconButton(
            onPressed: dishes.isNotEmpty ? _saveToDb : null,
            icon: Icon(
              Icons.save,
              color: dishes.isNotEmpty ? null : Theme.of(context).disabledColor,
            ),
          ),
          IconButton(
            onPressed: () {
              commonMDHintModalBottomSheet(
                context,
                "json文件结构",
                """
```
[
  {
    "dish_name": "回锅肉",
    "description": "此菜色味俱佳，肉鲜而香……",
    "tags": "川菜,家常菜,肉菜,麻辣鲜香",
    "meal_categories": "午餐,晚餐,夜宵",
    "images": [
      "https://www.xxx.jpg",
      "https://www.xxxx.jpg"
    ],
    "videos": ["https://……/video/"],
    "recipe": [
      "原料："
      "猪肉500克，蒜苗150克，化猪油40克，……",
      "作法："
      "1. 把带皮的肥瘦相连的猪肉洗干净。",
      "2. 锅内放开水置旺火上，下猪肉和葱、姜、……",
      "附 注：",
      "1.在肉汤中加适量新……",
      "2.根据爱好，菜内可加豆豉炒……",
    ],
    // 菜谱只支持单张图片
    "recipe_picture": "https://xxxx.com" 
  },
  { …… }
]
```
""",
                msgFontSize: 15.sp,
              );
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: isLoading
          ? buildLoader(isLoading)
          : Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                /// 最上方的功能按钮区域
                buildButtonsArea(),

                /// 食物组成列表不为空且大于50条，简单的列表展示
                if (dishes.isNotEmpty && dishes.length > 50)
                  ...buildDishListArea(),

                /// 食物组成列表不为空且不大于50条，简单的表格展示
                if (dishes.isNotEmpty && dishes.length <= 50)
                  ...buildDishDataTable(),
              ],
            ),
    );
  }

  /// 构建功能按钮区
  buildButtonsArea() {
    return Card(
      elevation: 5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: _openJsonFiles,
              icon: const Icon(Icons.file_upload),
              label: const Text("选择文件"),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  dishes = [];
                  // 更新需要构建的表格的长度和每条数据的可选中状态
                  dishItemsNum = 0;
                  dishSelectedList = [false];
                });
              },
              icon: Icon(
                Icons.clear,
                color: dishes.isNotEmpty
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).disabledColor,
              ),
              label: Text(
                "清空所有",
                style: TextStyle(
                  color: dishes.isNotEmpty
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).disabledColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 当上传的食物营养素信息超过50条，就单纯的列表展示
  buildDishListArea() {
    return [
      RichText(
        textAlign: TextAlign.left,
        text: TextSpan(
          children: [
            TextSpan(
              text: "共${dishes.length}条",
              style: TextStyle(fontSize: 14.sp, color: Colors.blue),
            ),
            TextSpan(
              text: "从左往右为：索引-菜品名称-标签",
              style: TextStyle(fontSize: 14.sp, color: Colors.green),
            ),
          ],
        ),
      ),
      SizedBox(height: 10.sp),
      Expanded(
        child: ListView.builder(
          itemCount: dishes.length,
          itemBuilder: (context, index) {
            return Row(
              verticalDirection: VerticalDirection.up,
              children: [
                Expanded(
                  child: RichText(
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        // 简单固定下宽度
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: 60.sp),
                            child: Padding(
                              padding: EdgeInsets.only(left: 10.sp),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ),
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: 160.sp),
                            child: Text(
                              "${dishes[index].dishName}",
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        // TextSpan(
                        //   text: '${index + 1} - ',
                        //   style: TextStyle(
                        //     fontSize: 12.sp,
                        //     color: Colors.green,
                        //   ),
                        // ),
                        // TextSpan(
                        //   text: "${dishes[index].dishName} - ",
                        //   style: TextStyle(
                        //     fontSize: 12.sp,
                        //     color: Colors.grey,
                        //   ),
                        // ),
                        TextSpan(
                          text: "${dishes[index].tags}",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ];
  }

  /// 当上传的食物营养素信息不超过50条，可以表格管理
  buildDishDataTable() {
    return [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.sp),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "上传条目",
              style: TextStyle(fontSize: 16.sp),
              textAlign: TextAlign.start,
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  // 先找到被选中的索引
                  List<int> trueIndices =
                      List.generate(dishSelectedList.length, (index) => index)
                          .where((i) => dishSelectedList[i])
                          .toList();

                  // 从列表中移除
                  // 倒序遍历需要移除的索引列表，以避免索引变化导致的问题
                  for (int i = trueIndices.length - 1; i >= 0; i--) {
                    dishes.removeAt(trueIndices[i]);
                  }
                  // 更新需要构建的表格的长度和每条数据的可选中状态
                  dishItemsNum = dishes.length;
                  dishSelectedList = List<bool>.generate(
                    dishItemsNum,
                    (int index) => false,
                  );
                });
              },
              child: Text(
                "移除选中",
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: SingleChildScrollView(
          child: DataTable(
            dataRowMinHeight: 20.sp, // 设置行高范围
            // dataRowMaxHeight: 80.sp,
            headingRowHeight: 25, // 设置表头行高
            horizontalMargin: 10, // 设置水平边距
            columnSpacing: 15.sp, // 设置列间距
            columns: const <DataColumn>[
              DataColumn(label: Text("菜品名称")),
              DataColumn(label: Text("菜品分类")),
            ],
            rows: List<DataRow>.generate(
              dishItemsNum,
              (int index) => DataRow(
                color: WidgetStateProperty.resolveWith<Color?>(
                    (Set<WidgetState> states) {
                  // All rows will have the same selected color.
                  if (states.contains(WidgetState.selected)) {
                    return Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.08);
                  }
                  // Even rows will have a grey color.
                  if (index.isEven) {
                    return Colors.grey.withOpacity(0.3);
                  }
                  return null; // Use default value for other states and odd rows.
                }),
                cells: <DataCell>[
                  DataCell(
                    SizedBox(
                      width: 0.35.sw,
                      child: Wrap(
                        children: [
                          Text(
                            '${dishes[index].dishName}',
                            style: TextStyle(fontSize: 12.sp),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 0.55.sw,
                      child: Text(
                        '${dishes[index].tags}',
                        style: TextStyle(fontSize: 12.sp),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                ],
                selected: dishSelectedList[index],
                onSelectChanged: (bool? value) {
                  setState(() {
                    dishSelectedList[index] = value!;
                  });
                },
              ),
            ),
          ),
        ),
      )
    ];
  }
}
