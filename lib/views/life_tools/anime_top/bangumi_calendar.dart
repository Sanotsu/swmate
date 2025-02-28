import 'package:flutter/material.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../apis/life_tools/bangumi/bangumi_apis.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/constants/constants.dart';
import '../../../models/life_tools/bangumi/bangumi.dart';
import '_components.dart';
import 'bangumi_item_detail.dart';

class BangumiCalendar extends StatefulWidget {
  const BangumiCalendar({super.key});

  @override
  State createState() => _BangumiCalendarState();
}

class _BangumiCalendarState extends State<BangumiCalendar> {
  final int pageSize = 10;
  int currentPage = 1;
  // 查询的结果列表
  List<BGMSubject> subjectList = [];
  // 日历的结果列表
  List<BGMLargeCalendar> calendarList = [];

  // 上拉下拉时的加载圈
  bool isRefreshLoading = false;
  bool hasMore = true;

  // 首次进入页面或者切换类型时的加载
  bool isLoading = false;

  late CusLabel selectedBgmType;

  // 关键字查询
  TextEditingController searchController = TextEditingController();
  String query = '';

  @override
  void initState() {
    super.initState();

    selectedBgmType = bgmTypes[1];

    // 默认进入是日历数据
    fetchBGMData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // 查询输入框有内容，就是条件查询；没有内容，就是播放日历查询
  // 如果是上拉下拉刷新，使用的loading标志不一样
  Future<void> fetchBGMData({bool isRefresh = false}) async {
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

    // 如果是日历，则一次查询完所有，上拉下拉都重新刷新
    if (query.isEmpty) {
      var jkRst = await getBangumiCalendar();
      if (!mounted) return;
      setState(() {
        calendarList = jkRst;
        hasMore = true;
      });
    } else {
      // 否则是关键字条件查询
      var jkRst = await searchBangumiLargeSubjectByKeyword(
        query,
        type: (selectedBgmType.value as int),
        start: (currentPage - 1) * pageSize,
        maxResults: pageSize,
      );

      if (!mounted) return;
      setState(() {
        if (currentPage == 1) {
          subjectList = jkRst.list ?? [];
        } else {
          subjectList.addAll(jkRst.list ?? []);
        }
        // 是否下拉加载更多，就该当前加载的数量，是否达到了响应的限制
        hasMore = (jkRst.results ?? 0) > currentPage * pageSize;
      });
    }

    setState(() {
      isRefresh ? isRefreshLoading = false : isLoading = false;
    });
  }

  // 关键字查询
  void _handleSearch() {
    setState(() {
      subjectList.clear();
      currentPage = 1;
      query = searchController.text;
    });

    unfocusHandle();

    fetchBGMData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bangumi番组计划'),
        actions: [
          buildInfoButtonOnAction(
            context,
            "数据来源: [https://bangumi.tv](https://bangumi.tv/)",
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
            TypeDropdown(
              selectedValue: selectedBgmType,
              items: bgmTypes,
              onChanged: (value) async {
                setState(() {
                  selectedBgmType = value!;
                });
                // 因为查询必须输入关键字，所以切换时不用触发查询
                // _handleSearch();
              },
            ),

            /// 关键字输入框
            KeywordInputArea(
              searchController: searchController,
              hintText: "关键字查询，空则查询每周番组",
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
                setState(() {
                  currentPage = 1;
                });
                await fetchBGMData(isRefresh: true);
              },
              onLoad: hasMore
                  ? () async {
                      if (!isRefreshLoading) {
                        setState(() {
                          currentPage++;
                        });
                        await fetchBGMData(isRefresh: true);
                      }
                    }
                  : null,
              // 查询框为空则显示每日放送；否则就是关键字查询后的列表
              child: query.isEmpty
                  ? ListView.builder(
                      itemCount: calendarList.length,
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            Container(
                              color: Colors.lightGreen[300],
                              width: 1.sw,
                              padding: EdgeInsets.all(15.sp),
                              child: Text(
                                "${calendarList[index].weekday?.cn}(${calendarList[index].weekday?.ja})",
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            buildItemCardWrap(
                              calendarList[index],
                              selectedBgmType,
                            ),

                            /// 直接使用这个，放在一行滚动到左右边界时，会显示EasyRefresh的loading图标
                            /// 原因不清楚
                            // SingleChildScrollView(
                            //   scrollDirection: Axis.horizontal,
                            //   child: buildItemCardWrap(
                            //     calendarList[index],
                            //     selectedBgmType,
                            //   ),
                            // ),
                          ],
                        );
                      },
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                        childAspectRatio: 2.8, // 调整子组件的宽高比
                      ),
                      itemCount: subjectList.length,
                      itemBuilder: (context, index) {
                        var subject = subjectList[index];

                        return buildOverviewItem(subject, index);
                      },
                    ),
            ),
    );
  }

  /// 预览列表的条目
  Widget buildOverviewItem(BGMSubject subject, int index) {
    return OverviewItem(
      imageUrl: subject.images?.medium ?? "",
      title: (subject.nameCn != null && subject.nameCn!.isNotEmpty)
          ? subject.nameCn!
          : subject.name ?? "",
      rankWidget: buildBgmScoreArea(
        subject.rating?.score,
        total: subject.rating?.total,
        rank: subject.rank,
      ),
      targetPage: BangumiItemDetail(
        id: subject.id!,
        subType: selectedBgmType.cnLabel,
      ),
      overviewList: [
        Text(
          "类型: ${bgmTypes.where((e) => e.value == subject.type).first.cnLabel}",
          style: TextStyle(fontSize: 12.sp),
          maxLines: 1,
        ),
        Text(
          "原名: ${subject.name}",
          style: TextStyle(fontSize: 12.sp),
          maxLines: 1,
        ),
        Text(
          "首播: ${subject.airDate}",
          style: TextStyle(fontSize: 12.sp),
          maxLines: 1,
        ),
      ],
    );
  }

  /// 每日放送是查询一周七天，需要List中再嵌套一个周几的放映列表
  Widget buildItemCardWrap(
    BGMLargeCalendar calendar,
    CusLabel type,
  ) {
    return Wrap(
      // direction: Axis.horizontal,
      // alignment: WrapAlignment.spaceAround,
      children: calendar.items != null && calendar.items!.isNotEmpty
          ? List.generate(
              calendar.items!.length,
              (index) {
                var subject = calendar.items![index];
                return SizedBox(
                  height: 240.sp,
                  width: 0.325.sw,
                  child: buildPreviewTileCard(
                    context,
                    // grid和small过于小了
                    subject.images?.medium ?? "",
                    subject.airDate ?? "",
                    subject.rating?.score ?? 0,
                    subject.rating?.total ?? 0,
                    (subject.nameCn != null && subject.nameCn!.isNotEmpty)
                        ? subject.nameCn!
                        : subject.name ?? "",
                    targetPage: BangumiItemDetail(
                      id: subject.id!,
                      subType: type.cnLabel,
                    ),
                  ),
                );
              },
            ).toList()
          : [],
    );
  }
}
