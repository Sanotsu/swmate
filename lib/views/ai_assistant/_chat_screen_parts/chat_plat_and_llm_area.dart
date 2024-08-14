import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../../common/components/tool_widget.dart';
import '../../../common/llm_spec/cus_llm_spec.dart';

///
/// 构建平台和模型的下拉选择框
///
/// 有的不存在流式切换，所以toggle也是可选
///
class PlatAndLlmRow extends StatefulWidget {
  // 被选中的平台
  final ApiPlatform? selectedPlatform;
  // 当平台改变时触发
  final Function(ApiPlatform?) onPlatformChanged;
  // 被选中的模型
  final CusLLMSpec? selectedModelSpec;
  // 当模型改变时触发
  final Function(CusLLMSpec?) onModelSpecChanged;
  // 在此组件内部构造平台下拉框和模型下拉框选项麻烦了点，直接当参数传入
  final List<DropdownMenuItem<ApiPlatform?>> Function() buildPlatformList;
  final List<DropdownMenuItem<CusLLMSpec?>> Function() buildModelSpecList;

  // 流式响应的部件不一定存在的
  // 是否显示切换按钮
  final bool showToggleSwitch;
  // 是否是流式响应
  final bool? isStream;
  // 是否流式响应切换按钮触发
  final void Function(int?)? onToggle;

  const PlatAndLlmRow({
    super.key,
    required this.selectedPlatform,
    required this.onPlatformChanged,
    required this.selectedModelSpec,
    required this.onModelSpecChanged,
    required this.buildPlatformList,
    required this.buildModelSpecList,
    this.showToggleSwitch = false,
    this.isStream = false,
    this.onToggle,
  });

  @override
  State createState() => _PlatAndLlmRowState();
}

class _PlatAndLlmRowState extends State<PlatAndLlmRow> {
  @override
  Widget build(BuildContext context) {
    Widget cpRow = Row(
      children: [
        const Text("平台:"),
        SizedBox(width: 10.sp),
        Expanded(
          child: DropdownButton<ApiPlatform?>(
            value: widget.selectedPlatform,
            isDense: true,
            // icon: Icon(Icons.arrow_drop_down, size: 36.sp), // 自定义图标
            underline: Container(), // 取消默认的下划线
            items: widget.buildPlatformList(),
            onChanged: widget.onPlatformChanged,
          ),
        ),
        if (widget.showToggleSwitch)
          ToggleSwitch(
            minHeight: 26.sp,
            minWidth: 48.sp,
            fontSize: 13.sp,
            cornerRadius: 5.sp,
            initialLabelIndex: widget.isStream == true ? 0 : 1,
            totalSwitches: 2,
            labels: const ['分段', '直出'],
            onToggle: widget.onToggle,
          ),
        if (widget.showToggleSwitch) SizedBox(width: 10.sp),
      ],
    );

    Widget modelRow = Row(
      children: [
        const Text("模型:"),
        SizedBox(width: 10.sp),
        Expanded(
          child: DropdownButton<CusLLMSpec?>(
            value: widget.selectedModelSpec,
            isDense: true,
            underline: Container(),
            menuMaxHeight: 300.sp,
            items: widget.buildModelSpecList(),
            onChanged: widget.onModelSpecChanged,
          ),
        ),
        IconButton(
          onPressed: () {
            commonHintDialog(
              context,
              "模型说明",
              widget.selectedModelSpec?.feature ??
                  widget.selectedModelSpec?.useCase ??
                  '',
              msgFontSize: 15.sp,
            );
          },
          icon: Icon(Icons.help_outline, color: Theme.of(context).primaryColor),
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.all(5.sp),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [cpRow, modelRow],
      ),
    );
  }
}
