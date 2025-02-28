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
  cc, // Chat Completions
  vision, // 视觉大模型
  tti_word, // 生成艺术字图片
  voice, // 语音大模型

  // 图片生成大模型分3种: 单独文生图、单独图生图、文生图生都可以
  tti, // Text To Image
  iti, // Image To Image
  image,

  // 视频生成大模型分3种: 单独文生视频、单独图生视频、文生图生都可以
  ttv, // Text To Video
  itv, // Image To Video
  video,
}

// 模型类型对应的中文名
final Map<LLModelType, String> MT_NAME_MAP = {
  LLModelType.cc: '文本对话',
  LLModelType.vision: '图片解读',
  LLModelType.tti_word: '创意文字',
  LLModelType.voice: '语音对话',
  LLModelType.tti: '文本生图',
  LLModelType.iti: '图片生图',
  LLModelType.image: '图片生成',
  LLModelType.ttv: '文生视频',
  LLModelType.itv: '图生视频',
  LLModelType.video: '视频生成',
};
