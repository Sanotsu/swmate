// mal 和 bgm 页面相关组件都在这里来

// 放映计划页面的单个预览图条目
// 一般上面预览图，下面开播日期、评星、名称
import 'package:flutter/material.dart';
import 'package:flutter_rating_stars/flutter_rating_stars.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/components/tool_widget.dart';
import '../../../common/constants.dart';
import '../../../common/utils/tools.dart';

// MAL 可排名的有anime、manga、characters、people，响应的参数不太相似
enum MALType {
  anime,
  manga,
  characters,
  people,
}

List<CusLabel> malTypes = [
  CusLabel(cnLabel: "动画", value: MALType.anime),
  CusLabel(cnLabel: "漫画", value: MALType.manga),
  CusLabel(cnLabel: "角色", value: MALType.characters),
  CusLabel(cnLabel: "人物", value: MALType.people),
];

// 看起来是MAL中动画的分类
List<CusLabel> malAnimeFilterTypes = [
  CusLabel(cnLabel: "TV", value: "tv"),
  CusLabel(cnLabel: "剧场版", value: "movie"),
  CusLabel(cnLabel: "OVA", value: "ova"),
  CusLabel(cnLabel: "特典", value: "special"),
  CusLabel(cnLabel: "ONA", value: "ona"),
  CusLabel(cnLabel: "音乐", value: "music"),
];

// 播放日分类
List<CusLabel> malWeekFilterTypes = [
  CusLabel(cnLabel: "全部", value: null),
  CusLabel(cnLabel: "星期一", value: "monday"),
  CusLabel(cnLabel: "星期二", value: "tuesday"),
  CusLabel(cnLabel: "星期三", value: "wednesday"),
  CusLabel(cnLabel: "星期四", value: "thursday"),
  CusLabel(cnLabel: "星期五", value: "friday"),
  CusLabel(cnLabel: "星期六", value: "saturday"),
  CusLabel(cnLabel: "星期天", value: "sunday"),
  CusLabel(cnLabel: "未知", value: "unknown"),
  CusLabel(cnLabel: "其他", value: "other"),
];

// 季节分类
List<CusLabel> malSeasonFilterTypes = [
  // 一月番
  CusLabel(cnLabel: "冬季番", value: "winter"),
  // 四月番
  CusLabel(cnLabel: "春季番", value: "spring"),
  // 七月番
  CusLabel(cnLabel: "夏季番", value: "summer"),
  // 十月番
  CusLabel(cnLabel: "秋季番", value: "fall"),
];

// MAL中部分简单的英文翻译成中文的枚举（仅用在显示中）
Map<String, String> malSeasonMap = {
  "winter": "冬季番",
  "spring": "春季番",
  "summer": "夏季番",
  "fall": "秋季番",
};

// bangumi 可排名的有1 = book, 2 = anime, 3 = music, 4 = game, 6 = real.没有5
List<CusLabel> bgmTypes = [
  CusLabel(cnLabel: "书籍", value: 1),
  CusLabel(cnLabel: "动画", value: 2),
  CusLabel(cnLabel: "音乐", value: 3),
  CusLabel(cnLabel: "游戏", value: 4),
  CusLabel(cnLabel: "三次元", value: 6),
];

List<CusLabel> bgmEpTypes = [
  CusLabel(cnLabel: "本篇", value: 0),
  CusLabel(cnLabel: "特别篇", value: 1),
  CusLabel(cnLabel: "音乐OP", value: 2),
  CusLabel(cnLabel: "ED", value: 3),
  CusLabel(cnLabel: "预告/宣传/广告", value: 4),
  CusLabel(cnLabel: "MAD", value: 5),
  CusLabel(cnLabel: "其他", value: 6),
];

