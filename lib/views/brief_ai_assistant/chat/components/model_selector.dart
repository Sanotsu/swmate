import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../../common/llm_spec/constant_llm_enum.dart';

class ModelSelector extends StatefulWidget {
  final List<CusBriefLLMSpec> models;
  final CusBriefLLMSpec? selectedModel;
  final ValueChanged<CusBriefLLMSpec?> onModelChanged;

  const ModelSelector({
    super.key,
    required this.models,
    this.selectedModel,
    required this.onModelChanged,
  });

  @override
  State<ModelSelector> createState() => _ModelSelectorState();
}

class _ModelSelectorState extends State<ModelSelector> {
  // 添加搜索关键字状态
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    // 监听搜索输入
    _searchController.addListener(() {
      setState(() {
        _searchKeyword = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 过滤模型列表
  List<CusBriefLLMSpec> get _filteredModels {
    if (_searchKeyword.isEmpty) return widget.models;

    return widget.models.where((model) {
      return (model.name?.toLowerCase().contains(_searchKeyword) ?? false) ||
          (CP_NAME_MAP[model.platform]!
              .toLowerCase()
              .contains(_searchKeyword)) ||
          (model.modelType.name.toLowerCase().contains(_searchKeyword));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.sp),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '选择模型',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.sp),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索模型...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.sp),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 8.sp),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredModels.length,
              itemBuilder: (context, index) {
                final model = _filteredModels[index];
                return ListTile(
                  title: Text('${CP_NAME_MAP[model.platform]}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(model.name ?? model.model),
                    ],
                  ),
                  selected: model == widget.selectedModel,
                  onTap: () => widget.onModelChanged(model),
                  trailing: model == widget.selectedModel
                      ? const Icon(Icons.check)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
