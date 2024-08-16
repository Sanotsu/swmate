// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'cus_llm_spec.g.dart';

///
/// 这里是付费的大模型通用
///
/// 定义云平台
/// 2024-07-08 这里的AI助手，估计只需要这个付费的就好了
///
/// 因为零一万物的API兼容openAI的api，后续付费的应该都是这样的，而不是之前免费的三大平台乱七八糟的
///
enum ApiPlatform {
  baidu,
  // tencent,
  aliyun,
  siliconCloud,
  lingyiwanwu,
}

// 大模型的分类，在不同页面可以用作模型的筛选
enum LLModelType {
  // CC, // Chat Completions
  // TTI, // Text To Image
  // ITI, // Image To Image
  // 用小写，大写不区分
  cc, // Chat Completions
  tti, // Text To Image
  iti, // Image To Image
}

// 模型对应的中文名
final Map<ApiPlatform, String> CP_NAME_MAP = {
  ApiPlatform.baidu: '百度',
  // ApiPlatform.tencent: '腾讯',
  ApiPlatform.aliyun: '阿里',
  ApiPlatform.siliconCloud: '硅动科技',
  ApiPlatform.lingyiwanwu: '零一万物',
};

///
/// 对话模型列表(chat completion model)
///   基座模型（base）、聊天模型（chat）和指令模型（instruct/it）
/// 文生图模型列表(text to image model)
enum CusLLM {
  // 命名规则(尽量)：部署所在平台_模型版本_参数(_类型)_上下文长度
  baidu_Ernie_Speed_8K,
  baidu_Ernie_Speed_128K,
  // baiduErnieSpeedAppBuilder,
  baidu_Ernie_Lite_8K,
  baidu_Ernie_Tiny_8K,
  baidu_Yi_34B_Chat_4K,
  baidu_Fuyu_8B, // 图像理解

  tencent_Hunyuan_Lite,

  // 通义万相，收费文生图
  aliyun_Wanx_v1_TTI,

  // 硅动科技免费的
  siliconCloud_Qwen2_7B_Instruct,
  siliconCloud_Qwen2_1p5B_Instruct,
  siliconCloud_Qwen1p5_7B_Chat,
  siliconCloud_GLM4_9B_Chat,
  siliconCloud_ChatGLM3_6B,
  siliconCloud_Yi1p5_9B_Chat_16K,
  siliconCloud_Yi1p5_6B_Chat,
  // 2024-08-08 查看时又有一些免费的(国外的，英文模型)
  siliconCloud_GEMMA2_9B_Instruct,
  siliconCloud_InternLM2p5_7B_Chat,
  siliconCloud_LLAMA3_8B_Instruct,
  siliconCloud_LLAMA3p1_8B_Instruct,
  siliconCloud_Mistral_7B_Instruct_v0p2,
  // Yi前缀，零一万物中，全都收费的
  YiLarge,
  YiMedium,
  YiVision,
  YiMedium200k,
  YiSpark,
  YiLargeRag,
  YiLargeTurbo,

  /// 文生图模型
  siliconCloud_Flux1_Schnell_TTI,
  siliconCloud_StableDiffusion3_TTI,
  siliconCloud_StableDiffusionXL_TTI,
  siliconCloud_StableDiffusion2p1_TTI,
  siliconCloud_StableDiffusion_Turbo_TTI,
  siliconCloud_StableDiffusionXL_Turbo_TTI,
  siliconCloud_StableDiffusionXL_Light_TTI,
}

