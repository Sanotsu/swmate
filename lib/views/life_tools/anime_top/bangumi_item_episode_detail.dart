import 'package:flutter/material.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../apis/bangumi/bangumi_apis.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/constants.dart';
import '../../../models/bangumi/bangumi.dart';
import '_components.dart';
import 'bangumi_item_detail.dart';

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
  final int _pageSize = 15;
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
    fetchBGMData();
  }

  // 查询输入框有内容，就是条件查询；没有内容，就是播放日历查询
  // 如果是上拉下拉刷新，使用的loading标志不一样
  Future<void> fetchBGMData({bool isRefresh = false}) async {
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

          /// 分类下拉框
          TypeDropdown(
            selectedValue: selectedBgmEpType,
            items: bgmEpTypes,
            label: "分集类型: ",
            width: 180.sp,
            onChanged: (value) async {
              setState(() {
                selectedBgmEpType = value!;
              });

              fetchBGMData();
            },
          ),

          Divider(height: 10.sp),

          /// 主列表，可上拉下拉刷新
          buildRefreshList(),
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
                await fetchBGMData(isRefresh: true);
              },
              onLoad: _hasMore
                  ? () async {
                      if (!_isRefreshLoading) {
                        setState(() {
                          _currentPage++;
                        });
                        await fetchBGMData(isRefresh: true);
                      }
                    }
                  : null,
              // 查询框为空则显示每日放送；否则就是关键字查询后的列表
              child: ListView.builder(
                itemCount: subjectList.length,
                itemBuilder: (context, index) {
                  return buildEpDetailCard(
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

/// 分集剧情简介卡片
Widget buildEpDetailCard(
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
          // border: TableBorder.all(color: Theme.of(context).disabledColor),
          // 隐藏边框
          border: TableBorder.all(width: 0, color: Colors.transparent),
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
            // buildTableRow("简介", "${item.desc}"),
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
        Row(
          children: [
            SizedBox(
              width: 80.sp,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.sp),
                child: const Text(
                  "简介",
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.left,
                ),
              ),
            ),
            Expanded(
              child: TranslatableText(text: item.desc ?? "", isAppend: false),
            ),
          ],
        ),
        Divider(height: 4.sp),
      ],
    ),
  );
}
