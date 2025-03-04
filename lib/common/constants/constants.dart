// 时间格式化字符串
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:io';

const constDatetimeFormat = "yyyy-MM-dd HH:mm:ss";
const constDateFormat = "yyyy-MM-dd";
const constMonthFormat = "yyyy-MM";
const constTimeFormat = "HH:mm:ss";
// 文件名后缀等
const constDatetimeSuffix = "yyyyMMdd_HHmmss";
// 未知的时间字符串
const unknownDateTimeString = '1970-01-01 00:00:00';
const unknownDateString = '1970-01-01';

const String placeholderImageUrl = 'assets/images/no_image.png';
const String brandImageUrl = 'assets/brand.png';

const String aiAssistantCoverUrl = 'assets/images/covers/ai_assistant.jpg';
const String aiImageCoverUrl = 'assets/images/covers/ai_image.jpg';
const String aiVideoCoverUrl = 'assets/images/covers/ai_video.jpg';

// 数据库分页查询数据的时候，还需要带上一个该表的总数量
// 还可以按需补入其他属性
class CusDataResult {
  List<dynamic> data;
  int total;

  CusDataResult({
    required this.data,
    required this.total,
  });
}

// 自定义标签，常用来存英文、中文、全小写带下划线的英文等。
class CusLabel {
  final String? enLabel;
  final String cnLabel;
  final dynamic value;

  CusLabel({
    this.enLabel,
    required this.cnLabel,
    required this.value,
  });

  @override
  String toString() {
    return '''
    CusLabel{
      enLabel: $enLabel, cnLabel: $cnLabel, value:$value
    }
    ''';
  }
}

// 菜品的分类和标签都用预设的
// 2024-03-10 这个项目取值都直接取value，就不区别中英文了
List<CusLabel> dishTagOptions = [
  CusLabel(enLabel: 'LuCuisine', cnLabel: "鲁菜", value: '鲁菜'),
  CusLabel(enLabel: 'ChuanCuisine', cnLabel: "川菜", value: '川菜'),
  CusLabel(enLabel: 'YueCuisine', cnLabel: "粤菜", value: '粤菜'),
  CusLabel(enLabel: 'SuCuisine', cnLabel: "苏菜", value: '苏菜'),
  CusLabel(enLabel: 'MinCuisine', cnLabel: "闽菜", value: '闽菜'),
  CusLabel(enLabel: 'ZheCuisine', cnLabel: "浙菜", value: '浙菜'),
  CusLabel(enLabel: 'XiangCuisine', cnLabel: "湘菜", value: '湘菜'),
  CusLabel(enLabel: 'stir-fried', cnLabel: "炒", value: '炒'),
  CusLabel(enLabel: 'Quick-fry', cnLabel: "爆", value: '爆'),
  CusLabel(enLabel: 'sauté', cnLabel: "熘", value: '熘'),
  CusLabel(enLabel: 'fry', cnLabel: "炸", value: '炸'),
  CusLabel(enLabel: 'boil', cnLabel: "烹", value: '烹'),
  CusLabel(enLabel: 'decoct', cnLabel: "煎", value: '煎'),
  CusLabel(enLabel: 'paste', cnLabel: "贴", value: '贴'),
  CusLabel(enLabel: 'bake', cnLabel: "烧", value: '烧'),
  CusLabel(enLabel: 'sweat', cnLabel: "焖", value: '焖'),
  CusLabel(enLabel: 'stew', cnLabel: "炖", value: '炖'),
  CusLabel(enLabel: 'steam', cnLabel: "蒸", value: '蒸'),
  CusLabel(enLabel: 'quick-boil', cnLabel: "汆", value: '汆'),
  CusLabel(enLabel: 'boil', cnLabel: "煮", value: '煮'),
  CusLabel(enLabel: 'braise', cnLabel: "烩", value: '烩'),
  CusLabel(enLabel: 'Qiang', cnLabel: "炝", value: '炝'),
  CusLabel(enLabel: 'salt', cnLabel: "腌", value: '腌'),
  CusLabel(enLabel: 'stir-and-mix', cnLabel: "拌", value: '拌'),
  CusLabel(enLabel: 'roast', cnLabel: "烤", value: '烤'),
  CusLabel(enLabel: 'bittern', cnLabel: "卤", value: '卤'),
  CusLabel(enLabel: 'freeze', cnLabel: "冻", value: '冻'),
  CusLabel(enLabel: 'wire-drawing', cnLabel: "拔丝", value: '拔丝'),
  CusLabel(enLabel: 'honey-sauce', cnLabel: "蜜汁", value: '蜜汁'),
  CusLabel(enLabel: 'smoked', cnLabel: "熏", value: '熏'),
  CusLabel(enLabel: 'roll', cnLabel: "卷", value: '卷'),
  CusLabel(enLabel: 'other', cnLabel: "其他技法", value: '其他技法'),
];

