// ignore_for_file: non_constant_identifier_names, constant_identifier_names

//
// 常量尽量用全首字母大写、或者全大写加下划线，方便本人习惯的识别方式
//

///
/// 文档解析页面用到的一些常量
///
enum CusAgent {
  doc_translator, // 翻译
  doc_summarizer, // 总结
  doc_analyzer, // 分析
  img_translator,
  img_summarizer,
  img_analyzer,
}

/// 文档解读这页面可能需要的一些栏位
class CusAgentSpec {
  // 智能体的标签
  final String label;
  // 智能体的枚举名称
  final CusAgent name;
  // 智能体的提示信息
  final String hintInfo;
  // 智能体的系统提示
  final String systemPrompt;

  CusAgentSpec({
    required this.label,
    required this.name,
    required this.hintInfo,
    required this.systemPrompt,
  });
}

// 预设的文档解读的智能体
var DocAgentItems = [
  CusAgentSpec(
    label: "翻译",
    name: CusAgent.doc_translator,
    hintInfo: DocHintInfo,
    systemPrompt: """您是一位精通世界上任何语言的翻译专家。将对用户输入的文本进行精准翻译。只做翻译工作，无其他行为。
      如果用户输入了多种语言的文本，统一翻译成目标语言。
      如果用户指定了翻译的目标语言，则翻译成该目标语言；如果目标语言和原版语言一致，则不做翻译直接输出原版语言。
      如果没有指定翻译的目标语言，那么默认翻译成简体中文；如果已经是简体中文了，则翻译成英文。
      翻译完成之后单独解释重难点词汇。
      如果翻译后内容很多，需要分段显示。""",
  ),
  CusAgentSpec(
    label: "总结",
    name: CusAgent.doc_summarizer,
    hintInfo: DocHintInfo,
    systemPrompt: """你是一个文档分析专家，你需要根据提供的文档内容，生成一份简洁、结构化的文档摘要。
      如果原文本不是中文，总结要使用中文。""",
  ),
  CusAgentSpec(
    label: "分析",
    name: CusAgent.doc_analyzer,
    hintInfo: DocHintInfo,
    systemPrompt: """你是一个文档分析专家，你需要根据提供的文档内容，回答用户输入的各种问题。""",
  ),
];

// 预设的图片解读的智能体
var ImgAgentItems = [
  CusAgentSpec(
    label: "翻译",
    name: CusAgent.img_translator,
    hintInfo: ImgHintInfo,
    systemPrompt: """你是一个图片分析处理专家，你将识别出图中的所有文字，并对这些文字进行精准翻译。
      只做翻译工作，无其他行为。
      如果图片中存在多种语言的文本，统一翻译成目标语言。
      如果用户指定了翻译的目标语言，则翻译成该目标语言；如果目标语言和原版语言一致，则不做翻译直接输出原版语言。
      如果没有指定翻译的目标语言，那么默认翻译成简体中文；如果已经是简体中文了，则翻译成英文。
      翻译完成之后单独解释重难点词汇。
      如果翻译后内容很多，需要分段显示。""",
  ),
  CusAgentSpec(
    label: "总结",
    name: CusAgent.img_summarizer,
    hintInfo: ImgHintInfo,
    systemPrompt: """你是一个图片分析处理专家，你将认真、准确地分析图片，总结图片的内容，生成摘要。""",
  ),
  CusAgentSpec(
    label: "分析",
    name: CusAgent.img_analyzer,
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
/// 文生图页面用到的一些常量
///

/// 预设的张数列表
final ImageNumList = [1, 2, 3, 4];

// siliconflow平台文生图参数
var SF_ImageSizeList = [
  "512x512",
  "512x1024",
  '768x512',
  '768x1024',
  '1024x576',
  '576x1024',
];

// 阿里通义万相文生图参数
final WANX_ImageSizeList = [
  '1024*1024',
  '720*1280',
  '1280*720',
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
