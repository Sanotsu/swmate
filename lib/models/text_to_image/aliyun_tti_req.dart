import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'aliyun_tti_req.g.dart';

///
/// 阿里云的 "通义万相" 的请求参数
/// (注意，完整文生图，包含了提交job和查询job状态两个部分)
/// (阿里的文本对话模型已有兼容openai API的了，但文生图还是自己的)
///
/// part1 提交job 的请求
/// part2 查询job状态的请求
///     作业任务状态查询 是个GET 请求，只需要传入job提交后返回的 task_id 即可
///     注意每次请求都有一个request_id(不管是提交job还是查询job状态)，但提交成功之后返回的参数里面，才有task_id
/// 所以，两个接口请求，只需要这个一个请求体
/// 2024-08-19 部署在阿里云的flux也是同样结构的参数，少量不一样
@JsonSerializable(explicitToJson: true)
class AliyunTtiReq {
  // 指明需要调用的模型，固定值wanx-v1
  @JsonKey(name: 'model')
  String model;

  @JsonKey(name: 'input')
  AliyunTtiInput input;

  @JsonKey(name: 'parameters')
  AliyunTtiParameter? parameters;

  AliyunTtiReq({
    required this.model,
    required this.input,
    this.parameters,
  });

  // 从字符串转
  factory AliyunTtiReq.fromRawJson(String str) =>
      AliyunTtiReq.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory AliyunTtiReq.fromJson(Map<String, dynamic> srcJson) =>
      _$AliyunTtiReqFromJson(srcJson);

  Map<String, dynamic> toJson() => _$AliyunTtiReqToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AliyunTtiInput {
  // 描述画面的提示词信息。支持中英文，长度不超过500个字符，超过部分会自动截断
  @JsonKey(name: 'prompt')
  String? prompt;

  // 画面中不想出现的内容描述词信息。支持中英文，长度不超过500个字符，超过部分会自动截断。
  @JsonKey(name: 'negative_prompt')
  String? negativePrompt;

  // 输入参考图像的URL；图片格式可为 jpg，png，tiff，webp等常见位图格式。默认为空。
  @JsonKey(name: 'ref_img')
  String? refImg;

  /// 2024-08-20 阿里云的 wordArt 锦书创意文字，栏位多很多(prompt依旧是必传参数)
  // 图片、文字2选一
  AliyunTtiImage? image;
  // 可能是AliyunTtiText(纹理和百家姓)，也可能是String(文字变形)
  dynamic text;

  // 纹理风格的类型，包括“自定义”和“预设风格”两大类，两类风格具体取值和说明见文档
  @JsonKey(name: 'texture_style')
  String? textureStyle;

  /// 百家姓的还有其他的
  // 百家姓(最多2个字符)
  @JsonKey(name: 'surname')
  String? surname;

  // 百家姓风格类型，包括“自定义”和“预设风格”两大类
  @JsonKey(name: 'style')
  String? style;

  // 风格参考图的地址
  @JsonKey(name: 'ref_image_url')
  String? refImageUrl;

  AliyunTtiInput({
    required this.prompt,
    this.negativePrompt,
    this.refImg,
  });

  // flux的输入只需要promt
  AliyunTtiInput.flux({required this.prompt});

  // 阿里云的 wordArt 锦书创意文字
  AliyunTtiInput.wordArtTexture({
    this.image,
    this.text,
    required this.prompt,
    this.textureStyle,
  });

  // 文字变形只需要text和prompt，但文字是String类型，其他两个是AliyunTtiText！！！！！
  // 单独的类 WordArtSemantic
  AliyunTtiInput.wordArtSemantic({
    required this.prompt,
    this.text,
  });

  // 阿里云的 wordArt 百家姓生成
  AliyunTtiInput.wordArtSurnames({
    this.text,
    required this.surname,
    this.prompt,
    this.style,
    this.refImageUrl,
  });

  // 从字符串转
  factory AliyunTtiInput.fromRawJson(String str) =>
      AliyunTtiInput.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory AliyunTtiInput.fromJson(Map<String, dynamic> srcJson) =>
      _$AliyunTtiInputFromJson(srcJson);

  Map<String, dynamic> toFullJson() => _$AliyunTtiInputToJson(this);

  // 自定义tojson方法，参数为null的就不加到json中
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (prompt != null) json['prompt'] = prompt;
    if (negativePrompt != null) json['negative_prompt'] = negativePrompt;
    if (refImg != null) json['ref_img'] = refImg;
    if (image != null) json['image'] = image;
    if (text != null) json['text'] = text;
    if (textureStyle != null) json['texture_style'] = textureStyle;
    if (surname != null) json['surname'] = surname;
    if (style != null) json['style'] = style;
    if (refImageUrl != null) json['ref_image_url'] = refImageUrl;

    return json;
  }
}

