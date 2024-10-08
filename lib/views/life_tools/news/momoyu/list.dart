import 'package:flutter/material.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../apis/news/momoyu_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/utils/tools.dart';
import '../../../../models/news/momoyu_info_resp.dart';
import '../_components/news_item_container.dart';

class MomoyuListAll extends StatefulWidget {
  const MomoyuListAll({super.key});

  @override
  State createState() => _MomoyuListAllState();
}

class _MomoyuListAllState extends State<MomoyuListAll> {
  final int pageSize = 10;
  int currentPage = 1;

  // 摸摸鱼列表响应结果
  List<MMYData> mmyDataList = [];

  // 上拉下拉时的加载圈
  bool isRefreshLoading = false;
  bool hasMore = true;

  // 首次进入页面或者切换类型时的加载
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    // 默认进入是日历数据
    fetchMMYNews();
  }

  // 查询输入框有内容，就是条件查询；没有内容，就是播放日历查询
  // 如果是上拉下拉刷新，使用的loading标志不一样
  Future<void> fetchMMYNews({bool isRefresh = false}) async {
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

    try {
      var jkRst = await getMomoyuList();
      setState(() {
        mmyDataList = jkRst.data ?? [];
        hasMore = false;
      });
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        isRefresh ? isRefreshLoading = false : isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('摸摸鱼(全列表)'),
        actions: [
          IconButton(
            onPressed: () {
              fetchMMYNews();
            },
            icon: const Icon(Icons.refresh),
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
                await fetchMMYNews(isRefresh: true);
              },
              onLoad: hasMore
                  ? () async {
                      if (!isRefreshLoading) {
                        setState(() {
                          currentPage++;
                        });
                        await fetchMMYNews(isRefresh: true);
                      }
                    }
                  : null,
              // 查询框为空则显示每日放送；否则就是关键字查询后的列表
              child: ListView.builder(
                itemCount: mmyDataList.length,
                itemBuilder: (context, index) {
                  var i = mmyDataList[index];
                  return Column(
                    children: [
                      Container(
                        color: Colors.lightGreen[300],
                        width: 1.sw,
                        padding: EdgeInsets.all(10.sp),
                        child: Row(
                          children: [
                            Text(
                              i.name ?? '',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              " (${formatTimeAgo(i.createTime ?? "")})",
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      buildItemCardWrap(i.data ?? []),
                    ],
                  );
                },
              ),
            ),
    );
  }

  /// 每日放送是查询一周七天，需要List中再嵌套一个周几的放映列表
  Widget buildItemCardWrap(List<MMYDataItem> item) {
    return Wrap(
      // direction: Axis.horizontal,
      // alignment: WrapAlignment.spaceAround,
      children: item.isNotEmpty
          ? List.generate(
              item.length,
              (index) {
                var i = item[index];
                return NewsItemContainer(
                  index: index + 1,
                  title: i.title ?? "",
                  trailingText: i.extra,
                  link: i.link ?? "https://momoyu.cc/",
                );
              },
            ).toList()
          : [],
    );
  }
}
