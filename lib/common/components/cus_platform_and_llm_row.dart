import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:toggle_switch/toggle_switch.dart';

import 'tool_widget.dart';
import '../llm_spec/cus_brief_llm_model.dart';
import '../llm_spec/constant_llm_enum.dart';

class CusPlatformAndLlmRow extends StatefulWidget {
  // 初始化的平台和模型（智能对话每次进入页面都是随机的，所以这里初始化不能固定，由调用处传入）
  final ApiPlatform initialPlatform;
  // 被选中的模型
  final CusBriefLLMSpec initialModelSpec;
  // 用于构建平台下拉框和模型下拉框选项
  final List<CusBriefLLMSpec> llmSpecList;
  // 指定可用于选择的模型类型
  final LLModelType targetModelType;
  // 是否显示切换流式/分段输出按钮
  final bool showToggleSwitch;
  // 当切换按钮被点击时触发
  final void Function(int?)? onToggle;
  // 是否是流式响应(文本对话时可以流式输出，文生图就没意义)
  final bool? isStream;
// 当平台或者模型切换后，要把当前的平台和模型传递给父组件
  final Function(ApiPlatform?, CusBriefLLMSpec?) onPlatformOrModelChanged;

  const CusPlatformAndLlmRow({
    super.key,
    required this.initialPlatform,
    required this.initialModelSpec,
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
  CusBriefLLMSpec? selectedModelSpec;

  @override
  void initState() {
    super.initState();

    // 假定一定有sf平台(因为限时免费)
    selectedPlatform = widget.initialPlatform;
    selectedModelSpec = widget.initialModelSpec;
  }

  @override
  void didUpdateWidget(covariant CusPlatformAndLlmRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 检查是否需要更新 selectedPlatform 和 selectedModelSpec
    if (widget.initialPlatform != oldWidget.initialPlatform ||
        widget.initialModelSpec != oldWidget.initialModelSpec) {
      setState(() {
        selectedPlatform = widget.initialPlatform;
        selectedModelSpec = widget.initialModelSpec;
      });
    }
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
  onModelChange(CusBriefLLMSpec? value) {
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
        alignment: AlignmentDirectional.center,
        child: Text(
          CP_NAME_MAP[platform]!,
          style: TextStyle(color: Colors.blue, fontSize: 15.sp),
        ),
      );
    }).toList();
  }

  /// 选定了云平台后，要构建用于下拉选择的该平台的大模型列表
  List<DropdownMenuItem<CusBriefLLMSpec>> buildCusLLMs() {
    // 用于下拉的模型除了属于指定平台，还需要是指定的目标类型的模型
    return widget.llmSpecList
        .where((spec) =>
            spec.platform == selectedPlatform &&
            spec.modelType == widget.targetModelType)
        .map((e) => DropdownMenuItem<CusBriefLLMSpec>(
              value: e,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                e.name ?? e.model,
                style: TextStyle(color: Colors.blue, fontSize: 15.sp),
              ),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 这个需要左右边距和其他模块对齐
        Padding(
          padding: EdgeInsets.fromLTRB(5.sp, 1.sp, 5.sp, 1.sp),
          child: buildPlatRow(),
        ),
        // 这里需要help图标和appbar上的图标对齐，所以没有右边的边距
        Padding(
          padding: EdgeInsets.fromLTRB(5.sp, 1.sp, 0.sp, 1.sp),
          child: buildModelRow(),
        ),
      ],
    );
  }

  // 平台选择行
  Widget buildPlatRow() {
    return Row(
      children: [
        const Text("平台:", style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(width: 10.sp),
        Expanded(
          child: buildDropdownButton2<ApiPlatform?>(
            value: selectedPlatform,
            items: widget.llmSpecList
                .map((spec) => spec.platform)
                .toSet()
                .toList(),
            onChanged: onCloudPlatformChanged,
            itemToString: (e) => CP_NAME_MAP[e]!,
          ),
        ),
        if (widget.showToggleSwitch) SizedBox(width: 10.sp),
        if (widget.showToggleSwitch)
          ToggleSwitch(
            minHeight: 30.sp,
            minWidth: 48.sp,
            fontSize: 13.sp,
            cornerRadius: 5.sp,
            initialLabelIndex: widget.isStream == true ? 0 : 1,
            totalSwitches: 2,
            labels: const ['分段', '直出'],
            onToggle: widget.onToggle,
          ),
      ],
    );
  }

  // 模型选择行
  Widget buildModelRow() {
    return Row(
      children: [
        const Text("模型:", style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(width: 10.sp),
        Expanded(
          child: buildDropdownButton2<CusBriefLLMSpec?>(
            value: selectedModelSpec,
            items: widget.llmSpecList
                .where((spec) =>
                    spec.platform == selectedPlatform &&
                    spec.modelType == widget.targetModelType)
                .toList(),
            onChanged: onModelChange,
            itemToString: (e) => e.name,
            alignment: AlignmentDirectional.centerStart,
          ),
        ),
        IconButton(
          onPressed: () {
            commonMarkdwonHintDialog(
              context,
              "模型说明",
              selectedModelSpec?.costPer != null
                  ? selectedModelSpec!.costPer.toString()
                  : "输入 ${selectedModelSpec?.inputPrice.toString()} 元/百万token； 输出 ${selectedModelSpec?.outputPrice.toString()} 元/百万token ",
              msgFontSize: 13.sp,
            );
          },
          icon: Icon(Icons.help_outline, color: Theme.of(context).primaryColor),
        ),
      ],
    );
  }
}
