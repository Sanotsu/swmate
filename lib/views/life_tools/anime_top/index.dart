import 'package:flutter/material.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter_rating_stars/flutter_rating_stars.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../apis/jikan/get_top_apis.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/constants.dart';
import '../../../models/jikan/jikan_top.dart';
import 'mal_item_detail.dart';

/*
const CustomEntranceCard(
  title: '动漫排行',
  subtitle: "多平台动漫排行榜",
  icon: Icons.leaderboard_outlined,
  targetPage: MALAnimeTop(),
),
*/

enum MALType {
  anime,
  manga,
  characters,
  people,
}

class MALAnimeTop extends StatefulWidget {
  const MALAnimeTop({super.key});

  @override
  State createState() => _MALAnimeTopState();
}

class _MALAnimeTopState extends State<MALAnimeTop> {
  final int _pageSize = 10;
  int _currentPage = 1;
  List<JKTopData> rankList = [];
  // 上拉下拉时的加载圈
  bool _isRefreshLoading = false;
  bool _hasMore = true;

  // 首次进入页面或者切换类型时的加载
  bool isLoading = false;

  // MAL 可排名的有anime、manga、characters、people，响应的参数不太相似
  List<CusLabel> malTypes = [
    CusLabel(cnLabel: "动画", value: MALType.anime),
    CusLabel(cnLabel: "漫画", value: MALType.manga),
    CusLabel(cnLabel: "角色", value: MALType.characters),
    CusLabel(cnLabel: "人物", value: MALType.people),
  ];
  late CusLabel selectedMalType;

  @override
  void initState() {
    super.initState();

    selectedMalType = malTypes.first;

    _fetchMALTopData();
  }

  // 这个是初始化页面或者切换了类型时的首次查询
  Future<void> _fetchMALTopData() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });

    var jkRst = await getJikanTop(
      type: (selectedMalType.value as MALType).name,
      page: 1,
      limit: _pageSize,
    );

    setState(() {
      rankList = jkRst.data;

      _hasMore = jkRst.pagination.hasNextPage;
      isLoading = false;
    });
  }

  // 这个是上拉下拉加载更多
  // 和上者区分是因为加载圈位置不同，上者固定了首页码
  Future<void> _refreshMALTopData() async {
    var jkRst = await getJikanTop(
      type: (selectedMalType.value as MALType).name,
      page: _currentPage,
      limit: _pageSize,
    );

    setState(() {
      if (_currentPage == 1) {
        rankList = jkRst.data;
      } else {
        rankList.addAll(jkRst.data);
      }
      _isRefreshLoading = false;
      _hasMore = jkRst.pagination.hasNextPage;
    });
  }

  // 动漫漫画和角色人物返回的结构不太一样
  bool isAnimeOrManga() => ["anime", "manga"].contains(
        (selectedMalType.value as MALType).name,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('MAL排行'),
          actions: [
            IconButton(
              onPressed: () {
                commonMDHintModalBottomSheet(
                  context,
                  "说明",
                  "数据来源[myanimelist](https://myanimelist.net/)",
                  msgFontSize: 15.sp,
                );
              },
              icon: const Icon(Icons.info_outline),
            ),
            buildPopupMenuButton(),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(5.sp),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "排行榜分类: ",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    width: 100.sp,
                    child: buildDropdownButton2<CusLabel>(
                      value: selectedMalType,
                      items: malTypes,
                      hintLable: "选择分类",
                      onChanged: (value) async {
                        setState(() {
                          selectedMalType = value!;
                        });
                        await _fetchMALTopData();
                      },
                      itemToString: (e) => (e as CusLabel).cnLabel,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? buildLoader(isLoading)
                  : EasyRefresh(
                      header: const ClassicHeader(),
                      footer: const ClassicFooter(),
                      onRefresh: () async {
                        _currentPage = 1;
                        await _refreshMALTopData();
                      },
                      onLoad: _hasMore
                          ? () async {
                              if (!_isRefreshLoading) {
                                setState(() {
                                  _isRefreshLoading = true;
                                });
                                _currentPage++;
                                await _refreshMALTopData();
                              }
                            }
                          : null,
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          childAspectRatio: 3, // 调整子组件的宽高比
                        ),
                        itemCount: rankList.length,
                        itemBuilder: (context, index) {
                          return buildPostItem(
                            context,
                            rankList[index],
                            index,
                            isAnimeOrManga(),
                            selectedMalType,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ));
  }

  Widget buildPopupMenuButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      // 调整弹出按钮的位置
      position: PopupMenuPosition.under,
      // 弹出按钮的偏移
      // offset: Offset(-25.sp, 0),
      onSelected: (String value) async {
        setState(() {
          // 理论上这里一定能找到，不然就有问题
          selectedMalType = malTypes
              .where((e) => (e.value as MALType).name == value)
              .toList()
              .first;
        });

        await _fetchMALTopData();
      },
      itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
        buildCusPopupMenuItem(context, "anime", "动漫排名", Icons.leaderboard),
        buildCusPopupMenuItem(context, "manga", "漫画排名", Icons.leaderboard),
        buildCusPopupMenuItem(context, "characters", "角色排名", Icons.leaderboard),
        buildCusPopupMenuItem(context, "people", "人物排名", Icons.leaderboard),
      ],
    );
  }
}

