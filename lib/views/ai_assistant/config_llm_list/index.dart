import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../common/llm_spec/cus_llm_model.dart';
import '../../../common/utils/db_tools/db_ai_tool_helper.dart';
import '../../../apis/_default_model_list/index.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/llm_spec/cus_llm_spec.dart';
import '../_helper/tools.dart';
import 'api_key_config/index.dart';

class ModelListIndex extends StatefulWidget {
  const ModelListIndex({super.key});

  @override
  State<ModelListIndex> createState() => _ModelListIndexState();
}

class _ModelListIndexState extends State<ModelListIndex> {
  final DBAIToolHelper dbHelper = DBAIToolHelper();
  List<CusLLMSpec> cusLlmSpecs = [];
  List<ApiPlatform> platList = [];

  List<bool> selectedRows = [];

  String note = '''1. 默认会加载所有作者能找到且支持的免费模型。
2. 可以加载已支持的平台**付费模型**，但**需要添加了自己的私钥才能正常使用**(点击右侧钥匙图标配置)。
3. **平台私钥只会放在用户自己设备的缓存中**。除了调用各个平台的大模型API、和加载网络图片，没有联网操作。
4. 加载了模型，但没有配置自己的私钥也无法使用(因为作者也没所有平台都充钱，不便用作者的私钥)

```
部分API 调用限制:  
RPM 每分钟请求数  
RPD 每天请求次数   
TPM 每分钟输入输出tokens

无问芯穹 单个 API Key 限制:

类型 数量   刷新时间  适用 API 服务 
RPM  12    1 分钟   所有预置模型  
RPD  3000  24 小时  所有预置模型  
TPM  12000 1 分钟   所有预置模型  
```
''';

  @override
  void initState() {
    getCusLLMSpecs();
    super.initState();
  }

  getCusLLMSpecs({ApiPlatform? platform}) async {
    var tempList = await dbHelper.queryCusLLMSpecList(platform: platform);

    tempList.sort((a, b) {
      // 先比较 平台名称
      int compareA = a.platform.name.compareTo(b.platform.name);
      if (compareA != 0) {
        return compareA;
      }

      // 如果 平台名称 相同，再比较 模型名称
      return a.name.compareTo(b.name);
    });

    setState(() {
      // 2024-08-26 目前系统角色中，文档解读和翻译解读预设的6个有name，过滤不显示(因为这6个和代码逻辑相关，不能被删除)，
      // 其他是没有的，用户新增删除可以自行管理
      cusLlmSpecs = tempList;

      platList = cusLlmSpecs.map((spec) => spec.platform).toSet().toList();

      // 一开始所有行都是未选中的
      selectedRows = List.filled(cusLlmSpecs.length, false);
    });
  }

  // 点击行选中框时改变状态
  void toggleSelection(int index) {
    setState(() {
      selectedRows[index] = !selectedRows[index];
    });
  }

