import 'package:json_annotation/json_annotation.dart';

part 'aliyun_wanx_req.g.dart';

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
@JsonSerializable(explicitToJson: true)
class AliyunWanxReq {
  // 指明需要调用的模型，固定值wanx-v1
  @JsonKey(name: 'model')
  String model;

  @JsonKey(name: 'input')
  WanxInput input;

  @JsonKey(name: 'parameters')
  WanxParameter? parameters;

  AliyunWanxReq({
    required this.model,
    required this.input,
    this.parameters,
  });

  factory AliyunWanxReq.fromJson(Map<String, dynamic> srcJson) =>
      _$AliyunWanxReqFromJson(srcJson);

  Map<String, dynamic> toJson() => _$AliyunWanxReqToJson(this);
}

@JsonSerializable(explicitToJson: true)
class WanxInput {
  // 描述画面的提示词信息。支持中英文，长度不超过500个字符，超过部分会自动截断
  @JsonKey(name: 'prompt')
  String prompt;

  // 画面中不想出现的内容描述词信息。支持中英文，长度不超过500个字符，超过部分会自动截断。
  @JsonKey(name: 'negative_prompt')
  String? negativePrompt;

  // 输入参考图像的URL；图片格式可为 jpg，png，tiff，webp等常见位图格式。默认为空。
  @JsonKey(name: 'ref_img')
  String? refImg;

  WanxInput({
    required this.prompt,
    this.negativePrompt,
    this.refImg,
  });

  factory WanxInput.fromJson(Map<String, dynamic> srcJson) =>
      _$WanxInputFromJson(srcJson);

  Map<String, dynamic> toJson() => _$WanxInputToJson(this);
}

@JsonSerializable(explicitToJson: true)
class WanxParameter {
  // 输出图像的风格，目前支持以下风格取值(注意要有尖括号)：
  //   "<auto>"：默认; "<3d cartoon>"：3D卡通; "<anime>"：动画; "<oil painting>"：油画
  //   "<watercolor>"：水彩; "<sketch>" ：素描;"<chinese painting>"：中国画; "<flat illustration>"：扁平插画
  @JsonKey(name: 'style')
  String? style;

  // 生成图像的分辨率，目前仅支持'1024*1024'，'720*1280'，'1280*720'三种分辨率，默认为1024*1024像素。
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

  WanxParameter({
    this.style,
    this.size,
    this.n,
    this.seed,
    this.strength,
    this.refMode,
  });

  factory WanxParameter.fromJson(Map<String, dynamic> srcJson) =>
      _$WanxParameterFromJson(srcJson);

  Map<String, dynamic> toJson() => _$WanxParameterToJson(this);
}
