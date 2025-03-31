import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../common/llm_spec/constant_llm_enum.dart';

class ModelFilter extends StatelessWidget {
  final List<CusBriefLLMSpec> models;
  final LLModelType selectedType;
  final Function(LLModelType)? onTypeChanged;
  final VoidCallback? onModelSelect;
  final bool isStreaming;
  final List<LLModelType> supportedTypes;
  // 2025-03-25 是否使用自定义Chip
  // 简洁版不使用，高级版使用
  final bool isCusChip;

  const ModelFilter({
    super.key,
    required this.models,
    required this.selectedType,
    required this.onTypeChanged,
    this.onModelSelect,
    this.isStreaming = false,
    this.supportedTypes = const [],
    this.isCusChip = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayTypes =
        supportedTypes.isEmpty ? LLModelType.values : supportedTypes;

    return Container(
      height: 40,
      padding: EdgeInsets.only(left: 8.sp),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: displayTypes.map((type) {
                final count = models.where((m) => m.modelType == type).length;

                if (count > 0) {
                  return isCusChip
                      ? Center(child: _buildCusChip(context, type, count))
                      : _buildFilterChip(context, type, count);
                }
                return const SizedBox.shrink();
              }).toList(),
            ),
          ),
          if (!isCusChip)
            IconButton(
              icon: const Icon(Icons.expand_more),
              onPressed: isStreaming ? null : onModelSelect,
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, LLModelType type, int count) {
    return Padding(
      padding: EdgeInsets.only(right: 8.sp),
      // // 自定义 Chip，可以自定义内边距、标签内边距、形状
      // child: RawChip(
      //   label: Text("${MT_NAME_MAP[type]}($count)"),
      //   selected: type == selectedType,
      //   onSelected: isStreaming
      //       ? null
      //       : (_) {
      //           onTypeChanged?.call(type);
      //           onModelSelect?.call();
      //         },
      //   // 选中时颜色
      //   selectedColor: Theme.of(context).primaryColorLight,
      //   // 自定义内边距
      //   padding: EdgeInsets.all(4.sp),
      //   // 自定义标签内边距
      //   labelPadding: EdgeInsets.symmetric(horizontal: 4.sp),
      //   // 自定义圆弧
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(8.sp),
      //   ),
      // ),

      // 系统默认 Chip，内边距不够小
      child: FilterChip(
        // padding: EdgeInsets.all(1.sp),
        // labelPadding: EdgeInsets.all(1.sp),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        label: Text("${MT_NAME_MAP[type]}($count)"),
        selected: type == selectedType,
        onSelected: isStreaming
            ? null
            : (_) {
                onTypeChanged?.call(type);
                onModelSelect?.call();
              },
      ),
    );
  }

  Widget _buildCusChip(BuildContext context, LLModelType type, int count) {
    return Padding(
      padding: EdgeInsets.only(right: 8.sp),
      child: InkWell(
        onTap: isStreaming
            ? null
            : () {
                onTypeChanged?.call(type);
                onModelSelect?.call();
              },
        borderRadius: BorderRadius.circular(8.sp),
        child: Container(
          padding: EdgeInsets.all(4.sp),
          decoration: BoxDecoration(
            // color: type == selectedType
            //     ? Theme.of(context).primaryColorLight
            //     : Colors.transparent,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8.sp),
            border: Border.all(
              color: type == selectedType
                  ? Theme.of(context).primaryColorLight
                  : Colors.transparent,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.sp),
            child: Text(
              "${MT_NAME_MAP[type]}($count)",
              style: TextStyle(
                color: type == selectedType
                    ? Theme.of(context).primaryColor
                    : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );

    // 2025-03-13 使用RawChip 不知道怎么设置透明背景色，该用上面简单代替一下
    // return Padding(
    //   padding: EdgeInsets.only(right: 8.sp),
    //   // 自定义 Chip，可以自定义内边距、标签内边距、形状

    //   child: RawChip(
    //     color:
    //         WidgetStateProperty.all<Color?>(Colors.transparent),
    //     label: Text("${MT_NAME_MAP[type]}($count)"),
    //     selected: type == selectedType,
    //     onSelected: isStreaming
    //         ? null
    //         : (_) {
    //             onTypeChanged?.call(type);
    //             onModelSelect?.call();
    //           },
    //     // 选中时颜色
    //     selectedColor: Theme.of(context).primaryColorLight,
    //     backgroundColor: Colors.transparent,
    //     // 自定义内边距
    //     padding: EdgeInsets.all(4.sp),
    //     // 自定义标签内边距
    //     labelPadding: EdgeInsets.symmetric(horizontal: 4.sp),
    //     // 自定义圆弧
    //     shape: RoundedRectangleBorder(
    //       borderRadius: BorderRadius.circular(8.sp),
    //     ),
    //   ),
    // );
  }
}
