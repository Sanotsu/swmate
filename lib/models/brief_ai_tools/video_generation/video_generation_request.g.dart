// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_generation_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoGenerationRequest _$VideoGenerationRequestFromJson(
        Map<String, dynamic> json) =>
    VideoGenerationRequest(
      model: json['model'] as String,
      prompt: json['prompt'] as String,
      quality: json['quality'] as String?,
      withAudio: json['with_audio'] as bool?,
      imageUrl: json['image_url'] as String?,
      size: json['size'] as String?,
      fps: (json['fps'] as num?)?.toInt(),
      requestId: json['request_id'] as String?,
      userId: json['user_id'] as String?,
      image: json['image'] as String?,
      seed: (json['seed'] as num?)?.toInt(),
      guidanceScale: (json['guidance_scale'] as num?)?.toDouble(),
      input: json['input'] == null
          ? null
          : AliyunVideoInput.fromJson(json['input'] as Map<String, dynamic>),
      parameters: json['parameters'] == null
          ? null
          : AliyunVideoParameter.fromJson(
              json['parameters'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$VideoGenerationRequestToJson(
        VideoGenerationRequest instance) =>
    <String, dynamic>{
      'model': instance.model,
      'prompt': instance.prompt,
      'input': instance.input?.toJson(),
      'parameters': instance.parameters?.toJson(),
      'quality': instance.quality,
      'with_audio': instance.withAudio,
      'image_url': instance.imageUrl,
      'size': instance.size,
      'fps': instance.fps,
      'request_id': instance.requestId,
      'user_id': instance.userId,
      'image': instance.image,
      'seed': instance.seed,
      'guidance_scale': instance.guidanceScale,
    };

AliyunVideoInput _$AliyunVideoInputFromJson(Map<String, dynamic> json) =>
    AliyunVideoInput(
      prompt: json['prompt'] as String?,
      imgUrl: json['img_url'] as String?,
    );

Map<String, dynamic> _$AliyunVideoInputToJson(AliyunVideoInput instance) =>
    <String, dynamic>{
      'prompt': instance.prompt,
      'img_url': instance.imgUrl,
    };

AliyunVideoParameter _$AliyunVideoParameterFromJson(
        Map<String, dynamic> json) =>
    AliyunVideoParameter(
      size: json['size'] as String?,
      seed: (json['seed'] as num?)?.toInt(),
      duration: (json['duration'] as num?)?.toInt() ?? 5,
      promptExtend: json['prompt_extend'] as bool? ?? true,
    );

Map<String, dynamic> _$AliyunVideoParameterToJson(
        AliyunVideoParameter instance) =>
    <String, dynamic>{
      'size': instance.size,
      'duration': instance.duration,
      'prompt_extend': instance.promptExtend,
      'seed': instance.seed,
    };
