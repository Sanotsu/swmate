// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aliyun_tti_req.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AliyunTtiReq _$AliyunTtiReqFromJson(Map<String, dynamic> json) => AliyunTtiReq(
      model: json['model'] as String,
      input: AliyunTtiInput.fromJson(json['input'] as Map<String, dynamic>),
      parameters: json['parameters'] == null
          ? null
          : AliyunTtiParameter.fromJson(
              json['parameters'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AliyunTtiReqToJson(AliyunTtiReq instance) =>
    <String, dynamic>{
      'model': instance.model,
      'input': instance.input.toJson(),
      'parameters': instance.parameters?.toJson(),
    };

AliyunTtiInput _$AliyunTtiInputFromJson(Map<String, dynamic> json) =>
    AliyunTtiInput(
      prompt: json['prompt'] as String?,
      negativePrompt: json['negative_prompt'] as String?,
      refImg: json['ref_img'] as String?,
    )
      ..image = json['image'] == null
          ? null
          : AliyunTtiImage.fromJson(json['image'] as Map<String, dynamic>)
      ..text = json['text']
      ..textureStyle = json['texture_style'] as String?
      ..surname = json['surname'] as String?
      ..style = json['style'] as String?
      ..refImageUrl = json['ref_image_url'] as String?;

Map<String, dynamic> _$AliyunTtiInputToJson(AliyunTtiInput instance) =>
    <String, dynamic>{
      'prompt': instance.prompt,
      'negative_prompt': instance.negativePrompt,
      'ref_img': instance.refImg,
      'image': instance.image?.toJson(),
      'text': instance.text,
      'texture_style': instance.textureStyle,
      'surname': instance.surname,
      'style': instance.style,
      'ref_image_url': instance.refImageUrl,
    };

AliyunTtiParameter _$AliyunTtiParameterFromJson(Map<String, dynamic> json) =>
    AliyunTtiParameter(
      style: json['style'] as String?,
      size: json['size'] as String?,
      n: (json['n'] as num?)?.toInt(),
      seed: (json['seed'] as num?)?.toInt(),
      strength: (json['strength'] as num?)?.toDouble(),
      refMode: json['ref_mode'] as String?,
      steps: (json['steps'] as num?)?.toInt(),
      guidance: (json['guidance'] as num?)?.toDouble(),
    )
      ..imageShortSize = (json['image_short_size'] as num?)?.toInt()
      ..alphaChannel = json['alpha_channel'] as bool?
      ..fontName = json['font_name'] as String?
      ..ttfUrl = json['ttf_url'] as String?
      ..outputImageRatio = json['output_image_ratio'] as String?;

Map<String, dynamic> _$AliyunTtiParameterToJson(AliyunTtiParameter instance) =>
    <String, dynamic>{
      'style': instance.style,
      'size': instance.size,
      'n': instance.n,
      'seed': instance.seed,
      'strength': instance.strength,
      'ref_mode': instance.refMode,
      'steps': instance.steps,
      'guidance': instance.guidance,
      'image_short_size': instance.imageShortSize,
      'alpha_channel': instance.alphaChannel,
      'font_name': instance.fontName,
      'ttf_url': instance.ttfUrl,
      'output_image_ratio': instance.outputImageRatio,
    };

AliyunTtiImage _$AliyunTtiImageFromJson(Map<String, dynamic> json) =>
    AliyunTtiImage(
      json['image_url'] as String,
    );

Map<String, dynamic> _$AliyunTtiImageToJson(AliyunTtiImage instance) =>
    <String, dynamic>{
      'image_url': instance.imageUrl,
    };

AliyunTtiText _$AliyunTtiTextFromJson(Map<String, dynamic> json) =>
    AliyunTtiText(
      textContent: json['text_content'] as String?,
      ttfUrl: json['ttf_url'] as String?,
      fontName: json['font_name'] as String?,
      outputImageRatio: json['output_image_ratio'] as String?,
    )
      ..textStrength = json['text_strength'] as String?
      ..textInverse = json['text_inverse'] as String?;

Map<String, dynamic> _$AliyunTtiTextToJson(AliyunTtiText instance) =>
    <String, dynamic>{
      'text_content': instance.textContent,
      'ttf_url': instance.ttfUrl,
      'font_name': instance.fontName,
      'output_image_ratio': instance.outputImageRatio,
      'text_strength': instance.textStrength,
      'text_inverse': instance.textInverse,
    };
