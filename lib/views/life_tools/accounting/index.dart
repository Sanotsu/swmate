import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

import '../../../common/components/tool_widget.dart';
import '../../../common/constants.dart';
import '../../../common/utils/db_tools/db_life_tool_helper.dart';
import '../../../models/base_model/brief_accounting_state.dart';
import 'bill_item_modify/index.dart';
import 'bill_report/index.dart';

/// 2024-05-28
/// 账单列表，按月查看
///   默认显示当前月的所有账单项次，并额外显示每天的总计的支出和收入；
///   点击选中年月日期，可切换到其他月份；选中的月份所在行有当月总计的支出和收入。
///   在显示选中月日期的清单时，如果有的话，可以上拉加载上一个月的项次数据，下拉加载后一个月的项次数据；
///     如果当前加载的账单项次不止一个月的数据，则在滚动时大概估算到当前展示的是哪一个月的项次，来更新显示的选中日期；
///     实现逻辑：
///         主要是绘制好每月项次列表后，保留每个月占用的总高度，存入数组；
///         根据滚动控制器得到当前已经加载的高度，和保留每个月总高度的对象列表进行比较；
///         如果“上一个的累加高度 <=  已加载的高度 < 当前的累加高度”，则当前月就是要展示的月份
///     两点注意：
///         1 存每月列表组件高度的数组存的是月份排序后的累加高度：
///            [{'2024-03': 240}, // 3月份组件总高度 240
///             {'2024-02': 490}, // 4月份组件总高度 490-240=250
///             {'2024-01': 630}, // 5月份组件总高度 630-490=140
///             {'2023-12': 670}, // ...
///             // ... 更多的月份数据];
///         2 滚动控制器总加载的高度和实际组件逐个计算的高度不一致，原因不明？？？
class BillItemIndex extends StatefulWidget {
  const BillItemIndex({super.key});

  @override
  State<BillItemIndex> createState() => _BillItemIndexState();
}

class _BillItemIndexState extends State<BillItemIndex> {
  final DBLifeToolHelper _dbHelper = DBLifeToolHelper();
  // 账单项次的列表滚动控制器
  ScrollController scrollController = ScrollController();

  // 是否查询账单项次中
  bool isLoading = false;
  // 单纯的账单条目列表
  List<BillItem> billItems = [];
  // 按日分组后的账单条目对象(key是日期，value是条目列表)
  Map<String, List<BillItem>> billItemGroupByDayMap = {};

  // 2024-05-27 因为默认查询有额外的分组统计等操作，
  // 所以关键字查询条目的展示要和默认的区分开来
  bool isQuery = false;
  // 关键字输入框控制器
  TextEditingController searchController = TextEditingController();

  // 账单可查询的范围，默认为当前，查询到结果之后更新
  SimplePeriodRange billPeriod = SimplePeriodRange(
    minDate: DateTime.now(),
    maxDate: DateTime.now(),
  );

  // 被选中的月份(yyyy-MM格式，作为查询条件或者反格式化为Datetime时，手动补上day)
  String selectedMonth = DateFormat(constMonthFormat).format(DateTime.now());

  // 虽然是已查询的最大最小日期，但逻辑中只关注年月，所以日最好存1号，避免产生影响
  DateTime minQueryedDate = DateTime.now();
  DateTime maxQueryedDate = DateTime.now();

  // 用户滑动的滚动方向，往上拉是up，往下拉时down，默认为none
  // 往上拉到头时获取更多数据就是取前一个月的，往下拉到头获取更多数据就是后一个月的
  String scollDirection = "none";

  // 用一个map来保存每个月份的条目数据组件的总高度
  // 如果加载了多个月份的数据，可以用列表已滚动的高度和每个月的组件总高度进行对比，得到当前月份
  List<Map<String, double>> monthlyWidgetHeights = [];

  var categoryList = [
    // 饮食
    "三餐", "外卖", "零食", "夜宵", "烟酒", "饮料",
    // 购物
    "购物", "买菜", "日用", "水果", "买花", "服装",
    // 娱乐
    "娱乐", "电影", "旅行", "运动", "纪念", "充值",
    // 住、行
    "交通", "住房", "房租", "房贷",
    // 生活
    "理发", "还款",
  ];

  // 选中查询的类型，默认是全部，可切换到“支出|收入|全部”
  String selectedType = "全部账单";

