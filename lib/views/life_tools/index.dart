import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../apis/life_tools/hitokoto/hitokoto_apis.dart';
import '../../common/components/tool_widget.dart';
import '../../common/llm_spec/cus_brief_llm_model.dart';
import '../../common/llm_spec/constant_llm_enum.dart';
import '../../models/life_tools/hitokoto/hitokoto.dart';
import '../../services/model_manager_service.dart';
import '../../services/network_service.dart';
import '../../common/components/custom_entrance_card.dart';

import 'accounting/index.dart';
import 'animal_lover/dog_cat_index.dart';
import 'anime_top/bangumi_calendar.dart';
import 'anime_top/mal_top_index.dart';
import 'food/nutritionix/index.dart';
import 'food/nutritionix_calculator/index.dart';
import 'free_dictionary/index.dart';
import 'news/base_news_page/newsapi_page.dart';
import 'news/base_news_page/sina_roll_news_page.dart';
import 'news/daily_60s/index.dart';
import 'news/momoyu/index.dart';
import 'news/readhub/index.dart';
import 'random_dish/dish_wheel_index.dart';
import 'food/usda_food_data/index.dart';
import 'waifu_pics/index.dart';

///
/// 常用的生活类工具
/// 记账、随机菜品等
///
class LifeToolIndex extends StatefulWidget {
  const LifeToolIndex({super.key});

  @override
  State createState() => _LifeToolIndexState();
}

class _LifeToolIndexState extends State<LifeToolIndex> {
  Hitokoto? hito;

  @override
  void initState() {
    getOneSentence();
    super.initState();
  }

