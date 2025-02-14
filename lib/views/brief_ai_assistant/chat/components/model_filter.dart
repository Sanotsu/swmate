import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../../common/llm_spec/cus_llm_spec.dart';

class ModelFilter extends StatelessWidget {
  final List<CusBriefLLMSpec> models;
  final LLModelType selectedType;
  final Function(LLModelType)? onTypeChanged;
  final VoidCallback? onModelSelect;
  final bool isStreaming;
  final List<LLModelType> supportedTypes;

  const ModelFilter({
    super.key,
    required this.models,
    required this.selectedType,
    required this.onTypeChanged,
    this.onModelSelect,
    this.isStreaming = false,
    this.supportedTypes = const [],
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
                  return Padding(
                    padding: EdgeInsets.only(right: 8.sp),
                    child: FilterChip(
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
                return const SizedBox.shrink();
              }).toList(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.model_training),
            onPressed: isStreaming ? null : onModelSelect,
          ),
        ],
      ),
    );
  }
}
