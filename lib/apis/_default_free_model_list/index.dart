// ignore_for_file: non_constant_identifier_names

import '../../common/llm_spec/cus_llm_model.dart';
import '../../common/llm_spec/cus_llm_spec.dart';

/// 全部免费的模型(默认app导入的)
var FREE_all_MODELS = FREE_baidu_MODELS +
    FREE_SiliconFlow_MODELS +
    FREE_tencent_MODELS +
    FREE_xfyun_MODELS +
    FREE_zhipuAI_MODELS;

final List<CusLLMSpec> FREE_baidu_MODELS = [
  /// 下面是官方免费的
  CusLLMSpec(
    ApiPlatform.baidu,
    CusLLM.baidu_Ernie_Speed_8K,
    "ernie_speed",
    'ERNIE-Speed-8K',
    8 * 1000,
    true,
    0,
    0,
    feature: """ERNIE Speed是百度2024年最新发布的自研高性能大语言模型，通用能力优异，
适合作为基座模型进行精调，更好地处理特定场景问题，同时具备极佳的推理性能。
ERNIE-Speed-8K是模型的一个版本，上下文窗口为8K。""",
  ),
  CusLLMSpec(
    ApiPlatform.baidu,
    CusLLM.baidu_Ernie_Speed_128K,
    "ernie-speed-128k",
    'ERNIE-Speed-128K',
    128 * 1000,
    true,
    0,
    0,
    feature: """ERNIE Speed是百度2024年最新发布的自研高性能大语言模型，通用能力优异，
    适合作为基座模型进行精调，更好地处理特定场景问题，同时具备极佳的推理性能。
    ERNIE-Speed-128K是模型的一个版本，上下文窗口为128K。""",
  ),
  CusLLMSpec(
    ApiPlatform.baidu,
    CusLLM.baidu_Ernie_Lite_8K,
    "ernie-lite-8k",
    'ERNIE-Lite-8K',
    8 * 1000,
    true,
    0,
    0,
    feature: "ERNIE Lite是百度自研的轻量级大语言模型，兼顾优异的模型效果与推理性能，适合低算力AI加速卡推理使用。",
  ),
  CusLLMSpec(
    ApiPlatform.baidu,
    CusLLM.baidu_Ernie_Tiny_8K,
    "ernie-tiny-8k",
    'ERNIE-Tiny-8K',
    8 * 1000,
    true,
    0,
    0,
    feature: """ERNIE Tiny是百度自研的超高性能大语言模型，部署与精调成本在文心系列模型中最低。
    ERNIE-Tiny-8K是模型的一个版本，上下文窗口为8K。""",
  ),
  CusLLMSpec(
    ApiPlatform.baidu,
    CusLLM.baidu_Yi_34B_Chat_4K,
    "yi_34b_chat",
    'YI-34B-Chat-4K',
    4 * 1000,
    true,
    0,
    0,
    feature: """Yi-34B是由零一万物开发并开源的双语大语言模型，使用4K序列长度进行训练，在推理期间可扩展到32K；
    模型在多项评测中全球领跑，取得了多项 SOTA 国际最佳性能指标表现，该版本为支持对话的chat版本。""",
  ),
  CusLLMSpec(
    ApiPlatform.baidu,
    CusLLM.baidu_Fuyu_8B,
    "fuyu_8b",
    'Fuyu-8B',
    4 * 1000,
    true,
    0,
    0,
    feature: """Fuyu-8B是由Adept AI训练的多模态图像理解模型，
    可以支持多样的图像分辨率，回答图形图表有关问题。模型在视觉问答和图像描述等任务上表现良好。""",
    modelType: LLModelType.vision,
  ),
];

final List<CusLLMSpec> FREE_tencent_MODELS = [
  CusLLMSpec(
    ApiPlatform.tencent,
    CusLLM.tencent_Hunyuan_Lite,
    "hunyuan-lite",
    'HUNYUAN-Lite',
    8 * 1000,
    true,
    0,
    0,
    feature: """腾讯混元大模型(Tencent Hunyuan)是由腾讯研发的大语言模型，
具备强大的中文创作能力，复杂语境下的逻辑推理能力，以及可靠的任务执行能力。
混元-Lite 升级为MOE结构，上下文窗口为256k，在NLP，代码，数学，行业等多项评测集上领先众多开源模型。""",
  ),
];

final List<CusLLMSpec> FREE_xfyun_MODELS = [
  CusLLMSpec(
    ApiPlatform.xfyun,
    CusLLM.xfyun_Spark_Lite,
    "general",
    'Spark-Lite',
    4000,
    true,
    0,
    0,
    feature: """轻量级大语言模型，低延迟，全免费。""",
    useCase: """适用于低算力推理与模型精调等定制化场景。""",
  ),
];

final List<CusLLMSpec> FREE_zhipuAI_MODELS = [
  CusLLMSpec(
    ApiPlatform.zhipu,
    CusLLM.zhipu_GLM4_Flash,
    "glm-4-flash",
    'GLM-4-Flash',
    128 * 1000,
    true,
    0,
    0,
    feature: """智谱AI首个免费API，零成本调用大模型。""",
  ),
];