  // 2024-10-17 注意，请求太过频繁会无法使用
  getOneSentence() async {
    // 如果没网，就不查询一言了
    bool isNetworkAvailable = await NetworkStatusService().isNetwork();

    if (!mounted) return;
    if (!isNetworkAvailable) {
      setState(() {
        hito = null;
      });
      return;
    }

    var a = await getHitokoto();

    if (!mounted) return;
    setState(() {
      hito = a;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('生活日常工具'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// 显示一言
          buildHitokoto(),
          const Divider(),

          /// 功能入口按钮
          Expanded(
            child: ListView(
              children: [
                /// 这个是直接展示全部
                // ...buildCardList(context),

                // /// 这个是分类的折叠栏
                ...buildExpansionTileList(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHitokoto() {
    return hito != null
        ? SizedBox(
            height: 60.sp,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.sp),
              child: RichText(
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: hito?.hitokoto ?? '',
                      style: TextStyle(color: Colors.blue, fontSize: 15.sp),
                    ),
                    // 第二行文本，靠右对齐
                    WidgetSpan(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "\n——${hito?.fromWho ?? ''}「${hito?.from ?? ''}」",
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : SizedBox(
            height: 60.sp,
            child: Text('<暂无网络>'),
          );
  }
}

/// 直接全部平铺展示
List<Widget> buildCardList(BuildContext context) {
  return [
    _titleWidget('实用小工具', iconData: Icons.build),
    ..._toolRows(context),
    const Divider(),
    _titleWidget('图片与动漫', iconData: Icons.image),
    ..._animeRows(context),
    const Divider(),
    _titleWidget('摸鱼看新闻', iconData: Icons.newspaper),
    ..._newsRows(context),
    const Divider(),
    _titleWidget('饮食和健康', iconData: Icons.set_meal),
    ..._foodRows(context),
  ];
}

/// 可折叠分类显示
List<Widget> buildExpansionTileList(BuildContext context) {
  return [
    ExpansionTile(
      // 展开后不显示上下的边框
      shape: const Border(),
      // 展开后不显示上下的边框(改为透明色也看不到)
      // shape: Border.all(color: Colors.transparent),
      leading: const Icon(Icons.build, color: Colors.green),
      title: _titleWidget('实用工具'),
      children: _toolRows(context),
    ),
    const Divider(),
    ExpansionTile(
      shape: const Border(),
      leading: const Icon(Icons.image, color: Colors.green),
      title: _titleWidget('图片动漫'),
      children: _animeRows(context),
    ),
    const Divider(),
    ExpansionTile(
      shape: const Border(),
      leading: const Icon(Icons.newspaper, color: Colors.green),
      title: _titleWidget('摸鱼新闻'),
      children: _newsRows(context),
    ),
    const Divider(),
    ExpansionTile(
      shape: const Border(),
      leading: const Icon(Icons.set_meal, color: Colors.green),
      title: _titleWidget('饮食健康'),
      children: _foodRows(context),
    ),
    const Divider(),
  ];
}

/// 具体每种分类的入口
List<Widget> _toolRows(BuildContext context) {
  return [
    _rowWidget([
      const LifeToolEntranceCard(
        title: '极简记账',
        subtitle: "手动记账图表统计",
        icon: Icons.receipt,
        targetPage: BillItemIndex(),
      ),
      const LifeToolEntranceCard(
        title: '随机菜品',
        subtitle: "随机生成一道菜品",
        icon: Icons.restaurant_menu,
        targetPage: DishWheelIndex(),
      ),
    ]),
    _rowWidget([
      LifeToolEntranceCard(
        title: '猫狗之家',
        subtitle: "图片识别猫狗品种",
        icon: FontAwesomeIcons.dog,
        onTap: () async {
          await navigateToScreenWithLLModels(
            context,
            LLModelType.vision,
            (llmSpecList) => DogCatLover(
              llmSpecList: llmSpecList,
            ),
            roleType: LLModelType.vision,
          );
        },
      ),
      LifeToolEntranceCard(
        title: '英英词典',
        subtitle: "维基词典单词查询",
        icon: Icons.newspaper,
        // targetPage: FreeDictionary(),
        onTap: () => showNoNetworkOrGoTargetPage(
          context,
          FreeDictionary(),
        ),
      ),
    ]),
  ];
}

List<Widget> _animeRows(BuildContext context) {
  return [
    _rowWidget([
      LifeToolEntranceCard(
        title: 'BGM动漫资讯',
        subtitle: "Bangumi番组计划",
        icon: Icons.leaderboard_outlined,
        onTap: () => showNoNetworkOrGoTargetPage(
          context,
          BangumiCalendar(),
        ),
      ),
      LifeToolEntranceCard(
        title: 'MAL动漫排行',
        subtitle: "MyAnimeList排行榜",
        icon: Icons.leaderboard_outlined,
        onTap: () => showNoNetworkOrGoTargetPage(
          context,
          MALTop(),
        ),
      ),
    ]),
    _rowWidget([
      LifeToolEntranceCard(
        title: 'WAIFU图片',
        subtitle: "随机二次元WAIFU",
        icon: Icons.image,
        onTap: () => showNoNetworkOrGoTargetPage(
          context,
          WaifuPicIndex(),
        ),
      ),
      const SizedBox(),
    ])
  ];
}

List<Widget> _newsRows(BuildContext context) {
  return [
    _rowWidget([
      LifeToolEntranceCard(
        title: '摸摸鱼',
        subtitle: "聚合新闻摸鱼网站",
        icon: Icons.newspaper,
        onTap: () => showNoNetworkOrGoTargetPage(
          context,
          MomoyuIndex(),
        ),
      ),
      LifeToolEntranceCard(
        title: 'Readhub',
        subtitle: "Readhub热门话题",
        icon: Icons.newspaper,
        onTap: () => showNoNetworkOrGoTargetPage(
          context,
          ReadhubIndex(),
        ),
      ),
    ]),
    _rowWidget([
      LifeToolEntranceCard(
        title: '每天60秒',
        subtitle: "每天60秒读懂世界",
        icon: Icons.newspaper,
        // targetPage: Daily60S(),
        onTap: () => showNoNetworkOrGoTargetPage(
          context,
          Daily60S(),
        ),
      ),
      LifeToolEntranceCard(
        title: '国际新闻',
        subtitle: "NewsAPI新闻资讯",
        icon: Icons.newspaper,
        onTap: () => showNoNetworkOrGoTargetPage(
          context,
          NewsApiPage(),
        ),
      ),
    ]),
    _rowWidget([
      LifeToolEntranceCard(
        title: '新浪新闻',
        subtitle: "新闻中心滚动新闻",
        icon: Icons.newspaper,
        onTap: () => showNoNetworkOrGoTargetPage(
          context,
          SinaRollNewsPage(),
        ),
      ),
      const SizedBox(),
    ]),
  ];
}

List<Widget> _foodRows(BuildContext context) {
  return [
    _rowWidget([
      LifeToolEntranceCard(
        title: "USDA食品",
        subtitle: "USDA食品数据中心",
        icon: Icons.food_bank,
        onTap: () => showNoNetworkOrGoTargetPage(
          context,
          USDAFoodDataCentral(),
        ),
      ),
      LifeToolEntranceCard(
        title: "Nutritionix",
        subtitle: "Nutritionix食品数据",
        icon: Icons.food_bank,
        onTap: () => showNoNetworkOrGoTargetPage(
          context,
          NutritionixFoodCentral(),
        ),
      ),
    ]),
    _rowWidget([
      LifeToolEntranceCard(
        title: "热量计算器",
        subtitle: "食物热量和运动消耗",
        icon: Icons.calculate,
        onTap: () => showNoNetworkOrGoTargetPage(
          context,
          NixSimpleCalculator(),
        ),
      ),
      const SizedBox(),
    ]),
  ];
}

// 分类的标题文字组件
Widget _titleWidget(String title, {IconData? iconData}) {
  return Padding(
    padding: EdgeInsets.all(5.sp),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (iconData != null) Icon(iconData, color: Colors.green),
        SizedBox(width: 10.sp),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: Colors.green,
          ),
        ),
      ],
    ),
  );
}

// 分类中的组件入口列表
Widget _rowWidget(List<Widget> children) {
  return SizedBox(
    height: 80.sp,
    child: Row(
      children: children.map((child) => Expanded(child: child)).toList(),
    ),
  );
}

/// 卡片在没有网的时候，点击就显示弹窗；有网才跳转到功能页面
void showNoNetworkOrGoTargetPage(
  BuildContext context,
  Widget targetPage,
) async {
  bool isNetworkAvailable = await NetworkStatusService().isNetwork();

  if (!context.mounted) return;
  isNetworkAvailable
      ? Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        )
      : commonHintDialog(
          context,
          "提示",
          "请联网后使用该功能。",
          msgFontSize: 15.sp,
        );
}

///
/// 点击智能助手的入口，跳转到子页面
///
Future<void> navigateToScreenWithLLModels(
  BuildContext context,
  LLModelType modelType,
  Widget Function(List<CusBriefLLMSpec>) pageBuilder, {
  LLModelType? roleType,
}) async {
  // 获取对话的模型列表(具体逻辑看函数内部)
  List<CusBriefLLMSpec> llmSpecList =
      await ModelManagerService.getAvailableModelByTypes([
    LLModelType.vision,
  ]);

  if (!context.mounted) return;
  if (llmSpecList.isEmpty) {
    return commonHintDialog(context, "提示", "无可用的模型，该功能不可用");
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => pageBuilder(llmSpecList),
      ),
    );
  }
}