///
/// 网格，上方预览图+下方简单名称，一排可以多个
///
Widget buildPreviewTileCard(
  BuildContext context,
  // 预览图片地址
  String imageUrl,
  // 开播日期
  String airDate,
  // 评分
  double score,
  // 评分人数
  int total,
  // 动画的标题
  String title, {
  // 点击跳转的目标页面
  Widget? targetPage,
}) {
  SizedBox imageArea = SizedBox(
    height: 150.sp,
    child: Padding(
      padding: EdgeInsets.all(2.sp),
      child: buildImageGridTile(
        context,
        imageUrl,
        fit: BoxFit.cover,
        isClickable: false,
      ),
    ),
  );

  // 开播时间
  var airDateArea = Text(
    "开播 $airDate",
    maxLines: 1,
    style: TextStyle(fontSize: 10.sp),
    textAlign: TextAlign.center,
  );

  // 评分区域
  var ratingArea = Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text("$score", style: TextStyle(fontSize: 15.sp)),
      SizedBox(width: 5.sp),
      Column(
        children: [
          RatingStars(
            axis: Axis.horizontal,
            value: score,
            starCount: 5,
            starSize: 12.sp,
            starSpacing: 2.sp,
            // 评分的最大值
            maxValue: 10,
            starOffColor: Colors.grey[300]!,
            // 填充时的星星颜色
            starColor: Colors.orange,
            // 不显示评分的文字，只显示星星
            valueLabelVisibility: false,
          ),
          Text("$total 评价", style: TextStyle(fontSize: 10.sp)),
        ],
      )
    ],
  );

  // 标题
  var titleArea = Text(
    title,
    // 大部分的标题2行可以显示，查看完整的还是进入详情页面吧
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
    textAlign: TextAlign.center,
  );

  return GestureDetector(
    // 单击预览
    onTap: targetPage != null
        ? () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => targetPage),
            );
          }
        : null,
    child: Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// 预览图片
          imageArea,
          Flexible(
            child: Column(children: [airDateArea, ratingArea, titleArea]),
          ),
        ],
      ),
    ),
  );
}

///
///  列表，左侧预览图+右边简单介绍，一排一般一个
///
class OverviewItem extends StatelessWidget {
  // 预览图地址
  final String imageUrl;
  // 条目名称
  final String title;
  // 评分部件(MAL可能是显示评分或者收藏，所以直接传入)
  final Widget rankWidget;
  // 概述的介绍部件列表
  final List<Widget> overviewList;
  // 点击跳转的目标页面
  final Widget? targetPage;
  // 文件下载的前缀
  final String prefix;
  // 图片展示的方式
  final BoxFit imageFit;

