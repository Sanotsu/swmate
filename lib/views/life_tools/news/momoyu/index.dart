import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../apis/life_tools/news/momoyu_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/constants/constants.dart';
import '../../../../common/utils/tools.dart';
import '../../../../models/life_tools/news/momoyu_info_resp.dart';
import '../_components/news_item_container.dart';
import 'list.dart';

// 一次只查询一个分类的数据，切换下拉框查看其他分类
class MomoyuIndex extends StatefulWidget {
  const MomoyuIndex({super.key});

  @override
  State createState() => _MomoyuIndexState();
}

class _MomoyuIndexState extends State<MomoyuIndex> {
  final int pageSize = 10;
  int currentPage = 1;

  List<MMYDataItem> calendarList = [];
  String? lastTime = DateTime.now().toIso8601String();

  // 上拉下拉时的加载圈
  bool isRefreshLoading = false;
  bool hasMore = true;

  // 首次进入页面或者切换类型时的加载
  bool isLoading = false;

  // 选中的来源
  late CusLabel selectedMmyItem;

  String onlineCount = '无数据';
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    selectedMmyItem = MomoyuItems[2];

    fetchMMYNews();
    fetchUserCount();

    // 启动定时器，每 60 秒查询一次数据
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      fetchUserCount();
    });
  }

  @override
  void dispose() {
    // 取消定时器，防止内存泄漏
    _timer.cancel();
    super.dispose();
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
      var jkRst = await getMomoyuItem(id: selectedMmyItem.value);
      if (!mounted) return;
      setState(() {
        calendarList = jkRst.data?.list ?? [];
        lastTime = jkRst.data?.time;
        hasMore = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    } finally {
      setState(() {
        isRefresh ? isRefreshLoading = false : isLoading = false;
      });
    }
  }

  Future<void> fetchUserCount() async {
    try {
      final rst = await getMomoyuUserCount();
      if (!mounted) return;
      setState(() {
        onlineCount = "实时摸鱼 ${rst.data ?? 0} 人";
      });
    } catch (e) {
      setState(() {
        onlineCount = '查询摸鱼人数失败';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text('摸摸鱼'),
        title: RichText(
          textAlign: TextAlign.start,
          text: TextSpan(
            children: [
              TextSpan(
                text: "摸摸鱼\t",
                style: TextStyle(
                  fontSize: 20.sp,
                  color: Colors.black,
                ),
              ),
              TextSpan(
                text: onlineCount,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              commonMDHintModalBottomSheet(
                context,
                "说明",
                "数据来源：摸摸鱼(https://momoyu.cc/)\n\n请勿频繁请求，避免IP封禁、影响原网站运行。",
                msgFontSize: 15.sp,
              );
            },
            icon: const Icon(Icons.info_outline),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MomoyuListAll(),
                ),
              );
            },
            icon: const Icon(Icons.list_alt),
          )
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
            Container(
              // color: Colors.lightGreen[300],
              width: 1.sw,
              padding: EdgeInsets.all(5.sp),
              child: Row(
                children: [
                  SizedBox(
                    width: 0.5.sw,
                    child: buildDropdownButton2<CusLabel>(
                      value: selectedMmyItem,
                      items: MomoyuItems,
                      labelSize: 15.sp,
                      hintLabel: "选择分类",
                      onChanged: (value) async {
                        setState(() {
                          selectedMmyItem = value!;
                        });
                        // 切换的时候可以直接更新了
                        fetchMMYNews();
                      },
                      itemToString: (e) => (e as CusLabel).cnLabel,
                    ),
                  ),
                  SizedBox(width: 10.sp),
                  Text(
                    "(${formatTimeAgo(lastTime ?? "")}更新)",
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Expanded(child: Container()),
                  IconButton(
                    onPressed: () {
                      fetchMMYNews();
                    },
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),

            Divider(height: 10.sp, thickness: 2.sp),

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
                itemCount: calendarList.length,
                itemBuilder: (context, index) {
                  var i = calendarList[index];

                  return NewsItemContainer(
                    index: index + 1,
                    title: i.title ?? "",
                    trailingText: i.extra,
                    link: i.link ?? "https://momoyu.cc/",
                  );
                },
              ),
            ),
    );
  }
}
