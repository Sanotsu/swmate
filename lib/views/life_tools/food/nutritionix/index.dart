import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import '../../../../apis/food/nutritionix/nutritionix_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../models/food/nutritionix/nix_search_instant_resp.dart';
import 'nix_food_item_nutrients_page.dart';
import 'nix_natural_language_query.dart';

/// 2024-10-19 页面显示逻辑应该是这样的：
/// 1 输入框输入关键词，触发 search/instant ，在可筛选输入框显示common和branded的列表
///   1-1 如果点击了common或者branded的某个条目，就直接跳转到营养素详情页
///   1-2 如果没有点击预选的而是直接点击搜索，则列表显示common和branded数据，点击之后再跳转到详情页
///       1-2-1 如果是common的，结果是直接调用了natural/nutrients 查看到详情数据
///       1-2-2 如果是branded，是调用search/item 查看详情数据(common没有id，branded有)
///
/// 2 默认就是个输入框，直接查询后就显示 search/instant 的列表
///   一些其他数据(比如有多少食物、多少餐馆，看指挥这个文件是不是固定的地址)
///   https://d1gvlspmcma3iu.cloudfront.net/item-totals.json
class NutritionixFoodCentral extends StatefulWidget {
  const NutritionixFoodCentral({super.key});

  @override
  State createState() => _NutritionixFoodCentralState();
}

