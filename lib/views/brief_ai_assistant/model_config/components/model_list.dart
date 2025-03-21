import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../../common/llm_spec/constant_llm_enum.dart';
import '../../../../common/utils/db_tools/db_brief_ai_tool_helper.dart';
import '../../../../common/utils/tools.dart';
import '../../../../services/model_manager_service.dart';

class ModelList extends StatefulWidget {
  const ModelList({super.key});

  @override
  State<ModelList> createState() => _ModelListState();
}

class _ModelListState extends State<ModelList> {
  final DBBriefAIToolHelper _dbHelper = DBBriefAIToolHelper();
  List<CusBriefLLMSpec> _models = [];
  bool _isLoading = true;
  bool _isImporting = false;
  int _sortColumnIndex = 0; // 当前排序的列索引
  bool _sortAscending = true; // 是否升序

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  // 加载模型列表
  Future<void> _loadModels() async {
    setState(() => _isLoading = true);
    try {
      final models = await _dbHelper.queryBriefCusLLMSpecList();
      setState(() => _models = models);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 删除模型
  Future<void> _deleteModel(BuildContext context, CusBriefLLMSpec model) async {
    if (model.isBuiltin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('内置模型不能删除')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除模型 ${model.name} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ModelManagerService.deleteUserModel(model.cusLlmSpecId);
      if (mounted) {
        _loadModels();
      }
    }
  }

  // 清除所有自行导入的模型
  Future<void> _clearAllModels(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除所有自行导入的模型吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ModelManagerService.clearUserModels();
      if (mounted) {
        _loadModels();
      }
    }
  }

  // 从JSON文件导入模型
  Future<void> _importFromJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null) return;