  const OverviewItem({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.rankWidget,
    required this.overviewList,
    this.targetPage,
    this.prefix = "mal",
    this.imageFit = BoxFit.scaleDown,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: targetPage != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => targetPage!),
              );
            }
          : null,
      child: Card(
        margin: EdgeInsets.all(5.sp),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Padding(
                padding: EdgeInsets.all(2.sp),
                child: buildImageGridTile(
                  context,
                  imageUrl,
                  prefix: prefix,
                  fit: imageFit,
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
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                  rankWidget,
                  const SizedBox(height: 5),
                  ...overviewList,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

///
/// 用户评分(详情页面的，要比预览页面要大些)
///
Widget buildBgmScoreArea(double? score, {int? total, int? rank}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text("${score ?? 0}", style: TextStyle(fontSize: 20.sp)),
      Column(
        children: [
          RatingStars(
            axis: Axis.horizontal,
            value: score ?? 0,
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
            "${total ?? 0}人评价",
            style: TextStyle(fontSize: 12.sp),
          ),
        ],
      ),
      if (rank != null && rank != 0)
        Container(
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
        ),
    ],
  );
}

///
/// MAL的角色和人物的排名是用户收藏
///
Widget buildFavoritesArea(int? favorites, {int? index}) {
  return Row(
    children: [
      Text(
        "${favorites ?? 0}人最爱",
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

///
/// 构建页面上action位置的使用说明按钮
///
Widget buildInfoButtonOnAction(BuildContext context, String note) {
  return IconButton(
    onPressed: () {
      commonMDHintModalBottomSheet(
        context,
        "说明",
        note,
        msgFontSize: 15.sp,
      );
    },
    icon: const Icon(Icons.info_outline),
  );
}

///
/// 固定的分类下拉框
/// 已经确定类型为 CusLabel，栏位提示为"分类"
///
class TypeDropdown extends StatelessWidget {
  final CusLabel? selectedValue;
  final List<CusLabel> items;
  final String? label;
  final String? hintLabel;
  // 下拉框宽度
  final double? width;
  final Function(CusLabel?) onChanged;

  const TypeDropdown({
    super.key,
    required this.selectedValue,
    required this.items,
    this.label,
    this.hintLabel,
    this.width,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(5.sp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            label ?? "分类: ",
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            width: width ?? 80.sp,
            child: buildDropdownButton2<CusLabel>(
              value: selectedValue,
              items: items,
              hintLabel: hintLabel ?? "选择分类",
              onChanged: onChanged,
              itemToString: (e) => (e as CusLabel).cnLabel,
            ),
          ),
        ],
      ),
    );
  }
}

///
/// 固定的关键字输入框行
///
class KeywordInputArea extends StatelessWidget {
  final TextEditingController searchController;
  final String hintText;
  final VoidCallback? onSearchPressed;
  final void Function(String)? textOnChanged;
  final double? height;
  final String? buttonHintText;

  const KeywordInputArea({
    super.key,
    required this.searchController,
    required this.hintText,
    this.onSearchPressed,
    this.height,
    this.buttonHintText,
    this.textOnChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? 32.sp,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.sp),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: hintText,
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
                onChanged: textOnChanged,
              ),
            ),
            SizedBox(width: 10.sp),
            SizedBox(
              width: 80.sp,
              child: ElevatedButton(
                style: buildFunctionButtonStyle(),
                onPressed: onSearchPressed,
                child: Text(buttonHintText ?? "搜索"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

///
/// 一般详情页中加粗的标题文字
///
Widget buildTitleText(
  String title, {
  double? fontSize = 16,
  Color? color = Colors.black54,
  TextAlign? textAlign = TextAlign.start,
}) {
  return Padding(
    padding: EdgeInsets.all(5.sp),
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

/// 正文文字
/// 一般详情页中的正文行，一个标签一个正文构成的行
Widget buildContentRow(
  String? label,
  String value, {
  double? labelFontSize,
  double? valueFontSize,
  int? maxLines,
  bool? isSmall,
}) {
  return Row(
    children: [
      if (label != null)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.sp),
          child: Text(
            label,
            style: TextStyle(
              fontSize: labelFontSize ?? (isSmall == true ? 12 : 14.sp),
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
              fontSize: valueFontSize ?? (isSmall == true ? 12 : 14.sp),
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

/// 构建跳转其他页面按钮
/// 一般在详情页的跳转到分集介绍、番组计划有用
Widget buildGotoButton(
  BuildContext context,
  String label,
  Widget targetPage,
) {
  return TextButton.icon(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetPage),
      );
    },
    icon: const Icon(Icons.arrow_right, color: Colors.blue),
    iconAlignment: IconAlignment.end,
    label: Text(
      label,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        // color: Theme.of(context).primaryColor,
        color: Colors.blue,
      ),
    ),
  );
}

/// 详情页面中构建关联人物或角色的卡片
/// 一般是上面为预览图，下面为姓名、岗位或职责(图方便暂时为一个Map)
/// 点击时需要带上编号进行跳转的目标详情页
class RelatedCardList<T, K> extends StatelessWidget {
  final String label;
  final List<Map<String, dynamic>> list;
  final Widget Function(T, K)? targetPageBuilder;
  final T Function(Map<String, dynamic>)? dataExtractor;
  final K Function(Map<String, dynamic>)? typeExtractor;

  const RelatedCardList({
    super.key,
    required this.label,
    required this.list,
    this.targetPageBuilder,
    this.dataExtractor,
    this.typeExtractor,
  });

  Widget _genCard(BuildContext context, Map<String, dynamic> item) {
    if (targetPageBuilder != null) {
      if (dataExtractor == null || typeExtractor == null) {
        throw Exception("需要跳转页面时必须传入完整参数");
      }
    }

    return GestureDetector(
      // 单击预览
      onTap: targetPageBuilder != null
          ? () {
              final T data = dataExtractor!(item);
              final K type = typeExtractor!(item);
              Navigator.push(
                context,
                MaterialPageRoute(
                  // bgm 和 mal 跳转子页面的参数类型不一样
                  builder: (context) => targetPageBuilder!(data, type),
                ),
              );
            }
          : null,
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
                  item["imageUrl"]!,
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
                    item["name"]!.toString(),
                    maxLines: 2,
                    style: TextStyle(fontSize: 10.sp),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  Expanded(child: Container()),
                  Text(
                    item["sub1"]!.toString(),
                    maxLines: 1,
                    style: TextStyle(fontSize: 10.sp),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    item["sub2"]!.toString(),
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
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTitleText(label),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            // direction: Axis.horizontal,
            // alignment: WrapAlignment.spaceAround,
            children: list.isNotEmpty
                ? List.generate(
                    list.length,
                    // 这个尺寸和上面的图片要配合好
                    (index) => SizedBox(
                      height: 180.sp,
                      width: 110.sp,
                      child: _genCard(context, list[index]),
                    ),
                  ).toList()
                : [],
          ),
        )
      ],
    );
  }
}

///
/// (详情页)构建可调用外部浏览器打开url的标题文字
buildUrlTitle(BuildContext context, String title, {String? url}) {
  return TextButton(
    onPressed: url != null ? () => launchStringUrl(url) : null,
    child: Text(
      title,
      style: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
      textAlign: TextAlign.center,
    ),
  );
}

///  (详情页)预览图和评分区域(评分区域由于结构差距，这里简单当作子组件传入)
Widget buildImageAndRatingArea(
  BuildContext context,
  String imageUrl, // 图片地址
  String imgDlPrefix, // 图片下载的名称前缀
  List<Widget> subList, // 右侧评分或简介的组件列表
) {
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
                imageUrl,
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
              children: subList,
            ),
          ),
        ],
      ),
    ),
  );
}

