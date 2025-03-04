import 'package:flutter/material.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../apis/life_tools/jikan/get_jikan_apis.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/constants/constants.dart';
import '../../../models/life_tools/jikan/jikan_data.dart';
import '_components.dart';
import 'mal_item_detail.dart';

class MALAnimeSchedule extends StatefulWidget {
  const MALAnimeSchedule({super.key});

  @override
  State createState() => _MALAnimeScheduleState();
}

class _MALAnimeScheduleState extends State<MALAnimeSchedule> {
  // 暂定一行3个，所以一页查询24条(上限25)
  final int _pageSize = 24;
  int _currentPage = 1;
  // 查询的结果列表
  List<JKData> subjectList = [];

  // 上拉下拉时的加载圈
  bool _isRefreshLoading = false;
  bool _hasMore = true;

  // 首次进入页面或者切换类型时的加载
  bool isLoading = false;

  // 是否展开历史季节查询
  bool _isExpanded = false;

  /// getSeason 的筛选条件
  // 选中的年份
  int? selectedYear;
  // 选中的季节分类
  CusLabel? selectedSeasonFilter;
  // 选中的动漫分类
  CusLabel? selectedAnimeFilter;

  /// getSchedules 的筛选条件
  // 选中的周几分类
  CusLabel? selectedWeekFilter;

  @override
  void initState() {
    super.initState();

    // 默认进入是日历数据
    fetchMALScheduleData();
  }

  // 查询输入框有内容，就是条件查询；没有内容，就是播放日历查询
  // 如果是上拉下拉刷新，使用的loading标志不一样
  Future<void> fetchMALScheduleData({bool isRefresh = false}) async {
    if (isRefresh) {
      if (_isRefreshLoading) return;
      setState(() {
        _isRefreshLoading = true;
      });
    } else {
      if (isLoading) return;
      setState(() {
        isLoading = true;
      });
    }

    // 如果历史季度查询打开，点击“查询”按钮就是历史季度的: /seasons/{year}/{season}
    // 关闭就是当前播放日期表: /schedules (数据很奇怪，感觉不太对)
    // 注意，播放日期表和当前季节 /seasons/now 数据不一样，后者打开历史季度但不选择任何数据时查询
    var jkRst = _isExpanded
        ? await getJikanSingleSeason(
            year: selectedYear,
            season: (selectedSeasonFilter?.value as String?),
            filter: (selectedAnimeFilter?.value as String?),
            page: _currentPage,
            limit: _pageSize,
          )
        : await getJikanSchedules(
            filter: (selectedWeekFilter?.value as String?),
            page: _currentPage,
            limit: _pageSize,
          );

    if (!mounted) return;
    setState(() {
      if (_currentPage == 1) {
        subjectList = jkRst.data;
      } else {
        subjectList.addAll(jkRst.data);
      }
      _hasMore = jkRst.pagination?.hasNextPage ?? false;
    });

    setState(() {
      isRefresh ? _isRefreshLoading = false : isLoading = false;
    });
  }

