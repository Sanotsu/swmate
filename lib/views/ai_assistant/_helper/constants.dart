// ignore_for_file: non_constant_identifier_names, constant_identifier_names

//
// 常量尽量用全首字母大写、或者全大写加下划线，方便本人习惯的识别方式
//

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

///
/// 文生图用到的一些常量
///

/// 预设的生成图片的张数列表
final ImageNumList = [1, 2, 3, 4];

// 智谱文生图支持的尺寸
var ZHIPU_CogViewSizeList = [
  "1024x1024",
  "768x1344",
  "864x1152",
  "1344x768",
  "1152x864",
  "1440x720",
  "720x1440",
];

// siliconflow平台文生图参数
// flux.1-schnell
var SF_Flux_ImageSizeList = [
  "1024x1024",
  "512x1024",
  '768x512',
  '768x1024',
  '1024x576',
  '576x1024',
  "512x512", // 文档没写，但实测可以
];

// SD3、SD XL、SD XL Lighting
var SF_SD3_XL_ImageSizeList = [
  "1024x1024",
  "1024x2048",
  '1536x1024',
  '1536x2048',
  '2048x1152',
  '1152x2048',
];

// SD2.1、SD Turbo、SD XL Turbo
var SF_SD2p1_ImageSizeList = [
  "512x512",
  "512x1024",
  '768x512',
  '768x1024',
  '1024x576',
  '576x1024',
  "1024x1024", // 文档没写，但实测可以
];

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

/// 阿里云tti支持的尺寸
final ALIYUN_WANX_ImageSizeList = [
  // 万相：虽然文档没写'768*1152'，但实测是支持的
  '1024*1024', '1280*720', '768*1152', '720*1280',
];

final ALIYUN_FLUX_ImageSizeList = [
  // flux
  '1024*1024', '1024*576', '768*1024', '768*512', '576*1024', '512*1024',
];

// 可选的图片风格
Map<String, String> WANX_StyleMap = {
  "默认": 'auto',
  "摄影": 'photography',
  "人像写真": 'portrait',
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
  'assets/aliyun_wanx_styles/摄影.png',
  'assets/aliyun_wanx_styles/人像写真.png',
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
  "512x512",
  "512x1024",
  "768x512",
  "768x1024",
  "1024x576",
  "576x1024",
  // 文档是这样，但不能用
  // "1024X1024",
  // "1024X2048",
  // '1536x1024',
  // '1536x2048',
  // '2048x1152',
  // '1152x2048',
];
