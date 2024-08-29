// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/llm_spec/cus_llm_model.dart';
import '../../../common/utils/db_tools/db_helper.dart';
import '../../common/llm_spec/cus_llm_spec.dart';

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
    getSystemPromptSpecs();
    super.initState();
  }

  getSystemPromptSpecs() async {
    var sysroleLl = await dbHelper.queryCusLLMSpecList();
    sysroleLl.sort((a, b) => a.platform.name.compareTo(b.platform.name));
    setState(() {
      // 2024-08-26 目前系统角色中，文档解读和翻译解读预设的6个有name，过滤不显示(因为这6个和代码逻辑相关，不能被删除)，
      // 其他是没有的，用户新增删除可以自行管理
      cusLlmSpecs = sysroleLl;

      platList = cusLlmSpecs.map((spec) => spec.platform).toSet().toList();
    });
    print(sysroleLl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("支持的模型列表"),
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
                child: DataTable(
                  dataRowMinHeight: 15.sp, // 设置行高范围
                  dataRowMaxHeight: 30.sp,
                  headingRowHeight: 25, // 设置表头行高
                  horizontalMargin: 10, // 设置水平边距
                  columnSpacing: 5.sp, // 设置列间距
                  columns: const <DataColumn>[
                    DataColumn(label: Text("序号")),
                    DataColumn(label: Text("平台")),
                    DataColumn(label: Text("模型")),
                  ],
                  rows: List<DataRow>.generate(
                    cusLlmSpecs.length,
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
                          SizedBox(width: 20.sp, child: Text('${index + 1} ')),
                        ),
                        DataCell(
                          SizedBox(
                            width: 70.sp,
                            child: Text(
                                CP_NAME_MAP[cusLlmSpecs[index].platform] ?? ""),
                          ),
                        ),
                        DataCell(
                          Text(
                            cusLlmSpecs[index].model,
                            style: TextStyle(fontSize: 13.sp),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ListView.builder(
              //   itemCount: cusLlmSpecs.length,
              //   itemBuilder: (BuildContext context, int index) {
              //     var a = cusLlmSpecs[index];

              //     return Card(
              //       child: Row(
              //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //         children: [
              //           Expanded(
              //             flex: 1,
              //             child: Text(
              //               "${index + 1} ${a.platform.name}",
              //             ),
              //           ),
              //           Expanded(
              //             flex: 2,
              //             child: Text(
              //               " ${a.name}",
              //             ),
              //           ),
              //         ],
              //       ),
              //       // child: ListTile(
              //       //   title: Text("${index + 1} ${a.platform.name} "),
              //       //   subtitle: Text(" ${a.name}"),
              //       //   dense: true,
              //       // ),
              //     );
              //   },
              // ),
            ),
          ],
        ),
      ),
    );
  }
}
