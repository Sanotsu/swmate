import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:swmate/common/components/tool_widget.dart';

import '../../../../common/llm_spec/cus_llm_model.dart';
import '../../../../common/utils/db_tools/db_helper.dart';
import '../../../apis/_self_model_list/index.dart';
import '../../../common/llm_spec/cus_llm_spec.dart';
import '../_helper/tools.dart';
import 'api_key_config/index.dart';

class ModelListIndex extends StatefulWidget {
  const ModelListIndex({super.key});

  @override
  State<ModelListIndex> createState() => _ModelListIndexState();
}

class _ModelListIndexState extends State<ModelListIndex> {
  final DBHelper dbHelper = DBHelper();
  List<CusLLMSpec> cusLlmSpecs = [];
  List<ApiPlatform> platList = [];

  @override
  void initState() {
    getCusLLMSpecs();
    super.initState();
  }

  getCusLLMSpecs() async {
    var tempList = await dbHelper.queryCusLLMSpecList();

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("模型列表"),
        actions: [
          TextButton(
            onPressed: () => commonMarkdwonHintDialog(
              context,
              "模型使用说明",
              '''1. 默认会加载所有作者能找到且支持的免费模型。
2. 可以加载已支持的平台**付费模型**，但**需要添加了自己的私钥才能正常使用**(点击右侧钥匙图标配置)。
3. **平台私钥只会放在用户自己设备的缓存中**。除了调用各个平台的大模型API、和加载网络图片，没有联网操作。
4. 加载了模型，但没有配置自己的私钥也无法使用(因为作者也没所有平台都充钱，用不了作者的私钥)
''',
            ),
            child: const Text("说明"),
          ),
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
              height: 70.sp,
              margin: EdgeInsets.fromLTRB(20, 0, 10.sp, 0.sp),
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
                  Divider(height: 10.sp, thickness: 1.sp),
                  Wrap(
                    children: List.generate(
                      platList.length,
                      (index) => Text("${CP_NAME_MAP[platList[index]]}  "),
                    ),
                  ),
                  Divider(height: 10.sp, thickness: 1.sp),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                // 模型表格，用Table和DataTable全看洗好，都留着
                child: buildModelTable(),
                // child: buildModelDataTable(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupMenuButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu),
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
        PopupMenuItem(
          value: 'onlyFree',
          child: Text(
            '仅加载免费模型',
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
        ),
        PopupMenuItem(
          value: 'onlyPricing',
          child: Text(
            '仅加载付费模型',
            style: TextStyle(color: Theme.of(context).primaryColor),
            textAlign: TextAlign.end,
          ),
        ),
        PopupMenuItem(
          value: 'all',
          child: Text(
            '加载全部模型',
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
        ),
      ],
    );
  }

  // 构建模型列表表格
  buildModelTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(7),
      },
      // border: TableBorder.all(),
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Colors.grey[300],
          ),
          children: const [
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
                child: Padding(
                  padding: EdgeInsets.all(5.sp),
                  child: Center(child: Text('${index + 1}')),
                ),
              ),
              TableCell(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 5.sp),
                  child: Center(
                    child: Text(CP_NAME_MAP[cusLlmSpecs[index].platform] ?? ""),
                  ),
                ),
              ),
              TableCell(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 5.sp),
                  child: Center(child: Text(cusLlmSpecs[index].modelType.name)),
                ),
              ),
              TableCell(
                child: Padding(
                  padding: EdgeInsets.all(5.sp),
                  child: Text(cusLlmSpecs[index].name),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  buildModelDataTable() {
    return DataTable(
      dataRowMinHeight: 15.sp, // 设置行高范围
      dataRowMaxHeight: 30.sp,
      headingRowHeight: 25, // 设置表头行高
      horizontalMargin: 10, // 设置水平边距
      columnSpacing: 5.sp, // 设置列间距
      columns: const [
        DataColumn(label: Text("序号")),
        DataColumn(label: Text("平台")),
        DataColumn(label: Text("模型")),
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
              SizedBox(width: 40.sp, child: Text('${index + 1} ')),
            ),
            DataCell(
              SizedBox(
                width: 80.sp,
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
          ],
        ),
      ),
    );
  }
}
