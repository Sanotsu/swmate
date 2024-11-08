import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../apis/news/newsapi_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/constants.dart';
import '../../../../common/utils/dio_client/interceptor_error.dart';
import '../../../../common/utils/tools.dart';
import '../../../../models/news/news_api_resp.dart';
import '../../anime_top/_components.dart';

///
/// 2024-11-06 newsapi 请求的数据
/// 免费版本，新闻会滞后1天，且每天100次请求限制，且只能看到最近1个月的新闻，且大陆无法访问
/// business entertainment general health science sports technology
List<CusLabel> newsapiCategorys = [
  CusLabel(cnLabel: "新闻", value: "general"),
  CusLabel(cnLabel: "商业", value: "business"),
  CusLabel(cnLabel: "娱乐", value: "entertainment"),
  CusLabel(cnLabel: "健康", value: "health"),
  CusLabel(cnLabel: "科学", value: "science"),
  CusLabel(cnLabel: "体育", value: "sports"),
  CusLabel(cnLabel: "科技", value: "technology"),
];

class NewsApiIndex extends StatefulWidget {
  const NewsApiIndex({super.key});

  @override
  State createState() => _NewsApiIndexState();
}

class _NewsApiIndexState extends State<NewsApiIndex> {
  final int _pageSize = 100;
  int _currentPage = 1;

  // 查询的结果列表
  List<NewsApiArticle> _newsapiList = [];
  // 保存新闻是否被点开(点开了可以看到更多内容)
  List<bool> _isExpandedList = [];

  // 上拉下拉时的加载圈
  bool _isRefreshLoading = false;
  bool _hasMore = true;

  // 首次进入页面或者切换类型时的加载
  bool _isLoading = false;

  late CusLabel selectedBgmType;

  // 是否点击了搜索(点击了之后才显示搜索框，否则不显示)
  bool _isClickSearch = false;
  // 关键字查询
  TextEditingController searchController = TextEditingController();
  String query = '';

  // 产品列表的滚动控制器(滚动到左右两边时显示箭头图标)
  ScrollController prodSelController = ScrollController();
  // 当前被选中的产品索引(默认选中第一个，全部)
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    selectedBgmType = newsapiCategorys[0];

    prodSelController.addListener(_prodScrollCtrlListener);

