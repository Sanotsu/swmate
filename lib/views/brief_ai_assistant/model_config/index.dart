import 'package:flutter/material.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../common/utils/db_tools/db_helper.dart';
import 'components/model_import.dart';
import 'components/api_key_config.dart';
import 'components/model_list.dart';

class BriefModelConfig extends StatefulWidget {
  const BriefModelConfig({super.key});

  @override
  State<BriefModelConfig> createState() => _BriefModelConfigState();
}

class _BriefModelConfigState extends State<BriefModelConfig> {
  final DBHelper _dbHelper = DBHelper();
  List<CusBriefLLMSpec> _models = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    setState(() => _isLoading = true);
    try {
      final models = await _dbHelper.queryCusBriefLLMSpecList();
      setState(() => _models = models);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('模型配置'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '模型列表'),
              Tab(text: '导入模型'),
              Tab(text: 'API配置'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ModelList(
              models: _models,
              isLoading: _isLoading,
              onRefresh: _loadModels,
            ),
            ModelImport(onImportSuccess: _loadModels),
            const ApiKeyConfig(),
          ],
        ),
      ),
    );
  }
}