  // 关键字查询
  void _handleSearch() {
    setState(() {
      subjectList.clear();
      _currentPage = 1;
    });

    unfocusHandle();

    fetchMALScheduleData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MAL番组计划'),
        actions: [
          buildInfoButtonOnAction(
            context,
            """默认查询最新的“每周番组”，可使用星期筛选。
\n展开“历史分季”后星期筛选无效。
\n使用“历史分季”需要同时选中“年份”和“分季”，否则查询当前季度的动漫。       
\n清空“历史分季”则查询当前季度的动漫。
\n收起“历史分季”则查询最新放映日历表。""",
          ),
        ],
      ),
      body: Column(
        children: [
          /// 分类查询区域
          buildDropdownAndQueryButtonArea(),

          /// 历史分季查询条件
          buildSeasonSelectPanel(),

          Divider(height: 20.sp),

          /// 主列表，可上拉下拉刷新
          buildRefreshList(),
        ],
      ),
    );
  }

  /// 分星期下拉框和查询按钮
  buildDropdownAndQueryButtonArea() {
    return SizedBox(
      height: 50.sp,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.sp),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Center(
                child: buildTitleText(
                  _isExpanded
                      ? (selectedYear != null && selectedSeasonFilter != null
                          ? "历史分季"
                          : "当前季度")
                      : "每周番组",
                  fontSize: 18.sp,
                ),
              ),
            ),
            SizedBox(
              width: 100.sp,
              child: buildDropdownButton2<CusLabel>(
                value: selectedWeekFilter,
                items: malWeekFilterTypes,
                hintLabel: "选择分类",
                onChanged: (value) {
                  setState(() {
                    selectedWeekFilter = value!;
                  });
                },
                itemToString: (e) => (e as CusLabel).cnLabel,
              ),
            ),
            SizedBox(width: 10.sp),
            SizedBox(
              width: 80.sp,
              child: ElevatedButton(
                style: buildFunctionButtonStyle(),
                onPressed: _handleSearch,
                child: const Text("查询"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建历史季度选择折叠栏
  Widget buildSeasonSelectPanel() {
    return Padding(
      padding: EdgeInsets.all(1.sp),
      child: ExpansionTile(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [Text('历史分季')],
        ),
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (bool expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(
                width: (1.sw - 120.sp) / 3,
                child: buildDropdownButton2<int>(
                  value: selectedYear,
                  // 这个数据其实有专门的接口getJikanSeasons，这是偷懒
                  items: List.generate(
                    DateTime.now().year - 1916 + 1,
                    (counter) => 1917 + counter,
                  ).reversed.toList(),
                  hintLabel: "年份",
                  onChanged: (value) async {
                    setState(() {
                      selectedYear = value!;
                    });
                  },
                  itemToString: (e) => (e as int).toString(),
                ),
              ),
              SizedBox(
                width: (1.sw - 120.sp) / 3,
                child: buildDropdownButton2<CusLabel>(
                  value: selectedSeasonFilter,
                  items: malSeasonFilterTypes,
                  hintLabel: "分季",
                  onChanged: (value) async {
                    setState(() {
                      selectedSeasonFilter = value!;
                    });
                  },
                  itemToString: (e) => (e as CusLabel).cnLabel,
                ),
              ),
              SizedBox(
                width: (1.sw - 120.sp) / 3,
                child: buildDropdownButton2<CusLabel>(
                  value: selectedAnimeFilter,
                  items: malAnimeFilterTypes,
                  hintLabel: "分类",
                  onChanged: (value) async {
                    setState(() {
                      selectedAnimeFilter = value!;
                    });
                  },
                  itemToString: (e) => (e as CusLabel).cnLabel,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    selectedYear = null;
                    selectedSeasonFilter = null;
                    selectedAnimeFilter = null;
                  });

                  _handleSearch();
                },
                icon: const Icon(Icons.clear),
              ),
            ],
          ),
        ],
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
                  _currentPage = 1;
                });
                await fetchMALScheduleData(isRefresh: true);
              },
              onLoad: _hasMore
                  ? () async {
                      if (!_isRefreshLoading) {
                        setState(() {
                          _currentPage++;
                        });
                        await fetchMALScheduleData(isRefresh: true);
                      }
                    }
                  : null,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 9 / 18, // 调整子组件的宽高比
                ),
                itemCount: subjectList.length,
                itemBuilder: (context, index) {
                  var item = subjectList[index];

                  return buildPreviewTileCard(
                    context,
                    item.images.jpg?.imageUrl ?? "",
                    "${item.aired?.from?.split("T").first}",
                    item.score ?? 0,
                    item.scoredBy ?? 0,
                    item.title ?? item.titleJapanese ?? "",
                    targetPage: MALItemDetail(
                      item: item,
                      // 放映默认应该只有动画
                      malType: CusLabel(cnLabel: "动画", value: MALType.anime),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