class _NutritionixFoodCentralState extends State<NutritionixFoodCentral>
    with SingleTickerProviderStateMixin {
  // 快速查询的预选列表有两种结构类型,用过tab切换显示
  List<NixBranded> brandedList = [];
  List<NixCommon> commonList = [];

  // 首次进入页面或者切换类型时的加载
  bool isLoading = false;

  // 关键字查询
  String query = '';

  String note = """数据来源: [nutritionix](https://www.nutritionix.com/)，品牌食品为美国品牌

截止2024-10-21，Nutritionix Database 1,201,565 food items and growing!

API文档参看
- https://www.nutritionix.com/business/api
- https://docx.riversand.com/developers/docs/nutritionix-api-guide
""";

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 这个是初始化页面或者切换了类型时的首次查询
  Future<void> fetchNixInstantData() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });

    var rst = await searchNixInstants(query);

    if (!mounted) return;
    setState(() {
      brandedList = rst.branded ?? [];
      commonList = rst.common ?? [];
    });

    setState(() {
      isLoading = false;
    });
  }

  // 关键字查询
  void _handleSearch() async {
    setState(() {
      brandedList.clear();
      commonList.clear();
    });

    unfocusHandle();

    fetchNixInstantData();
  }

  // 输入搜索框值变化时，实时查询预选列表数据
  Future<List<dynamic>> getFoodItem(String search) async {
    if (search.isEmpty) return [];

    // 当输入值变化时，也更新全局的查询条件，供直接点击了搜索按钮时也得到目标搜索值
    setState(() {
      query = search;
    });
    var rst = await searchNixInstants(search);

    var arr = [];
    arr.addAll(rst.common ?? []);
    arr.addAll(rst.branded ?? []);

    return arr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutritionix食品数据'),
        actions: [
          IconButton(
            onPressed: () {
              commonMDHintModalBottomSheet(
                context,
                "说明",
                note,
                msgFontSize: 15.sp,
              );
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: GestureDetector(
        // 允许子控件（如TextField）接收点击事件
        behavior: HitTestBehavior.translucent,
        // 点击空白处可以移除焦点，关闭键盘
        onTap: unfocusHandle,
        child: Column(
          children: [
            /// 跳转到食物能量和运动消耗计算页面的按钮
            buildCalculateButton(),

            /// 固定高度的查询区域
            /// 输入框值变化时，即时快速查询数据，并显示在输入框下方
            buildKeywordInputArea(),

            /// 没有点击快速结果条目，下方就显示查询结果
            if (commonList.isNotEmpty || brandedList.isNotEmpty)
              ...buildTabViewArea(),

            if (commonList.isEmpty && brandedList.isEmpty) const Text("暂无数据")
          ],
        ),
      ),
    );
  }

  ///
  /// 跳转到食物能量和运动消耗计算页面的按钮
  ///
  Widget buildCalculateButton() {
    return TextButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NixNaturalLanguageQuery(),
          ),
        );
      },
      icon: const Icon(Icons.arrow_right),
      iconAlignment: IconAlignment.end,
      label: Text(
        "食物能量和运动消耗计算",
        style: TextStyle(fontSize: 18.sp),
      ),
    );
  }

  ///
  /// 输入框值变化时，即时快速查询数据，并显示在输入框下方
  ///
  Widget buildKeywordInputArea() {
    var cusTypeAheadField = Expanded(
      child: TypeAheadField<dynamic>(
        suggestionsCallback: (search) => getFoodItem(search),
        builder: (context, controller, focusNode) {
          return SizedBox(
            height: 48.sp,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              // 不自动聚焦，点击输入框才聚焦
              autofocus: false,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter English Food Keywords',
              ),
              onChanged: (val) {
                setState(() {
                  query = val;
                });
              },
            ),
          );
        },
        itemBuilder: (context, food) {
          if (food is NixBranded) {
            return ListTile(
              title: Text(food.foodName ?? ''),
              subtitle: Text(food.brandName ?? ''),
            );
          } else {
            return ListTile(
              title: Text((food as NixCommon).foodName ?? ''),
            );
          }
        },
        onSelected: (food) {
          // 如果直接点击了快速结果条目，直接跳转到详情
          if (food is NixBranded) {
            Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (context) => NixFoodItemNutrientPage(
                  nixItemId: food.nixItemId,
                ),
              ),
            );
          }
          if (food is NixCommon) {
            Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (context) => NixFoodItemNutrientPage(
                  foodKeyword: food.foodName,
                ),
              ),
            );
          }
        },
      ),
    );

    return Container(
      height: 80.sp,
      // color: Colors.grey[200],
      padding: EdgeInsets.all(5.sp),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          cusTypeAheadField,
          SizedBox(width: 10.sp),
          SizedBox(
            width: 80.sp,
            child: ElevatedButton(
              style: buildFunctionButtonStyle(),
              onPressed: query.isNotEmpty ? _handleSearch : null,
              child: const Text("查询"),
            ),
          ),
        ],
      ),
    );
  }

  ///
  /// 食品查询结果的tab显示区域
  ///
  List<Widget> buildTabViewArea() {
    return [
      TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Common Foods'),
          Tab(text: 'Branded Foods'),
        ],
      ),
      // 可滚动的 TabBarView
      Expanded(
        child: isLoading
            ? buildLoader(isLoading)
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildNixCommonItem(),
                  _buildNixBrandedItem(),
                ],
              ),
      ),
    ];
  }

  /// 公共食品列表，可上拉下拉刷新
  Widget _buildNixCommonItem() {
    return ListView.builder(
      itemCount: commonList.length,
      itemBuilder: (context, index) {
        var item = commonList[index];
        return ListTile(
          leading: SizedBox(
            width: 48.sp,
            child: CachedNetworkImage(
              imageUrl: item.photo?.thumb ?? '',
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
          title: Text("${item.foodName}", maxLines: 2),
          subtitle: Text("${item.servingQty} ${item.servingUnit}", maxLines: 2),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NixFoodItemNutrientPage(
                  foodKeyword: item.foodName,
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 品牌食品列表，可上拉下拉刷新
  Widget _buildNixBrandedItem() {
    return ListView.builder(
      itemCount: brandedList.length,
      itemBuilder: (context, index) {
        var item = brandedList[index];
        return ListTile(
          leading: SizedBox(
            width: 48.sp,
            child: CachedNetworkImage(
              imageUrl: item.photo?.thumb ?? '',
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
          title: Text("${item.foodName}", maxLines: 2),
          subtitle: Text(
            "${item.brandName}\n${item.servingQty} ${item.servingUnit}",
            maxLines: 2,
          ),
          trailing: Text(
            "${item.nfCalories}\nCalories",
            textAlign: TextAlign.center,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NixFoodItemNutrientPage(
                  nixItemId: item.nixItemId,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