  @override
  void initState() {
    super.initState();

    // 2024-05-25 初始化查询时就更新已查询的最大日期和最小日期为当天所在月份的1号(后续用到的地方也只关心年月)
    maxQueryedDate = DateTime.tryParse("$selectedMonth-01") ?? DateTime.now();
    minQueryedDate = DateTime.tryParse("$selectedMonth-01") ?? DateTime.now();

    getBillPeriod();
    loadBillItemsByMonth();

    scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  /// 获取数据库中账单记录的日期起迄范围
  getBillPeriod() async {
    var tempPeriod = await _dbHelper.queryDateRangeList();

    // 异步执行结果，如果没挂载了，就不管了
    if (!mounted) return;
    setState(() {
      billPeriod = tempPeriod;
    });
  }

  /// 查询指定月份账单项次列表
  /// 获取系统当月的所有账单条目查询出来(这样每日、月度统计就是正确的)，
  /// 下滑显示完当月数据化，加载上一个月的所有数据出来
  /// 2024-05-27 这个查询不带关键字，有专门带关键字的查询函数
  Future<void> loadBillItemsByMonth() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    CusDataResult temp = await _dbHelper.queryBillItemList(
      startDate: "$selectedMonth-01",
      endDate: "$selectedMonth-31",
      page: 1,
      pageSize: 0,
    );

    var newData = temp.data as List<BillItem>;

    // 异步执行结果，如果没挂载了，就不管了
    if (!mounted) return;
    setState(() {
      // 2024-05-24 这里不能直接添加，还需要排序，不然上拉后下拉日期新的列表在日期旧的列表后面
      if (scollDirection == "down") {
        billItems.insertAll(0, newData);
      } else {
        billItems.addAll(newData);
      }

      // 加载完所有项次列表之后，要计算每个月项次组件的总高度，用于后续计算滑动所在的月份
      _computeMonthWidgetHeights();

      // 按照每天进行项次分组，方便后续计算每日的总支出/收入
      billItemGroupByDayMap = groupBy(billItems, (item) => item.date);

      // 数据加载成功也更新账单中有的时间范围
      getBillPeriod();

      isLoading = false;
    });
  }

