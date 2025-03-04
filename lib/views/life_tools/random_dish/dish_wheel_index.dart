import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/components/tool_widget.dart';
import '../../../common/constants/constants.dart';
import '../../../common/utils/db_tools/db_life_tool_helper.dart';
import '../../../common/utils/tools.dart';
import '../../../models/life_tools/dish_state.dart';
import 'dish_detail.dart';
import 'dish_list.dart';

/// 随机从数据库中获取10条食物数据，然后这里转盘再选一次
class DishWheelIndex extends StatefulWidget {
  const DishWheelIndex({super.key});

  @override
  State<DishWheelIndex> createState() => _DishWheelIndexState();
}

// TickerProviderStateMixin 允许一个小部件充当同一小部件​​树中多个“AnimationController”实例的“TickerProvider”。
class _DishWheelIndexState extends State<DishWheelIndex>
    with TickerProviderStateMixin {
  // 当前是哪个时间段(餐次字符串,2024-06-27 仅展示，不作为参数)
  String currentMeal = "";
  // 2024-06-27 当前的餐次分类，上面那个根据时间来获取，不让修改；
  // 这个是获取到之后，可以手动修改，用着查询的参数
  String mealCate = "";

  // 随机的10条食物列表和食物名称(名称用来显示，食物用来跳转)
  List<Dish> randomDishes = [];
  List<String> randomDishLabels = [];

  final DBLifeToolHelper _dbHelper = DBLifeToolHelper();

  // 转盘流控制器
  StreamController<int> streamController = StreamController<int>();

  // 转盘选中的值
  Dish? selectedValue;
  // 转盘是否旋转中，在就不显示选中的值
  var isWheelSpin = false;

  // 转盘下方提示语。刚打开app应该什么都没有，开始旋转显示旋转，旋转结束显示结果
  String selectedNote = "";

  // 2024-06-27 数据库中已经存在+预设的分类，修改时才好匹配上
  List<CusLabel> allDishCates = [];

  @override
  void initState() {
    super.initState();

    initCatesAndRondomDishes();
  }

  // 初始化所有菜品分类信息
  initCatesAndRondomDishes() async {
    // 一定在查询菜品之前，获得所有的菜品分类
    await getAllDishCatesTags();

    // 异步执行结果，如果没挂载了，就不管了
    if (!mounted) return;
    setState(() {
      currentMeal = getTimePeriod();
      mealCate = getTimePeriod();

      // 默认启动就根据当前时间查询符合餐次的菜品，构建转盘数据
      getRondomDishes();
    });
  }

  // 获取数据库中+预设的所有分类和标签
  getAllDishCatesTags() async {
    CusDataResult temp = await _dbHelper.queryDishList(
      page: 1,
      pageSize: 10000, // 应该查询所有
    );

    var newData = temp.data as List<Dish>;

    List<String> tempCates = [];

    for (var e in newData) {
      var a = (e.mealCategories?.split(","));
      // 合并两个列表, Set()字面量去除重复，然后转回List
      tempCates = <String>{...tempCates, ...?a}.toSet().toList();
    }

    // 移除已经存在的分类和标签
    for (var e in dishCateOptions) {
      if (tempCates.contains(e.cnLabel)) {
        tempCates.remove(e.cnLabel);
      }
    }

    // 再将标签和分类字符串简单转为对象列表
    allDishCates = tempCates
        .map((e) => CusLabel(value: e, enLabel: e, cnLabel: e))
        .toList();

    // 最后合并预设的和导入时存入数据库中的
    // 2024-07-16 是否已经销毁
    //    有些异步操作的结果可能在组件都销毁了才返回，还需要修改状态，此时就会报错，
    //  在修改状态前，检查是否还挂载中，如果没有就不再改变状态了(一般是在异步函数中才需要)
    if (!mounted) return;
    setState(() {
      allDishCates = <CusLabel>{...dishCateOptions, ...allDishCates}.toList();
    });
  }

  // 随机生成10条食物
  // 点击按钮才会调用这个函数，每次
  getRondomDishes() async {
    randomDishes = await _dbHelper.queryRandomDishList(
      size: 10,
      cate: mealCate,
    );

    // 检查当前State对象是否仍然挂载
    if (!mounted) return;
    setState(() {
      randomDishLabels = randomDishes.map((e) => e.dishName).toList();

      // 不管是刷新页面还是重新生成数据，都清空之前选择的菜品和提示语
      selectedNote = '';
      selectedValue = null;

      // 2024-03-23 如果指定餐次的预设菜品为空或者不足2个，关闭转盘的监听。取值会单独处理
      if (randomDishLabels.isEmpty || randomDishLabels.length < 2) {
        streamController.close();
      }
      // 2024-03-23 如果只有一条，则预选上那一条
      if (randomDishLabels.isNotEmpty && randomDishLabels.length < 2) {
        selectedValue = randomDishes.first;
      } else if (randomDishLabels.isNotEmpty && randomDishLabels.length >= 2) {
        // 如果预设菜单列表不为空，每次从无转盘切换到有转盘，不更新控制器，就是用旧的控制器来取新转盘的值，
        // fortune_wheel 组件就会报错：Bad state: Stream has already been listened to.
        // 注意，需要判断是否已经被关闭了，如果没有被关闭则不需要重新声明
        if (streamController.isClosed) {
          streamController = StreamController<int>();
        }
      }
    });
  }

  // 刷新页面，就重新获取餐次标签，和清除转盘（菜品列表为空就不显示了）
  refreshPage() {
    setState(() {
      currentMeal = getTimePeriod();
      mealCate = getTimePeriod();
      getRondomDishes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('今天吃什么?'),
        actions: buildAppBarActions(),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.pink.withOpacity(0.1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10.sp),
            Expanded(flex: 1, child: buildMealCateAndRondomButtonRow()),
            // const SizedBox(height: 20),
            // 默认是没有参数列表的，但点击随机生成之后，就会有，有了之后才显示转盘和开始按钮
            Expanded(flex: 3, child: buildFortuneWheelArea()),
            buildSelectedArea(),
            SizedBox(height: 20.sp),
          ],
        ),
      ),
    );
  }

  /// appbar的功能按钮
  buildAppBarActions() {
    return [
      IconButton(
        onPressed: isWheelSpin ? null : refreshPage,
        icon: const Icon(Icons.refresh),
      ),
      IconButton(
        onPressed: isWheelSpin
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DishList(),
                  ),
                );
              },
        icon: const Icon(Icons.menu),
      ),
      // 这里可展示说明
      IconButton(
        onPressed: isWheelSpin
            ? null
            : () {
                commonMDHintModalBottomSheet(
                  context,
                  "使用说明",
                  """**点击转盘即可开始旋转**
\n点击【餐次下拉选择框】可选择指定餐次，再点击【随机10款菜品】更新预选列表;
\n点击【随机10款菜品】按钮可更新预选列表，不足10个就全部显示;
\n点击下方随机结果的菜品名称可跳转到该菜品详情页;
\n顶部【刷新】图标按钮会根据当前系统时间获取并显示餐次标签;
\n顶部【菜单】图标按钮可以进入菜品列表管理页面;
\n**虽然“菜品列表”中网络图片会进行缓存，但也注意流量消耗。**""",
                );
              },
        icon: const Icon(Icons.info_outlined),
      )
    ];
  }

  /// 餐次标签和随机生成菜品按钮区域
  buildMealCateAndRondomButtonRow() {
    return Card(
      elevation: 3,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: '现在是 ',
                style: TextStyle(color: Colors.black, fontSize: 16.sp),
                children: [
                  TextSpan(
                    text: currentMeal,
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 24.sp,
                    ),
                  ),
                  TextSpan(
                    text: ' 时间!',
                    style: TextStyle(color: Colors.black, fontSize: 16.sp),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildMateCatesList(),
                SizedBox(
                  width: 144.sp,
                  child: FilledButton(
                    onPressed: isWheelSpin
                        ? null
                        : () {
                            getRondomDishes();
                          },
                    child: const Text("随机10款菜品"),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // 可以手动切换餐次分类
  _buildMateCatesList() {
    return DropdownMenu<String>(
      width: 144.sp,
      menuHeight: 300.sp,
      initialSelection: mealCate,
      // 限制下拉框高度更小点
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10.sp),
        constraints: BoxConstraints.tight(Size.fromHeight(40.sp)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.sp),
        ),
      ),
      // 2024-03-23 转盘在旋转的时候，不可点击切换餐次
      enabled: !isWheelSpin,
      onSelected: (String? value) {
        setState(() {
          // 2024-06-27 手动切换了分类，不改变当前用餐时间的预设分类
          mealCate = value!;
          // 2024-03-23 切换餐次就一并更新转盘预选列表
          getRondomDishes();
        });
      },
      // trailingIcon: Icon(Icons.arrow_drop_down_outlined, size: 14.sp),
      dropdownMenuEntries:
          allDishCates.map<DropdownMenuEntry<String>>((CusLabel value) {
        return DropdownMenuEntry<String>(
          value: value.cnLabel,
          label: value.cnLabel,
        );
      }).toList(),
    );
  }

  /// 转盘主体区域
  buildFortuneWheelArea() {
    if (randomDishLabels.isNotEmpty && randomDishLabels.length < 2) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("该餐次菜品仅1个", style: TextStyle(fontSize: 18.sp)),
          Text("${randomDishLabels.firstOrNull}"),
        ],
      );
    }
    return Column(
      children: [
        (randomDishLabels.isNotEmpty && randomDishLabels.length > 1)
            ? Expanded(
                child: SizedBox(
                  width: 0.95.sw,
                  height: 0.95.sw,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: GestureDetector(
                      // 实际上是先就确定了被选中的值，然后在转盘停下来时指针指向它。
                      // 所以要在转盘的动画结束后，才显示被选中的值
                      onTap: () {
                        setState(() {
                          isWheelSpin = true;

                          selectedNote = "看我转转转~";
                          // 获取随机的菜品信息
                          var index =
                              Fortune.randomInt(0, randomDishLabels.length);
                          selectedValue = randomDishes[index];
                          streamController.add(index);
                        });
                      },
                      child: Column(
                        children: [
                          Expanded(
                            // ？？？这里有个问题现象，就是转盘的值列表从有值转为空值，再转为有值会报错：
                            // Bad state: Stream has already been listened to.
                            // 实际是不是这样不清楚，但先保证db中每个餐次分类都有数据
                            child: FortuneWheel(
                              animateFirst: false,
                              // 被选中的值索引
                              selected: streamController.stream,
                              // 指示器样式
                              indicators: const <FortuneIndicator>[
                                FortuneIndicator(
                                  // <-- changing the position of the indicator
                                  alignment: Alignment.topCenter,
                                  child: TriangleIndicator(
                                    // <-- changing the color of the indicator
                                    color: Colors.amber,
                                    // <-- changing the width of the indicator
                                    width: 30.0,
                                    // <-- changing the height of the indicator
                                    height: 15.0,
                                    // <-- changing the elevation of the indicator
                                    elevation: 10,
                                  ),
                                ),
                              ],
                              // 条目的值和样式
                              items: [
                                for (var it in randomDishLabels)
                                  FortuneItem(
                                    child: Text(
                                      it.length > 8
                                          ? "${it.substring(0, 8)}..."
                                          : it,
                                    ),
                                    // style: const FortuneItemStyle(
                                    //   // <-- custom circle slice fill color
                                    //   color: Colors.red,
                                    //   // <-- custom circle slice stroke color
                                    //   borderColor: Colors.green,
                                    //   // <-- custom circle slice stroke width
                                    //   borderWidth: 3,
                                    // ),
                                  ),
                              ],
                              onAnimationStart: () {
                                debugPrint("动画开始了……");
                              },
                              onAnimationEnd: () {
                                setState(() {
                                  isWheelSpin = false;
                                  selectedNote = "最终选中了: ";
                                });

                                debugPrint("动画停止了……");
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : Container(),
        if (randomDishLabels.isEmpty)
          Padding(
            padding: EdgeInsets.all(20.sp),
            child: Text(
              "该餐次暂无菜品",
              style: TextStyle(fontSize: 18.sp),
            ),
          ),
        SizedBox(height: 10.sp),
        Text(selectedNote),
      ],
    );
  }

  /// 选择结果区域
  buildSelectedArea() {
    return (selectedValue != null && !isWheelSpin)
        ? SizedBox(
            height: 80.sp,
            child: Card(
              elevation: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ListTile(
                    // 菜品名称
                    title: Text(
                      "${selectedValue?.dishName}",
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DishDetail(dishItem: selectedValue!),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          )
        : SizedBox(height: 80.sp);
  }
}