/// 通用模型规格
@JsonSerializable(explicitToJson: true)
class CusLLMSpec {
  // 模型字符串(平台API参数的那个model的值)、模型名称、上下文长度数值，
  /// 是否免费，收费输入时百万token价格价格，输出时百万token价格(免费没写价格就先写0)
  ApiPlatform platform;
  String model;
  // 随便带上模型枚举名称，方便过滤筛选
  CusLLM cusLlm;
  String name;
  int? contextLength;
  bool isFree;
  // 每百万token单价
  double? inputPrice;
  double? outputPrice;
  // 是否是视觉理解大模型(即是否可以解析图片、分析图片内容，然后进行对话,使用时需要支持上传图片)
  bool? isVision;
  // 是否支持索引用实时全网检索信息服务
  bool? isQuote;
  // 模型特性
  String? feature;
  // 使用场景
  String? useCase;

  // 模型类型
  LLModelType modelType;
  // 每张图的花费
  double? costPerImage;

// 默认是对话模型的构造函数
  CusLLMSpec(this.platform, this.cusLlm, this.model, this.name,
      this.contextLength, this.isFree, this.inputPrice, this.outputPrice,
      {this.isVision = false,
      this.isQuote = false,
      this.feature,
      this.useCase,
      this.modelType = LLModelType.cc})
      : costPerImage = null;

// 文生图的栏位稍微不一样
  CusLLMSpec.tti(
    this.platform,
    this.cusLlm,
    this.model,
    this.name,
    this.isFree, {
    this.feature,
    this.useCase,
    this.modelType = LLModelType.cc,
    this.costPerImage = 0.5,
  })  : contextLength = null,
        inputPrice = null,
        outputPrice = null,
        isVision = null,
        isQuote = null;

  // 从字符串转
  factory CusLLMSpec.fromRawJson(String str) =>
      CusLLMSpec.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory CusLLMSpec.fromJson(Map<String, dynamic> srcJson) =>
      _$CusLLMSpecFromJson(srcJson);

  Map<String, dynamic> toJson() => _$CusLLMSpecToJson(this);
}

/// 具体的模型信息
final List<CusLLMSpec> CusLLM_SPEC_LIST = CCM_SPEC_LIST + TTI_SPEC_LIST;

