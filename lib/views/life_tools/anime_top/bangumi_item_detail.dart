import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../apis/bangumi/bangumi_apis.dart';
import '../../../common/components/bar_chart_widget.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/constants.dart';
import '../../../models/bangumi/bangumi.dart';
import 'bangumi_calendar.dart';

class BangumiItemDetail extends StatefulWidget {
  // 因为放送日历和查询结果的类型不一样，所以只需要传入编号和类型
  final int id;
  final CusLabel type;

  const BangumiItemDetail({
    super.key,
    required this.id,
    required this.type,
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

    var stat = await getBangumiSubjectById(widget.id);

    if (!mounted) return;
    setState(() {
      bgmSub = stat;

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
        title: Text("${widget.type.cnLabel}详情"),
      ),
      body: isLoading
          ? buildLoader(isLoading)
          : ListView(
              children: [
                /// 可跳转到源网页的标题
                buildTitleArea(),

                /// 预览图和评分区域
                buildImageAndRatingArea(bgmSub),

                /// 图片
                buildTitleText("图片"),
                buildPictureArea(),

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
        launchStringUrl(bgmSub.url ?? "");
      },
      child: Text(
        bgmSub.nameCn ?? "",
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
        textAlign: TextAlign.center,
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
        rank: item.rank,
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
          // border: TableBorder.all(color: Theme.of(context).disabledColor),
          // 隐藏边框
          border: TableBorder.all(width: 0, color: Colors.transparent),
          // 设置每列的宽度占比
          columnWidths: {
            0: FixedColumnWidth(100.sp),
            1: const FlexColumnWidth(1),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            buildTableRow("编号", "${item.id}"),
            buildTableRow("评分", "${item.rating?.score}"),
            buildTableRow("评分人数", "${item.rating?.total}"),
            buildTableRow("排名", "${item.rating?.rank ?? item.rank}"),
            buildTableRow("类别", widget.type.cnLabel), // "${item.type}"
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