@JsonSerializable(explicitToJson: true)
class AliyunTtiParameter {
  // 输出图像的风格，目前支持以下风格取值(注意要有尖括号)：
  //   "<auto>"：默认; "<3d cartoon>"：3D卡通; "<anime>"：动画; "<oil painting>"：油画
  //   "<watercolor>"：水彩; "<sketch>" ：素描;"<chinese painting>"：中国画; "<flat illustration>"：扁平插画
  @JsonKey(name: 'style')
  String? style;

  // 生成图像的分辨率，目前仅支持'1024*1024'，'720*1280'，'1280*720'三种分辨率，默认为1024*1024像素。
  // 2024-08-19 阿里云平台的flux.1 支持的尺寸有"512*1024, 768*512, 768*1024, 1024*576, 576*1024, 1024*1024"(默认)
  @JsonKey(name: 'size')
  String? size;

  // 本次请求生成的图片数量，目前支持1~4张，默认为1。
  @JsonKey(name: 'n')
  int? n;

  // 图片生成时候的种子值，取值范围为(0, 4294967290) 。如果不提供，则算法自动用一个随机生成的数字作为种子，
  //  如果给定了，则根据 batch 数量分别生成 seed，seed+1，seed+2，seed+3为参数的图片。
  @JsonKey(name: 'seed')
  int? seed;

  // 期望输出结果与垫图（参考图）的相似度，取值范围[0.0, 1.0]，数字越大，生成的结果与参考图越相似
  @JsonKey(name: 'strength')
  double? strength;

  // 垫图（参考图）生图使用的生成方式，可选值为'repaint' （默认） 和 'refonly'; 其中 repaint代表参考内容，refonly代表参考风格
  @JsonKey(name: 'ref_mode')
  String? refMode;

  // 图片生成的推理步数，如果不提供，则默认为30，如果给定了，则根据 steps 数量生成图片。
  // flux-schnell 模型官方默认 steps 为4，flux-dev 模型官方默认 steps 为50。
  @JsonKey(name: 'steps')
  int? steps;

  /// 2024-08-20 阿里云的 wordArt 锦书创意文字，额外的参数栏位(n是需要的)
  /// 文字纹理、文字变形、百家姓生成各自参数还不一样
  // 生成的图片短边的长度，默认为704，取值范围为[512, 1024]，
  @JsonKey(name: 'image_short_size')
  int? imageShortSize;

  // 是否返回带alpha通道的图片；默认为 false；
  @JsonKey(name: 'alpha_channel')
  bool? alphaChannel;

  // 文字纹理在intput，文字变形又放在参数
  @JsonKey(name: 'font_name')
  String? fontName;

  @JsonKey(name: 'ttf_url')
  String? ttfUrl;

  @JsonKey(name: 'output_image_ratio')
  String? outputImageRatio;

  AliyunTtiParameter({
    this.style,
    this.size,
    this.n,
    this.seed,
    this.strength,
    this.refMode,
    this.steps,
  });

