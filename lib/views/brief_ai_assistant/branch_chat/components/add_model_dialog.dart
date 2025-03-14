import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import '../../../../common/llm_spec/constant_llm_enum.dart';
import '../../../../common/llm_spec/cus_brief_llm_model.dart';

class AddModelDialog extends StatefulWidget {
  const AddModelDialog({super.key});

  @override
  State<AddModelDialog> createState() => _AddModelDialogState();
}

class _AddModelDialogState extends State<AddModelDialog> {
  ApiPlatform? _selectedPlatform;
  LLModelType? _selectedModelType;
  final _modelNameController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _modelNameController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('添加模型', style: TextStyle(fontSize: 18.sp)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 平台选择
              DropdownButtonFormField<ApiPlatform>(
                value: _selectedPlatform,
                decoration: const InputDecoration(labelText: '选择平台'),
                items: ApiPlatform.values.map((platform) {
                  return DropdownMenuItem(
                    value: platform,
                    child: Text(CP_NAME_MAP[platform] ?? platform.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedPlatform = value);
                },
                validator: (value) {
                  if (value == null) return '请选择平台';
                  return null;
                },
              ),
              SizedBox(height: 16.sp),

              // 模型类型选择
              DropdownButtonFormField<LLModelType>(
                value: _selectedModelType,
                decoration: const InputDecoration(labelText: '选择模型类型'),
                items: LLModelType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(MT_NAME_MAP[type] ?? type.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedModelType = value);
                },
                validator: (value) {
                  if (value == null) return '请选择模型类型';
                  return null;
                },
              ),
              SizedBox(height: 16.sp),

              // 模型名称输入
              TextFormField(
                controller: _modelNameController,
                decoration: const InputDecoration(
                  labelText: '模型名称',
                  hintText: '请输入模型名称',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入模型名称';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.sp),

              // API Key输入
              TextFormField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  hintText: '请输入API Key',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入API Key';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final modelSpec = CusBriefLLMSpec(
                _selectedPlatform!,
                _modelNameController.text.trim(),
                _selectedModelType!,
                name: _modelNameController.text.trim(),
                cusLlmSpecId: Uuid().v4(),
                gmtCreate: DateTime.now(),
              );

              Navigator.pop(context, {
                'modelSpec': modelSpec,
                'apiKey': _apiKeyController.text.trim(),
              });
            }
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
} 