import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../apis/food/nutritionix/nix_nutrient_enum_list.dart';
import '../../../../apis/food/nutritionix/nutritionix_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/constants.dart';
import '../../../../models/food/nutritionix/nix_natural_nutrient_resp.dart';

// 食品营养素详情页面
class NixFoodItemNutrientPage extends StatefulWidget {
  // branded类型的可以用编号查询详情
  final String? nixItemId;
  // common类型的只有关键字
  final String? foodKeyword;

  const NixFoodItemNutrientPage({super.key, this.nixItemId, this.foodKeyword});

  @override
  State<NixFoodItemNutrientPage> createState() =>
      _NixFoodItemNutrientPageState();
}

class _NixFoodItemNutrientPageState extends State<NixFoodItemNutrientPage> {
  String note = '''显示的营养素数值为输入的份量(Serving Size)和单份的积
\n\n份量最大为9999,不可为负数(否则默认重置为1.0)''';

  // 通过编号查询到食品信息
  late Future<List<NixNutrientFood>> _foodItemFuture;

  final _sizeController = TextEditingController(text: "1");
  double _size = 1.0;

  @override
  void initState() {
    super.initState();

    _sizeController.addListener(_onSizeChanged);
    _foodItemFuture = getFoodItem();
  }

  @override
  void dispose() {
    _sizeController.dispose();
    super.dispose();
  }

  void _onSizeChanged() {
    double newSize = double.tryParse(_sizeController.text) ?? 1;
    // 输入的值小于0或者大于1万,就重置输入为1
    if (newSize < 1 || newSize > 10000) {
      newSize = 1;
      // 更新 TextField 的显示值
      _sizeController.text = newSize.toString();
    }

    setState(() {
      _size = newSize;
    });
  }

  // 计算结果，如果没传分数位数默认为2位小数
  String _calculateValue(double? originalValue, {int? fractionDigits}) {
    if (originalValue == null) return "0";
    var temp = (originalValue * _size).toStringAsFixed(fractionDigits ?? 2);
    return temp.length > 12 ? "数据过大" : temp;
  }

