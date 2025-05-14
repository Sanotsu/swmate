import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import '../../../../common/llm_spec/constant_llm_enum.dart';
import '../../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../../common/utils/db_tools/db_brief_ai_tool_helper.dart';
import '../../../../services/cus_get_storage.dart';

class AddModelPage extends StatefulWidget {
  const AddModelPage({super.key});

  @override
  State<AddModelPage> createState() => _AddModelPageState();
}

class _AddModelPageState extends State<AddModelPage> {
  ApiPlatform? _selectedPlatform;
  LLModelType? _selectedModelType;

  final _formKey = GlobalKey<FormState>();
  final _modelNameController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _modelNameController.dispose();
    _apiKeyController.dispose();
    _descriptionController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('添加模型'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.sp),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 平台选择
              DropdownButtonFormField<ApiPlatform>(
                value: _selectedPlatform,
                decoration: const InputDecoration(
                  labelText: '选择平台',
                  border: OutlineInputBorder(),
                ),
                menuMaxHeight: 0.5.sh,
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
                decoration: const InputDecoration(
                  labelText: '选择模型类型',
                  border: OutlineInputBorder(),
                ),
                items: [
                  LLModelType.cc,
                  LLModelType.reasoner,
                  LLModelType.vision,
                  LLModelType.vision_reasoner
                ].map((type) {
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
              SizedBox(height: 16),

              // 如果选择的平台是自定义，则显示url输入框
              if (_selectedPlatform == ApiPlatform.custom) ...[
                _buildTextField(
                  controller: _baseUrlController,
                  labelText: '请求地址',
                  hintText: '比如:https://api.deepseek.com/v1',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入请求地址';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
              ],

              // 模型名称输入
              _buildTextField(
                controller: _modelNameController,
                labelText: '模型名',
                hintText: '请输入模型名(作为请求参数的那个,比如:deepseek-reasoner)',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入模型名';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // API Key输入
              _buildTextField(
                controller: _apiKeyController,
                labelText: 'API Key',
                hintText: '请输入API Key',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入API Key';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // 描述输入
              _buildTextField(
                controller: _descriptionController,
                labelText: '描述(非必填)',
                hintText: '请输入描述(非必填)',
              ),

              SizedBox(height: 32.sp),

              // 提交按钮
              _buildAddButton(),
            ],
          ),
        ),
      ),
    );
  }

  // 文本输入框
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      ),
      validator: validator,
      style: TextStyle(fontSize: 14),
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16.sp),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          final modelSpec = CusBriefLLMSpec(
            _selectedPlatform!,
            _modelNameController.text.trim(),
            _selectedModelType!,
            name: _modelNameController.text.trim(),
            baseUrl: _baseUrlController.text.trim(),
            apiKey: _apiKeyController.text.trim(),
            description: _descriptionController.text.trim(),
            cusLlmSpecId: const Uuid().v4(),
            gmtCreate: DateTime.now(),
          );

          // 1. 保存模型规格到数据库
          try {
            await DBBriefAIToolHelper().insertBriefCusLLMSpecList([modelSpec]);
          } catch (e) {
            if (!mounted) return;
            if (e.toString().contains("code 2067")) {
              EasyLoading.showError("该模型已存在,请检查‘平台+模型+模型类型’是否重复");
            } else {
              EasyLoading.showError(
                "新增模型出错,${e.toString()}",
                duration: Duration(seconds: 5),
              );
            }

            return;
          }

          // 2. 保存API Key到缓存(只更新指定平台的AK)
          // 2025-03-14 这里需要根据平台枚举值，来确定对应的AK Label
          // 所以AK Label的枚举值，需要完整包含上面平台的枚举值
          final akLabelList = ApiPlatformAKLabel.values.where(
            (label) =>
                label.name.contains(modelSpec.platform.name.toUpperCase()),
          );
          if (akLabelList.isNotEmpty) {
            await MyGetStorage().updatePlatformApiKey(
              akLabelList.first,
              _apiKeyController.text.trim(),
            );
          }

          // 3. 返回新加的模型规格用于被选中
          if (!mounted) return;
          Navigator.pop(context, modelSpec);
        }
      },
      child: const Text('添加'),
    );
  }
}
