// ignore_for_file: non_constant_identifier_names, constant_identifier_names

//
// 常量尽量用全首字母大写、或者全大写加下划线，方便本人习惯的识别方式
//

import '../../../common/llm_spec/cus_llm_spec.dart';

///
/// 文档解析页面用到的一些常量
///
enum CusSysRole {
  doc_translator, // 翻译
  doc_summarizer, // 总结
  doc_analyzer, // 分析
  img_translator,
  img_summarizer,
  img_analyzer,
}

/// 文档解读这页面可能需要的一些栏位
/// 2024-08-23 简单了解后，这可能不是智能体，只是系统角色而已
class CusSysRoleSpec {
  // 系统角色的标签
  final String label;
  // 系统角色的枚举名称
  CusSysRole? name;
  // 系统角色的提示信息
  String? hintInfo;
  // 系统角色的系统提示
  final String systemPrompt;

  // 系统角色图片地址
  String? imageUrl;
  // 类别(后续区分文本对话的系统角色、图片生成的系统角色等)
  LLModelType? sysRoleType;

  CusSysRoleSpec({
    required this.label,
    required this.name,
    required this.hintInfo,
    required this.systemPrompt,
  });

  CusSysRoleSpec.chat({
    required this.label,
    required this.systemPrompt,
    this.imageUrl,
    this.sysRoleType = LLModelType.cc,
  });
}

// 预设的文档解读的系统角色
var DocSysRoleItems = [
  CusSysRoleSpec(
    label: "翻译",
    name: CusSysRole.doc_translator,
    hintInfo: DocHintInfo,
    systemPrompt: """您是一位精通世界上任何语言的翻译专家。将对用户输入的文本进行精准翻译。只做翻译工作，无其他行为。
      如果用户输入了多种语言的文本，统一翻译成目标语言。
      如果用户指定了翻译的目标语言，则翻译成该目标语言；如果目标语言和原版语言一致，则不做翻译直接输出原版语言。
      如果没有指定翻译的目标语言，那么默认翻译成简体中文；如果已经是简体中文了，则翻译成英文。
      翻译完成之后单独解释重难点词汇。
      如果翻译后内容很多，需要分段显示。""",
  ),
  CusSysRoleSpec(
    label: "总结",
    name: CusSysRole.doc_summarizer,
    hintInfo: DocHintInfo,
    systemPrompt: """你是一个文档分析专家，你需要根据提供的文档内容，生成一份简洁、结构化的文档摘要。
      如果原文本不是中文，总结要使用中文。""",
  ),
  CusSysRoleSpec(
    label: "分析",
    name: CusSysRole.doc_analyzer,
    hintInfo: DocHintInfo,
    systemPrompt: """你是一个文档分析专家，你需要根据提供的文档内容，回答用户输入的各种问题。""",
  ),
];

// 预设的图片解读的系统角色
var ImgSysRoleItems = [
  CusSysRoleSpec(
    label: "翻译",
    name: CusSysRole.img_translator,
    hintInfo: ImgHintInfo,
    systemPrompt: """你是一个图片分析处理专家，你将识别出图中的所有文字，并对这些文字进行精准翻译。
      只做翻译工作，无其他行为。
      如果图片中存在多种语言的文本，统一翻译成目标语言。
      如果用户指定了翻译的目标语言，则翻译成该目标语言；如果目标语言和原版语言一致，则不做翻译直接输出原版语言。
      如果没有指定翻译的目标语言，那么默认翻译成简体中文；如果已经是简体中文了，则翻译成英文。
      翻译完成之后单独解释重难点词汇。
      如果翻译后内容很多，需要分段显示。""",
  ),
  CusSysRoleSpec(
    label: "总结",
    name: CusSysRole.img_summarizer,
    hintInfo: ImgHintInfo,
    systemPrompt: """你是一个图片分析处理专家，你将认真、准确地分析图片，总结图片的内容，生成摘要。""",
  ),
  CusSysRoleSpec(
    label: "分析",
    name: CusSysRole.img_analyzer,
    hintInfo: ImgHintInfo,
    systemPrompt: """你是一个图片分析处理专家，你将认真、准确地分析图片，并基于图片的内容，回答用户输入的各种问题。""",
  ),
];

const DocHintInfo = """1. 目前仅支持上传单个文档文件;
2. 上传文档目前仅支持 pdf、txt、docx、doc 格式;
3. 上传的文档和手动输入的文档总内容不超过8000字符;
4. 如有上传文件, 点击[文档解析完成]蓝字, 可以预览解析后的文档.""";

const ImgHintInfo = """1. 点击图片可预览、缩放
2. 支持 JPEG/PNG 格式
3. 图片最大支持 2048*1080
4. base64编码后大小不超过4M
5. 图片越大，处理耗时越久.""";

