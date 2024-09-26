import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import '../../../apis/_default_system_role_list/inner_system_prompt.dart';
import '../../../apis/chat_completion/common_cc_apis.dart';
import '../../../apis/jikan/get_jikan_apis.dart';
import '../../../common/components/bar_chart_widget.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/constants.dart';
import '../../../common/llm_spec/cus_llm_spec.dart';
import '../../../models/chat_competion/com_cc_resp.dart';
import '../../../models/chat_competion/com_cc_state.dart';
import '../../../models/jikan/jikan_statistic.dart';
import '../../../models/jikan/jikan_data.dart';
import '../../ai_assistant/_helper/handle_cc_response.dart';
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

  // 用于显示简介和背景说明的文本，可以大模型进行翻译
  String about = "";
  String background = "";
  // 避免追加时内容变化，用于确定翻译前后的内容
  String transPattern = "\n\n【大模型翻译：】\n\n";

  // 是否加载评分统计中
  bool isScoreLoading = false;
  // 评分统计结果
  JikanStatisticData? statisticData;
  // 评分组成
  List<List<ChartData>> malScoreList = [];

  // 是否加载图片中
  bool isPictureLoading = false;
  List<JKImage> malPictureList = [];

  @override
  void initState() {
    super.initState();

    jkdata = widget.item;
    about = widget.item.synopsis ?? widget.item.about ?? "";
    background = widget.item.background ?? "";

    if ((widget.malType.value as MALType) == MALType.anime ||
        (widget.malType.value as MALType) == MALType.manga) {
      queryMALStatistic();
    }

    queryMALPicture();
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
  queryMALPicture() async {
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

  /// 简单测试的写法
  Future<void> getTrans(String text) async {
    List<CCMessage> msgs = [
      CCMessage(content: getJsonTranslatorPrompt(), role: CusRole.system.name),
      CCMessage(
        // 避免重复翻译，都使用原始的文本+翻译后的文本
        // 这样写没用，应该是改的引用，widget.item其实也改变了
        content: text == "about"
            ? about.split(transPattern).first
            : background.split(transPattern).first,
        role: CusRole.user.name,
      ),
    ];

    // 非流式的
    (await zhipuCCRespWithCancel(msgs, model: "glm-4-flash", stream: false))
        .stream
        .listen(
      (crb) {
        // print(crb.cusText);

        setState(() {
          // 避免重复翻译，都使用原始的文本+翻译后的文本
          if (text == "about") {
            about =
                "${about.split(transPattern).first}$transPattern${crb.cusText}";
          } else {
            background =
                "${background.split(transPattern).first}$transPattern${crb.cusText}";
          }
        });
      },
      onDone: () {},
    );
  }

  // 根据不同的平台、选中的不同模型，调用对应的接口，得到回复
  // 虽然返回的响应通用了，但不同的平台和模型实际取值还是没有抽出来的
  _getCCResponse(String text) async {
    // 在调用前，不会设置响应状态
    if (isBotThinking) return;
    setState(() {
      isBotThinking = true;
    });

    List<ChatMessage> messages = [
      ChatMessage(
        messageId: const Uuid().v4(),
        role: CusRole.system.name,
        content: getJsonTranslatorPrompt(),
        dateTime: DateTime.now(),
      ),
      ChatMessage(
        messageId: const Uuid().v4(),
        role: CusRole.user.name,
        // 避免重复翻译，都使用原始的文本+翻译后的文本（直接修改widget.item其实也行，因为引用改变了）
        content: text == "about"
            ? about.split(transPattern).first
            : background.split(transPattern).first,
        dateTime: DateTime.now(),
      ),
    ];

    // 获取响应流
    StreamWithCancel<ComCCResp> tempStream = await getCCResponseSWC(
      messages: messages,
      selectedPlatform: ApiPlatform.zhipu,
      selectedModel: "glm-4-flash",
      isStream: isStream,
    );

    if (!mounted) return;
    setState(() {
      respStream = tempStream;
    });

    // 在得到响应后，就直接把响应的消息加入对话列表
    // 又因为是流式的,初始时文本设为空，SSE有推送时，会更新相关栏位
    // csMsg => currentStreamingMessage
    ChatMessage? csMsg = buildEmptyAssistantChatMessage();

    setState(() {
      messages.add(csMsg!);
    });

    // 处理流式响应
    handleCCResponseSWC(
      swc: respStream,
      onData: (crb) {
        commonOnDataHandler(
          crb: crb,
          csMsg: csMsg ?? buildEmptyAssistantChatMessage(),
          // 如果是流式响应，这里结束
          onStreamDone: () {
            if (!mounted) return;
            setState(() {
              csMsg = null;
              isBotThinking = false;
              translatorLastMessage(text, messages.last.content);
            });
          },
          setIsResponsing: () {
            setState(() {
              isBotThinking = true;
            });
          },
        );
      },
      onDone: () {
        // 如果不是流式响应，这里结束
        if (!isStream) {
          if (!mounted) return;
          setState(() {
            csMsg = null;
            isBotThinking = false;
          });

          translatorLastMessage(text, messages.last.content);
        }
      },
      onError: (error) {
        commonExceptionDialog(context, "异常提示", error.toString());
      },
    );
  }

  translatorLastMessage(String text, String cusText) {
    // 避免重复翻译，都使用原始的文本+翻译后的文本
    if (text == "about") {
      about = "${about.split(transPattern).first}$transPattern$cusText";
    } else {
      background =
          "${background.split(transPattern).first}$transPattern$cusText";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text("${widget.malType.cnLabel}详情"),
      ),
      body: ListView(
        children: [
          ...buildDetail(jkdata, (widget.malType.value as MALType)),
        ],
      ),
    );
  }

  /// 构建详情页面主体内容
  buildDetail(JKData item, MALType malType) {
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
                  children: _buildSubRatingChildren(item, malType),
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

      /// 图片
      if (!isPictureLoading) ...[
        buildTitleText("图片"),
        buildPictureArea(),
      ],

      /// 简介和背景栏位
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          buildTitleText("简介"),
          IconButton(
            onPressed: () => _getCCResponse("about"),
            icon: Icon(Icons.translate, size: 20.sp),
          ),
        ],
      ),
      buildItemRow(null, about),
      // 角色和人物没有背景栏位
      if (background.isNotEmpty) ...[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            buildTitleText("背景"),
            IconButton(
              onPressed: () => _getCCResponse("background"),
              icon: Icon(Icons.translate, size: 20.sp),
            ),
          ],
        ),
        buildItemRow(null, background),
      ],
      SizedBox(height: 20.sp),
    ];
  }

  // 构建上分右侧评分和概述区域内容children
  List<Widget> _buildSubRatingChildren(JKData item, MALType malType) {
    return [
      // 漫画或动漫分类时
      if (malType == MALType.anime || malType == MALType.manga) ...[
        /// 漫画动漫的星级评分，人物角色最爱人数
        buildBgmScoreArea(item.score, total: item.scoredBy, rank: item.rank),

        // if (malType == MALType.anime) ...buildAnimeBrief(item),
        // if (malType == MALType.manga) ...buildMangaBrief(item),

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
          // 想看人数
          Divider(height: 5.sp),
          Expanded(
            child: Text(
              """${statisticData?.watching ?? statisticData?.reading}人正在看/${statisticData?.planToWatch ?? statisticData?.planToRead}人想看/${statisticData?.completed}人看过
${statisticData?.onHold}人搁置/${statisticData?.dropped}人弃坑/${statisticData?.total}总人数""",
              style: TextStyle(fontSize: 10.5.sp),
            ),
          ),
        ]
      ],

      // 人物角色分类时
      if (malType == MALType.characters || malType == MALType.people)
        // 注意，这里排名要-1,因为该组件中用的索引
        // 实际上角色和人物没有排名
        ...[
        buildFavoritesArea(item.favorites),
        if (malType == MALType.characters) ...[
          buildItemRow("日文", "${item.nameKanji}",
              maxLines: 1, labelFontSize: 12.sp, valueFontSize: 12.sp),
          buildItemRow("简介", "${item.about}",
              maxLines: 6, labelFontSize: 12.sp, valueFontSize: 12.sp),
        ],
        if (malType == MALType.people) ...buildPeopleNote(item, isSmall: true),
      ]
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
            malPictureList.map((e) => e.jpg?.imageUrl ?? "").toSet().toList(),
            prefix: "mal_",
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  /// 概要也只少数几个栏位，不同分类栏位不一样(字体要小些)
  buildAnimeBrief(JKData item) {
    return [
      buildItemRow(
        "人气",
        "No.${item.popularity}",
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
        "${item.aired?.from?.split("T").first} ~ ${item.aired?.to?.split("T").first ?? 'now'}",
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

  buildMangaBrief(JKData item) {
    return [
      buildItemRow(
        "人气",
        "No.${item.popularity}",
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
  buildAnmieNote(JKData item) {
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
        "${item.aired?.from?.split("T").first} ~ ${item.aired?.to?.split("T").first ?? 'now'}",
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

  buildMangaNote(JKData item) {
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
        "期刊",
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

  buildCharactersNote(JKData item) {
    return [
      buildItemRow("姓名", "${item.name}"),
      buildItemRow("日文", "${item.nameKanji}"),
      buildItemRow("昵称", (item.nicknames ?? []).join("/")),
      buildItemRow("最爱", "${item.favorites}"),
    ];
  }

  buildPeopleNote(JKData item, {bool? isSmall}) {
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
