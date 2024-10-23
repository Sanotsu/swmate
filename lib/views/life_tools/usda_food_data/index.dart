import 'package:flutter/material.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../apis/usda_food_data_central/usda_food_data_apis.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/constants.dart';
import '../../../models/usda_food_data/usda_food_item.dart';
import '../anime_top/_components.dart';
import 'food_item_nutrients.dart';

// 主要用来区分不同数据源返回的结构不太，因此显示的栏位不同
enum UDSADataType {
  foundation,
  branded,
  survey,
  legacy,
}

List<CusLabel> usdaDataTypes = [
  CusLabel(
    cnLabel: "Foundation Foods",
    enLabel: UDSADataType.foundation.name,
    value: "Foundation",
  ),
  CusLabel(
    cnLabel: "SR Legacy Foods",
    enLabel: UDSADataType.legacy.name,
    value: "SR Legacy",
  ),
  CusLabel(
    cnLabel: "Survey Foods(FNDDS)",
    enLabel: UDSADataType.survey.name,
    value: "Survey (FNDDS)",
  ),
  CusLabel(
    cnLabel: "Branded Foods",
    enLabel: UDSADataType.branded.name,
    value: "Branded",
  ),
];

class USDAFoodDataCentral extends StatefulWidget {
  const USDAFoodDataCentral({super.key});

  @override
  State createState() => _USDAFoodDataCentralState();
}

class _USDAFoodDataCentralState extends State<USDAFoodDataCentral> {
  final int pageSize = 10;
  int currentPage = 1;
  List<USDAFoodItem> rankList = [];
  int? total;

  // 上拉下拉时的加载圈
  bool isRefreshLoading = false;
  bool hasMore = true;

  // 首次进入页面或者切换类型时的加载
  bool isLoading = false;

  // 选中的分类
  late CusLabel selectedUSDADataType;

  // 关键字查询
  TextEditingController searchController = TextEditingController();
  String query = '';

  String note = """
数据来源: [美国农业部食品数据中心(USDA FoodData Central)](https://fdc.nal.usda.gov/data-documentation.html)
\n\n“数据类型”官方文档: (https://fdc.nal.usda.gov/data-documentation.html)

定义分别如下：

| Data Type      | Definition  |
| ----------- | ------------------------------ |
| Foundation Foods    | Data and metadata on individual samples of commodity/commodity-derived minimally processed foods with insights into variability       |
| SR Legacy Foods     | Historic data on food components including nutrients derived from analyses, calculations, and published literature    |
| Survey Foods(FNDDS) | Data on nutrients and portion weights for foods and beverages reported in What We Eat in America, NHANES        |
| Branded Foods       | Data from labels of national and international branded foods collected by a public-private partnership     |
""";

  @override
  void initState() {
    super.initState();

    selectedUSDADataType = usdaDataTypes.first;

    fetchUSDAFoodData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // 这个是初始化页面或者切换了类型时的首次查询
  // 查询输入框有内容，就是条件查询；没有内容，就是排行榜查询(下同)
  Future<void> fetchUSDAFoodData({bool isRefresh = false}) async {
    if (isRefresh) {
      if (isRefreshLoading) return;
      setState(() {
        isRefreshLoading = true;
      });
    } else {
      if (isLoading) return;
      setState(() {
        isLoading = true;
      });
    }

    // 关键字条件查询，可以指定数据类型
    var usdaRst = await searchUSDAFoods(
      query,
      dataType: [selectedUSDADataType.value],
      pageNumber: currentPage,
      pageSize: pageSize,
    );

    if (!mounted) return;
    setState(() {
      if (currentPage == 1) {
        rankList = usdaRst.foods;
      } else {
        rankList.addAll(usdaRst.foods);
      }
      hasMore = usdaRst.totalPages > currentPage;

      total = usdaRst.totalHits;
    });

    setState(() {
      isRefresh ? isRefreshLoading = false : isLoading = false;
    });
  }

  // 关键字查询
  void _handleSearch() {
    setState(() {
      rankList.clear();
      currentPage = 1;
      query = searchController.text;
    });

    unfocusHandle();

    fetchUSDAFoodData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('USDA食品数据中心'),
        actions: [
          buildInfoButtonOnAction(context, note),
        ],
      ),
      body: GestureDetector(
        // 允许子控件（如TextField）接收点击事件
        behavior: HitTestBehavior.translucent,
        // 点击空白处可以移除焦点，关闭键盘
        onTap: unfocusHandle,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// 分类下拉框
                TypeDropdown(
                  selectedValue: selectedUSDADataType,
                  items: usdaDataTypes,
                  label: "数据类型:",
                  width: 200.sp,
                  onChanged: (value) async {
                    setState(() {
                      selectedUSDADataType = value!;
                    });
                    // 切换分类后，直接重新查询
                    _handleSearch();
                  },
                ),
                // 显示已加载数量和总数量
                if (total != null)
                  Expanded(
                    child: Text(
                      "${rankList.length}/$total",
                      style: TextStyle(fontSize: 10.sp),
                      textAlign: TextAlign.end,
                    ),
                  ),

                SizedBox(width: 5.sp),
              ],
            ),
            SizedBox(height: 10.sp),

