// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'com_tti_req.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComTtiReq _$ComTtiReqFromJson(Map<String, dynamic> json) => ComTtiReq(
      prompt: json['prompt'] as String,
      imageSize: json['image_size'] as String,
      numInferenceSteps: (json['num_inference_steps'] as num).toInt(),
      seed: (json['seed'] as num?)?.toInt(),
      batchSize: (json['batch_size'] as num?)?.toInt() ?? 1,
    )
      ..negativePrompt = json['negative_prompt'] as String?
      ..guidanceScale = (json['guidance_scale'] as num?)?.toDouble();

Map<String, dynamic> _$ComTtiReqToJson(ComTtiReq instance) => <String, dynamic>{
      'prompt': instance.prompt,
      'image_size': instance.imageSize,
      'num_inference_steps': instance.numInferenceSteps,
      'seed': instance.seed,
      'negative_prompt': instance.negativePrompt,
      'batch_size': instance.batchSize,
      'guidance_scale': instance.guidanceScale,
    };
