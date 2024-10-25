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
    // 计算屏幕剩余的高度
    // 设备屏幕的总高度
    //  - 屏幕顶部的安全区域高度，即状态栏的高度
    //  - 屏幕底部的安全区域高度，即导航栏的高度或者虚拟按键的高度
    //  - 应用程序顶部的工具栏（如 AppBar）的高度
    //  - 应用程序底部的导航栏的高度
    //  - 组件的边框间隔(不一定就是2)
    double screenBodyHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom -
        kToolbarHeight -
        kBottomNavigationBarHeight;

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
          SizedBox(
            height: screenBodyHeight - 80.sp,
            child: GridView.count(
              primary: false,
              padding: EdgeInsets.symmetric(horizontal: 5.sp),
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              crossAxisCount: 2,
              childAspectRatio: 3 / 2,
              children: <Widget>[
                const CustomEntranceCard(
                  title: '极简记账',
                  subtitle: "手动记账图表统计",
                  icon: Icons.receipt,
                  targetPage: BillItemIndex(),
                ),

                const CustomEntranceCard(
                  title: '随机菜品',
                  subtitle: "随机生成一道菜品",
                  icon: Icons.restaurant_menu,
                  targetPage: DishWheelIndex(),
                ),

                CustomEntranceCard(
                  title: '猫狗之家',
                  subtitle: "猫狗的图片和事实",
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
                  // targetPage: DogCatLover(),
                ),

                const CustomEntranceCard(
                  title: 'WAIFU图片',
                  subtitle: "随机二次元WAIFU",
                  icon: Icons.image,
                  targetPage: WaifuPicIndex(),
                ),

                const CustomEntranceCard(
                  title: 'MAL动漫排行',
                  subtitle: "MyAnimeList排行榜",
                  icon: Icons.leaderboard_outlined,
                  targetPage: MALTop(),
                ),

                const CustomEntranceCard(
                  title: 'BGM动漫资讯',
                  subtitle: "Bangumi番组计划",
                  icon: Icons.leaderboard_outlined,
                  targetPage: BangumiCalendar(),
                ),

                const CustomEntranceCard(
                  title: '摸摸鱼',
                  subtitle: "聚合新闻摸鱼网站",
                  icon: Icons.newspaper,
                  targetPage: MomoyuIndex(),
                ),

                const CustomEntranceCard(
                  title: '每天60秒',
                  subtitle: "每天60秒读懂世界",
                  icon: Icons.newspaper,
                  targetPage: Daily60S(),
                ),

                const CustomEntranceCard(
                  title: '英英词典',
                  subtitle: "维基词典单词查询",
                  icon: Icons.newspaper,
                  targetPage: FreeDictionary(),
                ),

                Container(),

                const CustomEntranceCard(
                  title: "食品数据",
                  subtitle: "USDA食品数据中心",
                  icon: Icons.food_bank,
                  targetPage: USDAFoodDataCentral(),
                ),

                const CustomEntranceCard(
                  title: "Nutritionix",
                  subtitle: "Nutritionix食品数据",
                  icon: Icons.food_bank,
                  targetPage: NutritionixFoodCentral(),
                ),

                const CustomEntranceCard(
                  title: "热量计算器",
                  subtitle: "食物热量和运动消耗",
                  icon: Icons.food_bank,
                  targetPage: NixSimpleCalculator(),
                ),

                // buildAIToolEntrance(
                //   "功能\n占位(TODO)",
                //   icon: const Icon(Icons.search),
                // ),
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
