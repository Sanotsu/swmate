import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../../common/llm_spec/constant_llm_enum.dart';

class ModelSelectorDialog extends StatefulWidget {
  final List<CusBriefLLMSpec> models;
  final CusBriefLLMSpec? selectedModel;

  const ModelSelectorDialog({
    super.key,
    required this.models,
    this.selectedModel,
  });

  @override
  State<ModelSelectorDialog> createState() => _ModelSelectorDialogState();
}

class _ModelSelectorDialogState extends State<ModelSelectorDialog> {
  late CusBriefLLMSpec? _selectedModel;
  LLModelType _selectedType = LLModelType.cc;

  @override
  void initState() {
    super.initState();

    initModels();
  }

  initModels() {
    _selectedModel = widget.selectedModel;
    // 默认被选中模型为空，如果有传入被选中模型，则选中该模型和模型类型
    if (widget.selectedModel != null) {
      _selectedModel = widget.models
          .where(
            (m) => m.cusLlmSpecId == widget.selectedModel!.cusLlmSpecId,
          )
          .firstOrNull;

      _selectedType = widget.selectedModel!.modelType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 0.8.sw,
        height: 0.7.sh,
        padding: EdgeInsets.all(8.sp),
        child: Column(
          children: [
            Text(
              '选择模型',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.sp),

            // 模型类型过滤器
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  LLModelType.cc,
                  LLModelType.reasoner,
                  LLModelType.vision,
                ].map((type) {
                  final count =
                      widget.models.where((m) => m.modelType == type).length;
                  return Padding(
                    padding: EdgeInsets.only(right: 8.sp),
                    child: ChoiceChip(
                      label: Text("${MT_NAME_MAP[type]}($count)"),
                      selected: type == _selectedType,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedType = type);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            SizedBox(height: 16.sp),

            // 模型列表
            Expanded(
              child: ListView.builder(
                itemCount: _filteredModels.length,
                itemBuilder: (context, index) {
                  final model = _filteredModels[index];
                  return RadioListTile<CusBriefLLMSpec>(
                    title: Text(model.name ?? model.model),
                    subtitle: Text(CP_NAME_MAP[model.platform] ?? '<未知>'),
                    value: model,
                    groupValue: _selectedModel,
                    onChanged: (value) {
                      setState(() => _selectedModel = value);
                    },
                  );
                },
              ),
            ),

            // 按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                SizedBox(width: 8.sp),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context, _selectedModel),
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<CusBriefLLMSpec> get _filteredModels {
    return widget.models
        .where((model) => model.modelType == _selectedType)
        .toList();
  }
}