///
/// 文本对话中，默认的角色列表
///
var defaultCCSysRoleList = [
  CusSysRoleSpec.chat(
    label: "总结",
    systemPrompt: """你是一个文档分析专家，你需要根据提供的文档内容，生成一份简洁、结构化的文档摘要。
      如果原文本不是中文，总结要使用中文。""",
  ),
];

///
/// 文生图页面用到的一些常量
///
/// 2024-08-19 不管原本接口支持的尺寸如何，这里统一下面4个(要确保每个模型都支持这4个)
/// 除了讯飞，因为其他论张算，它不同尺寸费用是不一样的
/// 512*512
/// 1024*1024
/// 720*1280,
/// 1280*720,
///
///

/// 预设的张数列表
final ImageNumList = [1, 2, 3, 4];

// final COMMON_ImageSizeList = [
//   "512x512",
//   "1024*1024",
//   '720*1280',
//   '1280*720',
// ];

// // 传一个奇怪的尺寸，报错看模型支持的尺寸列表(理想情况下有返回的话)
// final XUJIA_ImageSizeList = [
//   '608*1096',
//   '320*640',
//   '560*720',
//   '768*1152',
// ];

// siliconflow平台文生图参数
var SF_ImageSizeList = [
  "512x512",
  "512x1024",
  '768x512',
  '768x1024',
  '1024x576',
  '576x1024',
];

/// 根据下面信息，阿里云的tti尺寸统一一下
final ALIYUN_ImageSizeList = [
  '1024*1024',
  '720*1280',
  '1280*720',
  // 虽然文档没写，但实测是支持的
  '768*1152',
];

// // flux-schnell
// // 报错提示的：The height and width should be divided by 8
// // ['1024*1024', '720*1280', '1280*720', '768*1152']
// // 文档写的："512*1024, 768*512, 768*1024, 1024*576, 576*1024, 1024*1024"
// // 实测512*1024会报错
// final ALIYUN_FLUX_ImageSizeList = [
//   '1024*1024',
//   '720*1280',
//   '1280*720',
//   '768*1152',
// ];

// // 阿里通义万相文生图参数
// final WANX_ImageSizeList = [
//   '1024*1024',
//   '720*1280',
//   '1280*720',
//   // 虽然文档没写，但实测是支持的
//   '768*1152',
// ];

// // flux-schnell
// // 报错提示的：The height and width should be divided by 8
// // ['1024*1024', '720*1280', '1280*720', '768*1152']
// // 文档写的："512*1024, 768*512, 768*1024, 1024*576, 576*1024, 1024*1024"
// // 实测512*1024会报错
// final ALIYUN_FLUX_ImageSizeList = [
//   '1024*1024',
//   '720*1280',
//   '1280*720',
//   '768*1152',
// ];

// 讯飞文生图参数(宽高要拆成2个参数，所以取到值要split获取宽高)
// 每种尺寸价格不一定
final XFYUN_ImageSizeList = [
  "512x512",
  "640x360",
  "640x480",
  "640x640",
  "680x512",
  "512x680",
  "768x768",
  "720x1280",
  "1280x720",
  "1024x1024",
];

// 可选的图片风格
Map<String, String> WANX_StyleMap = {
  "默认": 'auto',
  "3D卡通": '3d cartoon',
  "动画": 'anime',
  "油画": 'oil painting',
  "水彩": 'watercolor',
  "素描": 'sketch',
  "中国画": 'chinese painting',
  "扁平插画": 'flat illustration',
};
// 选定的风格对应的预览本地图片
List<String> WANX_StyleImageList = [
  'assets/aliyun_wanx_styles/默认.jpg',
  'assets/aliyun_wanx_styles/3D卡通.jpg',
  'assets/aliyun_wanx_styles/动画.jpg',
  'assets/aliyun_wanx_styles/油画.jpg',
  'assets/aliyun_wanx_styles/水彩.jpg',
  'assets/aliyun_wanx_styles/素描.jpg',
  'assets/aliyun_wanx_styles/中国画.jpg',
  'assets/aliyun_wanx_styles/扁平插画.jpg',
];

/// 锦书文字纹理（字体变形也一样）支持的字体名称(如果没有自己传字体，默认支持的字体列表)
Map<String, String> WordArt_Texture_FontNameMap = {
  "阿里妈妈东方大楷": "dongfangdakai",
  "阿里巴巴普惠体": "puhuiti_m",
  "阿里妈妈数黑体": "shuheiti",
  "钉钉进步体": "jinbuti",
  "站酷酷黑体": 'kuheiti',
  "站酷快乐体": "kuaileti",
  "站酷文艺体": "wenyiti",
  "站酷小薇LOGO体": "logoti",
  "站酷仓耳渔阳体": "cangeryuyangti_m",
  "思源宋体": "siyuansongti_b",
  "思源黑体": "siyuanheiti_m",
  "方正楷体": "fangzhengkaiti",
};

