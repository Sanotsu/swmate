import '../llm_spec/cus_brief_llm_model.dart';
import '../llm_spec/cus_llm_spec.dart';

/// 内置的默认模型列表
final defaultImageGenerationModels = [
  /// 硅基流动
  CusBriefLLMSpec(
    ApiPlatform.siliconCloud,
    'black-forest-labs/FLUX.1-schnell',
    LLModelType.tti,
    'FLUX.1-schnell',
    true,
    costPer: 0,
    cusLlmSpecId: 'siliconCloud_flux_1_schnell_builtin',
    gmtRelease: DateTime.parse('2024-08-01'),
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
  CusBriefLLMSpec(
    ApiPlatform.siliconCloud,
    'stabilityai/stable-diffusion-xl-base-1.0',
    LLModelType.tti,
    'stable-diffusion-xl-base-1.0',
    true,
    costPer: 0,
    cusLlmSpecId: 'siliconCloud_stable_diffusion_xl_base_1_0_builtin',
    gmtRelease: DateTime.parse('2023-07-25'),
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
  CusBriefLLMSpec(
    ApiPlatform.siliconCloud,
    'stabilityai/stable-diffusion-3-5-large',
    LLModelType.tti,
    'stable-diffusion-3-5-large',
    true,
    costPer: 0,
    cusLlmSpecId: 'siliconCloud_stable_diffusion_3_5_large_builtin',
    gmtRelease: DateTime.parse('2024-10-23'),
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
  CusBriefLLMSpec(
    ApiPlatform.siliconCloud,
    'deepseek-ai/Janus-Pro-7B',
    LLModelType.tti,
    'Janus-Pro-7B',
    false,
    costPer: 0,
    cusLlmSpecId: 'siliconCloud_janus_pro_7b_builtin',
    gmtRelease: DateTime.parse('2025-01-28'),
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),

  /// 智谱AI
  CusBriefLLMSpec(
    ApiPlatform.zhipu,
    'cogview-3-flash',
    LLModelType.tti,
    'CogView-3-Flash',
    false,
    costPer: 0.06,
    cusLlmSpecId: 'zhipu_cogview_3_flash_builtin',
    gmtRelease: DateTime.parse('1970-01-01'),
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
];
