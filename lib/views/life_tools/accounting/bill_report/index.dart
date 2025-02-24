import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../../common/components/tool_widget.dart';
import '../../../../common/constants.dart';
import '../../../../common/utils/db_tools/db_life_tool_helper.dart';
import '../../../../models/base_model/brief_accounting_state.dart';

/// 绘制图表时，用于展示数据需要的结构
class ChartData {
  // 构建实例时注意位置参数的位置
  ChartData(this.x, this.y, [this.text, this.color]);
  // 分类
  final String x;
  // 分类对应的值
  final double y;
  // 分类标签显示的文本
  final String? text;
  // 该值用的颜色
  final Color? color;
}

class BillReportIndex extends StatefulWidget {
  const BillReportIndex({super.key});

  @override
  State<BillReportIndex> createState() => _BillReportIndexState();
}

class _BillReportIndexState extends State<BillReportIndex>
    with SingleTickerProviderStateMixin {
  late TooltipBehavior _tooltip;

  final DBLifeToolHelper _dbHelper = DBLifeToolHelper();
  // 定义TabController
  late TabController _tabController;

  // 账单可查询的范围，默认为当前，查询到结果之后更新
  SimplePeriodRange billPeriod = SimplePeriodRange(
    minDate: DateTime.now(),
    maxDate: DateTime.now(),
  );

  ///
  /// 月度统计相关的变量
  ///
  // 被选中的月份(yyyy-MM格式，作为查询条件或者反格式化为Datetime时，手动补上day)
  String selectedMonth = DateFormat(constMonthFormat).format(DateTime.now());
  // 月度统计列表数据
  late List<BillPeriodCount> monthCounts = [];
  // 月度项次列表数据
  late List<BillItem> monthBillItems = [];
  // 默认展示支出统计，切换到收入时变为false，也是用于按钮是否可用
  bool isMonthExpendClick = true;
  // 是否在加载月度统计数据
  bool isMonthLoading = false;

  ///
  /// 年度统计相关的变量(使用两套主要为了在月度做了一些操作之后切到年度，再切到月度时保留之前的操作后结果)
  ///
  // 被选中的年份(yyyy格式，作为查询条件或者反格式化为Datetime时，手动补上day)
  String selectedYear = DateFormat.y().format(DateTime.now());
  late List<BillPeriodCount> yearCounts = [];
  late List<BillItem> yearBillItems = [];
  // 默认展示支出统计，切换到收入时变为false，也是用于按钮是否可用
  bool isYearExpendClick = true;
  // 是否在加载年度统计数据
  bool isYearLoading = false;

  @override
  void initState() {
    _tooltip = TooltipBehavior(enable: true);

    // 初始化TabController
    _tabController = TabController(vsync: this, length: 2, initialIndex: 0);
    // 监听Tab切换
    _tabController.addListener(_handleTabSelection);

    getBillPeriod();

    // 初始化时就加载两个月的数据，虽然默认是展示月度，但切换都年度时不用重新初始化。
    // 后续再切换年度月度，都有可见的数据，在没改变选中的年月时不用重新查询。
    handleSelectedMonthChange();
    handleSelectedYearChange();

    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 获取数据库中账单记录的日期起迄范围
  getBillPeriod() async {
    var tempPeriod = await _dbHelper.queryDateRangeList();
    setState(() {
      billPeriod = tempPeriod;
    });
  }

  /// 获取指定月的统计数据(参考微信是指定月前后一起半年数据，做柱状图)
  _getMonthCount() async {
    // 选中2023-04
    // date 2023-04-01 00:00:01
    DateTime date =
        DateTime.tryParse("$selectedMonth-01 00:00:01") ?? DateTime.now();

    // start=2023-02-01 00:00:01
    var startDate = DateTime(date.year, date.month - 2, date.day);

    // end=2023-07-01 00:00:01
    var endDate = DateTime(date.year, date.month + 3, date.day);
    // 如果查询的终止范围超过最新的月份，则修正终止月份为当前月份
    if (endDate.isAfter(billPeriod.maxDate)) {
      endDate = billPeriod.maxDate;
      startDate = DateTime(endDate.year, endDate.month - 6, endDate.day);
    }

    String start = DateFormat(constMonthFormat).format(startDate);
    String end = DateFormat(constMonthFormat).format(endDate);

    var temp = await _dbHelper.queryBillCountList(
      countType: "month",
      startDate: "$start-01",
      endDate: "$end-31",
    );

    setState(() {
      monthCounts = temp;
    });
  }

  /// 获取指定年的统计数据(同上，只查询3年的数据)
  _getYearCount() async {
    DateTime date = DateTime.tryParse("$selectedYear-01-01") ?? DateTime.now();
    var startDate = DateTime(date.year - 1, date.month, date.day);
    var endDate = DateTime(date.year + 1, date.month, date.day);
    // 如果查询的终止范围超过最新的月份，则修正终止月份为当前月份
    // 起值超过了有记录的年份，返回结果统计时不会有该年份，柱状图就知道有记录的起止
    if (endDate.isAfter(billPeriod.maxDate)) {
      endDate = billPeriod.maxDate;
      startDate = DateTime(endDate.year - 2, endDate.month, endDate.day);
    }

    String start = DateFormat.y().format(startDate);
    String end = DateFormat.y().format(endDate);

    var temp = await _dbHelper.queryBillCountList(
      countType: "year",
      startDate: "$start-01-01",
      endDate: "$end-12-31",
    );

    setState(() {
      yearCounts = temp;
    });
  }

  // 获取指定月份的详细数据
  _getMonthBillItemList() async {
    var temp = await _dbHelper.queryBillItemList(
      startDate: "$selectedMonth-01",
      endDate: "$selectedMonth-31",
      page: 1,
      pageSize: 0,
    );
    var newData = temp.data as List<BillItem>;

    setState(() {
      monthBillItems = newData;
    });
  }

  // 获取指定年份的详细数据
  _getYearBillItemList() async {
    var temp = await _dbHelper.queryBillItemList(
      startDate: "$selectedYear-01-01",
      endDate: "$selectedYear-12-31",
      page: 1,
      pageSize: 0,
    );
    var newData = temp.data as List<BillItem>;

    setState(() {
      yearBillItems = newData;
    });
  }

  /// 切换了选中月份的查询函数
  void handleSelectedMonthChange() async {
    if (isMonthLoading) {
      return;
    }

    setState(() {
      isMonthLoading = true;
      monthCounts.clear();
      monthBillItems.clear();
    });

    await _getMonthCount();
    await _getMonthBillItemList();

    setState(() {
      isMonthLoading = false;
    });
  }

  /// 切换了选中年份的查询函数
  void handleSelectedYearChange() async {
    if (isYearLoading) {
      return;
    }

    setState(() {
      isYearLoading = true;
      yearCounts.clear();
      yearBillItems.clear();
    });
    // // 在当前上下文中查找最近的 FocusScope 并使其失去焦点，从而收起键盘。
    // 如果在init之类的地方使用，这个context会报错的
    // FocusScope.of(context).unfocus();
    await _getYearCount();
    await _getYearBillItemList();

    setState(() {
      isYearLoading = false;
    });
  }

  ///
  /// 处理Tab切换(目前无实际作用)
  ///
  /// 不做任何处理时，默认点击tab标签切换tab，这里会重复触发？？？
  /// 这是预期行为，参看：https://github.com/flutter/flutter/issues/13848
  ///
  _handleTabSelection() {
    // tab is animating. from active (getting the index) to inactive(getting the index)
    if (_tabController.indexIsChanging) {
      debugPrint("点击切换了tab--${_tabController.index}");
      // if (_tabController.index == 1) {
      //   // 如果是切换了月度统计和年度统计，重新查询
      //   debugPrint("isYearLoading--------$isYearLoading");
      //   _handleSelectedMonthChange();
      // } else {
      //   debugPrint("isMonthLoading--------$isMonthLoading");
      //   _handleSelectedYearChange();
      // }
    } else {
      // tab is finished animating you get the current index
      // here you can get your index or run some method once.
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        // 避免搜索时弹出键盘，让底部的minibar位置移动到tab顶部导致溢出的问题
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.lightGreen,
          title: const Text('账单统计'),
          // AppBar的preferredSize默认是固定的（对于标准AppBar来说是kToolbarHeight,56）
          // 如果不显示title，可以适当减小
          // toolbarHeight: kToolbarHeight - 36,
          // title: null,
          bottom: TabBar(
            // overlayColor: WidgetStateProperty.all(Colors.lightGreen),
            controller: _tabController,
            // onTap: (int i) {
            //   debugPrint("当前index${_tabController.index}-------点击的index$i");
            //   // 这里没法获取到前一个index是哪一个，
            //   if (i == 1) {
            //     _handleSelectedYearChange();
            //   } else {
            //     _handleSelectedMonthChange();
            //   }
            // },
            // 让tab按钮两边留空，更居中一点
            padding: EdgeInsets.symmetric(horizontal: 0.25.sw, vertical: 5.sp),
            tabs: const <Widget>[
              Tab(text: "月账单"),
              Tab(text: "年账单"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: <Widget>[
            // 月度账单页
            buildTabBarView('month'),
            // 年度账单页
            buildTabBarView('year'),
          ],
        ),
      ),
    );
  }

  ///
  /// 年度月度公共的方法
  ///
  /// 构建年度月度账单Tab页面
  buildTabBarView(String billType) {
    bool loadingFlag = ((billType == "month") ? isMonthLoading : isYearLoading);
    return Column(
      children: [
        buildChangeRow(billType),
        loadingFlag
            ? buildLoader(loadingFlag)
            : Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildCountRow(billType),
                      buildBarChart(billType),
                      buildPieChart(billType),
                      buildRankingTop(billType),
                    ],
                  ),
                ),
              ),
      ],
    );
  }

  /// 年度月度日期选择行
  /// 按月显示收支列表详情的月度切换按钮和月度收支总计的行
  buildChangeRow(String billType) {
    bool isMonth = billType == "month";
    return Container(
      height: 36.sp,
      color: Colors.lightGreen, // 显示占位用
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              width: 100.sp,
              child: TextButton.icon(
                // 按钮带标签默认icon在前面
                iconAlignment: IconAlignment.end,
                onPressed: () {
                  showMonthPicker(
                    context: context,
                    firstDate: billPeriod.minDate,
                    lastDate: billPeriod.maxDate,
                    initialDate: isMonth
                        ? DateTime.tryParse("$selectedMonth-01")
                        : DateTime.tryParse("$selectedYear-01-01"),
                    onlyYear: isMonth ? false : true,
                    monthPickerDialogSettings: MonthPickerDialogSettings(
                      headerSettings: PickerHeaderSettings(
                        // 不显示标头，只能滚动选择
                        // hideHeaderRow: true,
                        headerPadding: EdgeInsets.all(10.sp),
                      ),
                      dialogSettings: PickerDialogSettings(
                        // 不缩放默认title会溢出// 但这个比例不同设备怎么控制？？？
                        textScaleFactor: 0.9,
                        // 一定要先选择年
                        yearFirst: isMonth ? false : true,
                        // 弹窗自定义宽度(毕竟是弹窗，无法100%)
                        customWidth: 1.sw,
                      ),
                    ),
                  ).then((date) {
                    if (date != null) {
                      setState(() {
                        if (isMonth) {
                          selectedMonth =
                              DateFormat(constMonthFormat).format(date);
                          handleSelectedMonthChange();
                        } else {
                          selectedYear = date.year.toString();
                          handleSelectedYearChange();
                        }
                      });
                    }
                  });
                },
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                ),
                label: Text(
                  isMonth ? selectedMonth : selectedYear,
                  style: TextStyle(fontSize: 15.sp, color: Colors.white),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 50.sp,
            height: 20.sp,
            child: ElevatedButton(
              // 取掉按钮内边距，或者改到自己想要的大小
              style: ElevatedButton.styleFrom(
                // minimumSize: Size.zero,
                padding: EdgeInsets.symmetric(horizontal: 5.sp),
                // tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                // backgroundColor: Colors.lightGreen,
              ),
              onPressed: isMonth
                  ? (isMonthExpendClick
                      ? null
                      : () {
                          setState(() {
                            isMonthExpendClick = !isMonthExpendClick;
                          });
                        })
                  : (isYearExpendClick
                      ? null
                      : () {
                          setState(() {
                            isYearExpendClick = !isYearExpendClick;
                          });
                        }),
              autofocus: true,
              child: const Text("支出"),
            ),
          ),
          SizedBox(width: 10.sp),
          SizedBox(
            width: 50.sp,
            height: 20.sp,
            child: ElevatedButton(
              // 取掉按钮内边距，或者改到自己想要的大小
              style: ElevatedButton.styleFrom(
                // minimumSize: Size.zero,
                padding: EdgeInsets.symmetric(horizontal: 5.sp),
                // tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                // backgroundColor: Colors.lightGreen,
              ),
              onPressed: isMonth
                  ? (!isMonthExpendClick
                      ? null
                      : () {
                          setState(() {
                            isMonthExpendClick = !isMonthExpendClick;
                          });
                        })
                  : (!isYearExpendClick
                      ? null
                      : () {
                          setState(() {
                            isYearExpendClick = !isYearExpendClick;
                          });
                        }),
              child: const Text("收入"),
            ),
          ),
          SizedBox(width: 10.sp),
        ],
      ),
    );
  }

  /// 年度或月度统计行
  buildCountRow(String billType) {
    bool isMonth = billType == "month";

    // 获取支出/收入项次数量字符串
    getCounts(List<BillItem> items, bool isExpend) {
      var counts = items.where((e) => e.itemType == (isExpend ? 1 : 0)).length;
      return "共${isExpend ? '支出' : '收入'} $counts 笔，合计";
    }

    // 获取支出/收入金额总量字符串
    getTotal(List<BillPeriodCount> counts, String date, bool isExpend) {
      if (counts.isEmpty) return "";

      // 2024-06-03 统计记录可能没有对应月份的数据。
      //  比如6月1日查看统计，还没有账单项次记录，最新的只有5月份的
      var temp = counts.where((e) => e.period == date).toList();
      if (temp.isNotEmpty) {
        return "￥${isExpend ? temp.first.expendTotalValue : temp.first.incomeTotalValue}";
      }
      return isExpend ? '暂无支出' : '暂无收入';
    }

    var titleText = isMonth
        ? getCounts(monthBillItems, isMonthExpendClick)
        : getCounts(yearBillItems, isYearExpendClick);

    var textCount = isMonth
        ? getTotal(monthCounts, selectedMonth, isMonthExpendClick)
        : getTotal(yearCounts, selectedYear, isYearExpendClick);

    return Container(
      color: Colors.lightGreen,
      height: 50.sp,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ListTile(
            dense: true,
            title: Text(
              titleText,
              style: TextStyle(fontSize: 15.sp, color: Colors.white),
            ),
            trailing: Text(
              textCount,
              style: TextStyle(fontSize: 24.sp, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }

  /// 绘制收入支出柱状图(指定年度或月度字符串:yaer|month)
  buildBarChart(String billType) {
    // 不是月度，就是年度
    bool isMonth = billType == "month";

    return SizedBox(
      height: 200.sp, // 图表还是绝对高度吧，如果使用相对高度不同设备显示差异挺大
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20.sp, top: 5.sp),
            child: Text(
              isMonth
                  ? "${isMonthExpendClick ? '支出' : '收入'}对比￥"
                  : "${isYearExpendClick ? '支出' : '收入'}对比￥",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
          ),
          Expanded(
            child: SfCartesianChart(
              // x轴的一些配置
              primaryXAxis: CategoryAxis(
                // labelRotation: -60,
                // 隐藏x轴网格线
                majorGridLines: MajorGridLines(width: 0.sp),
                // 格式化x轴的刻度标签
                axisLabelFormatter: (AxisLabelRenderDetails details) {
                  // 默认的标签样式继续用，简单修改字体大小即可
                  TextStyle newStyle = details.textStyle.copyWith(
                    fontSize: isMonth ? 8.sp : 12.sp,
                  );

                  /// 格式化x轴标签日期文字(中文年月太长了)
                  // 获取当前区域
                  Locale locale = Localizations.localeOf(context);
                  // 获取月份标签，转为日期格式，再转为符合区域格式的日期年月字符串
                  var newLabel = "";
                  if (isMonth) {
                    newLabel = DateFormat.yM(locale.toString()).format(
                      DateTime.tryParse("${details.text}-01") ?? DateTime.now(),
                    );
                  } else {
                    newLabel = DateFormat.y(locale.toString()).format(
                      DateTime.tryParse("${details.text}-01-01") ??
                          DateTime.now(),
                    );
                  }
                  return ChartAxisLabel(newLabel, newStyle);
                },
              ),
              // y轴的一些配置
              primaryYAxis: const NumericAxis(
                // 隐藏y轴网格线
                majorGridLines: MajorGridLines(width: 0),
                // 不显示y轴标签
                isVisible: false,
              ),
              // 点击柱子的提示行为
              tooltipBehavior: _tooltip,
              // 柱子图数据
              series: <CartesianSeries<BillPeriodCount, String>>[
                ColumnSeries<BillPeriodCount, String>(
                  dataSource: isMonth ? monthCounts : yearCounts,
                  xValueMapper: (BillPeriodCount data, _) => data.period,
                  yValueMapper: (BillPeriodCount data, _) =>
                      (isMonth ? isMonthExpendClick : isYearExpendClick)
                          ? data.expendTotalValue
                          : data.incomeTotalValue,
                  width: 0.6, // 柱的宽度
                  spacing: 0.4, // 柱之间的间隔
                  name: isMonth
                      ? (isMonthExpendClick ? '支出' : '收入')
                      : (isYearExpendClick ? '支出' : '收入'),
                  color: const Color.fromRGBO(8, 142, 255, 1),
                  // 根据索引设置不同的颜色，高亮第三个柱子（索引为2，因为索引从0开始）
                  pointColorMapper: (BillPeriodCount value, int index) {
                    if (value.period ==
                        (isMonth ? selectedMonth : selectedYear)) {
                      return Colors.green; // 高亮颜色
                    } else {
                      return Colors.black12; // 其他柱子的颜色
                    }
                  },
                  // 数据标签的配置(默认不显示)
                  dataLabelSettings: DataLabelSettings(
                    // 显示数据标签
                    isVisible: true,
                    // 数据标签的位置
                    // labelAlignment: ChartDataLabelAlignment.bottom,
                    // 格式化标签组件（可以换成图标等其他部件）
                    builder: (dynamic data, dynamic point, dynamic series,
                        int pointIndex, int seriesIndex) {
                      var d = (data as BillPeriodCount);
                      return Text(
                        isMonth
                            ? "${isMonthExpendClick ? d.expendTotalValue : d.incomeTotalValue}"
                            : "${isYearExpendClick ? d.expendTotalValue : d.incomeTotalValue}",
                        style: TextStyle(fontSize: 10.sp),
                      );
                    },
                  ),
                  // 格式化标签文字字符串
                  // dataLabelMapper: (datum, index) {
                  //   return "￥${datum.expendTotalValue}";
                  // },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  buildPieChart(String billType) {
    // 不是月度，就是年度
    bool isMonth = billType == "month";

    // 获取支出/收入饼图数据
    getCateCounts(List<BillItem> items, bool isExpend) {
      // 先过滤是统计支出还是收入
      var tempList = items.where((e) => e.itemType == (isExpend ? 1 : 0));
      // 总的收入或者支出(分类求占比时的分母)
      double total = tempList.fold(0, (sum, item) => sum + item.value);

      // 再按照分类分组
      var groupByCate = groupBy(tempList, (item) => item.category);
      // 构建饼图需要的数据结构
      final List<ChartData> chartData = [];
      // 最后分组计算累加值
      for (var entry in groupByCate.entries) {
        // 存在null值就用未分类代替
        String cate = entry.key ?? "未分类";
        // 分类后的列表
        List<BillItem> itemsForCate = entry.value;
        // 计算分类后的累加值
        double cateTotal = itemsForCate.fold(
          0,
          (sum, item) => sum + item.value,
        );

        // 添加到图表数据列表中
        chartData.add(ChartData(
          cate,
          double.parse(cateTotal.toStringAsFixed(2)),
          "$cate:${((cateTotal / total) * 100).toStringAsFixed(2)}%",
        ));
      }

      // 从大到小排个序(？？？如果只显示top5的话，可以把小于前5的合并到一个“其他”分类去)
      chartData.sort((a, b) => b.y.compareTo(a.y));

      return chartData;
    }

    // 如果分类统计的数据为空，就不用显示饼图了
    List<ChartData> data = isMonth
        ? getCateCounts(monthBillItems, isMonthExpendClick)
        : getCateCounts(yearBillItems, isYearExpendClick);

    if (data.isEmpty) {
      return Container();
    }

    return SizedBox(
      height: 300.sp, // 图表还是绝对高度吧，如果使用相对高度不同设备显示差异挺大
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20.sp, top: 5.sp),
            child: Text(
              isMonth
                  ? "${isMonthExpendClick ? '支出' : '收入'}构成"
                  : "${isYearExpendClick ? '支出' : '收入'}构成",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
          ),
          Expanded(
            child: SfCircularChart(
              // 点击分类图显示提示
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <CircularSeries>[
                DoughnutSeries<ChartData, String>(
                  dataSource: data,
                  xValueMapper: (ChartData data, _) => data.x,
                  yValueMapper: (ChartData data, _) => data.y,
                  // 改变饼在整个图表所占比例(默认80%)
                  radius: '60%',
                  // 内圆的占比(越大内部孔就越大)
                  innerRadius: '50%',
                  // Segments will explode on tap
                  explode: true,
                  // First segment will be exploded on initial rendering
                  explodeIndex: 1,
                  // 多于的归位“其他”分类中(有自定义的标签，加上这个显示不太对劲，所以要针对index处理)
                  groupMode: CircularChartGroupMode.point,
                  groupTo: 7,
                  // 用于映射数据源中的文本(更详细的自定义用下面dataLabelSettings的builder)
                  // dataLabelMapper: (ChartData data, _) => data.text,
                  // 数据标签的配置(默认不显示)
                  dataLabelSettings: DataLabelSettings(
                    // 默认显示标签
                    isVisible: true,
                    // 标签相关使用对应分类图表的颜色
                    useSeriesColor: true,
                    // 智能排列数据标签，避免标签重叠时的交叉。
                    labelIntersectAction: LabelIntersectAction.shift,
                    // 标签显示的位置
                    labelPosition: ChartDataLabelPosition.outside,
                    // 标签和图连接线的设置
                    connectorLineSettings: ConnectorLineSettings(
                      // 指定连接线的形状
                      type: ConnectorType.line,
                      // 指定连接线的长度
                      length: '20%',
                      // 指定连接线的线宽
                      width: 1.sp,
                    ),
                    // 隐藏值为0的数据
                    showZeroValue: false,
                    // 自定义数据标签的外观
                    builder: (dynamic data, dynamic point, dynamic series,
                        int pointIndex, int seriesIndex) {
                      var d = (data as ChartData);
                      // 因为上面groupTo设定为7,这里大于7的都显示其他
                      if (pointIndex < 7) {
                        return Text(
                          d.text ?? "未分类",
                          style: TextStyle(fontSize: 10.sp),
                        );
                      } else {
                        return Text(
                          "其他",
                          style: TextStyle(fontSize: 10.sp),
                        );
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 按照数值大小倒序查看账单项次
  /// 这里应该是按照category大类分类统计，然后点击查看该分类的账单列表。暂时先这样
  buildRankingTop(String billType) {
    bool isMonth = billType == "month";

    // 按选择类型获取支出或收入的数据列表
    var orderedItems = isMonth
        ? (monthBillItems
            .where(
                (e) => isMonthExpendClick ? e.itemType != 0 : e.itemType == 0)
            .toList())
        : (yearBillItems
            .where((e) => isYearExpendClick ? e.itemType != 0 : e.itemType == 0)
            .toList());
    // 按照值降序排序
    orderedItems.sort((a, b) => b.value.compareTo(a.value));

    // 年度统计的，只要top10
    if (!isMonth) {
      orderedItems =
          orderedItems.length > 10 ? orderedItems.sublist(0, 10) : orderedItems;
    }

    // 如果没有账单列表数据，显示空提示
    if (orderedItems.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 50.sp),
          const Icon(Icons.file_present),
          const Text("暂无数据"),
        ],
      );
    }

    /// 有账单条目列表则创建并显示
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 20.sp, top: 5.sp, bottom: 10.sp),
          child: Text(
            isMonth
                ? "${isMonthExpendClick ? '支出' : '收入'}排行"
                : "${isYearExpendClick ? '支出' : '收入'}排行前十",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
          ),
        ),
        ListView.builder(
          shrinkWrap: true, // 允许ListView根据内容大小来包裹其内容
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(0),
          itemCount: orderedItems.length,
          itemBuilder: (BuildContext context, int index) {
            BillItem i = orderedItems[index];

            return Padding(
              // 设置内边距
              padding: EdgeInsets.fromLTRB(10.sp, 5.sp, 10.sp, 15.sp),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 5.sp),
                  SizedBox(
                    width: 25.sp,
                    child: Text("${index + 1}"),
                  ),
                  SizedBox(width: 5.sp),
                  // 后续模拟支出收入分类的图标
                  // 2024-09-12 flutter默认图标的rmb是一横，日语是两横
                  // 但实际上两者应该是一样的，都是两横
                  // currency_yuan、currency_yen
                  Icon(Icons.currency_yen, color: Colors.orange[300]!),
                  SizedBox(width: 5.sp),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i.item,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        RichText(
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          text: TextSpan(
                            children: [
                              // 为了分类占的宽度一致才用的，只是显示的话可不必
                              WidgetSpan(
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: 50.sp),
                                  child: Text(
                                    i.category ?? "<未分类>",
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ),
                              ),
                              TextSpan(
                                text: i.date,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // // 用上面那个一行更好看
                        // Text(
                        //   i.category ?? "<未分类>",
                        //   softWrap: true,
                        //   overflow: TextOverflow.ellipsis,
                        //   maxLines: 1,
                        //   style: TextStyle(fontSize: 10.sp),
                        // ),
                        // Text(
                        //   "${i.date}__${i.gmtModified ?? ''}",
                        //   softWrap: true,
                        //   overflow: TextOverflow.ellipsis,
                        //   maxLines: 1,
                        //   style: TextStyle(fontSize: 10.sp),
                        // )
                      ],
                    ),
                  ),
                  // 金额这里固定最大99999.99吧
                  SizedBox(
                    width: 90.sp,
                    child: Text(
                      "￥${i.value}",
                      style: TextStyle(fontSize: 15.sp),
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );

            /// ListTile dense为true默认高度48(否则为56),导致这个card高度56(64)，有些高了
            // return Card(
            //   // margin: EdgeInsets.all(5.sp), // 外边距
            //   elevation: 5,
            //   color: Colors.blueGrey,
            //   child: ListTile(
            //     dense: true,
            //     title: Text(
            //       "${index + 1} ${i.item}",
            //       softWrap: true,
            //       overflow: TextOverflow.ellipsis,
            //       maxLines: 1,
            //       style: TextStyle(fontSize: 15.sp),
            //     ),
            //     trailing: Text(
            //       "￥${i.value}",
            //       style: TextStyle(fontSize: 15.sp),
            //     ),
            //   ),
            // );
          },
        ),
      ],
    );
  }
}
