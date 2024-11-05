import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../apis/hitokoto/hitokoto_apis.dart';
import '../../common/llm_spec/cus_llm_spec.dart';
import '../../models/hitokoto/hitokoto.dart';
import '../ai_assistant/_componets/custom_entrance_card.dart';
import '../ai_assistant/index.dart';
import 'accounting/index.dart';
import 'animal_lover/dog_cat_index.dart';
import 'anime_top/bangumi_calendar.dart';
import 'anime_top/mal_top_index.dart';
import 'food/nutritionix/index.dart';
import 'food/nutritionix_calculator/index.dart';
import 'free_dictionary/index.dart';
import 'news/daily_60s/index.dart';
import 'news/momoyu/index.dart';
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
  String? hitokoto;
  Hitokoto? hito;

  @override
  void initState() {
    getOneSentence();
    super.initState();
  }

  // 2024-10-17 注意，请求太过频繁会无法使用
  getOneSentence() async {
    var a = await getHitokoto();

    if (!mounted) return;
    setState(() {
      hitokoto = "${a.hitokoto ?? ''}——${a.fromWho ?? ''}[${a.from ?? ''}]";
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
          // SizedBox(height: 10.sp),
          buildHitokoto(),
          // 滚动显示一行有趣的一言
          // hitokoto != null
          //     ? SimpleMarqueeOrText(
          //         data: hitokoto ?? "",
          //         velocity: 30,
          //         style: TextStyle(fontSize: 15.sp),
          //       )
          //     : Container(),
          // 入口按钮
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                // 这个是直接展示全部
                // ...buildCardList(context),
                // 这个是分类的折叠栏
                buildToolTile(context),
                const Divider(),
                buildAnimeTile(),
                const Divider(),
                buildNewsTile(),
                const Divider(),
                buildFoodTile(),
                const Divider(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHitokoto() {
    return hitokoto != null
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
        : Container(height: 60.sp);
  }
}

/// 直接全部平铺展示
List<Widget> buildCardList(BuildContext context) {
  return [
    const Divider(),
    titleWidget('实用小工具', iconData: Icons.build),
    ...toolRows(context),
    const Divider(),
    titleWidget('图片与动漫', iconData: Icons.image),
    ...animeRows(),
    const Divider(),
    titleWidget('摸鱼看新闻', iconData: Icons.newspaper),
    ...newsRows(),
    const Divider(),
    titleWidget('饮食和健康', iconData: Icons.set_meal),
    ...foodRows(),
  ];
}

/// 分类的折叠框显示
buildToolTile(BuildContext context) {
  return ExpansionTile(
    // 展开后不显示上下的边框
    shape: const Border(),
    // 展开后不显示上下的边框(改为透明色也看不到)
    // shape: Border.all(color: Colors.transparent),
    leading: const Icon(Icons.build, color: Colors.green),
    title: titleWidget('实用工具'),
    children: toolRows(context),
  );
}

buildAnimeTile() {
  return ExpansionTile(
    // 展开后不显示上下的边框
    shape: const Border(),
    leading: const Icon(Icons.image, color: Colors.green),
    title: titleWidget('图片动漫'),
    children: animeRows(),
  );
}

buildNewsTile() {
  return ExpansionTile(
    // 展开后不显示上下的边框
    shape: const Border(),
    leading: const Icon(Icons.newspaper, color: Colors.green),
    title: titleWidget('摸鱼新闻'),
    children: newsRows(),
  );
}

buildFoodTile() {
  return ExpansionTile(
    // 展开后不显示上下的边框
    shape: const Border(),
    leading: const Icon(Icons.set_meal, color: Colors.green),
    title: titleWidget('饮食健康'),
    children: foodRows(),
  );
}

Widget titleWidget(String title, {IconData? iconData}) {
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

List<Widget> toolRows(BuildContext context) {
  return [
    buildRow([
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
    buildRow([
      LifeToolEntranceCard(
        title: '猫狗之家',
        subtitle: "图片识别猫狗品种",
        icon: FontAwesomeIcons.dog,
        onTap: () async {
          await navigateToToolScreen(
            context,
            LLModelType.vision,
            (llmSpecList, cusSysRoleSpecs) => DogCatLover(
              llmSpecList: llmSpecList,
            ),
            roleType: LLModelType.vision,
          );
        },
      ),
      const LifeToolEntranceCard(
        title: '英英词典',
        subtitle: "维基词典单词查询",
        icon: Icons.newspaper,
        targetPage: FreeDictionary(),
      ),
    ]),
  ];
}

List<Widget> animeRows() {
  return [
    buildRow([
      const LifeToolEntranceCard(
        title: 'BGM动漫资讯',
        subtitle: "Bangumi番组计划",
        icon: Icons.leaderboard_outlined,
        targetPage: BangumiCalendar(),
      ),
      const LifeToolEntranceCard(
        title: 'MAL动漫排行',
        subtitle: "MyAnimeList排行榜",
        icon: Icons.leaderboard_outlined,
        targetPage: MALTop(),
      ),
    ]),
    buildRow([
      const LifeToolEntranceCard(
        title: 'WAIFU图片',
        subtitle: "随机二次元WAIFU",
        icon: Icons.image,
        targetPage: WaifuPicIndex(),
      ),
      const SizedBox(),
    ])
  ];
}

List<Widget> newsRows() {
  return [
    buildRow([
      const LifeToolEntranceCard(
        title: '摸摸鱼',
        subtitle: "聚合新闻摸鱼网站",
        icon: Icons.newspaper,
        targetPage: MomoyuIndex(),
      ),
      const LifeToolEntranceCard(
        title: '每天60秒',
        subtitle: "每天60秒读懂世界",
        icon: Icons.newspaper,
        targetPage: Daily60S(),
      ),
    ]),
  ];
}

List<Widget> foodRows() {
  return [
    buildRow([
      const LifeToolEntranceCard(
        title: "USDA食品",
        subtitle: "USDA食品数据中心",
        icon: Icons.food_bank,
        targetPage: USDAFoodDataCentral(),
      ),
      const LifeToolEntranceCard(
        title: "Nutritionix",
        subtitle: "Nutritionix食品数据",
        icon: Icons.food_bank,
        targetPage: NutritionixFoodCentral(),
      ),
    ]),
    buildRow([
      const LifeToolEntranceCard(
        title: "热量计算器",
        subtitle: "食物热量和运动消耗",
        icon: Icons.calculate,
        targetPage: NixSimpleCalculator(),
      ),
      const SizedBox(),
    ]),
  ];
}

Widget buildRow(List<Widget> children) {
  return SizedBox(
    height: 80.sp,
    child: Row(
      children: children.map((child) => Expanded(child: child)).toList(),
    ),
  );
}
