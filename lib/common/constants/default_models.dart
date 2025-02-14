import '../llm_spec/cus_brief_llm_model.dart';
import '../llm_spec/cus_llm_spec.dart';

/// 内置模型的 API Keys (用户不可见和修改)
// class DefaultApiKeys {
//   static const baiduApiKey = 'xxxx';
//   static const siliconCloudAK = 'xxxx';
//   static const lingyiAK = 'xxxx';
//   static const zhipuAK = 'xxxx';
//   static const infiniAK = 'xxxx';
//   static const aliyunApiKey = 'xxxx';
//   static const tencentApiKey = 'xxxx';
// }

// 内置模型使用的密钥的命名如上即可，这里只是使用了作者的密钥
part '_self_build_in_ak.dart';

/// 内置的默认模型列表
final defaultModels = [
  CusBriefLLMSpec(
    ApiPlatform.siliconCloud,
    'deepseek-ai/DeepSeek-R1-Distill-Llama-8B',
    LLModelType.cc,
    'DeepSeek-R1-Distill-Llama-8B',
    true,
    inputPrice: 0,
    outputPrice: 0,
    contextLength: 32000,
    cusLlmSpecId: 'siliconCloud_deepseek_r1_distill_llama_8b_builtin',
    gmtRelease: DateTime.parse('2025-01-20'),
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
  CusBriefLLMSpec(
    ApiPlatform.siliconCloud,
    'deepseek-ai/DeepSeek-R1-Distill-Qwen-7B',
    LLModelType.cc,
    'DeepSeek-R1-Distill-Qwen-7B',
    true,
    inputPrice: 0,
    outputPrice: 0,
    contextLength: 32000,
    cusLlmSpecId: 'siliconCloud_deepseek_r1_distill_qwen_7b_builtin',
    gmtRelease: DateTime.parse('2025-01-20'),
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
  CusBriefLLMSpec(
    ApiPlatform.siliconCloud,
    'deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B',
    LLModelType.cc,
    'DeepSeek-R1-Distill-Qwen-1.5B',
    true,
    inputPrice: 0,
    outputPrice: 0,
    contextLength: 32000,
    cusLlmSpecId: 'siliconCloud_deepseek_r1_distill_qwen_1_5b_builtin',
    gmtRelease: DateTime.parse('2025-01-20'),
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
  CusBriefLLMSpec(
    ApiPlatform.siliconCloud,
    'deepseek-ai/Janus-Pro-7B',
    LLModelType.tti,
    'Janus-Pro-7B',
    true,
    costPer: 0,
    cusLlmSpecId: 'siliconCloud_janus_pro_7b_builtin',
    gmtRelease: DateTime.parse('2025-01-28'),
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
    'Qwen/Qwen2.5-7B-Instruct',
    LLModelType.cc,
    'Qwen2.5-7B-Instruct',
    true,
    inputPrice: 0,
    outputPrice: 0,
    contextLength: 32000,
    cusLlmSpecId: 'siliconCloud_qwen2_5_7b_instruct_builtin',
    gmtRelease: DateTime.parse('2024-09-18'),
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
];
