import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:swmate/views/brief_ai_assistant/chat/index.dart';

import '../../common/components/cus_cards.dart';

import '../../common/constants.dart';
import '../ai_assistant/index.dart';
import 'image/index.dart';
import 'model_config/index.dart';
import 'video/index.dart';

class BriefAITools extends StatefulWidget {
  const BriefAITools({super.key});

  @override
  State createState() => _BriefAIToolsState();
}

class _BriefAIToolsState extends State<BriefAITools> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 避免搜索时弹出键盘，让底部的minibar位置移动到tab顶部导致溢出的问题
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text("AI 工具"),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BriefModelConfig(),
                ),
              );
            },
            icon: const Icon(Icons.import_export),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AIToolIndex()),
              );
            },
            child: Text("旧版"),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// 免责说明
          Padding(
            padding: EdgeInsets.all(2.sp),
            child: Text(
              "服务生成的所有内容均由人工智能模型生成，无法确保内容的真实性、准确性和完整性，仅供参考，且不代表开发者的态度或观点。",
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
          ),
          SizedBox(height: 10.sp),
          Expanded(
            child: CusCoverCard(
              targetPage: const BriefChatScreen(),
              title: "AI 助手",
              imageUrl: aiAssistantCoverUrl,
            ),
          ),
          Expanded(
            child: CusCoverCard(
              targetPage: const BriefImageScreen(),
              title: 'AI 绘图',
              imageUrl: aiImageCoverUrl,
            ),
          ),
          Expanded(
            child: CusCoverCard(
              targetPage: const BriefVideoScreen(),
              title: "AI 视频",
              imageUrl: aiVideoCoverUrl,
            ),
          ),
          // Expanded(
          //   child: CusCoverCard(
          //     targetPage: const BriefVideoScreen(),
          //     title: "AI 视频",
          //     imageUrl: aiVideoCoverUrl,
          //   ),
          // ),
          // Expanded(
          //   child: CusCoverCard(
          //     targetPage: const BriefVideoScreen(),
          //     title: "AI 视频",
          //     imageUrl: aiVideoCoverUrl,
          //   ),
          // ),
          // Expanded(
          //   child: CusCoverCard(
          //     targetPage: const BriefVideoScreen(),
          //     title: "AI 视频",
          //     imageUrl: aiVideoCoverUrl,
          //   ),
          // ),
        ],
      ),
    );
  }
}
