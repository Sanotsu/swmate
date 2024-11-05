import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../apis/food/usda_food_data_central/usda_food_data_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../models/food/usda_food_data/usda_food_item.dart';

// 食品营养素详情页面
class USDAFoodItemNutrientPage extends StatefulWidget {
  // 用编号查询详情
  final int fdcId;

  const USDAFoodItemNutrientPage({super.key, required this.fdcId});

  @override
  State<USDAFoodItemNutrientPage> createState() =>
      _USDAFoodItemNutrientPageState();
}

class _USDAFoodItemNutrientPageState extends State<USDAFoodItemNutrientPage> {
  String note = '''
数值为0不代表不存在该元素，而是小于检测设备能检测出来的最小值。

【SR Legacy】 released in April 2018, is the final release of this data type and will not be updated. For more recent data, users should search other data types in FoodData Central.

【Survey (FNDDS)】 Details about FNDDS 2019-2020 development, content, and Excel files can be found at:
https://www.ars.usda.gov/northeast-area/beltsville-md-bhnrc/beltsville-human-nutrition-research-center/food-surveys-research-group/docs/fndds-download-databases/

【Branded】 Information provided by food brand owners is label data. Brand owners are responsible for descriptions, nutrient data and ingredient information. USDA calculates values per 100g or 100ml from values per serving. Values calculated from %DV use current daily values for an adult 2,000 calorie diet (21 CFR 101.9(c)).
''';

  // 通过编号查询到食品信息
  late Future<USDAFoodItem> _foodItemFuture;

