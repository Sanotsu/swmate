import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../services/cus_get_storage.dart';

class ApiKeyConfig extends StatefulWidget {
  const ApiKeyConfig({super.key});

  @override
  State<ApiKeyConfig> createState() => _ApiKeyConfigState();
}

class _ApiKeyConfigState extends State<ApiKeyConfig> {
  bool _obscureText = true;
  Map<String, String> _apiKeys = {};

  @override
  void initState() {
    super.initState();
    // 使用 Future.microtask 确保在构建完成后加载数据
    Future.microtask(() => _loadApiKeys());
  }

  void _loadApiKeys() {
    final keys = MyGetStorage().getUserAKMap();
    if (mounted) {
      setState(() => _apiKeys = keys);
    }
  }

  Future<void> _importFromJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null) return;

    try {
      final file = File(result.files.single.path!);
      final jsonStr = await file.readAsString();
      final Map<String, dynamic> json = jsonDecode(jsonStr);

      // 保存到缓存
      await MyGetStorage().setUserAKMap(
        json.map((key, value) => MapEntry(key, value.toString())),
      );

      _loadApiKeys();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API KEY 导入成功')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败: $e')),
      );
    }
  }

  Future<void> _clearAllKeys() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除所有 API Key 吗？这将影响使用自定义模型的功能。'),
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
      await MyGetStorage().clearUserAKMap();
      _loadApiKeys(); // 重新加载数据

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已清除所有 API Key')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(vertical: 16.sp),
      children: [
        Row(
          children: [
            Text(
              'API Key 配置',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon:
                  Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureText = !_obscureText),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearAllKeys,
            ),
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: _importFromJson,
            ),
          ],
        ),
        if (_apiKeys.isEmpty)
          Padding(
            padding: EdgeInsets.all(32.sp),
            child: const Center(
              child: Text('暂无配置的 API Key'),
            ),
          )
        else
          ..._buildApiKeyList(),
      ],
    );
  }

  List<Widget> _buildApiKeyList() {
    return _apiKeys.entries.map((entry) {
      return Card(
        child: ListTile(
          title: Text(entry.key),
          subtitle: Text(
            _obscureText ? '••••••••' : entry.value,
            style: const TextStyle(color: Colors.green),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final newKeys = Map<String, String>.from(_apiKeys)
                ..remove(entry.key);
              await MyGetStorage().setUserAKMap(newKeys);
              _loadApiKeys();
            },
          ),
        ),
      );
    }).toList();
  }
}