    fetchHotTopicData();
  }

  // 产品分类滚动监听
  void _prodScrollCtrlListener() {
    setState(() {});
  }

  @override
  void dispose() {
    searchController.dispose();
    prodSelController.removeListener(_prodScrollCtrlListener);
    super.dispose();
  }

  // isRefresh 是上下拉的时候的刷新，初始化进入页面时就为false，展示加载圈位置不一样
  Future<void> fetchHotTopicData({bool isRefresh = false}) async {
    if (isRefresh) {
      if (_isRefreshLoading) return;
      setState(() {
        _isRefreshLoading = true;
      });
    } else {
      if (_isLoading) return;
      setState(() {
        _isLoading = true;
      });
    }

    // 否则是关键字条件查询
    try {
      // 2024-11-06 为了简单点，有输入就是查询everything的接口，不输入就是热点
      NewsApiResp htRst;
      if (query.isNotEmpty) {
        htRst = await getNewsapiList(
          query: query,
          type: "everything",
          pageSize: _pageSize,
          page: _currentPage,
        );
      } else {
        // 如果查询条件为空，就自动关闭查询输入框，展示分类栏
        setState(() {
          _isClickSearch = false;
        });

        htRst = await getNewsapiList(
          category: (selectedBgmType.value as String),
          pageSize: _pageSize,
          page: _currentPage,
        );
      }

      if (!mounted) return;
      setState(() {
        if (_currentPage == 1) {
          _newsapiList = htRst.articles ?? [];
        } else {
          _newsapiList.addAll(htRst.articles ?? []);
        }

        // 结果中可能存存remove的内容，要过滤掉
        _newsapiList =
            _newsapiList.where((i) => i.title != "[Removed]").toList();

        // 2024-11-06 免费用户只能查看100条新闻(在这里就只有1页)
        _hasMore = _pageSize * _currentPage >= 100 ? false : true;

        // 重新加载新闻列表都是未加载的状态
        _isExpandedList = List.generate(_newsapiList.length, (index) => false);
      });
    } on CusHttpException catch (e) {
      // API请求报错，显示报错信息
      // http连接相关的报错在拦截器就有弹窗报错了，这里暂时不显示了
      // showSnackMessage(context, e.cusMsg);
      debugPrint(e.toString());
    } catch (e) {
      // EasyLoading.showError(e.toString());
    } finally {
      setState(() {
        isRefresh ? _isRefreshLoading = false : _isLoading = false;
      });
    }
  }

  // 关键字查询
  void _handleSearch() {
    setState(() {
      _newsapiList.clear();
      _currentPage = 1;
      query = searchController.text;
    });

    unfocusHandle();

    fetchHotTopicData();
  }

  // 当产品被选中时进行查询
  void onProductTypeSelected(int index) {
    setState(() {
      _selectedIndex = index;
      selectedBgmType = newsapiCategorys[index];
    });

    _handleSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NewsAPI新闻'),
        actions: [
          IconButton(
            onPressed: () {
              // 如果点击之前是可搜索的，那么点击之后就是不可搜索(分类显示)，则清空输入
              setState(() {
                _isClickSearch = !_isClickSearch;

                if (!_isClickSearch) {
                  query = "";
                  searchController.text = "";
                }
              });
            },
            icon: Icon(
              _isClickSearch ? Icons.close : Icons.search,
            ),
          ),
          IconButton(
            onPressed: () {
              commonMDHintModalBottomSheet(
                context,
                "说明",
                """数据来源：[NewsAPI](https://newsapi.org/)
\n目前为免费订阅版本，该API不完全限制如下：
- **国内无法直接访问**
- 新闻滞后24小时
- 新闻搜索区间最近1个月内
- 每天累计请求上限100次
- 每个请求数据上限100条
                """,
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
            /// 关键字输入框
            if (_isClickSearch)
              SizedBox(
                height: 35.sp,
                child: KeywordInputArea(
                  searchController: searchController,
                  hintText: "Enter keywords",
                  onSearchPressed: _handleSearch,
                ),
              ),

            if (!_isClickSearch && query.isEmpty)
              buildCategorySelectionWithScroll(),

            Divider(),

            buildRefreshList(),
          ],
        ),
      ),
    );
  }

  /// 主列表，可上拉下拉刷新
  buildRefreshList() {
    return Expanded(
      child: _isLoading
          ? buildLoader(_isLoading)
          : EasyRefresh(
              header: const ClassicHeader(),
              footer: const ClassicFooter(),
              onRefresh: () async {
                setState(() {
                  _currentPage = 1;
                });
                await fetchHotTopicData(isRefresh: true);
              },
              onLoad: _hasMore
                  ? () async {
                      if (!_isRefreshLoading) {
                        setState(() {
                          _currentPage++;
                        });
                        await fetchHotTopicData(isRefresh: true);
                      }
                    }
                  : null,
              // 查询框为空则显示每日放送；否则就是关键字查询后的列表
              child: _newsapiList.isEmpty
                  ? ListView(
                      padding: EdgeInsets.all(8.sp),
                      children: <Widget>[
                        Center(child: Text("暂无数据")),
                      ],
                    )
                  : ListView.builder(
                      itemCount: _newsapiList.length,
                      itemBuilder: (context, index) {
                        return buildHotTopicCard(_newsapiList[index], index);
                      },
                    ),
            ),
    );
  }

  /// 热点话题新闻卡片
  Widget buildHotTopicCard(
    NewsApiArticle item,
    int index,
  ) {
    // 记录当前新闻是否被点开
    bool isExpanded = _isExpandedList[index];

    // 卡片在展开时和未展开时背景、边框、阴影等都稍微有点区别
    return Card(
      elevation: isExpanded ? 5 : 0,
      color: isExpanded ? null : Theme.of(context).canvasColor,
      shape: isExpanded
          ? null
          : RoundedRectangleBorder(
              // 未展开时取消圆角
              borderRadius: BorderRadius.zero,
            ),
      child: ExpansionTile(
        showTrailingIcon: false,
        initiallyExpanded: isExpanded,
        // 展开内容的交叉轴对齐方式
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        // 折叠栏展开后不显示上下边框线
        shape: const Border(),
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpandedList[index] = expanded;
          });
        },
        // 减少标题和子标题的 padding
        tilePadding: EdgeInsets.all(5.sp),
        // 减少展开后的内容区域的 padding
        // childrenPadding: EdgeInsets.all(0.sp),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    // "${index + 1} ${item.title}",
                    item.title ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ),
                Container(
                  width: 100.sp,
                  padding: EdgeInsets.only(left: 5.sp),
                  height: 70.sp,
                  child: buildNetworkOrFileImage(
                    item.urlToImage ?? '',
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),

            /// 发布时间和文章作者
            Container(
              padding: EdgeInsets.symmetric(vertical: 2.sp),
              child: RichText(
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: formatDateTimeString(item.publishedAt ?? ""),
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12.sp,
                      ),
                    ),
                    TextSpan(
                      text: "\t\t\t\t${item.author ?? ''}",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        /// 文章的描述(未点击时显示2行，点击展开后显示全部)
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                item.description ?? '',
                maxLines: isExpanded ? null : 2,
                overflow: isExpanded ? null : TextOverflow.ellipsis,
                style: TextStyle(
                  color: isExpanded ? null : Colors.black54,
                  fontSize: 14.sp,
                ),
                // 新闻总结文字两端对齐
                textAlign: TextAlign.justify,
              ),
            ),
          ],
        ),
        // 2024-11-06 这里content的内容似乎意义不大，
        // 而且在easy-refresh里面使用SingleChildScrollView，上下拉刷新会出现问题
        // 所以这里不显示了，点击展开只是多看点简介内容
        children: [
          /// 点击展开后，可跳转到源网页查看原文
          ListTile(
            title: Text(
              '来源: ${item.source?.name ?? item.source?.id ?? ""}',
              style: TextStyle(
                // 添加下划线
                decoration: TextDecoration.underline,
                decorationColor: Colors.blue,
                decorationThickness: 2.sp,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward,
              color: Theme.of(context).primaryColor,
            ),
            onTap: () => launchStringUrl(item.url ?? ''),
          ),
          // SizedBox(
          //   height: 100.sp,
          //   child: SingleChildScrollView(
          //     child: MarkdownBody(
          //       data: item.content,
          //       selectable: true,
          //       styleSheet: MarkdownStyleSheet(
          //         p: TextStyle(color: Colors.grey),
          //       ),
          //     ),
          //   ),
          // )
        ],
      ),
    );
  }

  Widget buildCategorySelectionWithScroll() {
    // 检查产品筛选滚动条是否有滚动位置信息，并且是否可以向左或向右滚动
    final canScrollLeft = prodSelController.positions.isNotEmpty &&
        prodSelController.position.pixels > 0;
    final canScrollRight = prodSelController.positions.isNotEmpty &&
        prodSelController.position.pixels <
            prodSelController.position.maxScrollExtent;

    /// 使用 InkWell 可以比较容易自定义样式
    return SizedBox(
      height: 35.sp,
      child: Row(
        children: [
          if (canScrollLeft)
            IconButton(
              icon: const Icon(Icons.arrow_left),
              onPressed: () {
                // 每次点击滚动一个60
                prodSelController.animateTo(
                  prodSelController.position.pixels - 60.sp,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          Expanded(
            child: ListView.builder(
              controller: prodSelController,
              scrollDirection: Axis.horizontal,
              itemCount: newsapiCategorys.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.sp),
                  child: InkWell(
                    onTap: () => onProductTypeSelected(index),
                    child: Container(
                      width: 60.sp,
                      height: 30.sp,
                      padding: EdgeInsets.all(1.sp),
                      decoration: BoxDecoration(
                        color: _selectedIndex == index
                            ? Colors.blue[100]
                            : Colors.white,
                        borderRadius: BorderRadius.circular(5.sp),
                        border: Border.all(color: Colors.grey, width: 1.sp),
                      ),
                      child: Center(
                        child: Text(
                          newsapiCategorys[index].cnLabel,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (canScrollRight)
            IconButton(
              icon: const Icon(Icons.arrow_right),
              onPressed: () {
                prodSelController.animateTo(
                  // 每次点击滚动一个60
                  prodSelController.position.pixels + 60.sp,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
        ],
      ),
    );
  }
}
