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

  // 2025-03-24 火山引擎默认调用和关联应用(比如配置了联网搜索)使用的url不一样
  // 避免出现冲突，分成两个且互不包含
  volcengine,
  volcesBot,
}

// 用户自行导入密钥时，json文件的key
// 2025-03-14 这里的label，需要完整包含上面平台的枚举值，
// 否则无法用户单个添加指定平台的模型时，正确识别
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
  USER_SILICONCLOUD_API_KEY, // 硅基流动
  USER_INFINI_GEN_STUDIO_API_KEY, // 无问芯穹的genStudio
  USER_VOLCENGINE_API_KEY, // 火山引擎
  USER_VOLCESBOT_API_KEY, // 火山引擎的bot
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
  ApiPlatform.volcengine: '火山引擎',
  ApiPlatform.volcesBot: '火山Bot',
};

// 大模型的分类，在不同页面可以用作模型的筛选
enum LLModelType {
  cc, // Chat Completions
  vision, // 视觉大模型
  // 2025-03-06 推理模型(深度思考)有思考过程，且支持的参数和对话模型差异很大，所以单独分类
  reasoner,

  // 图片生成大模型分3种: 单独文生图、单独图生图、文生图生都可以
  tti, // Text To Image
  iti, // Image To Image
  image,

  // 视频生成大模型分3种: 单独文生视频、单独图生视频、文生图生都可以
  ttv, // Text To Video
  itv, // Image To Video
  video,

  // 语音大模型
  audio, // 语音对话 (支持语音输入的，然后输出的也是文本、如果输入语音输出语音看omni)
  asr, // 语音识别
  tts, // 语音合成

  // 全模态，比如通义千问-Omni-Turbo
  // 支持文本, 图像，语音，视频输入理解和混合输入理解，具备文本和语音同时流式生成能力
  omni,
}

// 模型类型对应的中文名
final Map<LLModelType, String> MT_NAME_MAP = {
  LLModelType.cc: '文本对话',
  LLModelType.vision: '图片解读',
  LLModelType.reasoner: '深度思考',
  LLModelType.tti: '文本生图',
  LLModelType.iti: '图片生图',
  LLModelType.image: '图片生成',
  LLModelType.ttv: '文生视频',
  LLModelType.itv: '图生视频',
  LLModelType.video: '视频生成',
  LLModelType.audio: '语音对话',
  LLModelType.asr: '语音识别',
  LLModelType.tts: '语音合成',
  LLModelType.omni: '全模态',
};
