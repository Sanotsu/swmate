import '../llm_spec/cus_brief_llm_model.dart';
import '../llm_spec/constant_llm_enum.dart';
import 'default_image_generation_models.dart';
import 'default_video_generation_models.dart';

/// 内置模型的 API Keys (用户不可见和修改)
// class DefaultApiKeys {
//   static const baiduApiKey = 'xxx';
//   static const siliconCloudAK = 'sk-xxx';
//   static const lingyiAK = 'xxx';
//   static const zhipuAK = 'xxx.xxx';
//   static const infiniAK = 'sk-xxx';
//   static const aliyunApiKey = 'sk-xxx';
//   static const tencentApiKey = 'xxx';

//   // 讯飞(语音转文字需要)
//   static const xfyunAppId = 'xxx';
//   static const xfyunApiKey = 'xxx';
//   static const xfyunApiSecret = 'xxx';

//   // NUTRITIONIX的应用编号和密钥
//   static const nutritionixAppId = 'xxx';
//   static const nutritionixAppKey = 'xxx';

//   // fat secret api key(没用到)
//   static const fatSecretClientId = 'xxx';
//   static const fatSecretClientSecret = 'xxx';

//   // newsapi完整的api key
//   static const newsApiKey = 'xxx';
// }

// 内置模型使用的密钥的命名如上即可，这里只是使用了作者的密钥
part '_self_build_in_ak.dart';

/// 内置的默认模型列表
/// 2025-02-17 内置模型的 cusLlmSpecId 需要手动创建好，
/// 在应用首次初始化时，会根据 cusLlmSpecId 来判断是否存在，不存在才加入数据库
final defaultModels = [
  ...defaultImageGenerationModels,
  ...defaultVideoGenerationModels,
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