  // 查询选中月份的总支出/收入信息
  Future<List<BillPeriodCount>?> loadBillCountByMonth() async {
    try {
      return await _dbHelper.queryBillCountList(
        startDate: "$selectedMonth-01",
        endDate: "$selectedMonth-31",
      );
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  /// 2024-05-28 根据已经滚动的高度和每个月份所在列表子组件的总高度的map，获得当前月份
  // 假设列表项高度是固定的，并且 monthlyWidgetHeights 是每月列表的累积高度
  String _getCurrentMonth(double scrollPosition) {
    // 初始化一个变量来存储上一个月份的累积高度
    double prevCumulativeHeight = 0;

    // 遍历月份累积高度列表
    for (int i = 0; i < monthlyWidgetHeights.length; i++) {
      // 当前月份的累积高度
      double currentCumulativeHeight = monthlyWidgetHeights[i].values.first;

      // 检查滚动位置是否在当前月份和前一个月份之间
      // 注意：当i == 0时，prevCumulativeHeight为0，这对应于列表的顶部
      if (scrollPosition >= prevCumulativeHeight &&
          scrollPosition < currentCumulativeHeight) {
        // 滚动位置位于当前月份内，返回当前月份
        return monthlyWidgetHeights[i].keys.first;
      }

      // 更新上一个月份的累积高度为当前月份的累积高度
      prevCumulativeHeight = currentCumulativeHeight;
    }

    // 如果滚动位置超过所有月份的高度，返回最后一个月份
    // 注意：这通常不会发生，除非滚动位置在列表底部之外，但这里作为一个安全网
    return monthlyWidgetHeights.last.keys.first;
  }

  /// listview 滚动的侦听器，有以下功能：
  ///   1、上拉滚动到当月数据项次结束，则加载上一个月的数据；同理下拉到头加载下一个月的数据；
  ///   2、如果列表中有多个月份的数据，根据每个月份组件的累计高度和已加载的列表高度比较，得到当前显示的列表所在的月份。
  void _scrollListener() {
    if (isLoading) return;

    // 最大滚动范围(注意，这个 maxScrollExtent 的值在滚动过程中是变化的)
    final maxScrollExtent = scrollController.position.maxScrollExtent;
    // 已经滚动的高度
    final currentPosition = scrollController.position.pixels;
    // 已经滚动的高度(这两个是一样的？？？应该只是方向一致时)
    final offset = scrollController.offset;
    // 是否在顶部(最小滚动位置)
    final atEdge = scrollController.position.atEdge;
    // 是否超出滚动范围
    final outOfRange = scrollController.position.outOfRange;

    // 根据已经滚动的高度和提前存好账单列表组件的累积高度计算出当前展示的项次是哪个月份的
    String currentMonth = _getCurrentMonth(currentPosition);
    // 如果有多个月份的数据在滚动时，估算显示当前月份，并更新显示
    setState(() {
      selectedMonth = currentMonth;
    });

    /// 滚动到顶部，加载下一个月数据
    // 但是已经达到了账单记录的最大日期和最小日期月份，则不再加载了。
    if (atEdge && currentPosition == 0) {
      // 如果要查询的下一个月在已查询的最大月份之前，则更新下一个月为已查询最大月
      // 比如一直往上拉，已有202304-202308的数据，因为往上拉，此时被选中的月份是2023-04。
      // 现在往下拉到顶，应该查询2022309的数据，因为选中的是2023-04,不做任何处理的话查询的实际是202305的值，这不对。
      // 所以直接使用已查询的最大日期去+1查最新数据，并更新选中月份
      DateTime nextMonthDate = DateTime(
        maxQueryedDate.year,
        maxQueryedDate.month + 1,
        maxQueryedDate.day,
      );

      String nextMonth = DateFormat(constMonthFormat).format(nextMonthDate);
      // 如果当前月份的下一月的1号已经账单中最大日期了，就算到顶了也没有数据可加载乐
      if (nextMonthDate.isAfter(billPeriod.maxDate)) {
        setState(() {
          selectedMonth = DateFormat(constMonthFormat).format(maxQueryedDate);
        });
        return;
      }

      // 正常下拉加载更新的数据，要更新当前选中值和最大查询日期
      setState(() {
        selectedMonth = nextMonth;
        maxQueryedDate = nextMonthDate;
        scollDirection = "down";
        loadBillItemsByMonth();
      });
    } else if (atEdge && !outOfRange && offset >= maxScrollExtent) {
      /// 滚动到底部，查询下一个月的数据(看往上拉的逻辑说明)

      DateTime lastMonthDate = DateTime(
        minQueryedDate.year,
        minQueryedDate.month - 1,
        minQueryedDate.day,
      );
      String lastMonth = DateFormat(constMonthFormat).format(lastMonthDate);

      // 如果当前月份已经账单中最大日期了，到顶了也不再加载
      if (lastMonthDate.isBefore(billPeriod.minDate)) {
        setState(() {
          selectedMonth = DateFormat(constMonthFormat).format(minQueryedDate);
        });
        return;
      }

      // 上拉还有旧数据可查就继续查询
      setState(() {
        selectedMonth = lastMonth;
        minQueryedDate = lastMonthDate;
        scollDirection = "up";
        loadBillItemsByMonth();
      });
    }
  }

  // 查询指定月份的账单项次数据
  // 在切换了当前月份等情况下回用到
  void handleSearch() {
    setState(() {
      billItems.clear();
      scollDirection == "none";
    });
    // 在当前上下文中查找最近的 FocusScope 并使其失去焦点，从而收起键盘。
    FocusScope.of(context).unfocus();

    loadBillItemsByMonth();
  }

  // 关键字查询和带统计值得查询不一样，专门函数区分，避免异动之前的逻辑
  // 带关键字查询的就没有滚动加载更多了，注意查询结果特别大的时候，可能会有性能问题？？？
  void handleKeywordSearch({pageSize = 0}) async {
    // 在当前上下文中查找最近的 FocusScope 并使其失去焦点，从而收起键盘。
    // 如果要在init等地方使用，不能加这个，因为那时候还没有context
    FocusScope.of(context).unfocus();

    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    setState(() {
      billItems.clear();
      scollDirection == "none";
    });

    CusDataResult temp = await _dbHelper.queryBillItemList(
      itemKeyword: searchController.text.trim(),
      page: 1,
      pageSize: pageSize,
    );

    var newData = temp.data as List<BillItem>;

    // 异步执行结果，如果没挂载了，就不管了
    if (!mounted) return;
    setState(() {
      // 关键字查询结果，直接添加，没有其他顺序，
      billItems.addAll(newData);
      // 因为和带统计的账单项次复用构建列表组件，所以这个分组还是要有
      billItemGroupByDayMap = groupBy(billItems, (item) => item.date);
      isLoading = false;
    });
  }

  /*
  // 2024-05-27 当前带统计的每月子组件的结构如下，要计算其总高度
  Card(   // 边框有 8 
    child: Column(
      children: [
        ListTile(dense: true), // 48
        // Divider(),  // 16
        Column(
          children: [
            GestureDetector(child: ListTile()), // 64 固定有title和subtitle
            GestureDetector(child: ListTile()), // 64
            ...
  ])]));
  不过累加的值和实际的值对不上。
  比如5月测试数据，额外的ListTile*15,原本GestureDetector(child:ListTile())*42,
  计算的高度：15*(48+16+8[card的边框])+56*42=3432
  实际ListView滚动的总高度：3030
  */
  _computeMonthWidgetHeights() {
// 每次都要重新计算，避免累加
    monthlyWidgetHeights.clear();

    // 按照月份分组
    var temp = groupBy(billItems, (item) => item.date.substring(0, 7));

    var monthHegth = 0.0;
    for (var i = 0; i < temp.entries.length; i++) {
      var entry = temp.entries.toList()[i];

      // 处理每个月份的数据
      String tempMonth = entry.key;
      // 每个月实际拥有的账单项次数量
      List<BillItem> tempMonthItems = entry.value;

      // 按天分组统计支出收入的额外项次的数量
      var extraItemsLength =
          groupBy(tempMonthItems, (item) => item.date).entries.length;

      // 当前月份的组件总高度
      monthHegth += tempMonthItems.length * 64.0 + extraItemsLength * (48 + 8);
      // 实际测试，滚动的值比计算的值要小一些：
      //    第1、2个月份计算结果差402，第3个月差388，第4、5、6个月346，第7个月差332，第8个月318……
      //    没有继续下去，原因不明？？？暂时第一个月少算402,后面的几十个像素基本对得上。
      if (i == 0) {
        monthHegth -= 402;
      }

      // 注意，这里存的是每个月的累加高度
      monthlyWidgetHeights.add({tempMonth: monthHegth});
    }
  }

  /// 单纯导入账单列表json文件
  Future<void> loadBillIeamFromJson() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: ["json", "JSON"],
    );

    if (result != null) {
      try {
        // 不允许多选，理论就是第一个文件，且不为空
        File file = File(result.files.first.path!);

        // 如果是json文件
        String jsonData = await file.readAsString();
        // 默认json文件存的是列表
        List jsonList = json.decode(jsonData);

        // 保存到db
        // 先判断是否存在必要栏位
        bool flag = jsonList.every((e) =>
            e['item_type'] != null &&
            e['date'] != null &&
            e['item'] != null &&
            e['value'] != null);

        if (!mounted) return;
        if (!flag) {
          return commonExceptionDialog(context, "导入失败", "json文件结构栏位不正确");
        }

        // 使用工厂方法创建 BillItem 实例
        List<BillItem> temp = jsonList.map((e) {
          // 忽略用户的编号，通用使用uuid(fromJson中如果值为null会自动创建)
          e["bill_item_id"] = null;
          return BillItem.fromJson(e);
        }).toList();

        // 导入前，先删除所有旧的，因为json文件中没有id不好修改
        await _dbHelper.clearBillItems();
        await _dbHelper.insertBillItemList(temp);

        if (!mounted) return;
        commonHintDialog(context, "导入成功", "已导入选中的账单数据");
      } catch (e) {
        rethrow;
      }
    }
  }

