import 'package:flutter/material.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter_rating_stars/flutter_rating_stars.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../apis/bangumi/bangumi_apis.dart';
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

  // 关键字查询
  TextEditingController searchController = TextEditingController();
  String query = '';

  @override
  void initState() {
    super.initState();

    selectedMalType = malTypes.first;

    // 默认进入是top数据
    _initFetchMALData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // 这个是初始化页面或者切换了类型时的首次查询
  // 查询输入框有内容，就是条件查询；没有内容，就是排行榜查询(下同)
  Future<void> _initFetchMALData() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });

    // 默认是top查询，也可能是关键字条件查询
    var jkRst = query.isEmpty
        ? await getJikanTop(
            type: (selectedMalType.value as MALType),
            page: 1,
            limit: _pageSize,
          )
        : await getJikanSearch(
            q: query,
            type: (selectedMalType.value as MALType),
          );

    setState(() {
      rankList = jkRst.data;
      _hasMore = jkRst.pagination?.hasNextPage ?? false;
      isLoading = false;
    });
  }

  // 这个是上拉下拉加载更多
  // 和上者区分是因为加载圈位置不同，上者固定了首页码
  Future<void> _refreshMALData() async {
    // 默认是top查询，也可能是关键字条件查询
    var jkRst = query.isEmpty
        ? await getJikanTop(
            type: (selectedMalType.value as MALType),
            page: _currentPage,
            limit: _pageSize,
          )
        : await getJikanSearch(
            q: query,
            type: (selectedMalType.value as MALType),
            page: _currentPage,
            limit: _pageSize,
          );

    if (!mounted) return;
    setState(() {
      if (_currentPage == 1) {
        rankList = jkRst.data;
      } else {
        rankList.addAll(jkRst.data);
      }
      _isRefreshLoading = false;
      _hasMore = jkRst.pagination?.hasNextPage ?? false;
    });
  }

  // 动漫漫画和角色人物返回的结构不太一样
  bool isAnimeOrManga() => ["anime", "manga"].contains(
        (selectedMalType.value as MALType).name,
      );

  // 关键字查询
  void _handleSearch() {
    setState(() {
      rankList.clear();
      _currentPage = 1;
      query = searchController.text;
    });
    // 在当前上下文中查找最近的 FocusScope 并使其失去焦点，从而收起键盘。
    FocusScope.of(context).unfocus();

    _initFetchMALData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MAL排行'),
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
            "排行榜分类: ",
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            width: 80.sp,
            child: buildDropdownButton2<CusLabel>(
              value: selectedMalType,
              items: malTypes,
              hintLable: "选择分类",
              onChanged: (value) async {
                setState(() {
                  selectedMalType = value!;
                });
                await _initFetchMALData();
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
                  hintText: "输入关键字进行查询",
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
                _currentPage = 1;
                await _refreshMALData();
              },
              onLoad: _hasMore
                  ? () async {
                      if (!_isRefreshLoading) {
                        setState(() {
                          _isRefreshLoading = true;
                        });
                        _currentPage++;
                        await _refreshMALData();
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
                  return buildPostItem(
                    context,
                    rankList[index],
                    query.isEmpty ? index : null,
                    isAnimeOrManga(),
                    selectedMalType,
                  );
                },
              ),
            ),
    );
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

        await _initFetchMALData();
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
  int? index,
  bool isAnimeOrManga,
  CusLabel malType,
) {
  return GestureDetector(
    // 单击预览
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MALItemDetail(item: post, malType: malType),
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
                if (isAnimeOrManga) buildScoreArea(post, rank: post.rank),
                if (!isAnimeOrManga) buildFavoritesArea(post, index: index),
                const SizedBox(height: 5),
                // 如果是人物或角色，使用about的前几行；
                // 如果是动漫或者漫画，使用其他关键字(因为2行简介无实际作用)
                // Text(
                //   (isAnimeOrManga ? post.synopsis : post.about) ?? "",
                //   maxLines: isAnimeOrManga ? 2 : 3,
                //   overflow: TextOverflow.ellipsis,
                // ),
                if ((malType.value as MALType) == MALType.anime)
                  Text(
                    "类别: ${post.type}(${post.episodes}集)\n放送: ${post.aired?.from?.split("T").first} ~ ${post.aired?.to?.split("T").first ?? '至今'}\n成员: ${post.members}人 最爱: ${post.favorites}人",
                    maxLines: 3,
                    style: TextStyle(fontSize: 12.sp),
                  ),
                if ((malType.value as MALType) == MALType.manga)
                  Text(
                    "类别: ${post.type}(${post.volumes ?? 0}册单行本; ${post.chapters ?? 0}章)\n连载: ${post.published?.from?.split("T").first} ~ ${(post.published?.to?.split("T").first) ?? '至今'}\n成员: ${post.members}人 最爱: ${post.favorites}人",
                    maxLines: 3,
                    style: TextStyle(fontSize: 12.sp),
                  ),
                if (!isAnimeOrManga)
                  Text(
                    post.about ?? "",
                    maxLines: 4,
                    style: TextStyle(fontSize: 12.sp),
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
  int? rank,
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
      rank != null
          ? Container(
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
