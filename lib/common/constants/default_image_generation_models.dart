import '../llm_spec/cus_brief_llm_model.dart';
import '../llm_spec/constant_llm_enum.dart';

/// 内置的默认模型列表
final defaultImageGenerationModels = [
  /// 智谱AI
  CusBriefLLMSpec(
    ApiPlatform.zhipu,
    'cogview-3-flash',
    LLModelType.tti,
    'CogView-3-Flash',
    true,
    costPer: 0.0,
    cusLlmSpecId: 'zhipu_cogview_3_flash_builtin',
    gmtRelease: DateTime.parse('1970-01-01'),
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
];
