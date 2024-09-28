import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../apis/chat_completion/common_cc_apis.dart';
import '../../../apis/jikan/get_jikan_apis.dart';
import '../../../common/components/bar_chart_widget.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/constants.dart';
import '../../../models/chat_competion/com_cc_resp.dart';
import '../../../models/jikan/jikan_related_character_resp.dart';
import '../../../models/jikan/jikan_statistic.dart';
import '../../../models/jikan/jikan_data.dart';
import '_components.dart';

class MALItemDetail extends StatefulWidget {
  final JKData item;
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
  bool isBotThinking = false;
  bool isStream = false;
  StreamWithCancel<ComCCResp> respStream = StreamWithCancel.empty();

  late JKData jkdata;

  // 是否加载评分统计中
  bool isScoreLoading = false;
  // 评分统计结果
  JikanStatisticData? statisticData;
  // 评分组成
  List<List<ChartData>> malScoreList = [];

  // 详情页中额外查询的，暂时只有图片、角色表(原本就是角色、人物进来的就只有图片)
  // 是否加载图片中
  bool isPictureLoading = false;
  List<JKImage> malPictureList = [];

  bool isCharacterLoading = false;
  List<JKRelatedCharacter> malCharacterList = [];

  /// 注意请求限制：每秒最多3次，每分钟最多60次
  /// 所以默认进来就只有查询统计，图片、角色表，单独获取
  bool isShowPicture = false;
  bool isShowCharacter = false;

  @override
  void initState() {
    super.initState();

    jkdata = widget.item;

    if ((widget.malType.value as MALType) == MALType.anime ||
        (widget.malType.value as MALType) == MALType.manga) {
      queryMALStatistic();
    }
  }

  // 查询当前mal条目的评分统计
  queryMALStatistic() async {
    if (isScoreLoading) return;

    setState(() {
      isScoreLoading = true;
    });

    var stat = await getAMStatistics(
      jkdata.malId,
      type: (widget.malType.value as MALType),
    );

    if (!mounted) return;
    setState(() {
      statisticData = stat.data;

      // 先清空
      malScoreList.clear();
      var tempList = stat.data.scores ?? [];

      List<ChartData> tempScores = [];
      for (var e in tempList) {
        tempScores.add(ChartData("${e.score}星", e.percentage));
      }

      // 从左往右日期逐渐变大，所以数据要翻转
      malScoreList.addAll([
        tempScores.reversed.toList(),
      ]);
    });

    setState(() {
      isScoreLoading = false;
    });
  }

  // 查询图片
  queryMALPictures() async {
    if (isPictureLoading) return;

    setState(() {
      isPictureLoading = true;
    });

    var pics = await getJikanPictures(
      jkdata.malId,
      type: (widget.malType.value as MALType),
    );

    if (!mounted) return;
    setState(() {
      // 添加图片
      malPictureList = pics;
    });

    setState(() {
      isPictureLoading = false;
    });
  }

  /// 查询角色
  queryMALCharacters() async {
    if (isCharacterLoading) return;

    setState(() {
      isCharacterLoading = true;
    });

    var temp = await getJikanRelatedCharacters(
      widget.item.malId,
      type: (widget.malType.value as MALType),
    );

    if (!mounted) return;
    setState(() {
      // 添加图片
      malCharacterList = temp.data;
    });

    setState(() {
      isCharacterLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text("${widget.malType.cnLabel}详情"),
      ),
      body: buildBodyDetail(jkdata, (widget.malType.value as MALType)),
    );
  }

  /// 构建详情页面主体内容
  Widget buildBodyDetail(JKData item, MALType malType) {
    return ListView(
      children: [
        /// 标题
        TranslatableTitleButton(
          title: item.title ?? item.name ?? "",
          url: item.url,
        ),

        /// 预览图和评分区域
        buildImageAndRatingArea(
          context,
          item.images.jpg?.imageUrl ?? "",
          "mal",
          _buildSubRatingChildren(item, malType),
        ),

        /// 显示角色表、图片集、演职表
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // 只有动画和漫画才显示角色表
            if ((widget.malType.value as MALType) == MALType.anime ||
                (widget.malType.value as MALType) == MALType.manga)
              TextButton(
                onPressed: () {
                  setState(() => isShowCharacter = !isShowCharacter);
                  // 如果角色不为空，则已经查询过了，不用再查了，直接展示即可
                  if (isShowCharacter && malCharacterList.isEmpty) {
                    queryMALCharacters();
                  }
                },
                child: Text(isShowCharacter ? "隐藏角色表" : "显示角色表"),
              ),
            TextButton(
              onPressed: () {
                setState(() => isShowPicture = !isShowPicture);
                // 如果图片不为空，则已经查询过了，不用再查了，直接展示即可
                if (isShowPicture && malPictureList.isEmpty) {
                  queryMALPictures();
                }
              },
              child: Text(isShowPicture ? "隐藏图片集" : "显示图片集"),
            ),
          ],
        ),
        if (isShowCharacter) buildCharacterArea(),
        if (isShowPicture) buildPictureArea(),

        /// 基础信息栏位
        buildTitleText("信息"),
        if (malType == MALType.anime) ...buildAnmieNote(item),
        if (malType == MALType.manga) ...buildMangaNote(item),
        if (malType == MALType.characters) ...buildCharactersNote(item),
        if (malType == MALType.people) ...buildPeopleNote(item),

        /// 简介和背景栏位
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [buildTitleText("简介")],
        ),
        TranslatableText(
          text: item.synopsis ?? item.about ?? "",
          isAppend: false,
        ),