// 这个平台模型多，这里的顺序不一定和页面上一一对应，有更新时记得逐个看
final List<CusLLMSpec> FREE_SiliconFlow_MODELS = [
  CusLLMSpec(
    ApiPlatform.siliconCloud,
    CusLLM.siliconCloud_Qwen2_7B_Instruct,
    "Qwen/Qwen2-7B-Instruct",
    'Qwen2-开源版7B-Instruct',
    32 * 1000,
    true,
    0,
    0,
    feature: '通义千问2开源版7B_指令模型',
  ),
  CusLLMSpec(
    ApiPlatform.siliconCloud,
    CusLLM.siliconCloud_Qwen2_1p5B_Instruct,
    "Qwen/Qwen2-1.5B-Instruct",
    'Qwen2-开源版1.5B-Instruct',
    32 * 1000,
    true,
    0,
    0,
    feature: '通义千问2开源版1.5B_指令模型',
  ),
  CusLLMSpec(
    ApiPlatform.siliconCloud,
    CusLLM.siliconCloud_Qwen1p5_7B_Chat,
    "Qwen/Qwen1.5-7B-Chat",
    'Qwen1.5-开源版7B-Chat',
    32 * 1000,
    true,
    0,
    0,
    feature: '通义千问1.5开源版7B_对话模型',
  ),
  CusLLMSpec(
    ApiPlatform.siliconCloud,
    CusLLM.siliconCloud_GLM4_9B_Chat,
    "THUDM/glm-4-9b-chat",
    'GLM4-开源版9B-Chat',
    32 * 1000,
    true,
    0,
    0,
    feature: 'GLM4开源版9B_对话模型',
  ),
  CusLLMSpec(
    ApiPlatform.siliconCloud,
    CusLLM.siliconCloud_ChatGLM3_6B,
    "THUDM/chatglm3-6b",
    'ChatGLM3-开源版6B',
    32 * 1000,
    true,
    0,
    0,
    feature: 'ChatGLM3开源版6B_对话模型',
  ),
  CusLLMSpec(
    ApiPlatform.siliconCloud,
    CusLLM.siliconCloud_Yi1p5_9B_Chat_16K,
    "01-ai/Yi-1.5-9B-Chat-16K",
    'Yi1.5-开源版9B-Chat',
    16 * 1000,
    true,
    0,
    0,
    feature: '零一万物1.5开源版9B_对话模型',
  ),
  CusLLMSpec(
    ApiPlatform.siliconCloud,
    CusLLM.siliconCloud_Yi1p5_6B_Chat,
    "01-ai/Yi-1.5-6B-Chat",
    'Yi1.5-开源版6B-Chat',
    4 * 1000,
    true,
    0,
    0,
    feature: '零一万物1.5开源版6B_对话模型',
  ),
  // 2024-08-08 查看时又有一些免费的(国际领先的模型，最好使用英文指令)
  CusLLMSpec(
    ApiPlatform.siliconCloud,
    CusLLM.siliconCloud_GEMMA2_9B_Instruct,
    "google/gemma-2-9b-it",
    'Gemma2-9B-Instruct_英语',
    8 * 1000,
    true,
    0,
    0,
    feature: '国际模型_谷歌gemma2_9B_指令模型',
  ),
  CusLLMSpec(
    ApiPlatform.siliconCloud,
    CusLLM.siliconCloud_InternLM2p5_7B_Chat,
    "internlm/internlm2_5-7b-chat",
    'InternLM2.5-7B-Chat_英语',
    32 * 1000,
    true,
    0,
    0,
    feature: '国际模型_InternLM2.5_7B_对话模型',
  ),
  CusLLMSpec(
    ApiPlatform.siliconCloud,
    CusLLM.siliconCloud_LLAMA3_8B_Instruct,
    "meta-llama/Meta-Llama-3-8B-Instruct",
    'Llama3-8B-Instruct_英语',
    8 * 1000,
    true,
    0,
    0,
    feature: '国际模型_Meta_LLAMA3_8B_指令模型',
  ),
  CusLLMSpec(
    ApiPlatform.siliconCloud,
    CusLLM.siliconCloud_LLAMA3p1_8B_Instruct,
    "meta-llama/Meta-Llama-3.1-8B-Instruct",
    'Llama3.1-8B-Instruct_英语',
    8 * 1000,
    true,
    0,
    0,
    feature: '国际模型_Meta_LLAMA3.1_8B_指令模型',
  ),

  // https://huggingface.co/mistralai/Mistral-7B-Instruct-v0.2/discussions/52
  CusLLMSpec(
    ApiPlatform.siliconCloud,
    CusLLM.siliconCloud_Mistral_7B_Instruct_v0p2,
    "mistralai/Mistral-7B-Instruct-v0.2",
    'Mistral-7B-Instruct_英语',
    32 * 1000,
    true,
    0,
    0,
    feature: '国际模型_Mistral_7B_指令模型\n不支持system prompt设定，会报参数错误',
  ),
];