/// 锦书百家姓生成支持的字体名称(如果没有自己传字体，默认支持的字体列表)
/// 仅在input.style取"diy"时生效；input.text.ttf_url和input.text.font_name 需要二选一；
Map<String, String> WordArt_Surnames_FontNameMap = {
  "古风字体1": "gufeng1",
  "古风字体2": "gufeng2",
  "古风字体3": "gufeng3",
  "古风字体4": "gufeng4",
  "古风字体5": "gufeng5",
};

/// 锦书文字纹理支持的样式
Map<String, String> WordArt_Texture_StyleMap = {
  // “自定义”大类提供3种风格，用户可基于提供的风格通过提示词进行纹理效果自定义，
  // 支持输入提示词（input.prompt）和字体类型（input.text.ttf_url和input.text.font_name），
  // 取值类型如下：
  "立体材质": "material",
  "场景融合": "scene",
  "光影特效": "lighting",
  // 预设风格”大类提供20种风格，此类别为预设的风格效果，
  // 不支持用户自定义输入提示词（input.prompt）和字体类型（input.text.ttf_url和input.text.font_name），
  // 取值类型如下：
  "瀑布流水": "waterfall",
  "雪域高原": "snow_plateau",
  "原始森林": "forest",
  "天空遨游": "sky",
  "国风建筑": "chinese_building",
  "奇幻卡通": "cartoon",
  "乐高积木": "lego",
  "繁花盛开": "flower",
  "亚克力": "acrylic",
  "大理石": "marble",
  "绒线毛毡": "felt",
  "复古油画": "oil_painting",
  "水彩": "watercolor_painting",
  "中国画": "chinese_painting",
  "工笔画": "claborate_style_painting",
  "城市夜景": "city_night",
  "湖光山色": "mountain_lake",
  "秋日落叶": "autumn_leaves",
  "青龙献瑞": "green_dragon",
  "赤龙呈祥": "red_dragon",
};

/// 锦书百家姓生成支持的样式
Map<String, String> WordArt_Surnames_StyleMap = {
  // 风格类型，包括“自定义”和“预设风格”两大类
  //  “自定义”取值为"diy"，用户可通过提示词（input.prompt）、参考图（input. ref_image_url ）和字体相关参数（input.text）进行效果自定义，
  //  且提示词和参考图至少需要提供一项，
  "自定义": "diy",
  // 预设风格”大类提供12种风格，此类别为预设的风格效果，
  // 不支持用户输入提示词（input.prompt）、参考图（input. ref_image_url ）和字体相关参数（input.text）进行效果自定义
  "奇幻楼阁": "fantasy_pavilion",
  "绝色佳人": "peerless_beauty",
  "山水楼阁": "landscape_pavilion",
  "古风建筑": "traditional_buildings",
  "青龙女侠": "green_dragon_girl",
  "樱花烂漫": "cherry_blossoms",
  "可爱少女": "lovely_girl",
  "水墨少侠": "ink_hero",
  "动漫少女": "anime_girl",
  "水中楼阁": "lake_pavilion",
  "宁静乡村": "tranquil_countryside",
  "黄昏美景": "dusk_splendor",
};

// 输出的图片比例
// 纹理生成是 "1:1", "16:9", "9:16"
// 文字变形是 "1280x720", "720x1280", "1024x1024"
// 百家姓生成 没有
// 如果选中的是纹理，改为对应比例即可
var WordArt_outputImageRatioList = [
  "1280x720",
  "720x1280",
  "1024x1024",
];

///
/// 图生图中，部分模型有预设的风格
///

Map<String, String> PhotoMaker_StyleMap = {
  "逼真摄像": "Photographic (Default)",
  "电影质感": "Cinematic",
  "连环画册": "Comic book",
  "迪斯尼经典": "Disney Character",
  "数码艺术": "Digital Art",
  "奇幻艺术": "Fantasy Art",
  "复古朋克": "Neopunk",
  "画质增强": "Enhance",
  "降低质量": "Lowpoly",
  "线条艺术": "Line art",
  "无样式": "(No style)",
};

Map<String, String> InstantID_StyleMap = {
  "水彩": "Watercolor",
  "荧光": "Neon",
  "丛林": "Jungle",
  "火星": "Mars",
  "鲜艳": "Vibrant Color",
  "白雪": "Snow",
  "黑白": "Film Noir",
  "线条": "Line art",
  "无样式": "(No style)",
};

// siliconflow平台图生图参数
var SF_ITISizeList = [
  "1024X1024",
  "1024X2048",
  '1536x1024',
  '1536x2048',
  '2048x1152',
  '1152x2048',
];