        /// 角色和人物没有背景栏位
        if (item.background != null && item.background!.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              buildTitleText("背景"),
            ],
          ),
          TranslatableText(text: item.background ?? "", isAppend: false),
        ],
        SizedBox(height: 20.sp),
      ],
    );
  }

  // 构建上分右侧评分和概述区域内容children
  List<Widget> _buildSubRatingChildren(JKData item, MALType malType) {
    return [
      // 漫画或动漫分类时
      if (malType == MALType.anime || malType == MALType.manga) ...[
        /// 漫画动漫的星级评分，人物角色最爱人数
        buildBgmScoreArea(item.score, total: item.scoredBy, rank: item.rank),

        /// 评分人数分布
        if (!isScoreLoading) ...[
          SizedBox(
            height: 80.sp,
            child: BarChartWidget(
              seriesData: malScoreList,
              seriesColors: const [Colors.orange],
              seriesNames: const ["MAL评分"],
            ),
          ),
          Divider(height: 10.sp),

          /// 想看人数
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildCollectSize(
                        "在看 ${statisticData?.watching ?? statisticData?.reading}人"),
                    _buildCollectSize(
                        "想看 ${statisticData?.planToWatch ?? statisticData?.planToRead}人"),
                    _buildCollectSize("看过 ${statisticData?.completed}人"),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildCollectSize("搁置 ${statisticData?.onHold}人"),
                    _buildCollectSize("弃坑 ${statisticData?.dropped}人"),
                    _buildCollectSize("总数 ${statisticData?.total}人"),
                  ],
                )
              ],
            ),
          ),
        ]
      ],

      // 人物角色分类时
      if (malType == MALType.characters || malType == MALType.people)
        // 注意，实际上角色和人物没有排名
        ...[
        buildFavoritesArea(item.favorites),
        SizedBox(height: 5.sp),
        if (malType == MALType.characters)
          ...buildCharactersNote(item, isSmall: true),
        if (malType == MALType.people) ...buildPeopleNote(item, isSmall: true),
      ]
    ];
  }

  _buildCollectSize(String label) {
    return Expanded(
      child: Text(label, style: TextStyle(fontSize: 10.5.sp)),
    );
  }

  /// 动漫的图片
  Widget buildPictureArea() {
    Widget genGrid() {
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
              malPictureList.map((e) => e.jpg?.imageUrl ?? "").toSet().toList(),
              prefix: "mal_",
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    /// 图片只放一行，可以横向滚动显示
    return isPictureLoading
        ? buildLoader(isPictureLoading)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTitleText("图片集"),
              genGrid(),
            ],
          );
  }

  /// 动漫的角色表
  Widget buildCharacterArea() {
    return isCharacterLoading
        ? buildLoader(isCharacterLoading)
        : RelatedCardList<JKData, CusLabel>(
            label: "角色表",
            list: malCharacterList
                .map((e) => {
                      "id": e.character,
                      "imageUrl": e.character?.images.jpg?.imageUrl ?? "",
                      "name": e.character?.name,
                      "sub1": e.role,
                      "sub2": "${e.favorites}人最爱",
                      // 子组件中取来作为参数的栏位
                      // 角色的数据
                      "data": e.character,
                      // 类型要为角色
                      "type": CusLabel(
                        cnLabel: "角色",
                        value: MALType.characters,
                      ),
                    })
                .toList(),
            // 2024-09-28 由于关联查询的角色栏位不全，而复用的mal详情页面没有使用id重新查询
            // 所有详情页的角色表，就暂时不点击跳转了
            // targetPageBuilder: (JKData data, CusLabel type) =>
            //     MALItemDetail(item: data, malType: type),
            // dataExtractor: (Map<String, dynamic> item) => item["data"],
            // typeExtractor: (Map<String, dynamic> item) => item["type"],
          );
  }

  /// 因为4种类型的栏位差距过大，所以各自单独处理，就算有重复的也无所谓了
  List<Widget> buildAnmieNote(JKData item) {
    return [
      buildContentRow(
        "又名",
        (item.titles?.map((e) => e.title).toList() ?? []).join("/"),
      ),
      buildContentRow("类别", "${item.type}"),
      buildContentRow("来源", "${item.source}"),
      buildContentRow("集数", "${item.episodes}"),
      buildContentRow("状态", "${item.status}"),
      buildContentRow("完播", item.airing == true ? '放映中' : '已完结'),
      buildContentRow(
        "放送",
        "${item.aired?.from?.split("T").first} ~ ${item.aired?.to?.split("T").first ?? 'now'}",
      ),
      buildContentRow("时长", "${item.duration}"),
      buildContentRow("分级", "${item.rating}"),
      buildContentRow("评分", "${item.score}"),
      buildContentRow("评分人数", "${item.scoredBy}"),
      buildContentRow("排名", "${item.rank}"),
      buildContentRow("人气", "${item.popularity}"),
      buildContentRow("成员", "${item.members}"),
      buildContentRow("最爱", "${item.favorites}"),
      buildContentRow("分季", "${malSeasonMap[item.season]}"),
      buildContentRow("年份", "${item.year}"),
      buildContentRow("播放", "${item.broadcast?.string}"),
      buildContentRow(
        "特征",
        (item.demographics?.map((e) => e.name).toList() ?? []).join("/"),
      ),
      buildContentRow(
        "出品方",
        (item.producers?.map((e) => e.name).toList() ?? []).join("/"),
      ),
      buildContentRow(
        "工作室",
        (item.studios?.map((e) => e.name).toList() ?? []).join("/"),
      ),
      buildContentRow(
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

  List<Widget> buildMangaNote(JKData item) {
    return [
      buildContentRow(
        "又名",
        (item.titles?.map((e) => e.title).toList() ?? []).join("/"),
      ),
      buildContentRow("类别", "${item.type}"),
      buildContentRow("章数", "${item.chapters}"),
      buildContentRow("册数", "${item.volumes}"),
      buildContentRow("状态", "${item.status}"),
      buildContentRow("连载", item.publishing == true ? '连载中' : '已完结'),
      buildContentRow(
        "周期",
        "${item.published?.from?.split("T").first} ~ ${(item.published?.to?.split("T").first) ?? 'now'}",
      ),
      buildContentRow("评分", "${item.score}"),
      buildContentRow("评分人数", "${item.scoredBy}"),
      buildContentRow("排名", "${item.rank}"),
      buildContentRow("人气", "${item.popularity}"),
      buildContentRow("成员", "${item.members}"),
      buildContentRow("最爱", "${item.favorites}"),
      buildContentRow(
        "作者",
        (item.authors?.map((e) => e.name).toList() ?? []).join("/"),
      ),
      buildContentRow(
        "期刊",
        (item.serializations?.map((e) => e.name).toList() ?? []).join("/"),
      ),
      buildContentRow(
        "类型",
        (item.genres?.map((e) => e.name).toList() ?? []).join("/"),
      ),
      buildContentRow(
        "主题",
        (item.themes?.map((e) => e.name).toList() ?? []).join("/"),
      ),
      buildContentRow(
        "特征",
        (item.demographics?.map((e) => e.name).toList() ?? []).join("/"),
      ),
    ];
  }

  List<Widget> buildCharactersNote(JKData item, {bool? isSmall}) {
    return [
      buildContentRow("姓名", "${item.name}", isSmall: isSmall),
      buildContentRow("日文", "${item.nameKanji}", isSmall: isSmall),
      buildContentRow("昵称", (item.nicknames ?? []).join("/"), isSmall: isSmall),
      buildContentRow("最爱", "${item.favorites} 人", isSmall: isSmall),
    ];
  }

  List<Widget> buildPeopleNote(JKData item, {bool? isSmall}) {
    return [
      buildContentRow("姓名", "${item.name}", isSmall: isSmall),
      buildContentRow("中文", "${item.familyName ?? ''} ${item.givenName}",
          isSmall: isSmall),
      buildContentRow("昵称", (item.alternateNames ?? []).join("/"),
          isSmall: isSmall),
      buildContentRow("生日", item.birthday?.split('T').first ?? '',
          isSmall: isSmall),
      buildContentRow("最爱", "${item.favorites} 人", isSmall: isSmall),
    ];
  }
}
