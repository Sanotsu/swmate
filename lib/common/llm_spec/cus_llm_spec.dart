// ignore_for_file: constant_identifier_names, non_constant_identifier_names

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
  tencent,
  aliyun,
  siliconCloud,
  lingyiwanwu,
  xfyun, // 讯飞云，官网就是这样写的
}

// 大模型的分类，在不同页面可以用作模型的筛选
enum LLModelType {
  // CC, // Chat Completions
  // TTI, // Text To Image
  // ITI, // Image To Image
  // 用小写，大写不区分
  cc, // Chat Completions
  vision, // 视觉大模型
  tti, // Text To Image
  tti_word, // 生成艺术字图片
  iti, // Image To Image
}

// 模型对应的中文名
final Map<ApiPlatform, String> CP_NAME_MAP = {
  ApiPlatform.baidu: '百度',
  ApiPlatform.tencent: '腾讯',
  ApiPlatform.aliyun: '阿里',
  ApiPlatform.siliconCloud: '硅动科技',
  ApiPlatform.lingyiwanwu: '零一万物',
  ApiPlatform.xfyun: '讯飞',
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

  /// 讯飞的星火大模型轻量版
  xfyun_Spark_Lite,
  // 讯飞云文生图就是图片生成，没什么特别名字
  xfyun_TTI,

  // 通义万相，收费文生图
  aliyun_Wanx_v1_TTI,
  // 部署在阿里云的flux.1，限时免费
  aliyun_Flux_Merged_TTI,
  aliyun_Flux_Schnell_TTI,
  aliyun_Flux_Dev_TTI,

  /// 阿里云 锦书 创意文字
  // 文字纹理
  aliyun_Wordart_Texture_TTI_WORD,
  // 文字变形
  aliyun_Wordart_Semantic_TTI_WORD,
  // 百家姓生成
  aliyun_Wordart_Surnames_TTI_WORD,

  /// Yi前缀，零一万物中，全都收费的
  YiLarge,
  YiMedium,
  YiVision,
  YiMedium200k,
  YiSpark,
  YiLargeRag,
  YiLargeTurbo,

  /// 硅动科技免费的对话模型
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
  // 文生图模型
  siliconCloud_Flux1_Schnell_TTI,
  siliconCloud_StableDiffusion3_TTI,
  siliconCloud_StableDiffusionXL_TTI,
  siliconCloud_StableDiffusion2p1_TTI,
  siliconCloud_StableDiffusion_Turbo_TTI,
  siliconCloud_StableDiffusionXL_Turbo_TTI,
  siliconCloud_StableDiffusionXL_Lighting_TTI,
  // 图生图模型
  siliconCloud_PhotoMaker_ITI,
  siliconCloud_InstantID_ITI,
  siliconCloud_StableDiffusionXL_ITI,
  siliconCloud_StableDiffusion2p1_ITI,
  siliconCloud_StableDiffusionXL_Lighting_ITI,
}
