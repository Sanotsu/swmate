import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../apis/life_tools/bangumi/bangumi_apis.dart';
import '../../../common/components/bar_chart_widget.dart';
import '../../../common/components/tool_widget.dart';
import '../../../models/life_tools/bangumi/bangumi.dart';
import '_components.dart';
import 'bangumi_item_episode_detail.dart';

class BangumiItemDetail extends StatefulWidget {
  // 因为放送日历和查询结果的类型不一样，所以只需要传入编号和类型
  final int id;
  // 这里只用于显示标题，所以传入字符串即可
  final String subType;

  const BangumiItemDetail({
    super.key,
    required this.id,
    required this.subType,
  });

  @override
  State<BangumiItemDetail> createState() => _BangumiItemDetailState();
}

class _BangumiItemDetailState extends State<BangumiItemDetail> {
  // 是否根据id查询条目中
  bool isLoading = false;

  // 评分组成
  List<List<ChartData>> bgmScoreList = [];

  // 当前的条目
  late BGMSubject bgmSub;

  // 当前条目关联的人物、角色、条目
  List<BGMSubjectRelation> personList = [];
  late List<BGMSubjectRelation> characterList = [];
  late List<BGMSubjectRelation> subjectList = [];

  @override
  void initState() {
    super.initState();

    queryBGMSubject();
  }

  // 查询当前指定编号的条目
  queryBGMSubject() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    // 查询指定条目详情
    var stat = await getBangumiSubjectById(widget.id);

    // 查询指定条目的演职表
    var persons = await getBangumiSubjectRelated(
      widget.id,
      type: "persons",
    );

    // 查询指定条目的角色
    var characters = await getBangumiSubjectRelated(
      widget.id,
      type: "characters",
    );

    // 查询指定条目的关联条目
    var subjects = await getBangumiSubjectRelated(
      widget.id,
      type: "subjects",
    );

    if (!mounted) return;
    setState(() {
      bgmSub = stat;

      personList = persons;
      characterList = characters;
      subjectList = subjects;

      /// 构建评分柱状图的数据。
      // 先清空，再构建
      bgmScoreList.clear();

      List<ChartData> tempScores = [];
      if (bgmSub.rating?.count != null) {
        bgmSub.rating?.count!.forEach((key, value) {
          tempScores.add(ChartData(
            "$key星",
            value / (bgmSub.rating?.total ?? 1),
          ));
        });
      }

      // 从左往右日期逐渐变大，所以数据要翻转
      bgmScoreList.addAll([
        tempScores.reversed.toList(),
      ]);
    });

