import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../common/llm_spec/cus_llm_spec.dart';
import '../ai_assistant/_componets/custom_entrance_card.dart';
import '../ai_assistant/index.dart';
import 'accounting/index.dart';
import 'animal_lover/dog_cat_index.dart';
import 'anime_top/bangumi_calendar.dart';
import 'anime_top/mal_top_index.dart';
import 'random_dish/dish_wheel_index.dart';
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
          SizedBox(height: 10.sp),
          // 入口按钮
          SizedBox(
            height: screenBodyHeight - 50.sp,
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
                  icon: Icons.leaderboard_outlined,
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
}