/// 文本对话模型
final List<CusLLMSpec> CCM_SPEC_LIST = [
  /// 下面是官方免费的
  CusLLMSpec(
    ApiPlatform.baidu,
    CusLLM.baidu_Ernie_Speed_8K,
    "ernie_speed",
    'ERNIESpeed8K',
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
    'ERNIESpeed128K',
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
    'ERNIELite8K',
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
    'ERNIETiny8K',
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
    'YI_34B_Chat_4K',
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
    "fuyu-8b",
    'Fuyu_8B',
    4 * 1000,
    true,
    0,
    0,
    isVision: true,
    feature: """Fuyu-8B是由Adept AI训练的多模态图像理解模型，可以支持多样的图像分辨率，回答图形图表有关问题。
    模型在视觉问答和图像描述等任务上表现良好。""",
  ),
  // CusLLMSpec(
  //   ApiPlatform.tencent,
  //   CusLLM.tencent_Hunyuan_Lite,
  //   "hunyuan-lite",
  //   '混元Lite',
  //   8 * 1000,
  //   true,
  //   0,
  //   0,
  //   feature: """腾讯混元大模型(Tencent Hunyuan)是由腾讯研发的大语言模型，
  //       具备强大的中文创作能力，复杂语境下的逻辑推理能力，以及可靠的任务执行能力。
  //       混元-Lite 升级为MOE结构，上下文窗口为256k，在NLP，代码，数学，行业等多项评测集上领先众多开源模型。""",
  // ),

  CusLLMSpec(
    ApiPlatform.siliconCloud,
    CusLLM.siliconCloud_Qwen2_7B_Instruct,
    "Qwen/Qwen2-7B-Instruct",
    '通义千问2开源版7B_指令',
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
    '通义千问2开源版1.5B_指令',
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
    '通义千问1.5开源版7B_对话',
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
    'GLM4开源版9B_对话',
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
    'ChatGLM3开源版6B_对话',
    32 * 1000,
    true,
    0,
    0,
    feature: 'ChatGLM3开源版6B_对话模型',
  ),
  CusLLMSpec(
    ApiPlatform.siliconCloud,
    CusLLM.siliconCloud_Yi1p5_9B_Chat_16K,
    "01-ai/Yi-1.5-6B-Chat",
    '零一万物1.5开源版9B_对话',
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
    '零一万物1.5开源版6B_对话',
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
    '国际_Gemma2_9B_指令',
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
    '国际_InternLM2.5_7B_对话',
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
    '国际_Llama3_8B_指令',
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
    '国际_Llama 3.1_8B_指令',
    8 * 1000,
    true,
    0,
    0,
    feature: '国际模型_Meta_LLAMA3.1_8B_指令模型',
  ),
  CusLLMSpec(
    ApiPlatform.siliconCloud,
    CusLLM.siliconCloud_Mistral_7B_Instruct_v0p2,
    "mistralai/Mistral-7B-Instruct-v0.2",
    '国际_Mistral_7B_指令',
    32 * 1000,
    true,
    0,
    0,
    feature: '国际模型_Mistral_7B_指令模型',
  ),
  CusLLMSpec(
    ApiPlatform.lingyiwanwu,
    CusLLM.YiLarge,
    "yi-large",
    'YiLarge',
    32000,
    false,
    20,
    20,
    feature: """最新版本的yi-large模型。
    千亿参数大尺寸模型，提供超强问答及文本生成能力，具备极强的推理能力。
    并且对 System Prompt 做了专属强化。""",
    useCase: """适合于复杂语言理解、深度内容创作设计等复杂场景。""",
  ),
  CusLLMSpec(
    ApiPlatform.lingyiwanwu,
    CusLLM.YiMedium,
    "yi-medium",
    'YiMedium',
    16000,
    false,
    2.5,
    2.5,
    feature: """中型尺寸模型升级微调，能力均衡，性价比高。深度优化指令遵循能力。""",
    useCase: """适用于日常聊天、问答、写作、翻译等通用场景，是企业级应用和AI大规模部署的理想选择。""",
  ),
  CusLLMSpec(
    ApiPlatform.lingyiwanwu,
    CusLLM.YiVision,
    "yi-vision",
    'YiVision',
    4000,
    false,
    6,
    6,
    isVision: true,
    feature: """复杂视觉任务模型，提供高性能图片理解、分析能力。""",
    useCase: """适合需要分析和解释图像、图表的场景，如图片问答、图表理解、OCR、视觉推理、教育、研究报告理解或多语种文档阅读等。""",
  ),
  CusLLMSpec(
    ApiPlatform.lingyiwanwu,
    CusLLM.YiMedium200k,
    "yi-medium-200k",
    'YiMedium200k',
    200000,
    false,
    12,
    12,
    feature: """200K超长上下文窗口，提供长文本深度理解和生成能力。""",
    useCase: """适用于长文本的理解和生成，如文档阅读、问答、构建知识库等场景。""",
  ),
  CusLLMSpec(
    ApiPlatform.lingyiwanwu,
    CusLLM.YiSpark,
    "yi-spark",
    'YiSpark',
    16000,
    false,
    1,
    1,
    feature: """小而精悍，轻量极速模型。提供强化数学运算和代码编写能力。""",
    useCase: """适用于轻量化数学分析、代码生成、文本聊天等场景。""",
  ),
  CusLLMSpec(
    ApiPlatform.lingyiwanwu,
    CusLLM.YiLargeRag,
    "yi-large-rag",
    'YiLargeRag_检索增强生成',
    16000,
    false,
    25,
    25,
    isQuote: true,
    feature: """实时全网检索信息服务，模型进阶能力。基于yi-large模型，结合检索与生成技术提供精准答案。""",
    useCase: """适用于需要结合实时信息，进行复杂推理、文本生成等场景。""",
  ),
  CusLLMSpec(
    ApiPlatform.lingyiwanwu,
    CusLLM.YiLargeTurbo,
    "yi-large-turbo",
    'YiLargeTurbo',
    16000,
    false,
    12,
    12,
    feature: """超高性价比、卓越性能。根据性能和推理速度、成本，进行平衡性高精度调优。""",
    useCase: """适用于全场景、高品质的推理及文本生成等场景。""",
  ),
];

