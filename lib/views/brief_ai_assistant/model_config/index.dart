import 'package:flutter/material.dart';

import 'components/api_key_config.dart';
import 'components/model_list.dart';

class BriefModelConfig extends StatefulWidget {
  const BriefModelConfig({super.key});

  @override
  State<BriefModelConfig> createState() => _BriefModelConfigState();
}

class _BriefModelConfigState extends State<BriefModelConfig> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('模型配置'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '模型列表'),
              Tab(text: 'API配置'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ModelList(),
            ApiKeyConfig(),
          ],
        ),
      ),
    );
  }
}
