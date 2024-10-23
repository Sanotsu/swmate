import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../apis/food/nutritionix/nutritionix_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/utils/dio_client/interceptor_error.dart';
import '../../../../models/food/nutritionix/nix_natural_exercise_resp.dart';
import '../../../../models/food/nutritionix/nix_natural_nutrient_resp.dart';
import '../../../../services/cus_get_storage.dart';
import 'nix_food_item_nutrients_page.dart';

class NixNaturalLanguageQuery extends StatefulWidget {
  const NixNaturalLanguageQuery({super.key});

  @override
  State<NixNaturalLanguageQuery> createState() =>
      _NixNaturalLanguageQueryState();
}

class _NixNaturalLanguageQueryState extends State<NixNaturalLanguageQuery>
    with SingleTickerProviderStateMixin {
  // tab控制器
  late TabController _tabController;
  // 食物摄入文本框控制器
  final _foodController = TextEditingController();
  // 运动锻炼文本框控制器
  final _exerciseController = TextEditingController();

  // 食物摄入能量查询的结果
  List<NixNutrientFood> foodResult = [];
  // 运动消耗能量查询的结果
  List<NixExercise> exerciseResult = [];

  // 是否在查询数据中
  bool isLoading = false;

  // 身高体重年龄的修改表单全局key
  final _formKey = GlobalKey<FormBuilderState>();

  // 提示说明文本
  String note = '''数据来源于[nutritionix](https://www.nutritionix.com/business/api)

**运动需要每项单独一行输入**；避免理解不当，食物也建议每项单行输入。

\n\n[MET](https://en.wikipedia.org/wiki/Metabolic_equivalent_of_task)可以被理解为特定活动状态下相对于静息代谢状态的能耗水平。
\n\n可以简单的将 1 MET 定义为 1kcal/kg/hour （每公斤体重每小时消耗1大卡），这个数字基本与静息代谢率相等。

用于计算运动消耗的默认体重为70KG。
  ''';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(handleTabChange);
    _tabController.dispose();
    _foodController.dispose();
    _exerciseController.dispose();
    super.dispose();
  }

  // 切换tab时清空查询结果（暂时不用）
  void handleTabChange() {
    // tab is animating. from active (getting the index) to inactive(getting the index)
    if (_tabController.indexIsChanging) {
      debugPrint("点击切换了tab--${_tabController.index}");
    } else {
      // tab is finished animating you get the current index
      // here you can get your index or run some method once.

      if (_tabController.index == 0) {
        setState(() {
          // exerciseResult.clear();
        });
      }

      if (_tabController.index == 1) {
        setState(() {
          // foodResult.clear();
        });
      }
    }
  }

  // 自然语言查询食物摄入、运动消耗的接口
  Future<void> fetchData(String query) async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });

    if (query.isEmpty) {
      showSnackMessage(context, "输入框不可为空");
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      if (_tabController.index == 0) {
        var rst = await searchNixNutrientFoodByNL(query);

        if (!mounted) return;
        setState(() {
          foodResult = rst.foods ?? [];
        });
      } else {
        var rst = await searchNixExerciseByNL(
          query,
          heightCm: double.tryParse(box.read('height') ?? '170'),
          weightKg: double.tryParse(box.read('weight') ?? '70'),
          age: double.tryParse(box.read('age') ?? '30'),
        );

        if (!mounted) return;
        setState(() {
          exerciseResult = rst.exercises ?? [];
        });
      }
    } catch (e) {
      if (!mounted) return;

      if (e is CusHttpException) {
        showSnackMessage(
          context,
          "数据查询出错：${jsonDecode(e.errRespString)['message']}",
          seconds: 5,
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // 计算食物列表中指定营养素栏位的累计
  double getFoodNurientSum(double Function(NixNutrientFood) getValue) {
    return calculateSum(foodResult, getValue);
  }

  // 计算运动消耗列表中指定栏位的累计
  double getFoodExerciseSum(double Function(NixExercise) getValue) {
    return calculateSum(exerciseResult, getValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('食物能量与运动消耗'),
        actions: [
          IconButton(
            onPressed: () {
              commonMDHintModalBottomSheet(
                context,
                "食品成分说明",
                note,
                msgFontSize: 15.sp,
              );
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Food'),
            Tab(text: 'Exercise'),
          ],
        ),
      ),
      body: GestureDetector(
        // 允许子控件（如TextField）接收点击事件
        behavior: HitTestBehavior.translucent,
        // 点击空白处可以移除焦点，关闭键盘
        onTap: unfocusHandle,
        child: TabBarView(
          controller: _tabController,
          children: [
            buildTabContent(
              _foodController,
              'Enter a query like " 1 cup mashed potatoes and 2 tbsp gravy " to see how it works. We support tens of thousands of foods, including international dishes.',
              'Food',
            ),
            buildTabContent(
              _exerciseController,
              '''Enter your workout by lines. Examples:
  - ran 3 miles
  - 30 min weight lifting
  - 30 min yoga''',
              'Exercise',
            ),
          ],
        ),
      ),
    );
  }

  ///
  /// 构建tab内容(食物摄入和运动消耗都可以)
  ///
  Widget buildTabContent(
    TextEditingController controller,
    String hintText,
    String type,
  ) {
    return Padding(
      padding: EdgeInsets.all(5.sp),
      child: Column(
        children: [
          ...buildInputArea(controller, hintText),
          buildButtonArea(controller),
          if (_tabController.index == 0 && foodResult.isNotEmpty)
            ...buildFoodInputNutritionArea(type),
          if (_tabController.index == 1 && exerciseResult.isNotEmpty)
            ...buildExerciseBurnedArea(type),
        ],
      ),
    );
  }

  ///
  /// 输入框区域
  ///
  List<Widget> buildInputArea(
    TextEditingController controller,
    String hintText,
  ) {
    return [
      SizedBox(height: 10.sp),
      SizedBox(
        height: 120.sp,
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: EdgeInsets.all(5.sp),
              hintText: hintText,
              hintStyle: const TextStyle(
                // fontSize: 12.sp,
                fontWeight: FontWeight.normal,
              )
              // labelText: 'Input Natural Language Query',
              ),
          maxLines: 8,
          minLines: 5,
        ),
      ),
    ];
  }

  ///
  /// 按钮区域
  ///
  Widget buildButtonArea(TextEditingController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        (_tabController.index == 1)
            ? TextButton(
                onPressed: () {
                  _showFormDialog(context);
                },
                child: const Text('身高体重'),
              )
            : Container(),
        ElevatedButton(
          style: buildFunctionButtonStyle(),
          onPressed: isLoading
              ? null
              : () {
                  unfocusHandle();
                  fetchData(controller.text);
                },
          child: isLoading ? const Text('查询中') : const Text('查询'),
        ),
      ],
    );
  }

  ///
  /// 食物摄入的食物条目表格和营养素区域
  ///
  List<Widget> buildFoodInputNutritionArea(String type) {
    return [
      Divider(thickness: 5.sp),
      SizedBox(
        height: 60.sp,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Total Calories Intake:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              "${getFoodNurientSum((obj) => obj.nfCalories?.toDouble() ?? 0).toStringAsFixed(0)} kcal",
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
      SizedBox(
        height: 120.sp,
        child: SingleChildScrollView(
          child: _buildDataTable(type),
        ),
      ),
      Divider(thickness: 5.sp),
      Expanded(
        child: SingleChildScrollView(
          child: _buildMainNutrient(),
        ),
      ),
    ];
  }

  ///
  /// 运动消耗的卡路里总量和运动条目表格
  ///
  List<Widget> buildExerciseBurnedArea(String type) {
    return [
      Divider(thickness: 5.sp),
      Text(
        "身高 ${box.read('height') ?? '170'} 厘米, 体重 ${box.read('weight') ?? '70'} 公斤, 年龄 ${box.read('age') ?? '30'} 岁",
        textAlign: TextAlign.start,
      ),
      SizedBox(
        height: 80.sp,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Estimated Calories Burned:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              "${getFoodExerciseSum((obj) => obj.nfCalories?.toDouble() ?? 0).toStringAsFixed(0)} kcal",
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
      Divider(thickness: 5.sp),
      Expanded(
        child: SingleChildScrollView(
          child: _buildDataTable(type),
        ),
      ),
    ];
  }

  /// 构建表格
  Widget _buildDataTable(String type) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        dataRowMinHeight: 15.sp,
        dataRowMaxHeight: 56.sp,
        headingRowHeight: 50.sp,
        horizontalMargin: 10,
        headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
        columnSpacing: 10.sp,
        columns: _buildTableHead(type),
        rows:
            type == "Food" ? _buildFoodTableRows() : _buildExerciseTableRows(),
      ),
    );
  }

  // 构建表格标头
  List<DataColumn> _buildTableHead(String dataType) {
    if (dataType == "Food") {
      return const [
        DataColumn(label: Text("")),
        DataColumn(label: Text("Qty"), numeric: true),
        DataColumn(label: Text("Unit")),
        DataColumn(label: Text("Food")),
        DataColumn(label: Text("Calories")),
        DataColumn(label: Text("Weight")),
        // DataColumn(label: Text("Food Group")),
      ];
    } else {
      return const [
        // DataColumn(label: Text("")),
        DataColumn(label: Text("Exercise Name")),
        DataColumn(
          label: Text("MET", style: TextStyle(color: Colors.blue)),
          numeric: true,
        ),
        DataColumn(label: Text("Duration")),
        DataColumn(label: Text("Calories Expended")),
      ];
    }
  }

  // 构建食物摄入表格行数据
  List<DataRow> _buildFoodTableRows() {
    return List<DataRow>.generate(
      foodResult.length,
      (int index) {
        var item = foodResult[index];

        return DataRow(
          cells: <DataCell>[
            DataCell(
              SizedBox(
                width: 48.sp,
                height: 48.sp,
                child: CachedNetworkImage(
                  imageUrl: item.photo?.thumb ?? '',
                  fit: BoxFit.scaleDown,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
            _buildFormatDataCell(item.servingQty),
            _buildFormatDataCell(item.servingUnit),
            // _buildFormatDataCell(item.foodName),
            DataCell(
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NixFoodItemNutrientPage(
                        foodKeyword: item.foodName ?? _foodController.text,
                      ),
                    ),
                  );
                },
                child: Text(
                  "${item.foodName}",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightBlue,
                  ),
                ),
              ),
            ),
            _buildFormatDataCell("${item.nfCalories} kcal"),
            _buildFormatDataCell("${item.servingWeightGrams} g"),
            // _buildFormatDataCell(item.tags?.foodGroup),
          ],
        );
      },
    );
  }

  // 构建运动消耗表格行数据
  List<DataRow> _buildExerciseTableRows() {
    return List<DataRow>.generate(
      exerciseResult.length,
      (int index) {
        var item = exerciseResult[index];

        return DataRow(
          cells: <DataCell>[
            DataCell(
              Row(
                children: [
                  SizedBox(
                    width: 48.sp,
                    height: 48.sp,
                    child: CachedNetworkImage(
                      imageUrl: item.photo?.thumb ?? '',
                      fit: BoxFit.scaleDown,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  ),
                  Text(
                    item.name ?? '',
                    style: TextStyle(fontSize: 13.sp),
                  )
                ],
              ),
            ),
            // buildFormatDataCell(item.name),
            _buildFormatDataCell(item.met),
            _buildFormatDataCell("${item.durationMin} min"),
            _buildFormatDataCell("${item.nfCalories} kcal"),
          ],
        );
      },
    );
  }

  // 表格行格式化
  DataCell _buildFormatDataCell(dynamic label, {double? fontSize}) {
    return DataCell(
      Text(
        "${label ?? ''}",
        style: TextStyle(fontSize: fontSize ?? 13.sp),
        textAlign: TextAlign.end,
      ),
    );
  }

  /// 构建主要营养素显示区域
  Widget _buildMainNutrient() {
    return Column(
      children: [
        Text(
          'Total Main Nutritions',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        Divider(thickness: 1.sp),
        // buildNutrientRow(
        //   'Total Calories',
        //   getFoodNurientSum((obj) => obj.nfCalories ?? 0),
        //   'kcal',
        //   isBold: true,
        // ),
        buildNutrientRow(
          'Total Fat',
          getFoodNurientSum((obj) => obj.nfTotalFat ?? 0),
          'g',
          isBold: true,
        ),
        buildNutrientRow(
          'Saturated Fat',
          getFoodNurientSum((obj) => obj.nfSaturatedFat ?? 0),
          'g',
        ),
        buildNutrientRow(
          'Cholesterol',
          getFoodNurientSum((obj) => obj.nfCholesterol?.toDouble() ?? 0),
          'mg',
          isBold: true,
        ),
        buildNutrientRow(
          'Sodium',
          getFoodNurientSum((obj) => obj.nfSodium ?? 0),
          'mg',
          isBold: true,
        ),
        buildNutrientRow(
          'Potassium',
          getFoodNurientSum((obj) => obj.nfPotassium ?? 0),
          'mg',
          isBold: true,
        ),
        buildNutrientRow(
          'Total Carbohydrate',
          getFoodNurientSum((obj) => obj.nfTotalCarbohydrate ?? 0),
          'mg',
          isBold: true,
        ),
        buildNutrientRow(
          'Dietary Fiber',
          getFoodNurientSum((obj) => obj.nfDietaryFiber ?? 0),
          'g',
        ),
        buildNutrientRow(
          'Sugars',
          getFoodNurientSum((obj) => obj.nfSugars ?? 0),
          'g',
        ),
        buildNutrientRow(
          'Protein',
          getFoodNurientSum((obj) => obj.nfProtein ?? 0),
          'g',
          isBold: true,
        ),
      ],
    );
  }

  // 构建主要营养素显示行
  Widget buildNutrientRow(
    String label,
    double? value,
    String unit, {
    bool? isBold,
  }) {
    return value != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isBold == true
                  ? Text(
                      '$label: ${value.toStringAsFixed(2)} $unit',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : Row(
                      children: [
                        SizedBox(width: 20.sp),
                        Text('$label: ${value.toStringAsFixed(2)} $unit'),
                      ],
                    ),
              Divider(height: 10.sp),
            ],
          )
        : const SizedBox.shrink();
  }

  // 显示修改身高、体重、年龄的表单
  void _showFormDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            '输入身高、体重和年龄',
            style: TextStyle(fontSize: 18.sp),
          ),
          content: FormBuilder(
            key: _formKey,
            initialValue: {
              'height': box.read('height') ?? '',
              'weight': box.read('weight') ?? '',
              'age': box.read('age') ?? '',
            },
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FormBuilderTextField(
                    name: 'height',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '身高 (cm)'),
                  ),
                  FormBuilderTextField(
                    name: 'weight',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '体重 (kg)'),
                  ),
                  FormBuilderTextField(
                    name: 'age',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '年龄'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.saveAndValidate()) {
                  var values = (_formKey.currentState!.value);
                  box.write('height', values['height']);
                  box.write('weight', values['weight']);
                  box.write('age', values['age']);

                  Navigator.of(context).pop();
                }
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}

// 传入一个对象列表，和获取对象的某个属性，计算该属性的列表累加值
double calculateSum<T>(List<T> objects, double Function(T) getValue) =>
    objects.map(getValue).reduce((value, element) => value + element);
