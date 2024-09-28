import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class BarChartWidget extends StatelessWidget {
  final List<List<ChartData>> seriesData;
  final List<Color> seriesColors;
  final List<String> seriesNames;

  const BarChartWidget({
    super.key,
    required this.seriesData,
    required this.seriesColors,
    required this.seriesNames,
  });

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      // 设置图表的外边距
      margin: EdgeInsets.all(0.sp),
      // 显示图例
      legend: const Legend(
        // 隐藏图例
        isVisible: false,
        // 或者设置图例的显示方式
        // overflowMode: LegendItemOverflowMode.wrap,
      ),
      // (单个柱子)点击某个柱子，可以显示工具提醒
      tooltipBehavior: TooltipBehavior(enable: true),
      // (x轴的单个标签，可能多个柱子)在用户长按或点击图表时显示数据标签，并且可以配置为始终显示。
      trackballBehavior: TrackballBehavior(
        enable: true,
        tooltipAlignment: ChartAlignment.center,
        // 长按才激活
        activationMode: ActivationMode.longPress,
        tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
        // 显示的内容
        tooltipSettings: InteractiveTooltip(
          format: 'point.y',
          textStyle: TextStyle(fontSize: 10.sp),
        ),
      ),
      // x轴的一些配置
      primaryXAxis: CategoryAxis(
        // 间隔多少显示一个X轴标签
        interval: 1,
        // labelRotation: -60,
        // 隐藏x轴网格线(宽度设为0)
        majorGridLines: MajorGridLines(width: 0.sp),
        // 隐藏x轴刻度线(宽度设为0)
        // majorTickLines: MajorTickLines(width: 1.sp, size: 1),
        // 格式化x轴的刻度标签
        axisLabelFormatter: (AxisLabelRenderDetails details) {
          // 默认的标签样式继续用，简单修改字体大小即可
          TextStyle newStyle = details.textStyle.copyWith(
            fontSize: 10.sp,
          );
          // 格式化x轴标签文字
          var newLabel = details.text;
          return ChartAxisLabel(newLabel, newStyle);
        },
      ),
      // y轴的一些配置
      primaryYAxis: NumericAxis(
        // 隐藏y轴网格线(宽度设为0)
        majorGridLines: MajorGridLines(width: 1.sp),
        // 标签文字旋转角度
        // labelRotation: -60,
        // 标签文字大小
        labelStyle: TextStyle(fontSize: 10.sp),
        // 不显示y轴标签
        isVisible: false,
      ),

      series: List<CartesianSeries>.generate(
        seriesData.length,
        (index) => ColumnSeries<ChartData, String>(
          dataSource: seriesData[index],
          xValueMapper: (ChartData data, _) => data.category,
          yValueMapper: (ChartData data, _) => data.value,
          name: seriesNames[index],
          // 柱子之间的空隙
          spacing: 0.2,
          // 柱子的宽度(如果是1的话，x轴之间就没有间隔了)，宽度越大，上方可显示的文字区域就越大了
          width: 0.7,
          // 柱子的颜色
          color: seriesColors[index % seriesColors.length],
          // // 数据标签的配置(简单配置，默认不显示)
          // dataLabelSettings: DataLabelSettings(
          //   isVisible: true,
          //   labelAlignment: ChartDataLabelAlignment.outer,
          //   textStyle: TextStyle(
          //     fontSize: 10.sp,
          //     color: seriesColors[index % seriesColors.length],
          //   ),
          //   // 减少边框，不然柱子间空间不够文字不显示
          //   margin: EdgeInsets.all(0.sp),
          //   borderRadius: 0,
          //   // angle: -90, // 旋转90度
          // ),
          // 数据标签的配置(默认不显示)
          dataLabelSettings: DataLabelSettings(
            // 显示数据标签
            isVisible: true,
            // 数据标签的位置
            labelAlignment: ChartDataLabelAlignment.outer,
            // 减少边框，不然柱子间空间不够文字不显示
            margin: const EdgeInsets.all(0),
            // 格式化标签组件（可以换成图标等其他部件）
            builder: (dynamic data, dynamic point, dynamic series,
                int pointIndex, int seriesIndex) {
              var d = (data as ChartData);

              // return Text(
              //   d.value.toStringAsFixed(0),
              //   style: TextStyle(fontSize: 5.sp),
              // );
              return RotatedBox(
                // quarterTurns: 3, // 旋转90度
                quarterTurns: 0, // 不旋转
                child: Text(
                  "${d.value.toStringAsFixed(1)}%",
                  style: TextStyle(fontSize: 9.sp),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// syncfusion_flutter_charts 使用的图表数据结构都用这
class ChartData {
  ChartData(this.category, this.value);
  final String category;
  final double value;
}
