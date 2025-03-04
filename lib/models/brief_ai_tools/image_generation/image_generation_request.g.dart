// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_generation_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImageGenerationRequest _$ImageGenerationRequestFromJson(
        Map<String, dynamic> json) =>
    ImageGenerationRequest(
      model: json['model'] as String,
      prompt: json['prompt'] as String,
      n: (json['n'] as num?)?.toInt() ?? 1,
      size: json['size'] as String?,
      seed: (json['seed'] as num?)?.toInt(),
      steps: (json['steps'] as num?)?.toInt(),
      guidance: (json['guidance'] as num?)?.toDouble(),
      imageSize: json['image_size'] as String?,
      batchSize: (json['batch_size'] as num?)?.toInt(),
      numInferenceSteps: (json['num_inference_steps'] as num?)?.toInt(),
      guidanceScale: (json['guidance_scale'] as num?)?.toDouble(),
      negativePrompt: json['negative_prompt'] as String?,
      promptEnhancement: json['prompt_enhancement'] as bool?,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      imagePrompt: json['image_prompt'] as String?,
      promptUpsampling: json['prompt_upsampling'] as bool?,
      safetyTolerance: (json['safety_tolerance'] as num?)?.toInt(),
      interval: (json['interval'] as num?)?.toInt(),
      outputFormat: json['output_format'] as String? ?? "png",
      input: json['input'] == null
          ? null
          : AliyunWanxV2Input.fromJson(json['input'] as Map<String, dynamic>),
      parameters: json['parameters'] == null
          ? null
          : AliyunWanxV2Parameter.fromJson(
              json['parameters'] as Map<String, dynamic>),
      offload: (json['offload'] as num?)?.toDouble(),
      addSamplingMetadata: json['add_sampling_metadata'] as String?,
      userId: json['user_id'] as String?,
    );

Map<String, dynamic> _$ImageGenerationRequestToJson(
        ImageGenerationRequest instance) =>
    <String, dynamic>{
      'model': instance.model,
      'prompt': instance.prompt,
      'n': instance.n,
      'size': instance.size,
      'image_size': instance.imageSize,
      'batch_size': instance.batchSize,
      'num_inference_steps': instance.numInferenceSteps,
      'guidance_scale': instance.guidanceScale,
      'negative_prompt': instance.negativePrompt,
      'prompt_enhancement': instance.promptEnhancement,
      'width': instance.width,
      'height': instance.height,
      'image_prompt': instance.imagePrompt,
      'prompt_upsampling': instance.promptUpsampling,
      'guidance': instance.guidance,
      'safety_tolerance': instance.safetyTolerance,
      'interval': instance.interval,
      'output_format': instance.outputFormat,
      'seed': instance.seed,
      'steps': instance.steps,
      'input': instance.input?.toJson(),
      'parameters': instance.parameters?.toJson(),
      'offload': instance.offload,
      'add_sampling_metadata': instance.addSamplingMetadata,
      'user_id': instance.userId,
    };

AliyunWanxV2Input _$AliyunWanxV2InputFromJson(Map<String, dynamic> json) =>
    AliyunWanxV2Input(
      prompt: json['prompt'] as String?,
      negativePrompt: json['negative_prompt'] as String?,
    );

Map<String, dynamic> _$AliyunWanxV2InputToJson(AliyunWanxV2Input instance) =>
    <String, dynamic>{
      'prompt': instance.prompt,
      'negative_prompt': instance.negativePrompt,
    };

AliyunWanxV2Parameter _$AliyunWanxV2ParameterFromJson(
        Map<String, dynamic> json) =>
    AliyunWanxV2Parameter(
      size: json['size'] as String?,
      n: (json['n'] as num?)?.toInt(),
      seed: (json['seed'] as num?)?.toInt(),
      promptExtend: json['prompt_extend'] as bool?,
      watermark: json['watermark'] as bool? ?? false,
    );

Map<String, dynamic> _$AliyunWanxV2ParameterToJson(
        AliyunWanxV2Parameter instance) =>
    <String, dynamic>{
      'size': instance.size,
      'n': instance.n,
      'seed': instance.seed,
      'prompt_extend': instance.promptExtend,
      'watermark': instance.watermark,
    };
