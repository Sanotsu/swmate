import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../common/components/feature_grid_card.dart';
import '../../common/components/modern_feature_card.dart';
import 'branch_chat/branch_chat_page.dart';
import 'character_chat/character_list_page.dart';
import 'chat/index.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      // 避免搜索时弹出键盘，让底部的minibar位置移动到tab顶部导致溢出的问题
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 顶部横幅
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.fromLTRB(16.sp, 16.sp, 16.sp, 8.sp),
                padding: EdgeInsets.all(16.sp),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20.sp),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "思文",
                                style: TextStyle(
                                  fontSize: 26.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const BriefModelConfig(),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.settings,
                                  color: Colors.white,
                                ),
                                tooltip: '模型配置',
                              ),
                            ],
                          ),
                          SizedBox(height: 8.sp),
                          Text(
                            "让创意与效率并存，探索AI的无限可能",
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40.sp,
                      height: 40.sp,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(15.sp),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 30.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 免责声明
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.sp),
                child: Text(
                  "所有内容均由人工智能模型生成，无法确保内容的真实性、准确性和完整性，仅供参考，且不代表开发者的态度和观点",
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // 推荐功能
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.sp, 24.sp, 16.sp, 8.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4.sp,
                          height: 20.sp,
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            borderRadius: BorderRadius.circular(2.sp),
                          ),
                        ),
                        SizedBox(width: 8.sp),
                        Text(
                          "推荐功能",
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.sp),
                    ModernFeatureCard(
                      targetPage: const BranchChatPage(),
                      title: "高级助手",
                      subtitle: "强大的AI助手，支持分支对话和多种配置",
                      icon: Icons.psychology,
                      accentColor: Colors.blue,
                    ),
                    SizedBox(height: 12.sp),
                    ModernFeatureCard(
                      targetPage: const CharacterListPage(),
                      title: "角色扮演",
                      subtitle: "与各种角色对话，体验丰富多样的互动场景",
                      icon: Icons.people_alt,
                      accentColor: Colors.purple,
                    ),
                  ],
                ),
              ),
            ),

            // 所有功能网格
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.sp, 24.sp, 16.sp, 8.sp),
                child: Row(
                  children: [
                    Container(
                      width: 4.sp,
                      height: 20.sp,
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(2.sp),
                      ),
                    ),
                    SizedBox(width: 8.sp),
                    Text(
                      "所有功能",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.sp, 16.sp, 16.sp, 0),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 16.sp,
                  mainAxisSpacing: 16.sp,
                ),
                delegate: SliverChildListDelegate([
                  FeatureGridCard(
                    targetPage: const BranchChatPage(),
                    title: "高级助手",
                    icon: Icons.psychology,
                    accentColor: Colors.blue.shade600,
                    isNew: true,
                  ),
                  FeatureGridCard(
                    targetPage: const CharacterListPage(),
                    title: "角色扮演",
                    icon: Icons.people_alt,
                    accentColor: Colors.purple.shade600,
                    isNew: true,
                  ),
                  FeatureGridCard(
                    targetPage: const BriefChatScreen(),
                    title: "简洁助手",
                    icon: Icons.chat_bubble_outline,
                    accentColor: Colors.green.shade600,
                  ),
                  FeatureGridCard(
                    targetPage: const BriefImageScreen(),
                    title: "图片生成",
                    icon: Icons.image,
                    accentColor: Colors.orange.shade600,
                  ),
                  FeatureGridCard(
                    targetPage: const BriefVideoScreen(),
                    title: "视频生成",
                    icon: Icons.videocam,
                    accentColor: Colors.red.shade600,
                  ),
                ]),
              ),
            ),

            // 底部间距
            SliverToBoxAdapter(
              child: SizedBox(height: 24.sp),
            ),
          ],
        ),
      ),
    );
  }
}