/// 带有可翻译按钮的标题组件
/// 用于mal详情页英文标题翻译成中文等地方
class TranslatableTitleButton extends StatefulWidget {
  final String title;
  final String? url;

  const TranslatableTitleButton({super.key, required this.title, this.url});

  @override
  State<TranslatableTitleButton> createState() =>
      _TranslatableTitleButtonState();
}

class _TranslatableTitleButtonState extends State<TranslatableTitleButton> {
  String? translatedText;

  Future<void> _translateText() async {
    String translation = await getAITranslation(widget.title);
    setState(() {
      translatedText = translation;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: widget.url != null
                    ? () => launchStringUrl(widget.url!)
                    : null,
                child: Text(
                  "${widget.title}${translatedText != null ? '($translatedText)' : ''}",
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // 两个按钮都显示占太宽了，如果翻译结果不满意，关闭后再点击
            (translatedText != null && translatedText!.isNotEmpty)
                ? IconButton(
                    onPressed: () => setState(() => translatedText = null),
                    icon: Icon(Icons.clear, size: 16.sp),
                  )
                : IconButton(
                    onPressed: _translateText,
                    icon: Icon(Icons.translate, size: 16.sp),
                  ),
          ],
        ),
      ],
    );
  }
}

/// 带有可翻译按钮的正文组件
/// 用于mal详情页简介翻译成中文等地方
class TranslatableText extends StatefulWidget {
  final String text;
  // 是否是追加模式，不是就直接替换
  final bool? isAppend;

  const TranslatableText({
    super.key,
    required this.text,
    this.isAppend = true,
  });

  @override
  State<TranslatableText> createState() => _TranslatableTextState();
}

class _TranslatableTextState extends State<TranslatableText> {
  String? translatedText;

  Future<void> _translateText() async {
    String translation = await getAITranslation(widget.text);
    setState(() {
      translatedText = translation;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              onPressed: _translateText,
              icon: Icon(Icons.translate, size: 20.sp),
            ),
            if (translatedText != null && translatedText!.isNotEmpty)
              IconButton(
                onPressed: () => setState(() => translatedText = null),
                icon: Icon(Icons.clear, size: 20.sp),
              ),
          ],
        ),
        if (widget.isAppend == false)
          Padding(
            padding: EdgeInsets.all(5.sp),
            child: Text(
              translatedText ?? widget.text,
              // style: TextStyle(
              //   fontSize: 14.sp,
              //   color: Theme.of(context).primaryColor,
              // ),
            ),
          ),
        if (widget.isAppend == true) ...[
          Padding(
            padding: EdgeInsets.all(5.sp),
            child: Text(
              widget.text,
              // style: TextStyle(
              //   fontSize: 14.sp,
              //   color: Theme.of(context).primaryColor,
              // ),
            ),
          ),
          if (translatedText != null)
            Padding(
              padding: EdgeInsets.all(5.sp),
              child: Text(
                "【AI翻译】\n${translatedText!}",
                // style: TextStyle(
                //   fontSize: 14.sp,
                //   color: Colors.grey[600],
                // ),
              ),
            ),
        ],
      ],
    );
  }
}