    setState(() => _isImporting = true);
    try {
      final file = File(result.files.single.path!);
      final jsonStr = await file.readAsString();
      final jsonList = json.decode(jsonStr) as List;

      // 验证模型配置
      for (final item in jsonList) {
        if (!ModelManagerService.validateModelConfig(item)) {
          throw '模型配置格式错误';
        }
      }

      // 默认导入的json文件中是没有模型规格编号的，而该类为必要属性，所以需要先生成一个
      for (final item in jsonList) {
        item['cusLlmSpecId'] = const Uuid().v4();
      }

      // 转换为模型列表
      var models =
          jsonList.map((json) => CusBriefLLMSpec.fromJson(json)).toList();

      // 设置ID和时间
      models = models.map((e) {
        e.name = !(e.isFree ?? false)
            ? '【收费】${e.name ?? capitalizeWords(e.model)}'
            : (e.name ?? capitalizeWords(e.model));
        e.gmtCreate = DateTime.now();
        e.isBuiltin = false; // 用户导入的模型
        return e;
      }).toList();

      // 查询是否存在同名模型
      List<CusBriefLLMSpec> duplicateModels = [];
      final existModels = await _dbHelper.queryBriefCusLLMSpecList();
      for (final model in models) {
        if (existModels.any(
          (e) => e.platform == model.platform && e.model == model.model,
        )) {
          duplicateModels.add(model);
        } else {
          await _dbHelper.insertBriefCusLLMSpecList([model]);
        }
      }

      // await _dbHelper.insertBriefCusLLMSpecList(models);

      if (!mounted) return;
      commonHintDialog(
        context,
        '导入成功',
        """成功导入 ${models.length} 个模型，
          \n其中 ${duplicateModels.length} 个模型名称已存在，
          \n实际导入 ${models.length - duplicateModels.length} 个模型。""",
      );

      _loadModels();
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, "导入失败", e.toString());
      _loadModels();
    } finally {
      setState(() => _isImporting = false);
    }
  }

  /// 排序方法
  /// [getField] 获取排序的值
  /// [columnIndex] 列索引
  /// [ascending] 是否升序
  void _sort<T>(
    Comparable<T> Function(CusBriefLLMSpec d) getField,
    int columnIndex,
    bool ascending,
  ) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;

      _models.sort((a, b) {
        final aValue = getField(a);
        final bValue = getField(b);
        return ascending
            ? Comparable.compare(aValue, bValue)
            : Comparable.compare(bValue, aValue);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async => _loadModels(),
      child: ListView(
        children: [
          Row(
            children: [
              Padding(
                padding: EdgeInsets.all(16.sp),
                child: Text(
                  '已导入 ${_models.length} 个模型',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _clearAllModels(context),
              ),
              if (_isImporting)
                Padding(
                  padding: EdgeInsets.only(right: 16.sp),
                  child: SizedBox(
                    width: 16.sp,
                    height: 16.sp,
                    child: CircularProgressIndicator(strokeWidth: 2.sp),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.upload_file_outlined),
                  onPressed: () => _importFromJson(),
                ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              dataRowMinHeight: 15.sp,
              dataRowMaxHeight: 50.sp,
              headingRowHeight: 50.sp,
              horizontalMargin: 10.sp,
              headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
              columnSpacing: 10.sp,
              columns: [
                DataColumn(
                  label: const Text('平台'),
                  onSort: (columnIndex, ascending) {
                    _sort<String>(
                      (d) => CP_NAME_MAP[d.platform] ?? '',
                      columnIndex,
                      ascending,
                    );
                  },
                ),
                DataColumn(
                  label: const Text('模型'),
                  onSort: (columnIndex, ascending) {
                    _sort<String>(
                      (d) => d.name ?? d.model,
                      columnIndex,
                      ascending,
                    );
                  },
                ),
                DataColumn(
                  label: const Text('类型'),
                  onSort: (columnIndex, ascending) {
                    _sort<String>(
                      (d) => d.modelType.name,
                      columnIndex,
                      ascending,
                    );
                  },
                ),
                // DataColumn(
                //   label: const Text('输入+输出+单个'),
                //   onSort: (columnIndex, ascending) {
                //     _sort<num>(
                //       (d) =>
                //           (d.inputPrice ?? 0) +
                //           (d.outputPrice ?? 0) +
                //           (d.costPer ?? 0),
                //       columnIndex,
                //       ascending,
                //     );
                //   },
                // ),
                const DataColumn(
                  label: Text('操作'),
                  headingRowAlignment: MainAxisAlignment.center,
                ),
              ],
              rows: List<DataRow>.generate(
                _models.length,
                (int index) => DataRow(
                  color: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) {
                    // 所有行将具有相同的选定颜色
                    if (states.contains(WidgetState.selected)) {
                      return Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.08);
                    }
                    // 但修改偶数行为灰色
                    if (index.isEven) {
                      return Colors.grey.withValues(alpha: 0.3);
                    }
                    // 对其他状态和奇数行使用默认值
                    return null;
                  }),
                  cells: [
                    DataCell(Text(CP_NAME_MAP[_models[index].platform] ?? '')),
                    DataCell(SizedBox(
                      width: 0.45.sw,
                      child: Text(_models[index].model),
                    )),
                    DataCell(Text(_models[index].modelType.name)),
                    // DataCell(
                    //   Text(
                    //     '${_models[index].inputPrice ?? 0} + ${_models[index].outputPrice ?? 0} + ${_models[index].costPer ?? 0}',
                    //   ),
                    // ),
                    DataCell(
                      _models[index].isBuiltin
                          ? const SizedBox.shrink()
                          : IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  _deleteModel(context, _models[index]),
                            ),
                    ),
                  ],
                  //  长按显示该模型更多信息
                  onLongPress: () => showModelInfo(context, _models[index]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showModelInfo(BuildContext context, CusBriefLLMSpec model) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 1.sh,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.sp),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(model.name ?? model.model),
                    TextButton(
                      child: const Text('关闭'),
                      onPressed: () {
                        Navigator.pop(context);
                        unfocusHandle();
                      },
                    ),
                  ],
                ),
              ),
              Divider(height: 2.sp, thickness: 2.sp),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(10.sp),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('部署平台: ${CP_NAME_MAP[model.platform] ?? ''}'),
                        Text('模型代号: ${model.model}'),
                        Text('模型名称: ${model.name}'),
                        Text('模型类型: ${MT_NAME_MAP[model.modelType]}'),
                        Text('是否免费: ${(model.isFree ?? false) ? '是' : '否'}'),
                        Text('是否内置: ${model.isBuiltin ? '是' : '否'}'),
                        Text('输入价格: ${model.inputPrice ?? '0'}'),
                        Text('输出价格: ${model.outputPrice ?? '0'}'),
                        Text('单个花费: ${model.costPer ?? '0'}'),
                        Text('上下文长度: ${model.contextLength ?? 0}'),
                        Text(
                          '发布日期: ${model.gmtRelease?.toString().substring(0, 10) ?? ''}',
                        ),
                        Text(
                          '创建日期: ${model.gmtCreate?.toString().substring(0, 10) ?? ''}',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
