import '../llm_spec/cus_brief_llm_model.dart';
import '../llm_spec/constant_llm_enum.dart';
import 'default_image_generation_models.dart';
import 'default_video_generation_models.dart';

/// 内置模型的 API Keys (用户不可见和修改)
/// 2025-03-03 默认是有免费的模型，才可以慷慨提供内嵌的 API Keys，不免费的用户自行导入
// class DefaultApiKeys {
//   static const baiduApiKey = 'xxx';
//   static const tencentApiKey = 'xxx';
//   static const zhipuAK = 'xxx.xxx';
//   static const siliconCloudAK = 'sk-xxx';

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
/// 2025-03-03 至少保证每种类型都有一个免费的内置模型，方便测试使用(多了也不方便)
/// 更多的收费、免费的，用户自行导入
final defaultModels = [
  ...defaultImageGenerationModels,
  ...defaultVideoGenerationModels,
  CusBriefLLMSpec(
    ApiPlatform.siliconCloud,
    'deepseek-ai/DeepSeek-R1-Distill-Qwen-7B',
    LLModelType.cc,
    name: 'DeepSeek-R1-Distill-Qwen-7B',
    isFree: true,
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
    'Qwen/Qwen2.5-7B-Instruct',
    LLModelType.cc,
    name: 'Qwen2.5-7B-Instruct',
    isFree: true,
    inputPrice: 0,
    outputPrice: 0,
    contextLength: 32000,
    cusLlmSpecId: 'siliconCloud_qwen2_5_7b_instruct_builtin',
    gmtRelease: DateTime.parse('2024-09-18'),
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
  CusBriefLLMSpec(
    ApiPlatform.baidu,
    "ernie-speed-128k",
    LLModelType.cc,
    name: "ERNIE-Speed-128K",
    isFree: true,
    inputPrice: 0,
    outputPrice: 0,
    contextLength: 128000,
    cusLlmSpecId: 'baidu_ernie_speed_128k_builtin',
    gmtRelease: DateTime.parse('2024-03-14'),
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
  CusBriefLLMSpec(
    ApiPlatform.tencent,
    "hunyuan-lite",
    LLModelType.cc,
    name: "hunyuan-lite",
    isFree: true,
    inputPrice: 0,
    outputPrice: 0,
    contextLength: 256000,
    cusLlmSpecId: 'tencent_hunyuan_lite_builtin',
    gmtRelease: DateTime.parse('2024-10-30'),
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
  CusBriefLLMSpec(
    ApiPlatform.zhipu,
    "glm-4-flash",
    LLModelType.cc,
    name: "CGLM-4-Flash",
    isFree: true,
    inputPrice: 0,
    outputPrice: 0,
    contextLength: 16000,
    cusLlmSpecId: 'zhipu_glm_4_flash_builtin',
    gmtRelease: DateTime.parse('1970-01-01'),
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
  CusBriefLLMSpec(
    ApiPlatform.zhipu,
    "glm-4v-flash",
    LLModelType.vision,
    name: "GLM-4V-Flash",
    isFree: true,
    inputPrice: 0,
    outputPrice: 0,
    contextLength: 16000,
    cusLlmSpecId: 'zhipu_glm_4v_flash_builtin',
    gmtRelease: DateTime.parse('1970-01-01'),
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
];