    setState(() {
      isLoading = false;
    });
  }

  // 没看到剧照或者图片接口，这个图片可以省略
  genImageUrl() =>
      ["https://api.bgm.tv/v0/subjects/${widget.id}/image?type=large"];

  // 构建关联人物、角色、条目时，需要传给子组件的内容
  Map<String, dynamic> buildRelatedSimpleMap(BGMSubjectRelation e) => {
        "id": e.id!,
        "imageUrl": e.images?.medium ?? "",
        "name": e.name ?? e.nameCn,
        "sub1": e.relation,
        "sub2": e.career != null
            ? e.career?.join(',')
            : (e.actors != null && e.actors!.isNotEmpty)
                ? "cv: ${e.actors!.first.name}"
                : "",
        // 子组件中取来作为参数的栏位
        "data": e.id ?? 1,
        // 目前bgm的详情的type参数只是显示的文字而已，没有其他用法
        "type": e.nameCn ?? e.name ?? "",
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text("${widget.subType}详情"),
      ),
      body: isLoading
          ? buildLoader(isLoading)
          : ListView(
              children: [
                /// 标题
                buildUrlTitle(
                  context,
                  (bgmSub.nameCn != null && bgmSub.nameCn!.isNotEmpty)
                      ? bgmSub.nameCn!
                      : bgmSub.name ?? "",
                ),

                /// 预览图和评分区域
                buildImageAndRatingArea(
                  context,
                  bgmSub.images?.common ?? "",
                  "bangumi",
                  _buildSubRatingChildren(bgmSub),
                ),

                // 跳转到分集简介按钮
                // (2024-09-25 应该是只有动画才有意义)
                if (bgmSub.type == 2)
                  buildGotoButton(
                    context,
                    "分集简介",
                    BangumiEpisodeDetail(
                      subjectId: bgmSub.id!,
                      subjectName:
                          (bgmSub.nameCn != null && bgmSub.nameCn!.isNotEmpty)
                              ? bgmSub.nameCn!
                              : bgmSub.name ?? "",
                    ),
                  ),

                /// 图片(没找到有意义的获取图片API)
                // buildTitleText("图片"),
                // buildPictureArea(),

                if (characterList.isNotEmpty)
                  RelatedCardList<int, String>(
                    label: "角色表",
                    list: characterList
                        .map((e) => buildRelatedSimpleMap(e))
                        .toList(),
                    targetPageBuilder: (int data, String type) =>
                        BangumiItemDetail(id: data, subType: type),
                    dataExtractor: (Map<String, dynamic> item) => item["data"],
                    typeExtractor: (Map<String, dynamic> item) => item["type"],
                  ),

                if (personList.isNotEmpty)
                  RelatedCardList<int, String>(
                    label: "演职表",
                    list: personList
                        .map((e) => buildRelatedSimpleMap(e))
                        .toList(),
                    targetPageBuilder: (int data, String type) =>
                        BangumiItemDetail(id: data, subType: type),
                    dataExtractor: (Map<String, dynamic> item) => item["data"],
                    typeExtractor: (Map<String, dynamic> item) => item["type"],
                  ),

                if (subjectList.isNotEmpty)
                  RelatedCardList<int, String>(
                    label: "关联作品",
                    list: subjectList
                        .map((e) => buildRelatedSimpleMap(e))
                        .toList(),
                    targetPageBuilder: (int data, String type) =>
                        BangumiItemDetail(id: data, subType: type),
                    dataExtractor: (Map<String, dynamic> item) => item["data"],
                    typeExtractor: (Map<String, dynamic> item) => item["type"],
                  ),

                ///
                /// 上面几个占位的高度是比较固定的，下面的都不怎么固定
                ///
                /// 基础信息栏位
                buildTitleText("信息"),
                ...buildAnmieInfo(bgmSub),

                SizedBox(height: 20.sp),
              ],
            ),
    );
  }

  ///
  /// 从上到下的组件
  ///

  // 构建上分右侧评分和概述区域内容children
  List<Widget> _buildSubRatingChildren(BGMSubject item) {
    return [
      /// 星级评分
      buildBgmScoreArea(
        item.rating?.score ?? 0,
        total: item.rating?.total ?? 0,
        rank: item.rank ?? item.rating?.rank,
      ),

      /// 评分人数分布
      SizedBox(
        height: 80.sp,
        child: BarChartWidget(
          seriesData: bgmScoreList,
          seriesColors: const [Colors.orange],
          seriesNames: const ["BGM评分"],
        ),
      ),

      /// 想看人数
      Divider(height: 10.sp),
      Expanded(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildCollectSize("在看 ${item.collection?.doing}人"),
                _buildCollectSize("想看 ${item.collection?.wish}人"),
                _buildCollectSize("收藏 ${item.collection?.collect}人"),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildCollectSize("搁置 ${item.collection?.onHold}人"),
                _buildCollectSize("弃坑 ${item.collection?.dropped}人"),
                Expanded(child: Container()),
              ],
            )
          ],
        ),
      ),
    ];
  }

  _buildCollectSize(String label) {
    return Expanded(
      child: Text(label, style: TextStyle(fontSize: 10.5.sp)),
    );
  }

  /// 动漫的图片
  buildPictureArea() {
    /// 图片只放一行，可以横向滚动显示
    return SizedBox(
      height: 100.sp,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.sp),
        child: GridView.count(
          scrollDirection: Axis.horizontal, // 设置为横向滚动
          crossAxisCount: 1, // 每行显示 1 张图片
          mainAxisSpacing: 2.0, // 主轴方向的间距
          crossAxisSpacing: 2.0, // 交叉轴方向的间距
          childAspectRatio: 5 / 4, // 横向，高宽比
          children: buildImageList(
            context,
            // 2024-09-25 没看到多个图片的查询接口
            genImageUrl(),
            prefix: "bangumi_",
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  /// 信息简介部分(summary内容较多，单独出来)
  buildAnmieInfo(BGMSubject item) {
    return [
      Padding(
        padding: EdgeInsets.all(5.sp),
        child: Table(
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
            buildTableRow("编号", "${item.id}"),
            buildTableRow("评分", "${item.rating?.score}"),
            buildTableRow("评分人数", "${item.rating?.total}"),
            buildTableRow("排名", "${item.rating?.rank ?? item.rank}"),
            buildTableRow("类别", widget.subType), // "${item.type}"
            buildTableRow(
              "标签",
              (item.tags?.map((e) => "${e.name}(${e.count})").toList() ?? [])
                  .join(" / "),
            ),
            ...(item.infobox ?? []).map((e) => buildTableRow(
                  e.key,
                  // 这个value还可能有嵌套
                  // 如果是String就直接显示，如果是List，再取值
                  e.value is String
                      ? e.value
                      : (e.value.runtimeType is List)
                          ? (e.value as List)
                              .map((v) => (v as Map).values.join(" / "))
                          : e.value.toString(),
                )),
          ],
        ),
      ),

      /// 故事简介栏位
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [buildTitleText("简介")],
      ),
      TranslatableText(text: bgmSub.summary ?? "", isAppend: false),
    ];
  }
}

// 表格行
TableRow buildTableRow(
  String? label,
  String value, {
  double? labelFontSize,
  double? valueFontSize,
}) {
  return TableRow(
    children: [
      if (label != null)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.sp),
          child: Text(
            label,
            style: TextStyle(
              fontSize: labelFontSize ?? 14.sp,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.left,
          ),
        ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.sp),
        child: Text(
          value,
          style: TextStyle(
            fontSize: valueFontSize ?? 14.sp,
            color: Colors.black87,
          ),
          textAlign: TextAlign.left,
        ),
      ),
    ],
  );
}
