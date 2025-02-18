import '../llm_spec/cus_brief_llm_model.dart';
import '../llm_spec/cus_llm_spec.dart';
import 'default_images_generation_models.dart';

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
/// 2025-02-17 内置模型的 cusLlmSpecId 需要手动创建好，
/// 在应用首次初始化时，会根据 cusLlmSpecId 来判断是否存在，不存在才加入数据库
final defaultModels = [
  ...defaultImagesGenerationModels,
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
