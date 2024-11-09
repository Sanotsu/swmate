import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../common/components/tool_widget.dart';
import '../../../../common/constants.dart';

import '../../anime_top/_components.dart';
import '../_components/cus_scrollable_category_list.dart';

///
/// T 是新闻列表页面, U 是新闻条目
///
abstract class BaseNewsPageState<T extends StatefulWidget, U> extends State<T> {
  final int pageSize = 100;
  int currentPage = 1;

  // 查询的结果列表
  List<dynamic> newsList = [];
  // 保存新闻是否被点开(点开了可以看到更多内容)
  List<bool> isExpandedList = [];

  // 上拉下拉时的加载圈
  bool isRefreshLoading = false;
  bool hasMore = true;

  // 首次进入页面或者切换类型时的加载
  bool isLoading = false;

  // 被选中的分类
  late CusLabel selectedCategory;

  // 分类列表的滚动控制器(滚动到左右两边时显示箭头图标)
  ScrollController scrollController = ScrollController();
  // 当前被选中的分类索引(默认选中第一个，全部)
  int _selectedIndex = 0;

  ///
  /// 可关键搜索（newsapi有，新浪滚动新闻没有）
  ///
  // 页面是否显示搜索框
  bool get showSearchBox;
  // 是否点击了搜索(点击了之后才显示搜索框，否则不显示)
  bool isClickSearch = false;
  // 关键字查询
  TextEditingController searchController = TextEditingController();
  String query = '';

  @override
  void initState() {
    super.initState();
    selectedCategory = getCategories()[0];
    scrollController.addListener(_scrollListener);
    fetchNewsData();
  }

  // 分类分类滚动监听
  void _scrollListener() {
    setState(() {});
  }

  @override
  void dispose() {
    searchController.dispose();
    scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  // 获取分类列表
  List<CusLabel> getCategories();

  // 获取新闻数据
  // isRefresh 是上下拉的时候的刷新，初始化进入页面时就为false，展示加载圈位置不一样
  Future<void> fetchNewsData({bool isRefresh = false});

  // 处理分类选择
  void _onCategorySelected(int index) {
    setState(() {
      _selectedIndex = index;
      selectedCategory = getCategories()[index];
    });
    _handleSearch();
  }

  // 处理搜索
  void _handleSearch() {
    setState(() {
      newsList.clear();
      currentPage = 1;
      query = searchController.text;
    });
    unfocusHandle();
    fetchNewsData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getAppBarTitle()),
        actions: [
          // 如果点击之前是可搜索的，那么点击之后就是不可搜索(分类显示)，则清空输入
          if (showSearchBox)
            IconButton(
              onPressed: () {
                setState(() {
                  isClickSearch = !isClickSearch;

                  if (!isClickSearch) {
                    query = "";
                    searchController.text = "";
                  }
                });
              },
              icon: Icon(
                isClickSearch ? Icons.close : Icons.search,
              ),
            ),
          IconButton(
            onPressed: () {
              commonMDHintModalBottomSheet(
                context,
                "说明",
                getInfoMessage(),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 如果有查询功能，且选中了显示输入框，则显示输入框
            if (showSearchBox && isClickSearch)
              SizedBox(
                height: 35.sp,
                child: KeywordInputArea(
                  searchController: searchController,
                  hintText: "Enter keywords",
                  onSearchPressed: _handleSearch,
                ),
              ),

            // 如果没有查询功能，或者点击了输入框是显示的但输入框的内容是空的，就显示分类滚动
            if (!showSearchBox || (!isClickSearch && query.isEmpty))
              CusScrollableCategoryList(
                scrollController: scrollController,
                categories: getCategories(),
                selectedIndex: _selectedIndex,
                onCategorySelected: _onCategorySelected,
              ),
            Divider(),
            buildRefreshList(),
          ],
        ),
      ),
    );
  }

  /// 主列表，可上拉下拉刷新
  Widget buildRefreshList() {
    return Expanded(
      child: isLoading
          ? buildLoader(isLoading)
          : EasyRefresh(
              header: const ClassicHeader(),
              footer: const ClassicFooter(),
              onRefresh: () async {
                setState(() {
                  currentPage = 1;
                });
                await fetchNewsData(isRefresh: true);
              },
              onLoad: hasMore
                  ? () async {
                      if (!isRefreshLoading) {
                        setState(() {
                          currentPage++;
                        });
                        await fetchNewsData(isRefresh: true);
                      }
                    }
                  : null,
              // 查询框为空则显示每日放送；否则就是关键字查询后的列表
              child: newsList.isEmpty
                  ? ListView(
                      padding: EdgeInsets.all(8.sp),
                      children: <Widget>[
                        Center(child: Text("暂无数据")),
                      ],
                    )
                  : ListView.builder(
                      itemCount: newsList.length,
                      itemBuilder: (context, index) {
                        var item = newsList[index];
                        return buildNewsCard(item, index);
                      },
                    ),
            ),
    );
  }

  // 构建新闻卡片
  Widget buildNewsCard(U item, int index);

  // 获取AppBar标题
  String getAppBarTitle();

  // 获取信息提示内容
  String getInfoMessage();
}
