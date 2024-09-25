import 'package:flutter/material.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../apis/bangumi/bangumi_apis.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/constants.dart';
import '../../../models/bangumi/bangumi.dart';
import 'bangumi_item_detail.dart';

List<CusLabel> bgmEpTypes = [
  CusLabel(cnLabel: "本篇", value: 0),
  CusLabel(cnLabel: "特别篇", value: 1),
  CusLabel(cnLabel: "音乐OP", value: 2),
  CusLabel(cnLabel: "ED", value: 3),
  CusLabel(cnLabel: "预告/宣传/广告", value: 4),
  CusLabel(cnLabel: "MAD", value: 5),
  CusLabel(cnLabel: "其他", value: 6),
];

class BangumiEpisodeDetail extends StatefulWidget {
  final int subjectId;
  final String subjectName;

  const BangumiEpisodeDetail({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State createState() => _BangumiEpisodeDetailState();
}

class _BangumiEpisodeDetailState extends State<BangumiEpisodeDetail> {
  final int _pageSize = 10;
  int _currentPage = 1;
  // 查询的结果列表
  List<BGMEpisode> subjectList = [];

  // 上拉下拉时的加载圈
  bool _isRefreshLoading = false;
  bool _hasMore = true;

  // 首次进入页面或者切换类型时的加载
  bool isLoading = false;

  // 被选中的动画分集类型
  late CusLabel selectedBgmEpType;

  @override
  void initState() {
    super.initState();

    selectedBgmEpType = bgmEpTypes[0];

    // 默认进入是日历数据
    fetchBgmData();
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

    // 否则是关键字条件查询
    var jkRst = await getBangumiEpisodesById(
      widget.subjectId,
      type: (selectedBgmEpType.value as int),
      offset: (_currentPage - 1) * _pageSize,
      limit: _pageSize,
    );

    setState(() {
      if (_currentPage == 1) {
        subjectList = jkRst.data ?? [];
      } else {
        subjectList.addAll(jkRst.data ?? []);
      }
      // 是否下拉加载更多，就该当前加载的数量，是否达到了响应的限制
      _hasMore = (jkRst.total ?? 0) > _currentPage * _pageSize;
    });

    setState(() {
      isRefresh ? _isRefreshLoading = false : isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分集剧情'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          buildTitleText(
            widget.subjectName,
            fontSize: 18.sp,
            color: Colors.black,
          ),

          buildTypeDropdown(),

          Divider(height: 10.sp),

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
            "分集类型: ",
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            width: 180.sp,
            child: buildDropdownButton2<CusLabel>(
              value: selectedBgmEpType,
              items: bgmEpTypes,
              hintLable: "选择分类",
              onChanged: (value) async {
                setState(() {
                  selectedBgmEpType = value!;
                });

                fetchBgmData();
              },
              itemToString: (e) => (e as CusLabel).cnLabel,
            ),
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
              child: ListView.builder(
                itemCount: subjectList.length,
                itemBuilder: (context, index) {
                  return buildItemCard(
                    context,
                    subjectList[index],
                    selectedBgmEpType,
                  );
                },
              ),
            ),
    );
  }
}

/// 这些可能后续可以复用
/// 列表，左侧图片，右侧简介，一般一排一个
Widget buildItemCard(
  BuildContext context,
  BGMEpisode item,
  CusLabel type,
) {
  return Padding(
    padding: EdgeInsets.all(5.sp),
    child: Column(
      children: [
        buildTitleText("第${item.ep}集 ${item.nameCn}"),
        Table(
          // 设置表格边框
          border: TableBorder.all(color: Theme.of(context).disabledColor),
          // 隐藏边框
          // border: TableBorder.all(width: 0, color: Colors.transparent),
          // 设置每列的宽度占比
          columnWidths: {
            0: FixedColumnWidth(80.sp),
            1: const FlexColumnWidth(1),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            buildTableRow("原名称", "${item.name}"),
            // buildTableRow("中文名称", "${item.nameCn}"),
            buildTableRow("播放日期", "${item.airdate}"),
            buildTableRow("时长", "${item.duration}"),
            buildTableRow("简介", "${item.desc}"),
            // buildTableRow("集数", "${item.ep}"),
            // buildTableRow("排序", "${item.sort}"),
            // buildTableRow("类型", "${item.type}"),
            // buildTableRow("dic", "${item.disc}"),
            // buildTableRow("分集编号", "${item.id}"),
            // buildTableRow("动画编号", "${item.subjectId}"),
            // buildTableRow("评论数", "${item.comment}"),
            // buildTableRow("时长(秒)", "${item.durationSeconds}"),
          ],
        ),
      ],
    ),
  );
}
