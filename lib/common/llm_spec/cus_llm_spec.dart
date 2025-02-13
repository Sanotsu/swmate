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
  zhipu, // 智谱AI
  infini, // 无问芯穹的genStudio
}

// 模型对应的中文名
final Map<ApiPlatform, String> CP_NAME_MAP = {
  ApiPlatform.baidu: '百度',
  ApiPlatform.tencent: '腾讯',
  ApiPlatform.aliyun: '阿里',
  ApiPlatform.siliconCloud: '硅动科技',
  ApiPlatform.lingyiwanwu: '零一万物',
  ApiPlatform.xfyun: '讯飞',
  ApiPlatform.zhipu: '智谱',
  ApiPlatform.infini: '无问芯穹',
};

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
  ttv, // Text To Video
  voice, // 语音大模型
}

// 模型类型对应的中文名
final Map<LLModelType, String> MT_NAME_MAP = {
  LLModelType.cc: '文本对话',
  LLModelType.vision: '图片解读',
  LLModelType.tti: '文本生图',
  LLModelType.tti_word: '创意文字',
  LLModelType.iti: '图片生图',
  LLModelType.ttv: '文生视频',
  LLModelType.voice: '语音对话',
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
  /// 百度收费的模型
  baidu_ERNIE4p0_8K,
  baidu_ERNIE4p0_Turbo_8K,
  baidu_ERNIE3p5_8K,
  baidu_ERNIE3p5_128K,
  baidu_ERNIE_Novel_8K,

  tencent_Hunyuan_Lite,

  /// 腾讯收费的模型
  tencent_Hunyuan_Pro,
  tencent_Hunyuan_Standard,
  tencent_Hunyuan_Standard_256K,
  tencent_Hunyuan_Vision,

  zhipu_GLM4_Flash,

  /// 讯飞的星火大模型轻量版
  xfyun_Spark_Lite,
  // 讯飞付费大模型
  xfyun_Spark_Pro,

  // 讯飞云文生图就是图片生成，没什么特别名字
  xfyun_TTI,

  /// 通义万相，收费文生图
  /// 文生图模型地址
  // https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis
  aliyun_Wanx_v1_TTI,
  // 部署在阿里云的flux.1，限时免费，地址同上
  aliyun_Flux_Merged_TTI,
  aliyun_Flux_Schnell_TTI,
  aliyun_Flux_Dev_TTI,

  // /// 阿里云的收费模型（对话的没有免费token 了，第三方不兼容openAI，VL要上传文件不支持base64，所以都不处理了）
  // 2024-08-29 实测 Qwen_VL_Max_0809 图像理解兼容openAI的接口，可以上传base64的数据
  // /// 对话模型地址
  // // https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation
  // // 兼容openAI的地址(只支持通义千问（含VL）及其开源系列)
  // // https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions
  aliyun_Qwen_Max,
  aliyun_Qwen_Max_LongContext,
  aliyun_Qwen_Plus,
  aliyun_Qwen_Turbo,
  aliyun_Qwen_Long,
  // // 第三方对话，地址同上(不支持openAI兼容)
  // aliyun_Baichuan2_Turbo,
  // aliyun_Moonshot_V1_8K,
  // aliyun_Moonshot_V1_32K,
  // aliyun_Moonshot_V1_128K,
  // // https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation
  // aliyun_Yi_Large,
  // aliyun_Yi_Large_Turbo,
  // aliyun_Yi_Large_RAG,
  // aliyun_Yi_Medium,

  /// 视觉模型
  // https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation
  // 兼容openAI的地址(只支持通义千文VL)
  // https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions
  aliyun_Qwen_VL_Max_0809,
  aliyun_Qwen_VL_Max,
  aliyun_Qwen_VL_Plus,

  /// 阿里云 锦书 创意文字
  // 文字纹理
  // https://dashscope.aliyuncs.com/api/v1/services/aigc/wordart/texture
  aliyun_Wordart_Texture_TTI_WORD,
  // 文字变形
  // https://dashscope.aliyuncs.com/api/v1/services/aigc/wordart/semantic
  aliyun_Wordart_Semantic_TTI_WORD,
  // 百家姓生成
  // https://dashscope.aliyuncs.com/api/v1/services/aigc/wordart/surnames
  aliyun_Wordart_Surnames_TTI_WORD,

  /// Yi前缀，零一万物中，全都收费的
  lingyiwanwu_YiLarge,
  lingyiwanwu_YiMedium,
  lingyiwanwu_YiVision,
  lingyiwanwu_YiMedium200k,
  lingyiwanwu_YiSpark,
  lingyiwanwu_YiLargeRag,
  lingyiwanwu_YiLargeTurbo,

  /// 硅动科技免费的对话模型
  siliconCloud_Qwen2p5_7B_Instruct,
  siliconCloud_Qwen2_7B_Instruct,
  siliconCloud_Qwen2_1p5B_Instruct,
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

// 限时免费也当作收费
  siliconCloud_Qwen2p5_Coder_7B_Instruct,
  siliconCloud_VendorA_Qwen2_72B_Instruct,

  /// 硅动科技收费的模型
  siliconCloud_Qwen2p5_72B_Instruct,
  siliconCloud_Qwen2p5_32B_Instruct,
  siliconCloud_Qwen2p5_14B_Instruct,
  siliconCloud_Qwen2p5_Math_72B_Instruct,
  siliconCloud_Qwen2_Math_72B_Instruct,
  siliconCloud_Qwen2_57B_A14B_Instruct,
  siliconCloud_Yi1p5_34B_Chat_16K,
  siliconCloud_DeepSeek_V2p5,
  siliconCloud_DeepSeek_Coder_V2_Instruct,
  siliconCloud_DeepSeek_V2_Chat,
  siliconCloud_internlm2p5_20B_Chat,
  siliconCloud_Llama3p1_405B_Instruct,
  siliconCloud_Llama3p1_70B_Instruct,
  siliconCloud_Llama3_70B_Instruct,
  siliconCloud_gemma2_27B_Instruct,
  siliconCloud_Pro_Flux1_Schnell_TTI,
  siliconCloud_Pro_Flux1_Dev_TTI,

  /// 智谱AI相关收费模型
  // 对话
  zhipu_GLM4_Plus,
  zhipu_GLM4_0520,
  zhipu_GLM4_AirX,
  zhipu_GLM4_Air,
  zhipu_GLM4_Long,
  zhipu_GLM4_FlashX,
  // 多模态
  zhipu_GLM4V_Plus,
  zhipu_GLM4V,
  zhipu_CogView3_Plus_TTI,
  zhipu_CogView3_TTI,
  zhipu_CogVideoX_TTV,

  /// 无问芯穹的非企业用户可以限时限量的对话模型
  /// 2024-09-07 限时免费，很多企业用户才有资格申请的模型未列示
  // 单个 API Key 限制
  // 限制类型	                限制数量	      频率刷新时间窗口	适用 API 服务
  // 每分钟请求次数 (RPM)	      12	          1 分钟	        所有预置模型
  // 每天请求次数 (RPD)	        3000	        24 小时	        所有预置模型
  // 每分钟 Token 数量 (TPM)	  12000	        1 分钟	        所有预置模型
  // 2024-09-07 实测，下列不需要申请的模型不可用了
  // infini_ChatGLM2_6B, // 无权限
  // infini_ChatGLM2_6B_32K, // 无权限
  // infini_ChatGLM3_6B_Base, // 已关闭
  // infini_InfiniMegrez_7B, // 无权限
  // infini_Qwen_7B_Chat, // 无权限
  // infini_Qwen_14B_Chat,  // 服务器已关闭
  // infini_Qwen1p5_7B_Chat, // 无法连接到服务器
  // infini_Qwen1p5_72B, // 模型广场没此模型
  // infini_Qwen2_7B, // 服务器已关闭
  infini_Yi1p5_34B_Chat,
  infini_Baichuan2_7B_Chat,
  infini_Baichuan2_13B_Chat,
  infini_Baichuan2_13B_Base,
  infini_GLM4_9B_Chat,
  infini_ChatGLM3,
  infini_ChatGLM3_6B,
  infini_ChatGLM3_6B_32K,
  infini_MtInfini_3B,
  infini_Qwen2p5_7B_Instruct,
  infini_Qwen2p5_14B_Instruct,
  infini_Qwen2p5_32B_Instruct,
  infini_Qwen2p5_72B_Instruct,
  infini_Qwen_72B_Chat,
  infini_Qwen1p5_14B_Chat,
  infini_Qwen1p5_32B_Chat,
  infini_Qwen1p5_72B_Chat,
  infini_Qwen2_7B_Instruct,
  infini_Qwen2_72B_Instruct,
}
