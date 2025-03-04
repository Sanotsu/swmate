import 'package:flutter/material.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../apis/life_tools/jikan/get_jikan_apis.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/constants/constants.dart';
import '../../../models/life_tools/jikan/jikan_data.dart';
import '_components.dart';
import 'mal_item_detail.dart';
import 'mal_anime_schedule.dart';

class MALTop extends StatefulWidget {
  const MALTop({super.key});

  @override
  State createState() => _MALTopState();
}

class _MALTopState extends State<MALTop> {
  final int pageSize = 10;
  int currentPage = 1;
  List<JKData> rankList = [];

  // 上拉下拉时的加载圈
  bool isRefreshLoading = false;
  bool hasMore = true;

  // 首次进入页面或者切换类型时的加载
  bool isLoading = false;

  // 选中的分类
  late CusLabel selectedMalType;

  // 关键字查询
  TextEditingController searchController = TextEditingController();
  String query = '';

  @override
  void initState() {
    super.initState();

    selectedMalType = malTypes.first;

    // 默认进入是top数据
    fetchMALData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // 这个是初始化页面或者切换了类型时的首次查询
  // 查询输入框有内容，就是条件查询；没有内容，就是排行榜查询(下同)
  Future<void> fetchMALData({bool isRefresh = false}) async {
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

    // 默认是top查询，也可能是关键字条件查询
    var jkRst = query.isEmpty
        ? await getJikanTop(
            type: (selectedMalType.value as MALType),
            page: currentPage,
            limit: pageSize,
          )
        : await getJikanSearch(
            q: query,
            type: (selectedMalType.value as MALType),
            page: currentPage,
            limit: pageSize,
          );

    if (!mounted) return;
    setState(() {
      if (currentPage == 1) {
        rankList = jkRst.data;
      } else {
        rankList.addAll(jkRst.data);
      }
      hasMore = jkRst.pagination?.hasNextPage ?? false;
    });

    setState(() {
      isRefresh ? isRefreshLoading = false : isLoading = false;
    });
  }

  // 动漫漫画和角色人物返回的结构不太一样
  bool isAnimeOrManga() => [MALType.anime, MALType.manga].contains(
        (selectedMalType.value as MALType),
      );

  // 关键字查询
  void _handleSearch() {
    setState(() {
      rankList.clear();
      currentPage = 1;
      query = searchController.text;
    });

    unfocusHandle();

    fetchMALData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MAL排行榜'),
        actions: [
          buildInfoButtonOnAction(
            context,
            """数据来源: [myanimelist](https://myanimelist.net/)
\n\n详情页面中提供的翻译按钮，是使用AI大模型进行文本翻译成中文，不一定准确，请注意识别。""",
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
            /// 分类下拉框
            /// 左边加个按钮获取放映计划
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// 可跳转到MAL的播放日期表(不在当前页处理了)
                buildGotoButton(context, "放映计划", const MALAnimeSchedule()),

                /// 分类下拉框
                TypeDropdown(
                  selectedValue: selectedMalType,
                  items: malTypes,
                  label: "排行榜分类:",
                  onChanged: (value) async {
                    setState(() {
                      selectedMalType = value!;
                    });
                    // 切换分类后，直接重新查询
                    _handleSearch();
                  },
                ),
              ],
            ),
            SizedBox(height: 10.sp),

            /// 关键字输入框
            KeywordInputArea(
              searchController: searchController,
              hintText: "输入关键字进行查询",
              onSearchPressed: _handleSearch,
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
                await fetchMALData(isRefresh: true);
              },
              onLoad: hasMore
                  ? () async {
                      if (!isRefreshLoading) {
                        setState(() {
                          currentPage++;
                        });
                        await fetchMALData(isRefresh: true);
                      }
                    }
                  : null,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  childAspectRatio: 2.8, // 调整子组件的宽高比
                ),
                itemCount: rankList.length,
                itemBuilder: (context, index) {
                  var item = rankList[index];

                  return buildOverviewItem(item, index);
                },
              ),
            ),
    );
  }

  Widget buildOverviewItem(JKData item, int index) {
    return OverviewItem(
      imageUrl: item.images.jpg?.imageUrl ?? "",
      title: (isAnimeOrManga() ? item.title : item.name) ?? "",
      rankWidget: (isAnimeOrManga())
          ? buildBgmScoreArea(item.score, total: item.scoredBy, rank: item.rank)
          : buildFavoritesArea(item.favorites,
              index: query.isEmpty ? index : null),
      targetPage: MALItemDetail(item: item, malType: selectedMalType),
      overviewList: [
        if ((selectedMalType.value as MALType) == MALType.anime)
          Text(
            "类别: ${item.type}(${item.episodes}集)\n放送: ${item.aired?.from?.split("T").first} ~ ${item.aired?.to?.split("T").first ?? '至今'}\n成员: ${item.members}人 最爱: ${item.favorites}人",
            maxLines: 3,
            style: TextStyle(fontSize: 12.sp),
          ),
        if ((selectedMalType.value as MALType) == MALType.manga)
          Text(
            "类别: ${item.type}(${item.volumes ?? 0}册单行本; ${item.chapters ?? 0}章)\n连载: ${item.published?.from?.split("T").first} ~ ${(item.published?.to?.split("T").first) ?? '至今'}\n成员: ${item.members}人 最爱: ${item.favorites}人",
            maxLines: 3,
            style: TextStyle(fontSize: 12.sp),
          ),
        if (!isAnimeOrManga())
          Text(
            item.about ?? "",
            maxLines: 4,
            style: TextStyle(fontSize: 12.sp),
          ),
      ],
    );
  }
}