            /// 关键字输入框
            KeywordInputArea(
              searchController: searchController,
              hintText: "Input English keywords",
              onSearchPressed: _handleSearch,
              height: 48.sp,
            ),

            Divider(height: 20.sp),

            /// 主列表，可上拉下拉刷新
            buildRefreshList(),
          ],
        ),
      ),
    );
  }

  /// 主列表，可上拉下拉刷新
  buildRefreshList() {
    return Expanded(
      child: isLoading
          ? buildLoader(isLoading)
          : EasyRefresh(
              header: const ClassicHeader(),
              footer: const ClassicFooter(),
              onRefresh: () async {
                currentPage = 1;
                await fetchUSDAFoodData(isRefresh: true);
              },
              onLoad: hasMore
                  ? () async {
                      if (!isRefreshLoading) {
                        setState(() {
                          currentPage++;
                        });
                        await fetchUSDAFoodData(isRefresh: true);
                      }
                    }
                  : null,
              child: ListView.builder(
                itemCount: rankList.length,
                itemBuilder: (context, index) {
                  var item = rankList[index];

                  return buildOverviewItem(item, index);
                },
              ),
            ),
    );
  }

  Widget buildOverviewItem(USDAFoodItem item, int index) {
    // return ListTile(
    //   title: Text(
    //     "${item.fdcId}",
    //     maxLines: 4,
    //     style: TextStyle(fontSize: 12.sp),
    //   ),
    //   subtitle: Text(
    //     item.description,
    //     maxLines: 4,
    //     style: TextStyle(fontSize: 12.sp),
    //   ),
    // );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => USDAFoodItemNutrientPage(fdcId: item.fdcId),
          ),
        );
      },
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(5.sp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.start,
              ),

              ...buildItemDetails(item),
              // 几个atatype都有的测试栏位
              // Text(
              //   "食品编号：${item.fdcId}",
              //   style: TextStyle(fontSize: 12.sp),
              // ),
              // Text(
              //   "匹配程度：${item.score}",
              //   style: TextStyle(fontSize: 12.sp),
              // ),
              // Text(
              //   "发布日期：${item.publishedDate}",
              //   style: TextStyle(fontSize: 12.sp),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> buildItemDetails(USDAFoodItem item) {
    // Foundation Foods展示栏位：
    // NDB Number;	Description;	Most Recent Acquisition Date;	SR/Foundation Food Category
    if (selectedUSDADataType.enLabel == UDSADataType.foundation.name) {
      return [
        Text(
          "NDB编号：${item.ndbNumber}",
          style: TextStyle(fontSize: 12.sp),
        ),
        Text(
          "获取时间：${item.mostRecentAcquisitionDate}",
          style: TextStyle(fontSize: 12.sp),
        ),
        Text(
          "食品类别：${item.foodCategory}",
          style: TextStyle(fontSize: 12.sp),
        ),
      ];
    } else if (selectedUSDADataType.enLabel == UDSADataType.legacy.name) {
      return [
        Text(
          "NDB编号：${item.ndbNumber}",
          style: TextStyle(fontSize: 12.sp),
        ),
        Text(
          "食品类别：${item.foodCategory}",
          style: TextStyle(fontSize: 12.sp),
        ),
      ];
    }

    // Survey Foods (FNDDS)展示栏位：
    // Food Code;	Main Food Description;	Additional Food Description;	WWEIA Food Category
    else if (selectedUSDADataType.enLabel == UDSADataType.survey.name) {
      return [
        Text(
          "食品编号：${item.foodCode}",
          style: TextStyle(fontSize: 12.sp),
        ),
        Text(
          "额外描述：${item.additionalDescriptions}",
          style: TextStyle(fontSize: 12.sp),
        ),
        Text(
          "食品类别：${item.foodCategory}",
          style: TextStyle(fontSize: 12.sp),
        ),
      ];
    }

    // Branded Foods 展示栏位：
    // GTIN/UPC;	Description;	Branded Food Category;	Brand Owner;	Brand;	Market Country
    else if (selectedUSDADataType.enLabel == UDSADataType.branded.name) {
      return [
        Text(
          "通用条码：${item.gtinUpc}",
          style: TextStyle(fontSize: 12.sp),
        ),
        Text(
          "食品类别：${item.foodCategory}",
          style: TextStyle(fontSize: 12.sp),
        ),
        Text(
          "品牌持有：${item.brandOwner}",
          style: TextStyle(fontSize: 12.sp),
        ),
        Text(
          "品牌名称：${item.brandName}",
          style: TextStyle(fontSize: 12.sp),
        ),
        Text(
          "品牌市场：${item.marketCountry}",
          style: TextStyle(fontSize: 12.sp),
        ),
      ];
    } else {
      return [];
    }
  }
}
