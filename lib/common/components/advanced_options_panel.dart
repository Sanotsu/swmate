import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 高级参数配置面板
class AdvancedOptionsPanel extends StatefulWidget {
  // 当前选中的参数配置
  final Map<String, dynamic> currentOptions;
  // 可配置的参数列表
  final List<AdvancedOption> options;
  // 参数变化回调
  final Function(Map<String, dynamic>) onOptionsChanged;

  /// 如果直接使用面板，需要可调整是否启动高级选项；
  /// 但如果是把这个面板放在了弹窗等其他地方，可能打开弹窗点击确认就是启用高级选项了，
  /// 就不需要单独的启用开关了
  final bool isShowEnabledSwitch;
  // 添加是否启用高级参数的回调
  // 如果不显示启用开关，那这两个参数就不是必须的了
  final bool enabled;
  final Function(bool)? onEnabledChanged;

  const AdvancedOptionsPanel({
    super.key,
    required this.currentOptions,
    required this.options,
    required this.onOptionsChanged,
    this.isShowEnabledSwitch = true,
    this.enabled = true,
    this.onEnabledChanged,
  });

  @override
  State<AdvancedOptionsPanel> createState() => _AdvancedOptionsPanelState();
}

class _AdvancedOptionsPanelState extends State<AdvancedOptionsPanel> {
  // 当前选中的参数配置
  late Map<String, dynamic> _options;
  // 高级选项默认展开
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _options = Map.from(widget.currentOptions);

    // 如果当前值为空，使用默认值初始化
    for (var option in widget.options) {
      if (!_options.containsKey(option.key)) {
        _options[option.key] = option.defaultValue;
      }
    }