  Future<List<NixNutrientFood>> getFoodItem() async {
    if (widget.nixItemId != null) {
      var rst = await searchNixNutrientFoodById(nixItemId: widget.nixItemId);
      return rst.foods ?? [];
    } else if (widget.foodKeyword != null && widget.foodKeyword!.isNotEmpty) {
      var rst = await searchNixNutrientFoodByNL(widget.foodKeyword!);
      return rst.foods ?? [];
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("食品成分详情"),
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
      ),
      body: GestureDetector(
        // 允许子控件（如TextField）接收点击事件
        behavior: HitTestBehavior.translucent,
        // 点击空白处可以移除焦点，关闭键盘
        onTap: unfocusHandle,
        child: FutureBuilder<List<NixNutrientFood>>(
          future: _foodItemFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return buildLoader(true);
            } else if (snapshot.hasError) {
              throw snapshot;
              // return Center(child: Text('数据查询出错: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('暂无数据'));
            }

            final items = snapshot.data!;

            if (items.isEmpty) {
              return const Center(child: Text("数据为空"));
            }
            final item = items.first;

            return Container(
              // width: double.infinity,
              // decoration: BoxDecoration(
              //   color: Colors.white,
              //   borderRadius: BorderRadius.only(
              //     topLeft: Radius.circular(15.sp),
              //     topRight: Radius.circular(15.sp),
              //   ),
              // ),
              padding: EdgeInsets.all(5.sp),
              child: Column(
                children: [
                  buildHeaderArea(item),
                  buildInputServingSizeArea(item),
                  Divider(thickness: 2.sp, color: Colors.black),
                  Expanded(
                    child: SingleChildScrollView(
                      child: buildNutritionTable(item),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  ///
  /// 构建标题部分
  ///
  Widget buildHeaderArea(NixNutrientFood item) {
    return Card(
      child: ListTile(
        leading: SizedBox(
          width: 48.sp,
          child: CachedNetworkImage(
            imageUrl: item.photo?.thumb ?? '',
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
        title: Text("${item.foodName}", maxLines: 2),
        subtitle: Text(
          "${item.brandName ?? ''} ${item.tags?.item ?? ''}",
          maxLines: 2,
        ),
      ),
    );
  }

  ///
  /// 构建输入份数值部分
  ///
  Widget buildInputServingSizeArea(NixNutrientFood item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Serving Size: "),
        SizedBox(
          width: 80.sp,
          height: 36.sp,
          child: TextField(
            controller: _sizeController,
            decoration: InputDecoration(
              // 输入框内边距
              contentPadding: EdgeInsets.all(0.sp),
              border: OutlineInputBorder(
                // 边框线
                borderSide: const BorderSide(color: Colors.teal),
                // 输入框圆角
                borderRadius: BorderRadius.circular(8.sp),
              ),
            ),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  ///
  /// 构建营养素部分
  ///
  Widget buildNutritionTable(NixNutrientFood item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Food Size',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const Text('Per', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('Serving Qty: ${item.servingQty} ${item.servingUnit}'),
        if (item.servingWeightGrams != null)
          Text('Serving Weight: ${item.servingWeightGrams} grams'),
        if (item.updatedAt != null)
          Text(
            "Last updated: ${DateFormat(constDatetimeFormat).format(DateTime.tryParse(item.updatedAt!) ?? DateTime.now())}",
          ),

        Divider(thickness: 1.sp),
        const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(
          'Serving Qty: ${_calculateValue((item.servingQty ?? 0.0).toDouble())} ${item.servingUnit}',
        ),
        if (item.servingWeightGrams != null)
          Text(
            "Serving Weight: ${_calculateValue((item.servingWeightGrams ?? 0.0).toDouble())} g",
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Calories',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            Text(
              _calculateValue(item.nfCalories, fractionDigits: 0),
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),

        /// 这些是固定栏位返回的营养素(主要营养素)
        Divider(thickness: 10.sp),
        Text(
          'Main Nutritions',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        Divider(thickness: 1.sp),

        _buildNutrientRow('Total Fat', item.nfTotalFat, 'g', isBold: true),
        _buildNutrientRow('Saturated Fat', item.nfSaturatedFat, 'g'),
        _buildNutrientRow('Cholesterol', item.nfCholesterol?.toDouble(), 'mg',
            isBold: true),
        _buildNutrientRow('Sodium', item.nfSodium, 'mg', isBold: true),
        _buildNutrientRow('Potassium', item.nfPotassium, 'mg', isBold: true),
        _buildNutrientRow('Total Carbohydrate', item.nfTotalCarbohydrate, 'mg',
            isBold: true),
        _buildNutrientRow('Dietary Fiber', item.nfDietaryFiber, 'g'),
        _buildNutrientRow('Sugars', item.nfSugars, 'g'),
        _buildNutrientRow('Protein', item.nfProtein, 'g', isBold: true),

        if (item.nfIngredientStatement != null) ...[
          const Text(
            'INGREDIENTS(原料):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('${item.nfIngredientStatement}'),
        ],

        Divider(thickness: 10.sp),
        if (item.fullNutrients != null) ...[
          Text(
            'Full Nutritions',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          Divider(thickness: 1.sp),
          ...List.generate(
            item.fullNutrients!.length,
            (index) {
              var temp = getNixNutrientById(item.fullNutrients![index].attrId);

              return Container(
                color: index % 2 == 0 ? Colors.grey[200] : Colors.white,
                height: 48.sp,
                child: Row(
                  children: [
                    SizedBox(
                      width: 0.6.sw,
                      child: Text(
                        '${temp["name"]}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _calculateValue(item.fullNutrients![index].value),
                        textAlign: TextAlign.end,
                      ),
                    ),
                    SizedBox(width: 10.sp),
                    SizedBox(
                      width: 48.sp,
                      child: Text("${temp["unit"]}"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  /// 构建营养素行
  Widget _buildNutrientRow(String label, double? value, String unit,
      {bool? isBold}) {
    return value != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isBold == true
                  ? Text(
                      '$label: ${_calculateValue(value)} $unit',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : Row(
                      children: [
                        SizedBox(width: 20.sp),
                        Text('$label: ${_calculateValue(value)} $unit'),
                      ],
                    ),
              Divider(height: 10.sp),
            ],
          )
        : const SizedBox.shrink();
  }
}
