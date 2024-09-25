import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../apis/bangumi/bangumi_apis.dart';
import '../../../common/components/bar_chart_widget.dart';
import '../../../common/components/tool_widget.dart';
import '../../../models/bangumi/bangumi.dart';
import 'bangumi_calendar.dart';
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
                /// 可跳转到源网页的标题
                buildTitleArea(),

                /// 预览图和评分区域
                buildImageAndRatingArea(bgmSub),

                // 跳转到分集简介按钮
                // (2024-09-25 应该是只有动画才有意义)
                if (bgmSub.type == 2) buildGotoEpisodesArea(),

                /// 图片(没找到有意义的获取图片API)
                // buildTitleText("图片"),
                // buildPictureArea(),

                if (characterList.isNotEmpty) ...[
                  buildTitleText("角色表"),
                  buildRelatedTileCard(context, characterList),
                ],

                if (personList.isNotEmpty) ...[
                  buildTitleText("演职表"),
                  buildRelatedTileCard(context, personList),
                ],

                if (subjectList.isNotEmpty) ...[
                  buildTitleText("关联作品"),
                  buildRelatedTileCard(context, subjectList),
                ],

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
  /// 可跳转到源网页的标题
  Widget buildTitleArea() {
    return TextButton(
      onPressed: () {
        // launchStringUrl(bgmSub.url ?? "");
      },
      child: Text(
        (bgmSub.nameCn != null && bgmSub.nameCn!.isNotEmpty)
            ? bgmSub.nameCn!
            : bgmSub.name ?? "",
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 可跳转到源网页的标题
  Widget buildGotoEpisodesArea() {
    return TextButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BangumiEpisodeDetail(
              subjectId: bgmSub.id!,
              subjectName: (bgmSub.nameCn != null && bgmSub.nameCn!.isNotEmpty)
                  ? bgmSub.nameCn!
                  : bgmSub.name ?? "",
            ),
          ),
        );
      },
      icon: const Icon(Icons.arrow_right),
      iconAlignment: IconAlignment.end,
      label: Text(
        "分集简介",
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
        textAlign: TextAlign.end,
      ),
    );
  }

  /// 预览图和评分区域
  Widget buildImageAndRatingArea(BGMSubject item) {
    return SizedBox(
      height: 160.sp,
      child: Card(
        margin: EdgeInsets.only(left: 5.sp, right: 5.sp),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧预览图片
            Expanded(
              flex: 1,
              child: Padding(
                padding: EdgeInsets.all(2.sp),
                child: buildImageGridTile(
                  context,
                  item.images?.common ?? "",
                  prefix: "bangumi",
                  fit: BoxFit.scaleDown,
                ),
              ),
            ),
            SizedBox(width: 10.sp),
            // 右侧简介
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildSubRatingChildren(item),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
      Divider(height: 5.sp),
      Expanded(
        child: Text(
          """${item.collection?.doing}人正在看/${item.collection?.wish}人想看/${item.collection?.collect}人收藏
${item.collection?.onHold}人搁置/${item.collection?.dropped}人弃坑""",
          style: TextStyle(fontSize: 10.5.sp),
        ),
      ),
    ];
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

      // // 实测，上面的无边框表格显示更好看
      // buildItemRow("编号", "${item.id}"),
      // buildItemRow("评分", "${item.rating?.score}"),
      // buildItemRow("评分人数", "${item.rating?.total}"),
      // buildItemRow("排名", "${item.rating?.rank ?? item.rank}"),
      // ...(item.infobox ?? []).map((e) => buildItemRow(
      //       e.key,
      //       e.value.toString(),
      //     )),
      // buildItemRow("类别", "${item.type}"),
      // buildItemRow(
      //   "标签",
      //   (item.tags?.map((e) => "${e.name} ${e.count}").toList() ?? [])
      //       .join("/"),
      // ),

      /// 故事简介栏位
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [buildTitleText("简介")],
      ),
      buildItemRow(null, bgmSub.summary ?? ""),
    ];
  }
}

/// 网格，预览图+名称，一排可以多个
/// ??? 2024-09-25 暂时不做点击继续跳转到关联页面了，同样的tag等也不跳转了
Widget buildRelatedTileCard(
  BuildContext context,
  List<BGMSubjectRelation> list,
) {
  Widget genCard(BGMSubjectRelation item) => GestureDetector(
        // 单击预览
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BangumiItemDetail(
                id: item.id!,
                // // 这里应该是有的
                // subType:
                //     bgmTypes.where((e) => e.value == item.type).first.cnLabel,
                // 2024-09-25 嵌套跳转的，直接传名字吧
                subType: "[${item.name ?? item.nameCn}]",
              ),
            ),
          );
        },
        child: Card(
          shape: RoundedRectangleBorder(
            // 减少圆角半径
            borderRadius: BorderRadius.circular(0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// 预览图片
              SizedBox(
                height: 110.sp,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.sp),
                  child: buildImageGridTile(
                    context,
                    item.images?.medium ?? "",
                    prefix: "bangumi",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // 简介
              Flexible(
                child: Column(
                  children: [
                    Text(
                      "${item.name}",
                      maxLines: 3,
                      style: TextStyle(fontSize: 10.sp),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    Expanded(child: Container()),
                    Text(
                      "${item.relation}",
                      maxLines: 1,
                      style: TextStyle(fontSize: 10.sp),
                      textAlign: TextAlign.center,
                    ),
                    if (item.career != null)
                      Text(
                        "${item.career?.join(',')}",
                        maxLines: 1,
                        style: TextStyle(fontSize: 10.sp),
                        textAlign: TextAlign.center,
                      ),
                    if (item.actors != null && item.actors!.isNotEmpty)
                      Text(
                        "cv: ${item.actors!.first.name}",
                        maxLines: 1,
                        style: TextStyle(fontSize: 10.sp),
                        textAlign: TextAlign.center,
                      ),
                    SizedBox(height: 2.sp),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Wrap(
      // direction: Axis.horizontal,
      // alignment: WrapAlignment.spaceAround,
      children: list.isNotEmpty
          ? List.generate(
              list.length,
              // 这个尺寸和下面的图片要配合好
              (index) => SizedBox(
                height: 180.sp,
                width: 110.sp,
                child: genCard(list[index]),
              ),
            ).toList()
          : [],
    ),
  );
}

// 标题文字
Widget buildTitleText(
  String title, {
  double? fontSize = 16,
  Color? color = Colors.black54,
  TextAlign? textAlign = TextAlign.start,
}) {
  return Padding(
    padding: EdgeInsets.all(10.sp),
    child: Text(
      title,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      textAlign: textAlign,
    ),
  );
}

// 正文文字
Widget buildItemRow(
  String? label,
  String value, {
  double? labelFontSize,
  double? valueFontSize,
  int? maxLines,
}) {
  return Row(
    children: [
      if (label != null)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.sp),
          child: Text(
            label,
            style: TextStyle(
              fontSize: labelFontSize ?? 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      Expanded(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.sp),
          child: Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize ?? 14.sp,
              color: Colors.black87,
            ),
            textAlign: TextAlign.left,
            softWrap: true,
            maxLines: maxLines,
          ),
        ),
      ),
    ],
  );
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
        Text(
          label,
          style: TextStyle(
            fontSize: labelFontSize ?? 14.sp,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.left,
        ),
      Text(
        value,
        style: TextStyle(
          fontSize: valueFontSize ?? 14.sp,
          color: Colors.black87,
        ),
        textAlign: TextAlign.left,
      ),
    ],
  );
}