  Widget _buildPopupMenuButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_outlined),
      // 调整弹出按钮的位置
      position: PopupMenuPosition.under,
      // 弹出按钮的偏移
      // offset: Offset(-25.sp, 0),
      onSelected: (String value) async {
        // 处理选中的菜单项
        if (value == 'info') {
          commonMDHintModalBottomSheet(
            context,
            "使用说明",
            """1. 长按账单条目可以进行删除;
2. 双击账单条目可以进行修改;
3. 支持指定结构的json文件导入，会覆盖已有数据;
```
[
  {
    // 0 收入,1 支出
    "item_type": 0, 
    "category": "工资",
    "item": "工资",
    "value": 2874.0
    "date": "2016-07-01",
  },
  //...
]
```
""",
            msgFontSize: 15.sp,
          );
        } else if (value == 'import') {
          setState(() {
            billItems.clear();
            scollDirection == "none";
            isLoading = true;
          });

          await loadBillIeamFromJson();

          if (!context.mounted) return;
          setState(() {
            isLoading = false;
          });

          await loadBillItemsByMonth();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
        buildCusPopupMenuItem(context, "import", "导入账单", Icons.file_upload),
        buildCusPopupMenuItem(context, "info", "使用说明", Icons.info_outline),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 避免搜索时弹出键盘，让底部的minibar位置移动到tab顶部导致溢出的问题
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("极简记账"),
        // 明确说明不要返回箭头，避免其他地方使用push之后会自动带上返回箭头
        // leading: const Icon(Icons.arrow_back),
        backgroundColor: Colors.lightGreen,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BillEditPage(),
                ),
              ).then((value) {
                // 如果有新增成功，则重新查询当前月份数据
                if (value != null && value) {
                  setState(() {
                    // 注意，这里返回后，默认查询的是当前选中的月份
                    // 比如选中的是6月份，新增的是8月份，就得滚到8月份去看
                    handleSearch();
                  });
                }
              });
            },
            icon: Icon(
              Icons.add_outlined,
              color: Theme.of(context).primaryColor,
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BillReportIndex(),
                ),
              );
            },
            icon: Icon(
              Icons.bar_chart_outlined,
              color: Theme.of(context).primaryColor,
            ),
          ),
          _buildPopupMenuButton(),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            /// test 已查询的月度范围
            buildQueryRangeRow(),

            /// 2024-05-27 展开关键字查询时，隐藏当月的统计行
            if (!isQuery) buildMonthCountRow(),

            /// 当选中了关键字查询，才展示条目关键字搜索行
            if (isQuery) buildSearchRow(),

            /// 构建账单条目列表(关键字查询和默认统计查询都用这个，内部有区分)
            buildBillItemList(),
          ],
        ),
      ),
    );
  }

  /// 显示已加载的账单项次范围，或者查询时显示可查询的范围
  buildQueryRangeRow() {
    String locale = Localizations.localeOf(context).toString();
    return Container(
      height: 50.sp,
      // color: Colors.amberAccent,
      color: Colors.lightGreen,
      child: Padding(
        padding: EdgeInsets.fromLTRB(15.sp, 0, 4, 0),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text(isQuery ? "可查询的数据范围" : "已加载的数据范围")),
            Expanded(
              flex: 4,
              // 不是关键字查询时展示范围为滚动查询的范围，是关键字查询时就是账单起止范围
              child: Text(
                !isQuery
                    ? "${DateFormat.yM(locale).format(minQueryedDate)}~${DateFormat.yM(locale).format(maxQueryedDate)}"
                    : "${DateFormat.yM(locale).format(billPeriod.minDate)}~${DateFormat.yM(locale).format(billPeriod.maxDate)}",
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
              ),
            ),
            // 2024-05-27 点击按钮切换是否显示关键字查询区块
            SizedBox(
              width: 60.sp,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    isQuery = !isQuery;
                    // 如果点击之后是展开或者收起查询区域，都要重置已经输入的关键字
                    searchController.text = "";
                    // 如果是收起查询区域，则要重新展示当前月的列表及统计数据
                    if (!isQuery) {
                      handleSearch();
                    } else {
                      // 如果是进入了关键字查询，默认展示10条
                      // 没有这个查询，切到关键字查询时显示的是之前带统计的已查询的所有列表
                      // _handleKeywordSearch(pageSize: 10);
                    }
                  });
                },
                icon: Icon(isQuery ? Icons.clear : Icons.search),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 按月显示收支列表详情的月度切换按钮和月度收支总计的行
  buildMonthCountRow() {
    return Container(
      height: 50.sp,
      // color: Colors.amber, // 显示占位用
      color: Colors.grey[400], // 显示占位用
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 2, child: _buildCurrentMonthButton()),
          Expanded(flex: 3, child: _buildCurrentMonthCountTile()),
        ],
      ),
    );
  }

  // 可切换的被选中的月份按钮
  _buildCurrentMonthButton() {
    return SizedBox(
      width: 100.sp,
      // 按钮带标签默认icon在前面，所以使用方向组件改变方向
      // 又因为ui和intl都有TextDirection类，所以显示什么ui的导入
      child: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: TextButton.icon(
          onPressed: () {
            showMonthPicker(
              context: context,
              firstDate: billPeriod.minDate,
              lastDate: billPeriod.maxDate,
              initialDate: DateTime.tryParse("$selectedMonth-01"),
              // 一定要先选择年
              // yearFirst: true,
              // customWidth: 1.sw,
              // 不缩放默认title会溢出
              // textScaleFactor: 0.9, // 但这个比例不同设备怎么控制？？？
              // 不显示标头，只能滚动选择
              // hideHeaderRow: true,
            ).then((date) {
              if (date != null) {
                setState(() {
                  selectedMonth = DateFormat(constMonthFormat).format(date);
                  maxQueryedDate =
                      DateTime.tryParse("$selectedMonth-01") ?? DateTime.now();
                  minQueryedDate =
                      DateTime.tryParse("$selectedMonth-01") ?? DateTime.now();
                  handleSearch();
                });
              }
            });
          },
          icon: const Icon(Icons.arrow_drop_down),
          label: Text(
            selectedMonth,
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // 这里是月度账单下拉后查询的总计结果，理论上只存在1条，不会为空。
  _buildCurrentMonthCountTile() {
    return FutureBuilder<List<BillPeriodCount>?>(
      future: loadBillCountByMonth(),
      builder: (BuildContext context,
          AsyncSnapshot<List<BillPeriodCount>?> snapshot) {
        List<Widget> children;
        // 有数据
        if (snapshot.hasData) {
          var list = snapshot.data!;
          if (list.isNotEmpty) {
            children = <Widget>[
              Text(
                "支出 ¥${list[0].expendTotalValue}  收入 ¥${list[0].incomeTotalValue}",
                style: TextStyle(fontSize: 12.sp),
                textAlign: TextAlign.end,
              ),
            ];
          } else {
            children = <Widget>[const Text("该月份无账单")];
          }
        } else if (snapshot.hasError) {
          // 有错误
          children = <Widget>[
            const Icon(Icons.error_outline, color: Colors.red, size: 30),
          ];
        } else {
          // 加载中
          children = const <Widget>[
            SizedBox(width: 30, height: 30, child: CircularProgressIndicator()),
          ];
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          ),
        );
      },
    );
  }

  /// 条目关键字搜索行
  buildSearchRow() {
    return Container(
      height: 50.sp,
      // color: Colors.amberAccent,
      color: Colors.grey[400], // 显示占位用
      child: Padding(
        padding: EdgeInsets.fromLTRB(4.sp, 0, 4, 0),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: "输入关键字进行查询",
                  // 设置透明底色
                  filled: true,
                  fillColor: Colors.transparent,
                  isDense: true,
                  // border: OutlineInputBorder(
                  //   borderRadius: BorderRadius.circular(10.0),
                  // ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: TextButton(
                onPressed: handleKeywordSearch,
                child: const Text("搜索"),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// 构建收支条目列表(都是完整月份的列表加在一起的)
  buildBillItemList() {
    return Expanded(
      child: ListView.builder(
        itemCount: billItemGroupByDayMap.entries.length,
        itemBuilder: (context, index) {
          if (index == billItemGroupByDayMap.entries.length) {
            return buildLoader(isLoading);
          } else {
            return _buildBillItemCard(index);
          }
        },
        // 因为列表是复用的，所有关键字查询展示时不要启用滚动控制器
        controller: isQuery ? null : scrollController,
      ),
    );
  }

  // 构建账单项次条目组件(Card中有手势包裹的Tile或者Row)
  _buildBillItemCard(int index) {
    // 获取当前分组的日期和账单项列表
    var entry = billItemGroupByDayMap.entries.elementAt(index);
    String date = entry.key;
    List<BillItem> itemsForDate = entry.value;

    // 计算每天的总支出/收入
    double totalExpend = 0.0;
    double totalIncome = 0.0;
    for (var item in itemsForDate) {
      if (item.itemType != 0) {
        totalExpend += item.value;
      } else {
        totalIncome += item.value;
      }
    }

    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(date, style: TextStyle(fontSize: 15.sp)),
            trailing: isQuery
                ? null
                : Text(
                    '支出 ¥${totalExpend.toStringAsFixed(2)} 收入 ¥${totalIncome.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 13.sp,
                    ),
                  ),
            // tileColor: Colors.lightGreen,
            tileColor: Colors.grey[300],
            dense: true,
            // 可以添加副标题或尾随图标等
          ),
          // const Divider(), // 可选的分隔线
          // 为每个BillItem创建一个Tile
          Column(
            children: ListTile.divideTiles(
              context: context,
              tiles: itemsForDate
                  .map(
                    (item) => _buildItemGestureDetector(item),
                  )
                  .toList(),
            ).toList(),
          ),
        ],
      ),
    );
  }

  GestureDetector _buildItemGestureDetector(BillItem item) {
    return GestureDetector(
      // 暂定长按删除弹窗、双击跳到修改
      // ListTile 没有双击事件，所以包裹一个手势
      onDoubleTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BillEditPage(billItem: item),
          ),
        ).then((value) {
          // 如果有修改成功，则重新查询当前月份数据
          if (value != null && value) {
            setState(() {
              handleSearch();
            });
          }
        });
      },
      onLongPress: () {
        // 不管如何，关闭弹窗后都失去焦点收起键盘
        FocusScope.of(context).unfocus();
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("删除提示"),
              content: SizedBox(
                height: 100.sp,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "确定删除选中的条目:\n    ${item.date}",
                      style: TextStyle(fontSize: 15.sp),
                    ),
                    Text(
                      "\t\t\t\t${item.itemType != 0 ? '支出' : '收入'}: ${item.category ?? ''} ${item.item} ${item.value}",
                      style: TextStyle(fontSize: 12.sp),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("取消"),
                ),
                TextButton(
                  onPressed: () async {
                    await _dbHelper.deleteBillItemById(item.billItemId);
                    if (mounted) {
                      // ignore: use_build_context_synchronously
                      Navigator.of(context).pop(true);
                    }
                  },
                  child: const Text("确定"),
                ),
              ],
            );
          },
        ).then((value) {
          // 成功删除就重新查询
          if (value != null && value) {
            setState(() {
              // 这里不区分带统计和不带统计的是因为，如果是关键字查询删除之后，重新查询关键字为空，则默认查询所有数据。
              // 如果数据较多就比较大，保留之前带统计的查询就不会太大，而且顺序也是没问题的。
              handleSearch();
            });
          }
        });
      },
      child: _buildItem(item, type: "tile"),
    );
  }

  _buildItem(BillItem item, {String type = 'tile'}) {
    if (type == 'tile') {
      return ListTile(
        dense: true,
        // 和之前使用RichText效果类似(子标题固定空字符串而不是null，是为了计算组件高度时能统一，否则高度不一致)
        title: Text(item.item, style: TextStyle(fontSize: 15.sp)),
        subtitle: Text(item.category ?? '<未分类>'),
        trailing: Text(
          '${item.itemType == 0 ? '+' : '-'}${item.value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
            color: item.itemType != 0 ? Colors.black : Colors.green,
          ),
        ),
      );
    }

    // 如果觉得默认的tile不够紧凑，可以试一下自定义的其他组件
    return Padding(
      // 设置内边距
      padding: EdgeInsets.fromLTRB(10.sp, 5.sp, 10.sp, 5.sp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      // 为了分类占的宽度一致才用的，只是显示的话可不必
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: 60.sp),
                          child: Text(
                            "<${item.category ?? '未分类'}>",
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ),
                      // TextSpan(
                      //   text: "<${item.category ?? '未分类'}>  ",
                      //   style: TextStyle(
                      //     color: Theme.of(context).primaryColor,
                      //     fontSize: 12.sp,
                      //   ),
                      // ),
                      TextSpan(
                        text: item.item,
                        style: TextStyle(color: Colors.blue, fontSize: 15.sp),
                      ),
                    ],
                  ),
                ),

                /// 另外的分类和条目展示
                // Text(
                //   item.item,
                //   softWrap: true,
                //   overflow: TextOverflow.ellipsis,
                //   maxLines: 1,
                //   style: TextStyle(
                //     fontSize: 12.sp,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                // Text(
                //   item.category ?? '<未分类>',
                //   style: TextStyle(fontSize: 12.sp),
                // ),
                /// 如果没有按日期分组的话，就可以单独列日期行
                // Text(
                //   "${item.date}___created:${item.gmtModified ?? ''}",
                //   softWrap: true,
                //   overflow: TextOverflow.ellipsis,
                //   maxLines: 1,
                //   style: TextStyle(fontSize: 10.sp),
                // )
              ],
            ),
          ),
          Expanded(
            child: Text(
              "￥${item.value.toStringAsFixed(2)}",
              style: TextStyle(fontSize: 15.sp),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
