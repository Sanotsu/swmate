import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import '../../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../../common/utils/db_tools/db_helper.dart';
import '../../../../services/model_manager_service.dart';

class ModelImport extends StatefulWidget {
  final VoidCallback onImportSuccess;

  const ModelImport({
    super.key,
    required this.onImportSuccess,
  });

  @override
  State<ModelImport> createState() => _ModelImportState();
}

class _ModelImportState extends State<ModelImport> {
  final DBHelper _dbHelper = DBHelper();
  bool _importing = false;

  Future<void> _importFromJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null) return;

    setState(() => _importing = true);
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

      // 转换为模型列表
      var models =
          jsonList.map((json) => CusBriefLLMSpec.fromJson(json)).toList();

      // 设置ID和时间
      models = models.map((e) {
        e.cusLlmSpecId = const Uuid().v4();
        e.name = !e.isFree ? '【收费】${e.name}' : e.name;
        e.gmtCreate = DateTime.now();
        e.isBuiltin = false; // 用户导入的模型
        return e;
      }).toList();

      await _dbHelper.insertCusBriefLLMSpecList(models);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功导入 ${models.length} 个模型')),
      );
      widget.onImportSuccess();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败: $e')),
      );
    } finally {
      setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '从 JSON 文件导入模型配置',
            style: TextStyle(fontSize: 18.sp),
          ),
          SizedBox(height: 20.sp),
          if (_importing)
            const CircularProgressIndicator()
          else
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('选择文件'),
              onPressed: _importFromJson,
            ),
        ],
      ),
    );
  }
}