    _options.forEach((key, value) {
      print('高级选项panel中的初始值 > key: $key, value: $value');
    });
  }

  @override
  void didUpdateWidget(covariant AdvancedOptionsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果当前选中的参数配置发生变化，更新当前选中的参数配置
    if (widget.currentOptions != oldWidget.currentOptions) {
      setState(() {
        _options = Map.from(widget.currentOptions);
      });
    }
  }

  // 更新参数配置
  void _updateOption(String key, dynamic value) {
    setState(() {
      _options[key] = value;
      widget.onOptionsChanged(_options);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.sp),
      child: Column(
        children: [
          /// 如果需要显示启用开关
          if (widget.isShowEnabledSwitch) ...[
            // 启用开关
            SwitchListTile(
              title: const Text('启用高级参数'),
              value: widget.enabled,
              onChanged: widget.onEnabledChanged,
            ),
            // 展开/收起按钮
            ListTile(
              title: Text('高级选项', style: TextStyle(fontSize: 14.sp)),
              trailing:
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onTap: () => setState(() => _isExpanded = !_isExpanded),
            )
          ],

          // 高级选项列表(启用了高级选项并且展开了)
          if (widget.enabled && _isExpanded)
            Padding(
              padding: EdgeInsets.all(8.sp),
              child: Column(
                children: widget.options.map((option) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 8.sp),
                    child: _buildOptionWidget(option),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // 根据参数类型构建对应的组件
  Widget _buildOptionWidget(AdvancedOption option) {
    switch (option.type) {
      case OptionType.slider:
        return _buildSlider(option);
      case OptionType.toggle:
        return _buildToggle(option);
      case OptionType.select:
        return _buildSelect(option);
      case OptionType.number:
        return _buildNumberInput(option);
      case OptionType.text:
        return _buildTextInput(option);
    }
  }

  // 构建滑块组件
  Widget _buildSlider(AdvancedOption option) {
    // 能进入滑块组件的，都是number,int或者double
    var tempValue = _options[option.key] ?? option.defaultValue;
    double value = double.tryParse(tempValue.toString()) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOptionLabel(option),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: option.min ?? 0,
                max: option.max ?? 1,
                divisions: option.divisions,
                onChanged: (value) => _updateOption(
                  option.key,
                  option.isNeedInt == true
                      ? value.toInt()
                      : double.tryParse(value.toStringAsFixed(2)) ?? 0,
                ),
              ),
            ),
            Text(
              option.isNeedInt == true
                  ? value.toInt().toString()
                  : value.toStringAsFixed(2),
              style: TextStyle(fontSize: 12.sp),
            ),
          ],
        ),
      ],
    );
  }

  // 构建开关组件
  Widget _buildToggle(AdvancedOption option) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 使用统一的标签组件
        _buildOptionLabel(option),
        // 自定义开关组件布局
        Row(
          children: [
            // 开关左边留点间距
            SizedBox(width: 16.sp),
            // 缩小滑块组件点击区域
            Transform.scale(
              // 缩放比例
              scale: 0.9,
              child: Switch(
                value: _options[option.key] ?? option.defaultValue,
                onChanged: (value) => _updateOption(option.key, value),
                // 缩小点击区域
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            // 可选：在开关旁边显示当前状态文本
            Text(
              (_options[option.key] ?? option.defaultValue) ? '已启用' : '已禁用',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  // 构建下拉选择组件
  Widget _buildSelect(AdvancedOption option) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOptionLabel(option),
        DropdownButton<dynamic>(
          value: _options[option.key] ?? option.defaultValue,
          items: option.items?.map((item) {
            return DropdownMenuItem(
              value: item.value,
              child: Text(item.label),
            );
          }).toList(),
          onChanged: (value) => _updateOption(option.key, value),
        ),
      ],
    );
  }

  // 构建数字输入组件
  Widget _buildNumberInput(AdvancedOption option) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOptionLabel(option),
        Padding(
          padding: EdgeInsets.only(left: 20.sp),
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: option.hint,
              contentPadding: EdgeInsets.symmetric(horizontal: 8.sp),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.sp),
              ),
            ),
            controller: TextEditingController(
              text: (_options[option.key] ?? option.defaultValue)?.toString(),
            ),
            onChanged: (value) {
              final number = int.tryParse(value);
              if (number != null) {
                _updateOption(option.key, number);
              }
            },
          ),
        ),
      ],
    );
  }

  // 构建文本输入组件
  Widget _buildTextInput(AdvancedOption option) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOptionLabel(option),
        Padding(
          padding: EdgeInsets.only(left: 20.sp),
          child: TextField(
            decoration: InputDecoration(
              hintText: option.hint,
              contentPadding: EdgeInsets.symmetric(horizontal: 8.sp),
            ),
            controller: TextEditingController(
              text: (_options[option.key] ?? option.defaultValue)?.toString(),
            ),
            onChanged: (value) => _updateOption(option.key, value),
          ),
        ),
      ],
    );
  }

  // 构建参数标签组件
  Widget _buildOptionLabel(AdvancedOption option) {
    return Tooltip(
      message: option.description ?? '',
      child: Row(
        children: [
          Text(option.label, style: TextStyle(fontSize: 14.sp)),
          if (option.description != null)
            Padding(
              padding: EdgeInsets.only(left: 4.sp),
              child: Icon(Icons.info_outline, size: 16.sp),
            ),
        ],
      ),
    );
  }
}

/// 参数选项类型
enum OptionType {
  slider, // 滑块
  toggle, // 开关
  select, // 下拉选择
  number, // 数字输入
  text, // 文本输入
}

/// 选择项
class OptionItem {
  final String label;
  final dynamic value;

  const OptionItem(this.label, this.value);
}

/// 参数配置项
class AdvancedOption {
  final String key; // 参数键名
  final String label; // 显示标签
  final String? description; // 参数描述
  final String? hint; // 输入提示
  final OptionType type; // 参数类型
  final dynamic defaultValue; // 默认值
  final double? min; // 最小值(用于slider)
  final double? max; // 最大值(用于slider)
  final int? divisions; // 分段数(用于slider)
  final bool? isNeedInt; // 是否要取整(用于slider)
  final List<OptionItem>? items; // 选项列表(用于select)

  const AdvancedOption({
    required this.key,
    required this.label,
    required this.type,
    this.description,
    this.hint,
    this.defaultValue,
    this.min,
    this.max,
    this.divisions,
    this.isNeedInt,
    this.items,
  });
}
