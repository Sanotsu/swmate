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
  aliyun,
  baidu,
  tencent,

  deepseek,
  lingyiwanwu,
  zhipu,

  siliconCloud,
  infini,
}

// 用户自行导入密钥时，json文件的key
enum ApiPlatformAKLabel {
  // 传统主流多模型平台(自研+第三方)
  USER_ALIYUN_API_KEY,
  USER_BAIDU_API_KEY_V2,
  USER_TENCENT_API_KEY,

  // 自平台(只有自研)
  USER_DEEPSEEK_API_KEY, // 深度求索
  USER_LINGYIWANWU_API_KEY, // 零一万物
  USER_ZHIPU_API_KEY, // 智谱AI

  // 第三方多模型平台(只有第三方)
  USER_SILICON_CLOUD_API_KEY, // 硅基流动
  USER_INFINI_GEN_STUDIO_API_KEY, // 无问芯穹的genStudio
}

// 模型对应的中文名
final Map<ApiPlatform, String> CP_NAME_MAP = {
  ApiPlatform.aliyun: '阿里',
  ApiPlatform.baidu: '百度',
  ApiPlatform.tencent: '腾讯',
  ApiPlatform.deepseek: '深度求索',
  ApiPlatform.lingyiwanwu: '零一万物',
  ApiPlatform.zhipu: '智谱',
  ApiPlatform.siliconCloud: '硅基流动',
  ApiPlatform.infini: '无问芯穹',
};

// 大模型的分类，在不同页面可以用作模型的筛选
enum LLModelType {
  cc, // Chat Completions
  vision, // 视觉大模型
  voice, // 语音大模型

  // 图片生成大模型分3种: 单独文生图、单独图生图、文生图生都可以
  tti, // Text To Image
  iti, // Image To Image
  image,

  // 视频生成大模型分3种: 单独文生视频、单独图生视频、文生图生都可以
  ttv, // Text To Video
  itv, // Image To Video
  video,

  // 全模态，比如通义千问-Omni-Turbo
  // 支持文本, 图像，语音，视频输入理解和混合输入理解，具备文本和语音同时流式生成能力
  omni,
}

// 模型类型对应的中文名
final Map<LLModelType, String> MT_NAME_MAP = {
  LLModelType.cc: '文本对话',
  LLModelType.vision: '图片解读',
  LLModelType.voice: '语音对话',
  LLModelType.tti: '文本生图',
  LLModelType.iti: '图片生图',
  LLModelType.image: '图片生成',
  LLModelType.ttv: '文生视频',
  LLModelType.itv: '图生视频',
  LLModelType.video: '视频生成',
  LLModelType.omni: '全模态',
};
