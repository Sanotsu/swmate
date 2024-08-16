import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../../common/components/tool_widget.dart';
import '../../../common/llm_spec/cus_llm_spec.dart';

class CusPlatformAndLlmRow extends StatefulWidget {
  // 用于构建平台下拉框和模型下拉框选项
  final List<CusLLMSpec> llmSpecList;
  // 指定可用于选择的模型类型
  final LLModelType targetModelType;
  // 是否显示切换流式/分段输出按钮
  final bool showToggleSwitch;
  // 当切换按钮被点击时触发
  final void Function(int?)? onToggle;
  // 是否是流式响应(文本对话时可以流式输出，文生图就没意义)
  final bool? isStream;
// 当平台或者模型切换后，要把当前的平台和模型传递给父组件
  final Function(ApiPlatform?, CusLLMSpec?) onPlatformOrModelChanged;

  const CusPlatformAndLlmRow({
    super.key,
    required this.llmSpecList,
    this.targetModelType = LLModelType.tti,
    this.showToggleSwitch = false,
    this.isStream = false,
    this.onToggle,
    required this.onPlatformOrModelChanged,
  });

  @override
  State createState() => _CusPlatformAndLlmRowState();
}

class _CusPlatformAndLlmRowState extends State<CusPlatformAndLlmRow> {
  // 被选中的平台
  ApiPlatform? selectedPlatform;
  // 被选中的模型
  CusLLMSpec? selectedModelSpec;

  @override
  void initState() {
    super.initState();
    if (widget.llmSpecList.isNotEmpty) {
      // 假定一定有sf平台(因为限时免费)
      selectedPlatform = ApiPlatform.siliconCloud;
      selectedModelSpec =
          widget.llmSpecList.where((e) => e.platform == selectedPlatform).first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      child: Padding(
        padding: EdgeInsets.only(left: 10.sp),
        child: PlatAndLlmRowContent(
          selectedPlatform: selectedPlatform,
          onPlatformChanged: onCloudPlatformChanged,
          selectedModelSpec: selectedModelSpec,
          onModelSpecChanged: onModelChange,
          buildPlatformList: buildCloudPlatforms,
          buildModelSpecList: buildPlatformLLMs,
          showToggleSwitch: widget.showToggleSwitch,
          isStream: widget.isStream,
          onToggle: widget.onToggle,
        ),
      ),
    );
  }

  /// 当切换了云平台时，要同步切换选中的大模型
  onCloudPlatformChanged(ApiPlatform? value) {
    // 如果平台被切换，则更新当前的平台为选中的平台，且重置模型为符合该平台的模型的第一个
    if (value != selectedPlatform) {
      setState(() {
        selectedPlatform = value ?? ApiPlatform.siliconCloud;
        // 切换平台后，修改选中的模型为该平台第一个
        selectedModelSpec = widget.llmSpecList
            .where((spec) =>
                spec.platform == selectedPlatform &&
                spec.modelType == widget.targetModelType)
            .toList()
            .first;
      });
    }

    // 平台和模型返回给父组件
    widget.onPlatformOrModelChanged(value, selectedModelSpec);
  }

  /// 当模型切换时，除了改变当前模型，也要返回给父组件
  onModelChange(CusLLMSpec? value) {
    setState(() {
      selectedModelSpec = value!;
      // 平台和模型返回给父组件
      widget.onPlatformOrModelChanged(
        selectedPlatform,
        selectedModelSpec,
      );
    });
  }

  /// 构建用于下拉的平台列表
  List<DropdownMenuItem<ApiPlatform?>> buildCloudPlatforms() {
    // 从传入的模型spec列表中获取到平台列表供展示
    return widget.llmSpecList
        .map((spec) => spec.platform)
        .toSet()
        .map((platform) {
      return DropdownMenuItem(
        value: platform,
        child: Text(
          CP_NAME_MAP[platform]!,
          style: const TextStyle(color: Colors.blue),
        ),
      );
    }).toList();
  }

  /// 选定了云平台后，要构建用于下拉选择的该平台的大模型列表
  List<DropdownMenuItem<CusLLMSpec>> buildPlatformLLMs() {
    // 用于下拉的模型除了属于指定平台，还需要是指定的目标类型的模型
    return widget.llmSpecList
        .where((spec) =>
            spec.platform == selectedPlatform &&
            spec.modelType == widget.targetModelType)
        .map((e) => DropdownMenuItem<CusLLMSpec>(
              value: e,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                e.name,
                style: const TextStyle(color: Colors.blue),
              ),
            ))
        .toList();
  }
}

class PlatAndLlmRowContent extends StatelessWidget {
  final ApiPlatform? selectedPlatform;
  final Function(ApiPlatform?) onPlatformChanged;
  final CusLLMSpec? selectedModelSpec;
  final Function(CusLLMSpec?) onModelSpecChanged;
  final List<DropdownMenuItem<ApiPlatform?>> Function() buildPlatformList;
  final List<DropdownMenuItem<CusLLMSpec?>> Function() buildModelSpecList;
  final bool showToggleSwitch;
  final bool? isStream;
  final void Function(int?)? onToggle;

  const PlatAndLlmRowContent({
    super.key,
    required this.selectedPlatform,
    required this.onPlatformChanged,
    required this.selectedModelSpec,
    required this.onModelSpecChanged,
    required this.buildPlatformList,
    required this.buildModelSpecList,
    required this.showToggleSwitch,
    required this.isStream,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    Widget cpRow = Row(
      children: [
        const Text("平台:"),
        SizedBox(width: 10.sp),
        Expanded(
          child: DropdownButton<ApiPlatform?>(
            value: selectedPlatform,
            isDense: true,
            underline: Container(),
            items: buildPlatformList(),
            onChanged: onPlatformChanged,
          ),
        ),
        if (showToggleSwitch)
          ToggleSwitch(
            minHeight: 26.sp,
            minWidth: 48.sp,
            fontSize: 13.sp,
            cornerRadius: 5.sp,
            initialLabelIndex: isStream == true ? 0 : 1,
            totalSwitches: 2,
            labels: const ['分段', '直出'],
            onToggle: onToggle,
          ),
        if (showToggleSwitch) SizedBox(width: 10.sp),
      ],
    );

    Widget modelRow = Row(
      children: [
        const Text("模型:"),
        SizedBox(width: 10.sp),
        Expanded(
          child: DropdownButton<CusLLMSpec?>(
            value: selectedModelSpec,
            isDense: true,
            underline: Container(),
            menuMaxHeight: 300.sp,
            items: buildModelSpecList(),
            onChanged: onModelSpecChanged,
          ),
        ),
        IconButton(
          onPressed: () {
            commonHintDialog(
              context,
              "模型说明",
              selectedModelSpec?.feature ?? selectedModelSpec?.useCase ?? '',
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