/// 这些可能后续可以复用
Widget buildPostItem(
  BuildContext context,
  JKTopData post,
  int index,
  bool isAnimeOrManga,
  CusLabel malType,
) {
  return GestureDetector(
    // 单击预览
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MALItemDetail(
            item: post,
            malType: malType,
          ),
        ),
      );
    },
    child: Card(
      margin: EdgeInsets.all(5.sp),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CachedNetworkImage(
          //   imageUrl: post.images.jpg?.imageUrl ?? "",
          //   placeholder: (context, url) => const CircularProgressIndicator(),
          //   errorWidget: (context, url, error) => const Icon(Icons.error),
          //   width: 100,
          //   height: 100,
          //   fit: BoxFit.cover,
          // ),

          Expanded(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.all(2.sp),
              child: buildImageGridTile(
                context,
                post.images.jpg?.imageUrl ?? "",
                prefix: "mal",
                fit: BoxFit.scaleDown,
              ),
            ),
          ),

          SizedBox(width: 10.sp),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    (isAnimeOrManga ? post.title : post.name) ?? "",
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
                if (isAnimeOrManga) buildScoreArea(post, index: index),
                if (!isAnimeOrManga) buildFavoritesArea(post, index: index),
                const SizedBox(height: 5),
                Text(
                  (isAnimeOrManga ? post.synopsis : post.about) ?? "",
                  maxLines: isAnimeOrManga ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// MAL的动漫和漫画的排名是用户评分
Widget buildScoreArea(
  JKTopData post, {
  int? index,
  dynamic Function(double)? onValueChanged,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        "${post.score ?? 0}",
        style: TextStyle(fontSize: 20.sp),
      ),
      Column(
        children: [
          RatingStars(
            axis: Axis.horizontal,
            value: post.score ?? 0,
            onValueChanged: onValueChanged,
            starCount: 5,
            starSize: 15.sp,
            starSpacing: 2.sp,
            // 评分的最大值
            maxValue: 10,
            // maxValueVisibility: true,
            // 未填充时的星星颜色
            // starOffColor: const Color(0xffe7e8ea),
            starOffColor: Colors.grey[300]!,
            // 填充时的星星颜色
            starColor: Colors.orange,
            // 不显示评分的文字，只显示星星
            valueLabelVisibility: false,
            // valueLabelColor: const Color(0xff9b9b9b),
            // valueLabelTextStyle: TextStyle(
            //   color: Colors.white,
            //   fontWeight: FontWeight.w400,
            //   fontStyle: FontStyle.normal,
            //   fontSize: 12.sp,
            // ),
            // valueLabelRadius: 10,
            // valueLabelPadding: const EdgeInsets.symmetric(
            //   vertical: 1,
            //   horizontal: 8,
            // ),
            // valueLabelMargin: const EdgeInsets.only(right: 8),
            // 评分时的动画
            // animationDuration: const Duration(milliseconds: 1000),
            // 星星的旋转角度
            // angle: 30,
          ),
          Text(
            "${post.scoredBy ?? 0}人评价",
            style: TextStyle(fontSize: 12.sp),
          ),
        ],
      ),
      index != null
          ? Container(
              width: 90.sp,
              padding: EdgeInsets.all(2.sp),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.sp),
                color: Colors.amber[200],
              ),
              child: Text(
                "Top No.${index + 1}",
                style: TextStyle(fontSize: 12.sp),
                textAlign: TextAlign.center,
              ),
            )
          : Container(),
    ],
  );
}

// MAL的角色和任务的排名是用户收藏
Widget buildFavoritesArea(JKTopData post, {int? index}) {
  return Row(
    children: [
      Text(
        "${post.favorites ?? 0}人最爱",
        style: TextStyle(fontSize: 12.sp),
      ),
      SizedBox(width: 10.sp),
      index != null
          ? Container(
              width: 90.sp,
              padding: EdgeInsets.all(2.sp),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.sp),
                color: Colors.amber[200],
              ),
              child: Text(
                "Top No.${index + 1}",
                style: TextStyle(fontSize: 12.sp),
                textAlign: TextAlign.center,
              ))
          : Container(),
    ],
  );
}
