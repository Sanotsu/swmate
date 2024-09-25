import 'package:flutter/material.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter_rating_stars/flutter_rating_stars.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../apis/bangumi/bangumi_apis.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/constants.dart';
import '../../../models/bangumi/bangumi.dart';
import 'bangumi_item_detail.dart';

// bangumi 可排名的有1 = book, 2 = anime, 3 = music, 4 = game, 6 = real.没有5
List<CusLabel> bgmTypes = [
  CusLabel(cnLabel: "书籍", value: 1),
  CusLabel(cnLabel: "动画", value: 2),
  CusLabel(cnLabel: "音乐", value: 3),
  CusLabel(cnLabel: "游戏", value: 4),
  CusLabel(cnLabel: "三次元", value: 6),
];

///
/// 动漫推荐，进来就是bangumi的放送日历，可切换MAL的Schedule
///   点击日历中的item跳转到对应的详情页面去
///
/// 然后可点击指定按钮，跳转到自定义的bangumi详情页面
///
class BangumiCalendar extends StatefulWidget {
  const BangumiCalendar({super.key});

  @override
  State createState() => _BangumiCalendarState();
}

class _BangumiCalendarState extends State<BangumiCalendar> {
  final int _pageSize = 10;
  int _currentPage = 1;
  // 查询的结果列表
  List<BGMSubject> subjectList = [];
  // 日历的结果列表
  List<BGMLargeCalendar> calendarList = [];
  // 上拉下拉时的加载圈
  bool _isRefreshLoading = false;
  bool _hasMore = true;

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
    fetchBgmData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // 查询输入框有内容，就是条件查询；没有内容，就是播放日历查询
  // 如果是上拉下拉刷新，使用的loading标志不一样
  Future<void> fetchBgmData({bool isRefresh = false}) async {
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

    // 如果是日历，则一次查询完所有，上拉下拉都重新刷新
    if (query.isEmpty) {
      var jkRst = await getBangumiCalendar();
      setState(() {
        calendarList = jkRst;
        _hasMore = true;
      });
    } else {
      // 否则是关键字条件查询
      var jkRst = await searchBangumiLargeSubjectByKeyword(
        query,
        type: (selectedBgmType.value as int),
        start: (_currentPage - 1) * _pageSize,
        maxResults: _pageSize,
      );

      setState(() {
        if (_currentPage == 1) {
          subjectList = jkRst.list ?? [];
        } else {
          subjectList.addAll(jkRst.list ?? []);
        }
        // 是否下拉加载更多，就该当前加载的数量，是否达到了响应的限制
        _hasMore = (jkRst.results ?? 0) > _currentPage * _pageSize;
      });
    }

    setState(() {
      isRefresh ? _isRefreshLoading = false : isLoading = false;
    });
  }

  // 关键字查询
  void _handleSearch() {
    setState(() {
      subjectList.clear();
      _currentPage = 1;
      query = searchController.text;
    });

    unfocusHandle();

    fetchBgmData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bangumi放映'),
        actions: [
          IconButton(
            onPressed: () async {
              // var b = BgmParam(
              //   keyword: "超人",
              //   filter: BGMFilter(tag: ["童年", "原创"]),
              // );
              // var a = await getBangumiSubject(b);
              // print(a.runtimeType);

              // await getBangumiSubjectById(2);
              // var rr = await searchBangumiLargeSubjectByKeyword("");

              var rr = await getBangumiCalendar();

              print(rr.first.toRawJson());
            },
            icon: const Icon(Icons.info_outline),
          ),
          IconButton(
            onPressed: () {
              commonMDHintModalBottomSheet(
                context,
                "说明",
                "数据来源[bangumi](https://bangumi.tv/)",
                msgFontSize: 15.sp,
              );
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          /// 分类下拉框
          buildTypeDropdown(),

          /// 关键字输入框
          buildKeywordInputArea(),

          Divider(height: 5.sp),

          /// 主列表，可上拉下拉刷新
          buildRefreshList(),
        ],
      ),
    );
  }

  /// 分类下拉框
  buildTypeDropdown() {
    return Padding(
      padding: EdgeInsets.all(5.sp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "分类: ",
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            width: 80.sp,
            child: buildDropdownButton2<CusLabel>(
              value: selectedBgmType,
              items: bgmTypes,
              hintLable: "选择分类",
              onChanged: (value) async {
                setState(() {
                  selectedBgmType = value!;
                });
                // 因为查询必须输入关键字，所以切换时不用触发查询
                // _handleSearch();
              },
              itemToString: (e) => (e as CusLabel).cnLabel,
            ),
          ),
        ],
      ),
    );
  }

  /// 关键字输入框
  buildKeywordInputArea() {
    return SizedBox(
      height: 32.sp,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.sp),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "关键字查询，空则查询每日放送",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // 边框圆角
                    borderSide: const BorderSide(
                      color: Colors.blue, // 边框颜色
                      width: 2.0, // 边框宽度
                    ),
                  ),
                  contentPadding: EdgeInsets.only(left: 10.sp),
                  // 设置透明底色
                  filled: true,
                  fillColor: Colors.transparent,
                ),
              ),
            ),
            SizedBox(width: 10.sp),
            SizedBox(
              width: 80.sp,
              child: ElevatedButton(
                style: buildFunctionButtonStyle(),
                onPressed: _handleSearch,
                child: const Text("搜索"),
              ),
            ),
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
                  _currentPage = 1;
                });
                await fetchBgmData(isRefresh: true);
              },
              onLoad: _hasMore
                  ? () async {
                      if (!_isRefreshLoading) {
                        setState(() {
                          _currentPage++;
                        });
                        await fetchBgmData(isRefresh: true);
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
                              context,
                              calendarList[index],
                              selectedBgmType,
                            ),

                            /// 直接使用这个，放在一行滚动到左右边界时，会显示EasyRefresh的loading图标
                            /// 原因不清楚
                            // SingleChildScrollView(
                            //   scrollDirection: Axis.horizontal,
                            //   child: buildItemCardWrap(
                            //     context,
                            //     calendarList[index],
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
                        return buildItemCard(
                          context,
                          subjectList[index],
                          selectedBgmType,
                        );
                      },
                    ),
            ),
    );
  }
}

