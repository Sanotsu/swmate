import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/components/tool_widget.dart';
import '../../../common/constants.dart';
import '../../../models/jikan/jikan_top.dart';
import 'index.dart';

class MALItemDetail extends StatefulWidget {
  final JKTopData item;
  final CusLabel malType;

  const MALItemDetail({
    super.key,
    required this.item,
    required this.malType,
  });

  @override
  State<MALItemDetail> createState() => _MALItemDetailState();
}

class _MALItemDetailState extends State<MALItemDetail> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text("${widget.malType.cnLabel}详情"),
        actions: const [
          IconButton(
            onPressed: null,
            icon: Icon(Icons.translate),
          ),
        ],
      ),
      body: ListView(
        children: [
          ...buildDetail(widget.item, (widget.malType.value as MALType)),
        ],
      ),
    );
  }

  /// 构建详情页面主体内容
  buildDetail(JKTopData item, MALType malType) {
    return [
      TextButton(
        onPressed: () {
          launchStringUrl(item.url);
        },
        child: Text(
          item.title ?? item.name ?? "",
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ),

      SizedBox(
        height: 150.sp,
        child: Card(
          margin: EdgeInsets.all(5.sp),
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
                    item.images.jpg?.imageUrl ?? "",
                    prefix: "mal",
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
                  children: [
                    if (malType == MALType.anime ||
                        malType == MALType.manga) ...[
                      // 注意，这里排名要-1,因为该组件中用的索引
                      buildScoreArea(
                        item,
                        index: item.rank != null ? item.rank! - 1 : null,
                      ),
                    ],
                    if (malType == MALType.characters ||
                        malType == MALType.people)
                      buildFavoritesArea(
                        item,
                        index: item.rank != null ? item.rank! - 1 : null,
                      ),
                    if (malType == MALType.anime) ...buildAnimeBrief(item),
                    if (malType == MALType.manga) ...buildMangaBrief(item),
                    if (malType == MALType.characters) ...[
                      buildItemRow(
                        "日文",
                        "${item.nameKanji}",
                        maxLines: 1,
                        labelFontSize: 12.sp,
                        valueFontSize: 12.sp,
                      ),
                      buildItemRow(
                        "简介",
                        "${item.about}",
                        maxLines: 6,
                        labelFontSize: 12.sp,
                        valueFontSize: 12.sp,
                      ),
                    ],
                    if (malType == MALType.people)
                      ...buildPeopleNote(item, isSmall: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      /// 基础信息栏位
      buildTitleText("信息"),
      if (malType == MALType.anime) ...buildAnmieNote(item),
      if (malType == MALType.manga) ...buildMangaNote(item),
      if (malType == MALType.characters) ...buildCharactersNote(item),
      if (malType == MALType.people) ...buildPeopleNote(item),

      /// 简介和背景栏位
      buildTitleText("简介"),
      buildItemRow(null, item.synopsis ?? item.about ?? ""),
      // 角色和人物没有背景栏位
      if (malType == MALType.anime || malType == MALType.manga) ...[
        buildTitleText("背景"),
        buildItemRow(null, item.background ?? ""),
      ]
    ];
  }

  /// 概要也只少数几个栏位，不同分类栏位不一样(字体要小些)
  buildAnimeBrief(JKTopData item) {
    return [
      buildItemRow(
        "人气",
        "${item.popularity}",
        labelFontSize: 12.sp,
        valueFontSize: 12.sp,
      ),
      buildItemRow(
        "集数",
        "${item.episodes}",
        labelFontSize: 12.sp,
        valueFontSize: 12.sp,
      ),
      buildItemRow(
        "时长",
        "${item.duration}",
        labelFontSize: 12.sp,
        valueFontSize: 12.sp,
      ),
      // buildItemRow(
      //   "分级",
      //   "${item.rating}",
      //   maxLines: 1,
      //   labelFontSize: 12.sp,
      //   valueFontSize: 12.sp,
      // ),
      buildItemRow(
        "放送",
        "${item.aired?.from?.split("T").first} ~ ${item.aired?.to?.split("T").first}",
        labelFontSize: 12.sp,
        valueFontSize: 12.sp,
      ),
      buildItemRow(
        "类型",
        (item.genres?.map((e) => e.name).toList() ?? []).join("/"),
        maxLines: 2,
        labelFontSize: 12.sp,
        valueFontSize: 12.sp,
      ),
    ];
  }

  buildMangaBrief(JKTopData item) {
    return [
      buildItemRow(
        "人气",
        "${item.popularity}",
        labelFontSize: 12.sp,
        valueFontSize: 12.sp,
      ),
      buildItemRow(
        "作者",
        (item.authors?.map((e) => e.name).toList() ?? []).join("/"),
        labelFontSize: 12.sp,
        valueFontSize: 12.sp,
        maxLines: 1,
      ),
      buildItemRow(
        "册数",
        "${item.volumes ?? '无'}",
        labelFontSize: 12.sp,
        valueFontSize: 12.sp,
      ),
      buildItemRow(
        "周期",
        "${item.published?.from?.split("T").first} ~ ${(item.published?.to?.split("T").first) ?? 'now'}",
        labelFontSize: 12.sp,
        valueFontSize: 12.sp,
      ),
      buildItemRow(
        "类型",
        (item.genres?.map((e) => e.name).toList() ?? []).join("/"),
        maxLines: 2,
        labelFontSize: 12.sp,
        valueFontSize: 12.sp,
      ),
    ];
  }

  /// 因为4种类型的栏位差距过大，所以各自单独处理，就算有重复的也无所谓了
  buildAnmieNote(JKTopData item) {
    return [
      buildItemRow(
        "又名",
        (item.titles?.map((e) => e.title).toList() ?? []).join("/"),
      ),
      buildItemRow("类别", "${item.type}"),
      buildItemRow("来源", "${item.source}"),
      buildItemRow("集数", "${item.episodes}"),
      buildItemRow("状态", "${item.status}"),
      buildItemRow("完播", item.airing == true ? '放映中' : '已完结'),
      buildItemRow(
        "放送",
        "${item.aired?.from?.split("T").first} ~ ${item.aired?.to?.split("T").first}",
      ),
      buildItemRow("时长", "${item.duration}"),
      buildItemRow("分级", "${item.rating}"),
      buildItemRow("评分", "${item.score}"),
      buildItemRow("评分人数", "${item.scoredBy}"),
      buildItemRow("排名", "${item.rank}"),
      buildItemRow("人气", "${item.popularity}"),
      buildItemRow("成员", "${item.members}"),
      buildItemRow("最爱", "${item.favorites}"),
      buildItemRow("分季", "${item.season}"),
      buildItemRow("年份", "${item.year}"),
      buildItemRow("播放", "${item.broadcast?.string}"),
      buildItemRow(
        "特征",
        (item.demographics?.map((e) => e.name).toList() ?? []).join("/"),
      ),
      buildItemRow(
        "出品方",
        (item.producers?.map((e) => e.name).toList() ?? []).join("/"),
      ),
      buildItemRow(
        "工作室",
        (item.studios?.map((e) => e.name).toList() ?? []).join("/"),
      ),
      buildItemRow(
        "类型",
        (item.genres?.map((e) => e.name).toList() ?? []).join("/"),
      ),
      // 因为这种点击跳转url是跳到原始的MAL网站，暂时其他就不跳转了，这里只是留个简单示例
      if (item.genres != null && item.genres!.isNotEmpty) ...[
        // Padding(
        //   padding: EdgeInsets.symmetric(horizontal: 10.sp),
        //   child: const Text("类型"),
        // ),
        Wrap(
          direction: Axis.horizontal,
          spacing: 5.sp,
          alignment: WrapAlignment.spaceAround,
          children: List.generate(
            item.genres!.length,
            (index) => buildSmallButtonTag(
              item.genres![index].name ?? "",
              bgColor: Colors.lightGreen[100],
              labelTextSize: 12.sp,
              onPressed: item.genres![index].url != null
                  ? () => launchStringUrl(item.genres![index].url!)
                  : null,
            ),
          ).toList(),
        ),
        Wrap(
          children: List.generate(
            item.genres!.length,
            (index) => TextButton(
              onPressed: () => launchStringUrl(item.genres![index].url!),
              child: Text(item.genres![index].name ?? ""),
            ),
          ).toList(),
        ),
      ],
    ];
  }

  buildMangaNote(JKTopData item) {
    return [
      buildItemRow(
        "又名",
        (item.titles?.map((e) => e.title).toList() ?? []).join("/"),
      ),
      buildItemRow("类别", "${item.type}"),
      buildItemRow("章数", "${item.chapters}"),
      buildItemRow("册数", "${item.volumes}"),
      buildItemRow("状态", "${item.status}"),
      buildItemRow("连载", item.publishing == true ? '连载中' : '已完结'),
      buildItemRow(
        "周期",
        "${item.published?.from?.split("T").first} ~ ${(item.published?.to?.split("T").first) ?? 'now'}",
      ),
      buildItemRow("评分", "${item.score}"),
      buildItemRow("评分人数", "${item.scoredBy}"),
      buildItemRow("排名", "${item.rank}"),
      buildItemRow("人气", "${item.popularity}"),
      buildItemRow("成员", "${item.members}"),
      buildItemRow("最爱", "${item.favorites}"),
      buildItemRow(
        "作者",
        (item.authors?.map((e) => e.name).toList() ?? []).join("/"),
      ),
      buildItemRow(
        "连载期刊",
        (item.serializations?.map((e) => e.name).toList() ?? []).join("/"),
      ),
      buildItemRow(
        "类型",
        (item.genres?.map((e) => e.name).toList() ?? []).join("/"),
      ),
      buildItemRow(
        "主题",
        (item.themes?.map((e) => e.name).toList() ?? []).join("/"),
      ),
      buildItemRow(
        "特征",
        (item.demographics?.map((e) => e.name).toList() ?? []).join("/"),
      ),
    ];
  }

  buildCharactersNote(JKTopData item) {
    return [
      buildItemRow("姓名", "${item.name}"),
      buildItemRow("日文", "${item.nameKanji}"),
      buildItemRow("昵称", (item.nicknames ?? []).join("/")),
      buildItemRow("最爱", "${item.favorites}"),
    ];
  }

  buildPeopleNote(JKTopData item, {bool? isSmall}) {
    return [
      buildItemRow(
        "姓名",
        "${item.name}",
        labelFontSize: isSmall == true ? 12 : null,
        valueFontSize: isSmall == true ? 12 : null,
      ),
      buildItemRow(
        "中文",
        "${item.familyName} ${item.givenName}",
        labelFontSize: isSmall == true ? 12 : null,
        valueFontSize: isSmall == true ? 12 : null,
      ),
      buildItemRow(
        "昵称",
        (item.alternateNames ?? []).join("/"),
        labelFontSize: isSmall == true ? 12 : null,
        valueFontSize: isSmall == true ? 12 : null,
      ),
      buildItemRow(
        "生日",
        "${item.birthday?.split('T').first}",
        labelFontSize: isSmall == true ? 12 : null,
        valueFontSize: isSmall == true ? 12 : null,
      ),
      buildItemRow(
        "最爱",
        "${item.favorites}",
        labelFontSize: isSmall == true ? 12 : null,
        valueFontSize: isSmall == true ? 12 : null,
      ),
    ];
  }
}

// 标题文字
buildTitleText(
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
buildItemRow(
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
