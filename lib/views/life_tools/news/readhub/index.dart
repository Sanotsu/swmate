import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../apis/news/readhub_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/constants.dart';
import '../../../../common/utils/tools.dart';
import '../../../../models/news/readhub_hot_topic_resp.dart';

///
/// 2024-11-06 readhub 只处理热门话题这一个，其他分类暂时不弄了
///
class ReadhubIndex extends StatefulWidget {
  const ReadhubIndex({super.key});

  @override
  State createState() => _ReadhubIndexState();
}

class _ReadhubIndexState extends State<ReadhubIndex> {
  final int _pageSize = 10;
  int _currentPage = 1;

  // 查询的结果列表
  List<ReadhubHotTopicItem> _hotTopicList = [];
  // 保存新闻是否被点开(点开了可以看到更多内容)
  List<bool> _isExpandedList = [];

  // 上拉下拉时的加载圈
  bool _isRefreshLoading = false;
  bool _hasMore = true;

  // 首次进入页面或者切换类型时的加载
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchHotTopicData();
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
    var htRst = await getReadhubHotTopicList(
      size: _pageSize,
      page: _currentPage,
    );

    if (!mounted) return;
    setState(() {
      if (_currentPage == 1) {
        _hotTopicList = htRst.items ?? [];
      } else {
        _hotTopicList.addAll(htRst.items ?? []);
      }
      // 2024-11-05 往下滚动一定会有更久的数据？
      _hasMore = true;

      // 重新加载新闻列表都是未加载的状态
      _isExpandedList = List.generate(_hotTopicList.length, (index) => false);
    });

    setState(() {
      isRefresh ? _isRefreshLoading = false : _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Readhub 热门话题'),
        actions: [
          IconButton(
            onPressed: () {
              commonMDHintModalBottomSheet(
                context,
                "说明",
                "数据来源：[Readhub](https://readhub.cn/)",
                msgFontSize: 15.sp,
              );
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
              child: ListView.builder(
                itemCount: _hotTopicList.length,
                itemBuilder: (context, index) {
                  return buildHotTopicCard(
                    _hotTopicList[index],
                    index,
                  );
                },
              ),
            ),
    );
  }

  /// 热点话题新闻卡片
  Widget buildHotTopicCard(
    ReadhubHotTopicItem item,
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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    // "${index + 1} ${item.title}",
                    item.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 2.sp),
              child: RichText(
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.end,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "${item.siteNameDisplay}\t\t\t\t",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 14.sp,
                      ),
                    ),
                    TextSpan(
                      text: formatTimeAgo(item.publishDate),
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          item.summary,
          maxLines: isExpanded ? null : 3,
          overflow: isExpanded ? null : TextOverflow.ellipsis,
          style: TextStyle(
            color: isExpanded ? null : Colors.black54,
            fontSize: 14.sp,
          ),
          // 新闻总结文字两端对齐
          textAlign: TextAlign.justify,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.newsAggList != null && item.newsAggList!.isNotEmpty) ...[
            Text(
              "新闻报道",
              style: TextStyle(fontSize: 16.sp),
              textAlign: TextAlign.start,
            ),
            ...(item.newsAggList!).map((newsAgg) => buildNewsAggItem(newsAgg)),
          ],
          if (item.timeline?.topics != null &&
              item.timeline!.topics.isNotEmpty) ...[
            Divider(),
            Text(
              "相关话题",
              style: TextStyle(fontSize: 16.sp),
              textAlign: TextAlign.start,
            ),
            ...(item.timeline!.topics)
                .map((detail) => buildTimelineItem(detail))
          ]
        ],
      ),
    );
  }

  // 关联新闻
  buildNewsAggItem(ReadhubNewsAggList newsAgg) {
    return Column(
      children: [
        Divider(),
        GestureDetector(
          onTap: () => launchStringUrl(newsAgg.url),
          child: Row(
            children: [
              // Icon(Icons.link, size: 20.sp, color: Colors.grey),
              SizedBox(width: 5.sp),
              Expanded(
                child: Text(
                  newsAgg.title,
                  style: TextStyle(color: Colors.blue),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              VerticalDivider(width: 5.sp, thickness: 2.sp, color: Colors.red),
              Container(
                width: 70.sp,
                padding: EdgeInsets.only(right: 5.sp),
                child: Text(
                  newsAgg.siteNameDisplay,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 相关话题时间线
  buildTimelineItem(ReadhubTimelineTopic topic) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.only(left: 5.sp, right: 5.sp),
      // 年月日的时间字符串
      leading: SizedBox(
        width: 65.sp,
        child: Text(
          DateFormat(constDateFormat).format(DateTime.parse(topic.createdAt)),
          style: TextStyle(color: Colors.grey),
        ),
      ),
      // 新闻标题
      title: Text(
        topic.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          decoration: TextDecoration.underline, // 添加下划线
          decorationColor: Colors.blue, // 下划线颜色
          decorationThickness: 2.sp, // 下划线粗细
        ),
      ),
      onTap: () => launchStringUrl("https://readhub.cn/topic/${topic.uid}"),
    );
  }
}