  // 点击删除时删除选中的模型
  void deleteSelectedRows() async {
    // 删除选中的模型
    for (int i = selectedRows.length - 1; i >= 0; i--) {
      if (selectedRows[i]) {
        await dbHelper.deleteCusLLMSpecById(cusLlmSpecs[i].cusLlmSpecId!);
      }
    }

    // 重新加载
    setState(() {
      getCusLLMSpecs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("模型列表"),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ApiKeyConfig(),
              ),
            ),
            icon: const Icon(Icons.key),
          ),
          _buildPopupMenuButton(),
          IconButton(
            onPressed: () {
              commonMDHintModalBottomSheet(
                context,
                "模型使用说明",
                note,
                msgFontSize: 15.sp,
              );
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: Container(
        // height: MediaQuery.of(context).size.height / 4 * 3,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15.sp),
            topRight: Radius.circular(15.sp),
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 120.sp,
              margin: EdgeInsets.fromLTRB(10, 0, 10.sp, 0.sp),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "目前支持 ${cusLlmSpecs.map((spec) => spec.platform).toSet().length} 个平台中的 ${cusLlmSpecs.length} 个大模型，具体列表如下",
                      ),
                    ],
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Wrap(
                          direction: Axis.horizontal,
                          spacing: 5.sp,
                          alignment: WrapAlignment.spaceAround,
                          children: List.generate(
                            platList.length,
                            (index) => buildSmallButtonTag(
                              "${CP_NAME_MAP[platList[index]]}",
                              bgColor: Colors.lightGreen[100],
                              labelTextSize: 12.sp,
                            ),
                          ).toList(),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: deleteSelectedRows,
                        child: const Text('删除选中的模型'),
                      )
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                // 模型表格，用Table和DataTable全看洗好，都留着
                // child: buildModelTable(),
                child: buildModelDataTable(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupMenuButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      // 调整弹出按钮的位置
      position: PopupMenuPosition.under,
      // 弹出按钮的偏移
      // offset: Offset(-25.sp, 0),
      onSelected: (String value) async {
        // 处理选中的菜单项
        if (value == 'onlyFree') {
          await testInitModelAndSysRole(FREE_all_MODELS);
        } else if (value == 'onlyPricing') {
          await testInitModelAndSysRole(PRICING_all_MODELS);
        } else if (value == 'all') {
          await testInitModelAndSysRole(ALL_MODELS);
        }

        await getCusLLMSpecs();
      },
      itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
        buildCusPopupMenuItem(
            context, "onlyFree", "仅加载免费模型", Icons.import_export),
        buildCusPopupMenuItem(
            context, "onlyPricing", "仅加载付费模型", Icons.import_export),
        buildCusPopupMenuItem(context, "all", "加载全部模型", Icons.import_export),
      ],
    );
  }

  // 构建模型列表表格
  buildModelTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
        4: FlexColumnWidth(6),
      },
      // border: TableBorder.all(),
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Colors.grey[300],
          ),
          children: const [
            TableCell(
              child: SizedBox(),
            ),
            TableCell(
              child: Center(
                child: Text(
                  '序号',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            TableCell(
              child: Center(
                child: Text(
                  '平台',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            TableCell(
              child: Center(
                child: Text(
                  '类型',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            TableCell(
              child: Center(
                child: Text(
                  '模型',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        ...List<TableRow>.generate(
          cusLlmSpecs.length,
          (int index) => TableRow(
            decoration: BoxDecoration(
              color: (index.isEven) ? Colors.grey.withOpacity(0.3) : null,
            ),
            children: <TableCell>[
              TableCell(
                child: Checkbox(
                  value: selectedRows[index],
                  onChanged: (value) => toggleSelection(index),
                ),
              ),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Center(child: Text('${index + 1}')),
              ),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Center(
                  child: Text(CP_NAME_MAP[cusLlmSpecs[index].platform] ?? ""),
                ),
              ),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Center(child: Text(cusLlmSpecs[index].modelType.name)),
              ),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Text(cusLlmSpecs[index].name),
              ),
            ],
          ),
        ),
      ],
    );
  }

  ///
  /// 这个table比较方便横向纵向滚动，上面那个横向稍微难处理点
  ///
  buildModelDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        dataRowMinHeight: 15.sp, // 设置行高范围
        dataRowMaxHeight: 30.sp,
        headingRowHeight: 50.sp, // 设置表头行高
        horizontalMargin: 10, // 设置水平边距
        headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
        columnSpacing: 5.sp, // 设置列间距
        columns: const [
          DataColumn(label: Text("")),
          DataColumn(label: Text("序号")),
          DataColumn(label: Text("平台")),
          DataColumn(label: Text("模型")),
          DataColumn(label: Text("输入(元)\n/M token")),
          DataColumn(label: Text("输出(元)\n/M token")),
        ],
        rows: List<DataRow>.generate(
          cusLlmSpecs.length,
          (int index) => DataRow(
            color: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
              // 所有行将具有相同的选定颜色
              if (states.contains(WidgetState.selected)) {
                return Theme.of(context).colorScheme.primary.withOpacity(0.08);
              }
              // 但修改偶数行为灰色
              if (index.isEven) {
                return Colors.grey.withOpacity(0.3);
              }
              // 对其他状态和奇数行使用默认值
              return null;
            }),
            cells: <DataCell>[
              DataCell(
                SizedBox(
                  width: 30.sp,
                  child: Checkbox(
                    value: selectedRows[index],
                    onChanged: (value) => toggleSelection(index),
                  ),
                ),
              ),
              DataCell(
                SizedBox(width: 30.sp, child: Text('${index + 1}')),
              ),
              DataCell(
                SizedBox(
                  width: 65.sp,
                  child: Text(
                    CP_NAME_MAP[cusLlmSpecs[index].platform] ?? "",
                  ),
                ),
              ),
              DataCell(
                Text(
                  cusLlmSpecs[index].name,
                  style: TextStyle(fontSize: 13.sp),
                ),
              ),
              DataCell(
                Text(
                  cusLlmSpecs[index].isFree
                      ? "0"
                      : "${cusLlmSpecs[index].inputPrice ?? ''}",
                  style: TextStyle(fontSize: 13.sp),
                ),
              ),
              DataCell(
                Text(
                  cusLlmSpecs[index].isFree
                      ? "0"
                      : "${cusLlmSpecs[index].outputPrice ?? '${cusLlmSpecs[index].costPer}/张(个)'}",
                  style: TextStyle(fontSize: 13.sp),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