List<CusLabel> dishCateOptions = [
  CusLabel(enLabel: 'Breakfast', cnLabel: "早餐", value: '早餐'),
  CusLabel(enLabel: 'Lunch', cnLabel: "早茶", value: '早茶'),
  CusLabel(enLabel: 'Lunch', cnLabel: "午餐", value: '午餐'),
  CusLabel(enLabel: 'AfternoonTea', cnLabel: "下午茶", value: '下午茶'),
  CusLabel(enLabel: 'Dinner', cnLabel: "晚餐", value: '晚餐'),
  CusLabel(enLabel: 'MidnightSnack', cnLabel: "夜宵", value: '夜宵'),
  CusLabel(enLabel: 'Dessert', cnLabel: "甜点", value: '甜点'),
  CusLabel(enLabel: 'StapleFood', cnLabel: "主食", value: '主食'),
  CusLabel(enLabel: 'Other', cnLabel: "其他", value: '其他'),
];

// 进入对话页面简单预设的一些问题
List<String> defaultChatQuestions = [
  "你好，介绍一下你自己。",
  "将“纵观世界风云，风景这边独好”这句话，翻译成英语、日语、俄语和西班牙语。",
  "介绍一下“受害者有罪论”，并分析这个说法是否合理。",
  "老板经常以未达到工作考核来克扣工资，经常让我无偿加班，是否已经违法？",
  "你是一位产品文案。请设计一份PPT大纲，介绍你们公司新推出的防晒霜，要求言简意赅并且具有创意。",
  "你是一位10w+爆款文章的编辑。请结合赛博玄学主题，如电子木鱼、机甲佛祖、星座、塔罗牌、人形锦鲤、工位装修等，用俏皮有网感的语言撰写一篇公众号文章。",
  "我是小区物业人员，小区下周六（9.30号）下午16:00-18:00，因为电力改造施工要停电，请帮我拟一份停电通知。",
  "一只青蛙一次可以跳上1级台阶，也可以跳上2级。求该青蛙跳上一个n级的台阶总共有多少种跳法。",
  "使用python3编写一个快速排序算法。",
  // "你是一个营养师。现在请帮我制定一周的健康减肥食谱。",
  // "小明因为女朋友需要的高额彩礼费而伤心焦虑，请帮我安慰一下他。",
  // "请为一家互联网公司写一则差旅费用管理规则。",
  // "小王最近天天加班，压力很大，心情很糟。也想着跳槽，但是就业大环境很差，不容易找到新工作。现在他很迷茫，请帮他出出主意。",
  // "使用python3编写一个快速排序算法。",
  // "如果我的邻居持续发出噪音严重影响我的生活，除了民法典1032条，还有什么法条支持居民向噪音发出者维权？",
  // "请帮我写一份通用的加薪申请模板。",
  // "一个长方体的棱长和是144厘米，它的长、宽、高之比是4:3:2，长方体的体积是多少？",
];

List<String> chatQuestionSamples = [
  "你好，介绍一下你自己。",
  "如何制作鱼香肉丝。",
  "苏东坡是谁？详细介绍一下。",
  "2024年巴黎奥运会金牌榜",
];

/// 保存文档解读、图片解读结果的目录
final FILE_INTERPRET_DIR =
    Directory('/storage/emulated/0/SWMate/file_interpret');

/// 智能对话和多聊中对话语音文件目录
final CHAT_AUDIO_DIR = Directory('/storage/emulated/0/SWMate/chat_audio');

/// 所有的文生图、图生图都保存在同一个位置
final LLM_IG_DIR = Directory('/storage/emulated/0/SWMate/image_generation');

///  新版本的文生图(2025-02-18保存在系统的pictures目录下photo_manager扫不到)
final LLM_IG_DIR_V2 =
    Directory('/storage/emulated/0/SWMate/brief_image_generation');

/// 所有的文生视频都保存在同一个位置
final LLM_VG_DIR = Directory('/storage/emulated/0/SWMate/video_generation');

/// 所有的视频都保存在同一个位置
final LLM_VG_DIR_V2 =
    Directory('/storage/emulated/0/SWMate/brief_video_generation');

/// 一般性质的文件下载的位置
final DL_DIR = Directory('/storage/emulated/0/SWMate/download');

// 可供翻译的目标语言
enum TargetLanguage {
  simplifiedChinese, // 中文(简体)
  traditionalChinese, // 中文(繁体)
  english, // 英语
  japanese, // 日语
  french, // 法语
  russian, // 俄语
  korean, // 韩语
  spanish, // 西班牙语
  portuguese, // 葡萄牙语
  german, // 德语
  vietnamese, // 越南语
  arabic, // 阿拉伯语
}

// 语言标签
Map<TargetLanguage, String> LangLabelMap = {
  TargetLanguage.simplifiedChinese: "中文(简体)",
  TargetLanguage.traditionalChinese: "中文(繁体)",
  TargetLanguage.english: "英语",
  TargetLanguage.japanese: "日语",
  TargetLanguage.french: "法语",
  TargetLanguage.russian: "俄语",
  TargetLanguage.korean: "韩语",
  TargetLanguage.spanish: "西班牙语",
  TargetLanguage.portuguese: "葡萄牙语",
  TargetLanguage.german: "德语",
  TargetLanguage.vietnamese: "越南语",
  TargetLanguage.arabic: "阿拉伯语",
};

// 大模型对话的角色枚举
enum CusRole {
  system,
  user,
  assistant,
}

// 2025-02-25 新版本图片、视频等AI生成资源管理页面，使用mime获取分类时自定义的key枚举
// 自定义媒体资源分类 custom mime classification
enum CusMimeCls {
  IMAGE,
  VIDEO,
  AUDIO,
}
