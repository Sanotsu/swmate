import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../../common/llm_spec/cus_llm_spec.dart';
import '../../../../services/model_manager_service.dart';

class ModelList extends StatelessWidget {
  final List<CusBriefLLMSpec> models;
  final bool isLoading;
  final VoidCallback onRefresh;

  const ModelList({
    super.key,
    required this.models,
    required this.isLoading,
    required this.onRefresh,
  });

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
      await ModelManagerService.deleteUserModel(model.cusLlmSpecId!);
      onRefresh();
    }
  }

  Future<void> _clearAllKeys(BuildContext context) async {
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
      onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        children: [
          Row(
            children: [
              Padding(
                padding: EdgeInsets.all(16.sp),
                child: Text(
                  '已导入 ${models.length} 个模型',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _clearAllKeys(context),
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              dataRowMinHeight: 15.sp, // 设置行高范围
              dataRowMaxHeight: 50.sp,
              headingRowHeight: 50.sp, // 设置表头行高
              horizontalMargin: 10, // 设置水平边距
              headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
              columnSpacing: 10.sp, // 设置列间距
              columns: const [
                DataColumn(label: Text('平台')),
                DataColumn(label: Text('模型')),
                DataColumn(label: Text('类型')),
                DataColumn(label: Text('价格')),
                DataColumn(
                  label: Text('操作'),
                  headingRowAlignment: MainAxisAlignment.center,
                ),
              ],
              rows: List<DataRow>.generate(
                models.length,
                (int index) => DataRow(
                  color: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) {
                    // 所有行将具有相同的选定颜色
                    if (states.contains(WidgetState.selected)) {
                      return Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.08);
                    }
                    // 但修改偶数行为灰色
                    if (index.isEven) {
                      return Colors.grey.withOpacity(0.3);
                    }
                    // 对其他状态和奇数行使用默认值
                    return null;
                  }),
                  cells: [
                    DataCell(Text(CP_NAME_MAP[models[index].platform] ?? '')),
                    DataCell(Text(models[index].name)),
                    DataCell(Text(models[index].modelType.name)),
                    DataCell(Text(models[index].isFree ? '免费' : '付费')),
                    DataCell(
                      models[index].isBuiltin
                          ? const SizedBox.shrink()
                          : IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  _deleteModel(context, models[index]),
                            ),
                    ),
                  ],
                  //  长按显示该模型更多信息
                  onLongPress: () => showModelInfo(context, models[index]),
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
                    Text(model.name),
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
                        Text('是否免费: ${model.isFree ? '是' : '否'}'),
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
