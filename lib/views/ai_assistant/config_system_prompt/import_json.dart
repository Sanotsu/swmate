import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import '../../../common/components/tool_widget.dart';
import '../../../common/llm_spec/cus_llm_model.dart';
import '../../../common/utils/db_tools/db_helper.dart';

class SystemPromptJsonImport extends StatefulWidget {
  const SystemPromptJsonImport({super.key});

  @override
  State<SystemPromptJsonImport> createState() => _SystemPromptJsonImportState();
}

class _SystemPromptJsonImportState extends State<SystemPromptJsonImport> {
  final DBHelper _dbHelper = DBHelper();

  // 是否在解析json中或导入数据库中
  bool isLoading = false;
  // 解析后的json数据列表
  List<CusSysRoleSpec> sysRoleSpecs = [];
  // 上传的json文件列表
  List<File> jsons = [];

  // 构建json文件加载成功后的锻炼数据表格要用到
  // 待上传的动作数量已经每个动作的选中状态
  int exerciseItemsNum = 0;
  List<bool> exerciseSelectedList = [false];

  // 用户可以选择多个json文件
  Future<void> _openJsonFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'JSON'],
      // allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        isLoading = true;
      });

      for (File file in result.files.map((file) => File(file.path!))) {
        if (file.path.toLowerCase().endsWith('.json')) {
          try {
            String jsonData = await file.readAsString();

            // 如果一个json文件只是一个动作，那就加上中括号；如果本身就是带了中括号的多个，就不再加
            List cusRoleMaps =
                jsonData.trim().startsWith("[") && jsonData.trim().endsWith("]")
                    ? json.decode(jsonData)
                    : json.decode("[$jsonData]");

            var temp =
                cusRoleMaps.map((e) => CusSysRoleSpec.fromJson(e)).toList();

            setState(() {
              sysRoleSpecs.addAll(temp);
              // 更新需要构建的表格的长度和每条数据的可选中状态
              exerciseItemsNum = sysRoleSpecs.length;
              exerciseSelectedList =
                  List<bool>.generate(exerciseItemsNum, (int index) => false);
            });
          } catch (e) {
            // 弹出报错提示框
            if (!mounted) return;

            commonExceptionDialog(
              context,
              "json导入失败",
              "json解析失败:${file.path},\n${e.toString}",
            );

            setState(() {
              isLoading = false;
            });

            rethrow;
            // 中止操作
            // return;
          }
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

    sysRoleSpecs = sysRoleSpecs.map((e) {
      e.cusSysRoleSpecId = const Uuid().v4();
      e.gmtCreate = DateTime.now();
      return e;
    }).toList();

    // 这里导入去重的工作要放在上面解析文件时，这里就全部保存了。
    try {
      await _dbHelper.insertCusSysRoleSpecList(sysRoleSpecs);
    } on Exception catch (e) {
      // 将错误信息展示给用户
      if (!mounted) return;
      commonExceptionDialog(
        context,
        "插入数据库报错",
        e.toString(),
      );

      setState(() {
        isLoading = false;
      });
      return;
    }

    // 保存完了，情况数据，并弹窗提示。
    setState(() {
      setState(() {
        jsons = [];
        sysRoleSpecs = [];
        // 更新需要构建的表格的长度和每条数据的可选中状态
        exerciseItemsNum = 0;
        exerciseSelectedList = [false];

        isLoading = false;
      });
    });

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("提示"),
          content: const Text("导入成功"),
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
        title: const Text(
          "系统角色JSON导入",
        ),
        actions: [
          IconButton(
            onPressed: sysRoleSpecs.isNotEmpty ? _saveToDb : null,
            icon: Icon(
              Icons.save,
              color: sysRoleSpecs.isNotEmpty
                  ? null
                  : Theme.of(context).disabledColor,
            ),
          ),
        ],
      ),
      body: isLoading
          ? buildLoader(isLoading)
          : Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                /// 最上方的功能按钮区域
                _buildButtonsArea(),

                /// json文件列表不为空才显示对应区域
                if (jsons.isNotEmpty) ..._buildJsonFileInfoArea(),

                /// 列表不为空且大于50条，简单的列表展示
                if (sysRoleSpecs.isNotEmpty && sysRoleSpecs.length > 50)
                  ..._buildListArea(),

                /// 列表不为空且不大于50条，简单的表格展示
                if (sysRoleSpecs.isNotEmpty && sysRoleSpecs.length <= 50)
                  ..._buildDataTable(),
              ],
            ),
    );
  }

  // 构建功能按钮区
  _buildButtonsArea() {
    return Card(
      elevation: 5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: TextButton(
              onPressed: _openJsonFiles,
              child: Text(
                "选择文件",
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
          ),
          Expanded(
            child: TextButton(
              onPressed: () {
                setState(() {
                  jsons = [];
                  sysRoleSpecs = [];
                  // 更新需要构建的表格的长度和每条数据的可选中状态
                  exerciseItemsNum = 0;
                  exerciseSelectedList = [false];
                });
              },
              child: Text(
                "清空数据",
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
          ),
          Expanded(
            child: TextButton(
              // 如果选中为空，则禁用点击
              onPressed: exerciseSelectedList
                      .where((e) => e)
                      .toList()
                      .isNotEmpty
                  ? () {
                      setState(() {
                        // 先找到被选中的索引
                        List<int> trueIndices = List.generate(
                                exerciseSelectedList.length, (index) => index)
                            .where((i) => exerciseSelectedList[i])
                            .toList();

                        // 从列表中移除
                        // 倒序遍历需要移除的索引列表，以避免索引变化导致的问题
                        for (int i = trueIndices.length - 1; i >= 0; i--) {
                          sysRoleSpecs.removeAt(trueIndices[i]);
                        }
                        // 更新需要构建的表格的长度和每条数据的可选中状态
                        exerciseItemsNum = sysRoleSpecs.length;
                        exerciseSelectedList = List<bool>.generate(
                          exerciseItemsNum,
                          (int index) => false,
                        );
                      });
                    }
                  : null,
              child: Text(
                "移除选中",
                style: TextStyle(fontSize: 15.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建json文件列表区
  _buildJsonFileInfoArea() {
    return [
      Text(
        "导入json文件",
        style: TextStyle(fontSize: 12.sp),
        textAlign: TextAlign.start,
      ),
      SizedBox(
        height: 100.sp,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: jsons.length,
          itemBuilder: (context, index) {
            return Text(
              jsons[index].path,
              style: TextStyle(fontSize: 12.sp),
              textAlign: TextAlign.start,
            );
          },
        ),
      ),
    ];
  }

  // 当上传的信息超过50条，就单纯的列表展示
  _buildListArea() {
    return [
      RichText(
        textAlign: TextAlign.left,
        text: TextSpan(
          children: [
            TextSpan(
              text: "共 ${sysRoleSpecs.length} 条数据，",
              style: TextStyle(fontSize: 15.sp, color: Colors.blue),
            ),
            TextSpan(
              text: "主要栏位展示：",
              style: TextStyle(fontSize: 15.sp, color: Colors.green),
            ),
          ],
        ),
      ),
      SizedBox(height: 10.sp),
      Expanded(
        child: ListView.builder(
          itemCount: sysRoleSpecs.length,
          itemBuilder: (context, index) {
            return Row(
              verticalDirection: VerticalDirection.up,
              children: [
                Expanded(
                  child: RichText(
                    textAlign: TextAlign.start,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${index + 1} - ',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.green,
                          ),
                        ),
                        TextSpan(
                          text: "${sysRoleSpecs[index].sysRoleType} - ",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.red,
                          ),
                        ),
                        TextSpan(
                          text: sysRoleSpecs[index].label,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey,
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

  // 当上传的信息不超过50条，可以表格管理
  _buildDataTable() {
    return [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.sp),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "上传条数 ${sysRoleSpecs.length}",
              style: TextStyle(fontSize: 15.sp),
              textAlign: TextAlign.start,
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
            columnSpacing: 5.sp, // 设置列间距
            columns: const <DataColumn>[
              DataColumn(label: Text("序号")),
              DataColumn(label: Text("名称")),
              DataColumn(label: Text("分类")),
            ],
            rows: List<DataRow>.generate(
              exerciseItemsNum,
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
                      width: 25.sp,
                      child: Text(
                        '${index + 1} ',
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      sysRoleSpecs[index].label,
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 120.sp,
                      child: Text(
                        '${sysRoleSpecs[index].sysRoleType}',
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ),
                  ),
                ],
                selected: exerciseSelectedList[index],
                onSelectChanged: (bool? value) {
                  setState(() {
                    exerciseSelectedList[index] = value!;
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