/// 每日放送是查询一周七天，需要List中再嵌套一个周几的放映列表
Widget buildItemCardWrap(
  BuildContext context,
  BGMLargeCalendar calendar,
  CusLabel type,
) {
  return Wrap(
    // direction: Axis.horizontal,
    // alignment: WrapAlignment.spaceAround,
    children: calendar.items != null && calendar.items!.isNotEmpty
        ? List.generate(
            calendar.items!.length,
            (index) => SizedBox(
              height: 240.sp,
              width: 0.325.sw,
              child: buildTileCard(
                context,
                calendar.items![index],
                type,
              ),
            ),
          ).toList()
        : [],
  );
}

/// 网格，预览图+名称，一排可以多个
Widget buildTileCard(
  BuildContext context,
  BGMSubject subject,
  CusLabel type,
) {
  return GestureDetector(
    // 单击预览
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BangumiItemDetail(
            id: subject.id!,
            type: type,
          ),
        ),
      );
    },
    child: Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// 预览图片
          SizedBox(
            height: 150.sp,
            child: Padding(
              padding: EdgeInsets.all(2.sp),
              child: buildImageGridTile(
                context,
                subject.images?.medium ?? "",
                prefix: "bangumi",
                fit: BoxFit.cover,
              ),
            ),
          ),
          Flexible(
            child: Column(
              children: [
                /// 开播时间
                Text(
                  "开播 ${subject.airDate}",
                  maxLines: 1,
                  style: TextStyle(fontSize: 10.sp),
                  textAlign: TextAlign.center,
                ),

                /// 评分
                // Transform.scale(
                //   scale: 0.5,
                //   child: Expanded(
                //     child: buildScoreArea(
                //       subject.rating?.score ?? 0,
                //       total: subject.rating?.total ?? 0,
                //     ),
                //   ),
                // ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${subject.rating?.score ?? 0}",
                      style: TextStyle(fontSize: 15.sp),
                    ),
                    SizedBox(width: 5.sp),
                    Column(
                      children: [
                        RatingStars(
                          axis: Axis.horizontal,
                          value: subject.rating?.score ?? 0,
                          starCount: 5,
                          starSize: 12.sp,
                          starSpacing: 2.sp,
                          // 评分的最大值
                          maxValue: 10,
                          starOffColor: Colors.grey[300]!,
                          // 填充时的星星颜色
                          starColor: Colors.orange,
                          // 不显示评分的文字，只显示星星
                          valueLabelVisibility: false,
                        ),
                        Text(
                          "${subject.rating?.total ?? 0} 评价",
                          style: TextStyle(fontSize: 10.sp),
                        ),
                      ],
                    )
                  ],
                ),

                /// 标题
                Text(
                  subject.nameCn ?? "",
                  // 大部分的标题2行可以显示，查看完整的还是进入详情页面吧
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// 这些可能后续可以复用
/// 列表，左侧图片，右侧简介，一般一排一个
Widget buildItemCard(
  BuildContext context,
  BGMSubject subject,
  CusLabel type,
) {
  return GestureDetector(
    // 单击预览
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BangumiItemDetail(
            id: subject.id!,
            type: type,
          ),
        ),
      );
    },
    child: Card(
      margin: EdgeInsets.all(5.sp),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.all(2.sp),
              child: buildImageGridTile(
                context,
                subject.images?.medium ?? "",
                prefix: "bangumi",
                fit: BoxFit.scaleDown,
              ),
            ),
          ),
          SizedBox(width: 10.sp),
          Flexible(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    subject.nameCn ?? "",
                    // 大部分的标题1行可以显示，查看完整的还是进入详情页面吧
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ),
                buildBgmScoreArea(
                  subject.rating?.score ?? 0,
                  total: subject.rating?.total ?? 0,
                  rank: subject.rank,
                ),
                const SizedBox(height: 5),
                Text(
                  "类型: ${bgmTypes.where((e) => e.value == subject.type).first.cnLabel}",
                  maxLines: 1,
                ),
                Text("原名: ${subject.name}", maxLines: 1),
                Text("首播: ${subject.airDate}", maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// 动漫和漫画的排名是用户评分
Widget buildBgmScoreArea(double score, {int? total, int? rank}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text("$score", style: TextStyle(fontSize: 20.sp)),
      Column(
        children: [
          RatingStars(
            axis: Axis.horizontal,
            value: score,
            starCount: 5,
            starSize: 15.sp,
            starSpacing: 2.sp,
            // 评分的最大值
            maxValue: 10,
            starOffColor: Colors.grey[300]!,
            // 填充时的星星颜色
            starColor: Colors.orange,
            // 不显示评分的文字，只显示星星
            valueLabelVisibility: false,
          ),
          Text(
            "$total人评价",
            style: TextStyle(fontSize: 12.sp),
          ),
        ],
      ),
      if (rank != null)
        Container(
          width: 90.sp,
          padding: EdgeInsets.all(2.sp),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5.sp),
            color: Colors.amber[200],
          ),
          child: Text(
            "Top No.$rank",
            style: TextStyle(fontSize: 12.sp),
            textAlign: TextAlign.center,
          ),
        ),
    ],
  );
}