  AliyunTtiParameter.wanx(
      {this.style, this.size, this.n, this.seed, this.strength, this.refMode});

  AliyunTtiParameter.flux({this.size, this.seed, this.steps});

  // 文字纹理就这3个
  AliyunTtiParameter.wordArtTexture({
    required this.n,
    this.imageShortSize = 1024,
    this.alphaChannel = true,
  });

  // 文字变形
  AliyunTtiParameter.wordArtSemantic({
    required this.n,
    this.steps = 60,
    this.fontName = "dongfangdakai",
    this.ttfUrl,
    this.outputImageRatio = "1280x720",
  });

  // 百家姓就一个n
  AliyunTtiParameter.wordArtSurnames({
    required this.n,
  });

  // 从字符串转
  factory AliyunTtiParameter.fromRawJson(String str) =>
      AliyunTtiParameter.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory AliyunTtiParameter.fromJson(Map<String, dynamic> srcJson) =>
      _$AliyunTtiParameterFromJson(srcJson);

  Map<String, dynamic> toJson() => _$AliyunTtiParameterToJson(this);
}

/// 阿里云锦书艺术文字可传参考图片
@JsonSerializable(explicitToJson: true)
class AliyunTtiImage {
  @JsonKey(name: 'image_url')
  String imageUrl;

  AliyunTtiImage(this.imageUrl);

  // 从字符串转
  factory AliyunTtiImage.fromRawJson(String str) =>
      AliyunTtiImage.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory AliyunTtiImage.fromJson(Map<String, dynamic> srcJson) =>
      _$AliyunTtiImageFromJson(srcJson);

  Map<String, dynamic> toJson() => _$AliyunTtiImageToJson(this);
}

/// 阿里云锦书艺术文字可传文字内容
@JsonSerializable()
class AliyunTtiText {
  // 用户输入的文字内容，小于6个字；若选择了input.text，此字段为必须字段，且不能为空字符串""；
  @JsonKey(name: 'text_content')
  String? textContent;

  // 用户传入的ttf文件；标准的ttf文件，文件大小小于30M；
  @JsonKey(name: 'ttf_url')
  String? ttfUrl;

// 使用预置字体的名称；当使用input.text时，input.text.ttf_url和input.text.font_name 需要二选一；
// 默认为"dongfangdakai"
  @JsonKey(name: 'font_name')
  String? fontName;

  // 文字输入的图片的宽高比；默认为"1:1"，可选的比例有："1:1", "16:9", "9:16"；
  @JsonKey(name: 'output_image_ratio')
  String? outputImageRatio;

  /// 百家姓生成需要的几个
  // 生成图片中文字字形的强度，取值范围为[0, 1]，越接近1表示字形强度越大，即生成的字越明显，默认为0.5；
  // 仅在input.style取"diy"时生效；
  @JsonKey(name: 'text_strength')
  String? textStrength;

  @JsonKey(name: 'text_inverse')
  String? textInverse;

  AliyunTtiText({
    this.textContent,
    this.ttfUrl,
    this.fontName,
    this.outputImageRatio,
  });

  // 生成纹理
  AliyunTtiText.wordArtTexture({
    this.textContent,
    this.ttfUrl,
    this.fontName,
    this.outputImageRatio,
  });

  // 文字变形只需要文本内容，且不需要这个外部内，但为了保持一致，这里用上了
  // 传参数的时候可以需要处理一下
  AliyunTtiText.wordArtSemantic({this.textContent});

  // 百家姓
  AliyunTtiText.wordArtSurnames({
    this.ttfUrl,
    this.fontName,
    this.textStrength,
    this.textInverse,
  });

  // 从字符串转
  factory AliyunTtiText.fromRawJson(String str) =>
      AliyunTtiText.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory AliyunTtiText.fromJson(Map<String, dynamic> srcJson) =>
      _$AliyunTtiTextFromJson(srcJson);

  Map<String, dynamic> toJson() => _$AliyunTtiTextToJson(this);
}
