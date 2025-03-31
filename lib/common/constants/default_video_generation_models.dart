import '../llm_spec/cus_brief_llm_model.dart';
import '../llm_spec/constant_llm_enum.dart';

final defaultVideoGenerationModels = [
  CusBriefLLMSpec(
    ApiPlatform.zhipu,
    'cogvideox-flash',
    LLModelType.video,
    name: 'cogvideox-flash',
    isFree: true,
    costPer: 0,
    cusLlmSpecId: 'zhipu_cogvideox_flash_builtin',
    gmtRelease: DateTime.parse('1970-01-01'),
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
];