/// 文生图的模型
final List<CusLLMSpec> TTI_SPEC_LIST = [
  CusLLMSpec.tti(
    ApiPlatform.aliyun,
    CusLLM.aliyun_Wanx_v1_TTI,
    "wanx-v1",
    '阿里-通义万相',
    false,
    feature: """通义万相-文本生成图像大模型，
        支持中英文双语输入，重点风格包括但不限于水彩、油画、中国画、素描、扁平插画、二次元、3D卡通""",
    modelType: LLModelType.tti,
  ),
  CusLLMSpec.tti(
    ApiPlatform.siliconCloud,
    CusLLM.siliconCloud_Flux1_Schnell_TTI,
    "black-forest-labs/FLUX.1-schnell",
    'Flux.1-schnell',
    true,
    feature: """SiliconCloud Flux.1-schnell""",
    useCase: """SiliconCloud Flux.1-schnell""",
    modelType: LLModelType.tti,
  ),
  CusLLMSpec.tti(
    ApiPlatform.siliconCloud,
    CusLLM.siliconCloud_StableDiffusion3_TTI,
    "stabilityai/stable-diffusion-3-medium",
    'Stable Diffusion 3',
    true,
    feature: """SiliconCloud Stable Diffusion 3""",
    useCase: """SiliconCloud Stable Diffusion 3""",
    modelType: LLModelType.tti,
  ),
  CusLLMSpec.tti(
    ApiPlatform.siliconCloud,
    CusLLM.siliconCloud_StableDiffusionXL_TTI,
    "stabilityai/stable-diffusion-xl-base-1.0",
    'Stable Diffusion XL',
    true,
    feature: """SiliconCloud Stable Diffusion XL""",
    useCase: """SiliconCloud Stable Diffusion XL""",
    modelType: LLModelType.tti,
  ),
  CusLLMSpec.tti(
    ApiPlatform.siliconCloud,
    CusLLM.siliconCloud_StableDiffusion2p1_TTI,
    "stabilityai/stable-diffusion-2-1",
    'Stable Diffusion 2.1',
    true,
    feature: """SiliconCloud Stable Diffusion 2.1""",
    useCase: """SiliconCloud Stable Diffusion 2.1""",
    modelType: LLModelType.tti,
  ),
  CusLLMSpec.tti(
    ApiPlatform.siliconCloud,
    CusLLM.siliconCloud_StableDiffusion_Turbo_TTI,
    "stabilityai/sd-turbo",
    'Stable Diffusion Turbo',
    true,
    feature: """SiliconCloud Stable Diffusion Turbo""",
    useCase: """SiliconCloud Stable Diffusion Turbo""",
    modelType: LLModelType.tti,
  ),
  CusLLMSpec.tti(
    ApiPlatform.siliconCloud,
    CusLLM.siliconCloud_StableDiffusionXL_Turbo_TTI,
    "stabilityai/sdxl-turbo",
    'Stable Diffusion XL Turbo',
    true,
    feature: """SiliconCloud Stable Diffusion XL Turbo""",
    useCase: """SiliconCloud Stable Diffusion XL Turbo""",
    modelType: LLModelType.tti,
  ),
  CusLLMSpec.tti(
    ApiPlatform.siliconCloud,
    CusLLM.siliconCloud_StableDiffusionXL_Light_TTI,
    "ByteDance/SDXL-Lightning",
    'Stable Diffusion XL Lighting',
    true,
    feature: """SiliconCloud Stable Diffusion XL Lighting""",
    useCase: """SiliconCloud Stable Diffusion XL Lighting""",
    modelType: LLModelType.tti,
  ),
];