  @override
  void initState() {
    super.initState();
    _foodItemFuture = getUSDAFoodById(widget.fdcId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text("食品成分表(每100克)"),
        title: RichText(
          textAlign: TextAlign.left,
          text: TextSpan(
            children: [
              TextSpan(
                text: "食品成分表",
                style: TextStyle(fontSize: 22.sp, color: Colors.black),
              ),
              TextSpan(
                text: "(每100克)",
                style: TextStyle(fontSize: 15.sp, color: Colors.blue),
              ),
            ],
          ),
        ),
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
      body: FutureBuilder<USDAFoodItem>(
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

          final item = snapshot.data!;
          final dataType = item.dataType ?? "Foundation";

          return Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 5.sp),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15.sp),
                topRight: Radius.circular(15.sp),
              ),
            ),
            child: Column(
              children: [
                // SingleChildScrollView(
                //   scrollDirection: Axis.horizontal,
                //   child: Row(
                //     children: [
                //       Wrap(
                //         spacing: 10.sp,
                //         children: buildFoodDetails(dataType, item),
                //       ),
                //     ],
                //   ),
                // ),
                SizedBox(
                  height: 50.sp,
                  child: Center(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.description,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.sp,
                              color: Theme.of(context).primaryColor,
                            ),
                            maxLines: 2,
                          ),
                        ),
                        if (dataType == "Branded")
                          IconButton(
                            onPressed: () {
                              commonMDHintModalBottomSheet(
                                context,
                                "Ingredients",
                                item.ingredients ?? '',
                                msgFontSize: 15.sp,
                              );
                            },
                            icon: const Icon(Icons.biotech),
                          ),
                      ],
                    ),
                  ),
                ),
                Divider(height: 5.sp),
                SizedBox(
                  height: 100.sp,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: buildFoodDetails(dataType, item),
                    ),
                  ),
                ),
                Divider(height: 5.sp),
                if (item.foodNutrients != null)
                  Expanded(
                    child: SingleChildScrollView(
                      child: buildFoodDataTable(dataType, item.foodNutrients!),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> buildFoodDetails(String dataType, USDAFoodItem item) {
    final details = <Widget>[];

    if (dataType == "Foundation" || dataType == "SR Legacy") {
      details.addAll([
        buildDetailItem("Data Type:", "${item.dataType}"),
        buildDetailItem("Food Category:", item.foodCategory['description']),
        buildDetailItem("FDC ID:", "${item.fdcId}"),
        buildDetailItem("NDB Number:", "${item.ndbNumber}"),
        buildDetailItem("FDC Published:", "${item.publicationDate}"),
      ]);
    }

    if (dataType == "Survey (FNDDS)") {
      details.addAll([
        buildDetailItem("Data Type:", "${item.dataType}"),
        buildDetailItem("FDC ID:", "${item.fdcId}"),
        buildDetailItem("Food Code:", "${item.foodCode}"),
        buildDetailItem("Start Date:", "${item.startDate}"),
        buildDetailItem("End Date:", "${item.endDate}"),
        buildDetailItem("Food Category:",
            "${item.wweiaFoodCategory?.wweiaFoodCategoryDescription}"),
        buildDetailItem("FDC Published:", "${item.publicationDate}"),
      ]);
    }

    if (dataType == "Branded") {
      details.addAll([
        buildDetailItem("Data Type:", "${item.dataType}"),
        buildDetailItem("Food Category:", item.brandedFoodCategory ?? ''),
        buildDetailItem("Brand Owner:", "${item.brandOwner}"),
        buildDetailItem("Brand:", "${item.brandName}"),
        buildDetailItem("FDC ID:", "${item.fdcId}"),
        buildDetailItem("GTIN/UPC:", "${item.gtinUpc}"),
        buildDetailItem("FDC Published:", "${item.publicationDate}"),
        buildDetailItem("Available Date:", "${item.availableDate}"),
        buildDetailItem("Modified Date:", "${item.modifiedDate}"),
        buildDetailItem("Market Country:", "${item.marketCountry}"),
        buildDetailItem(
            "Trade Channel:",
            item.tradeChannels != null
                ? item.tradeChannels!.join(',')
                : 'NO_TRADE_CHANNEL'),
      ]);
    }

    return details;
  }

  buildDetailItem(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 120.sp,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget buildFoodDataTable(
      String dataType, List<USDAFoodNutrient> foodNutrients) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        dataRowMinHeight: 15.sp,
        dataRowMaxHeight: 30.sp,
        headingRowHeight: 50.sp,
        horizontalMargin: 10,
        headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
        columnSpacing: 10.sp,
        columns: buildTableHead(dataType),
        rows: List<DataRow>.generate(
          foodNutrients.length,
          (int index) {
            var item = foodNutrients[index];
            bool isNutrientLabel = item.nutrient?.isNutrientLabel ?? false;
            int indentLevel = item.nutrient?.indentLevel ?? 0;

            return DataRow(
              color: WidgetStateProperty.resolveWith<Color?>(
                  (Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.08);
                }
                if (index.isEven) {
                  return Colors.grey[500]!.withOpacity(0.3);
                }
                return null;
              }),
              cells:
                  buildTableCells(dataType, isNutrientLabel, indentLevel, item),
            );
          },
        ),
      ),
    );
  }

  List<DataColumn> buildTableHead(String dataType) {
    if (dataType == "Foundation") {
      return const [
        DataColumn(label: Text("名称")),
        DataColumn(label: Text("数值"), numeric: true),
        DataColumn(label: Text("单位")),
        DataColumn(label: Text("Deriv. By")),
        DataColumn(label: Text("n")),
        DataColumn(label: Text("最小值")),
        DataColumn(label: Text("最大值")),
        DataColumn(label: Text("平均值")),
        DataColumn(label: Text("收录年份")),
      ];
    } else {
      return const [
        DataColumn(label: Text("名称")),
        DataColumn(label: Text("数值"), numeric: true),
        DataColumn(label: Text("单位")),
      ];
    }
  }

  List<DataCell> buildTableCells(
    String dataType,
    bool isNutrientLabel,
    int indentLevel,
    USDAFoodNutrient item,
  ) {
    if (dataType == "Foundation") {
      double averageAmount = item.amount ?? 0;
      var amountLable = averageAmount.toStringAsFixed(3);

      if (averageAmount == 0 &&
          item.nutrientAnalysisDetails != null &&
          item.nutrientAnalysisDetails!.isNotEmpty) {
        averageAmount = item.nutrientAnalysisDetails!.first.loq ?? 0;
        amountLable = "<${averageAmount.toStringAsFixed(3)}";
      }

      return <DataCell>[
        DataCell(
          buildFormatCellText(
            "${item.nutrient?.name}",
            isNutrientLabel,
            indentLevel,
          ),
        ),
        DataCell(
          Text(
            isNutrientLabel ? "" : amountLable,
            style: TextStyle(fontSize: 13.sp),
          ),
        ),
        DataCell(
          Text(
            isNutrientLabel ? "" : "${item.nutrient?.unitName}",
            style: TextStyle(fontSize: 13.sp),
          ),
        ),
        DataCell(
          Text(
            isNutrientLabel
                ? ""
                : "${item.foodNutrientDerivation?.description}",
            style: TextStyle(fontSize: 13.sp),
          ),
        ),
        DataCell(
          Text(
            isNutrientLabel ? "" : "${item.dataPoints ?? ''}",
            style: TextStyle(fontSize: 13.sp),
          ),
        ),
        DataCell(
          Text(
            isNutrientLabel ? "" : "${item.min ?? ''}",
            style: TextStyle(fontSize: 13.sp),
          ),
        ),
        DataCell(
          Text(
            isNutrientLabel ? "" : "${item.max ?? ''}",
            style: TextStyle(fontSize: 13.sp),
          ),
        ),
        DataCell(
          Text(
            isNutrientLabel ? "" : "${item.median ?? ''}",
            style: TextStyle(fontSize: 13.sp),
          ),
        ),
        DataCell(
          Text(
            isNutrientLabel ? "" : "${item.minYearAcquired ?? ''}",
            style: TextStyle(fontSize: 13.sp),
          ),
        ),
      ];
    } else {
      return [
        DataCell(
          buildFormatCellText(
            "${item.nutrient?.name}",
            isNutrientLabel,
            indentLevel,
          ),
        ),
        DataCell(
          Text(
            isNutrientLabel ? "" : "${item.amount ?? ''}",
            style: TextStyle(fontSize: 13.sp),
          ),
        ),
        DataCell(
          Text(
            isNutrientLabel ? "" : "${item.nutrient?.unitName}",
            style: TextStyle(fontSize: 13.sp),
          ),
        ),
      ];
    }
  }

  Widget buildFormatCellText(
    String? label,
    bool isNutrientLabel,
    int indentLevel,
  ) {
    return Row(
      children: [
        SizedBox(
          width: (isNutrientLabel ? indentLevel : indentLevel + 1) * 20.sp,
        ),
        Expanded(
          child: Text(
            label ?? '',
            style: TextStyle(
              fontSize: isNutrientLabel ? 15.sp : 13.sp,
              fontWeight: isNutrientLabel ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
