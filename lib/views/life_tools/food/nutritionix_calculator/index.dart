import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../apis/_default_system_role_list/inner_system_prompt.dart';
import '../../../../apis/food/nutritionix/nutritionix_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/utils/dio_client/interceptor_error.dart';
import '../../../../common/utils/tools.dart';
import '../../../../models/food/nutritionix/nix_natural_exercise_resp.dart';
import '../../../../models/food/nutritionix/nix_natural_nutrient_resp.dart';
import '../../../../services/cus_get_storage.dart';
import '../nutritionix/nix_food_item_nutrients_page.dart';

///
/// 2024-10-25
/// 直接隐藏大模型翻译中文为英文这部分
/// 如果后续想要用户看到翻译后的内容，到时候再加显示按钮
///
class NixSimpleCalculator extends StatefulWidget {
  const NixSimpleCalculator({super.key});

  @override
  State createState() => _NixSimpleCalculatorState();
}

class _NixSimpleCalculatorState extends State<NixSimpleCalculator>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _foodController = TextEditingController();
  final TextEditingController _exerciseController = TextEditingController();

  // 输入的食物摄入或者运动项次(两者不会同时存在)
  String foodQuery = '';
  String exerciseQuery = '';

  // 身高体重年龄的修改表单全局key
  final _formKey = GlobalKey<FormBuilderState>();

  // 是否在查询数据中
  bool isLoading = false;

  // 食物摄入能量查询的结果
  List<NixNutrientFood> foodResult = [];
  // 运动消耗能量查询的结果
  List<NixExercise> exerciseResult = [];

  // 中文翻译后的英文
  String translatedTxt = "";

  // 提示说明文本
  String note = '''
数据来源于[nutritionix API](https://www.nutritionix.com/business/api)

**运动需要每项单独一行输入**；避免理解不当，食物也建议每项单行输入。
- 最好使用可量化的单位，比如：300克熟米饭、跳绳30分钟……
- 原始接口需要英文输入，所以默认是把用户输入使用大模型翻译为英文后调用后台API(已经是英文则使用原文)，结果仅供参考。

[MET](https://en.wikipedia.org/wiki/Metabolic_equivalent_of_task)可以被理解为特定活动状态下相对于静息代谢状态的能耗水平。
- 可以简单的将 1 MET 定义为 1kcal/kg/hour（每公斤体重每小时消耗1大卡），这个数字基本与静息代谢率相等。

用于计算运动消耗的默认体重为70KG。
- 可以点击“身高体重”文字按钮进行修改。
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

  // 切换tab之后，翻译的内容也要变了(暂时不用)
  void handleTabChange() {
    // tab is animating. from active (getting the index) to inactive(getting the index)
    if (_tabController.indexIsChanging) {
      debugPrint("点击切换了tab--${_tabController.index}");
    } else {
      // tab is finished animating you get the current index
      // here you can get your index or run some method once.

      // 切换tab后，翻译成的英文不显示
      setState(() {
        translatedTxt = "";
      });

      // if (_tabController.index == 0) {
      //   if (foodQuery.isEmpty) {
      //     setState(() {
      //       foodResult.clear();
      //     });
      //   }
      // }

      // if (_tabController.index == 1) {
      //   if (exerciseQuery.isEmpty) {
      //     setState(() {
      //       exerciseResult.clear();
      //     });
      //   }
      // }
    }
  }

  Future<String> _translateText(String text) async {
    // 如果tab索引为0,即查询食物；否则就是运动
    return await getAITranslation(
      text,
      systemPrompt: translateToEnglish(),
    );
  }

  // 自然语言查询食物摄入、运动消耗的接口
  Future<void> fetchData() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });

    String input = _tabController.index == 0
        ? _foodController.text
        : _exerciseController.text;

    var query = await _translateText(input);

    if (!mounted) return;
    setState(() {
      translatedTxt = query;
    });

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
      } else {
        showSnackMessage(
          context,
          "数据查询出错\n 其他错误：${e.toString()}",
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
      appBar: AppBar(
        title: const Text('热量计算器'),
        actions: [
          IconButton(
            onPressed: () {
              commonMDHintModalBottomSheet(
                context,
                "使用说明",
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
            Tab(text: '食物摄入'),
            Tab(text: '运动消耗'),
          ],
        ),
      ),
      body: GestureDetector(
        // 允许子控件（如TextField）接收点击事件
        behavior: HitTestBehavior.translucent,
        // 点击空白处可以移除焦点，关闭键盘
        onTap: unfocusHandle,
        child: Column(
          children: [
            SizedBox(
              height: 120.sp,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInputTab(
                    _foodController,
                    '自然语言输入，比如：\n“1杯土豆泥，2汤匙肉汁，300克熟米饭”',
                  ),
                  _buildInputTab(
                    _exerciseController,
                    '逐行输入你的运动量，示例：\n  跑了3英里\n  30分钟举重\n  30分钟瑜伽',
                  ),
                ],
              ),
            ),

            /// 按钮区域
            buildButtonArea(),

            /// 翻译后的文本
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.sp),
              child: Text(translatedTxt),
            ),

            /// 请求响应区域
            isLoading ? buildLoader(isLoading) : buildResultArea(),
          ],
        ),
      ),
    );
  }

  ///
  /// 输入框所在的tab区域
  ///
  Widget _buildInputTab(
    TextEditingController controller,
    String hintText,
  ) {
    return Padding(
      padding: EdgeInsets.all(5.sp),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          contentPadding: EdgeInsets.all(5.sp),
          hintText: hintText,
          hintStyle: const TextStyle(
            fontWeight: FontWeight.normal,
          ),
        ),
        onChanged: (val) {
          setState(() {
            if (_tabController.index == 0) {
              foodQuery = val;
            } else {
              exerciseQuery = val;
            }
          });
        },
        maxLines: 8,
        minLines: 5,
      ),
    );
  }

  ///
  /// 按钮区域
  ///
  Widget buildButtonArea() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        (_tabController.index == 1)
            ? TextButton(
                onPressed: isLoading ? null : () => _showHeightWeightDialog(),
                child: const Text('身高体重'),
              )
            : Container(),
        ElevatedButton(
          style: buildFunctionButtonStyle(),
          onPressed: isLoading ||
                  (foodQuery.isEmpty && _tabController.index == 0) ||
                  (exerciseQuery.isEmpty && _tabController.index == 1)
              ? null
              : () {
                  unfocusHandle();
                  fetchData();
                },
          child: isLoading ? const Text('计算中') : const Text('计算'),
        ),
      ],
    );
  }

  ///
  /// 请求响应区域
  ///
  Widget buildResultArea() {
    debugPrint(
      "当前的结果--${_tabController.index}-食物${foodResult.length} 运动${exerciseResult.length}",
    );

    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(1.sp),
          child: Column(
            children: [
              if (_tabController.index == 0 && foodResult.isNotEmpty)
                ...buildFoodInputNutritionArea("Food"),
              if (_tabController.index == 1 && exerciseResult.isNotEmpty)
                ...buildExerciseBurnedArea("Exercise"),
            ],
          ),
        ),
      ),
    );
  }

  ///
  /// 食物摄入的食物条目表格和营养素区域
  ///
  List<Widget> buildFoodInputNutritionArea(String type) {
    return [
      Divider(thickness: 1.sp),
      SizedBox(height: 24.sp),
      SizedBox(
        height: 68.sp,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              '预估食物热量总摄入：',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              "${getFoodNurientSum((obj) => obj.nfCalories?.toDouble() ?? 0).toStringAsFixed(0)} 大卡",
              style: TextStyle(
                fontSize: 25.sp,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
      // Divider(thickness: 5.sp),
      _buildDataTable(type),
    ];
  }

  ///
  /// 运动消耗的卡路里总量和运动条目表格
  ///
  List<Widget> buildExerciseBurnedArea(String type) {
    return [
      Divider(thickness: 1.sp),
      SizedBox(
        height: 24.sp,
        child: Text(
          "身高 ${box.read('height') ?? '170'} 厘米, 体重 ${box.read('weight') ?? '70'} 公斤, 年龄 ${box.read('age') ?? '30'} 岁",
          textAlign: TextAlign.start,
        ),
      ),
      SizedBox(
        height: 68.sp,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              '预估运动热量总消耗：',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              "${getFoodExerciseSum((obj) => obj.nfCalories?.toDouble() ?? 0).toStringAsFixed(0)} 大卡",
              style: TextStyle(
                fontSize: 25.sp,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
      // Divider(thickness: 5.sp),
      _buildDataTable(type),
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
        horizontalMargin: 10.sp,
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
        DataColumn(label: Text("数量"), numeric: true),
        DataColumn(label: Text("单位")),
        DataColumn(label: Text("食物")),
        DataColumn(label: Text("热量")),
        DataColumn(label: Text("重量")),
      ];
    } else {
      return const [
        DataColumn(label: Text("运动名称")),
        DataColumn(
          label: Text("MET", style: TextStyle(color: Colors.blue)),
          numeric: true,
        ),
        DataColumn(label: Text("持续时长")),
        DataColumn(label: Text("热量消耗")),
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
            _buildFormatDataCell("${item.nfCalories} 大卡"),
            _buildFormatDataCell("${item.servingWeightGrams} 克"),
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
            _buildFormatDataCell(item.met),
            _buildFormatDataCell("${item.durationMin} 分钟"),
            _buildFormatDataCell("${item.nfCalories} 大卡"),
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

  ///
  /// 显示修改身高、体重、年龄的表单
  ///
  void _showHeightWeightDialog() {
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
