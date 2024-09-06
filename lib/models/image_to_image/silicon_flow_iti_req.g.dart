// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'silicon_flow_iti_req.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SiliconflowItiReq _$SiliconflowItiReqFromJson(Map<String, dynamic> json) =>
    SiliconflowItiReq(
      prompt: json['prompt'] as String,
      image: json['image'] as String?,
      imageSize: json['image_size'] as String?,
      batchSize: (json['batch_size'] as num?)?.toInt(),
      numInferenceSteps: (json['num_inference_steps'] as num?)?.toInt(),
      guidanceScale: (json['guidance_scale'] as num?)?.toDouble(),
      negativePrompt: json['negative_prompt'] as String?,
      seed: (json['seed'] as num?)?.toInt(),
      controlnetConditioningScale:
          (json['controlnet_conditioning_scale'] as num?)?.toDouble(),
      enhanceFaceRegion: json['enhance_face_region'] as bool?,
      faceImage: json['face_image'] as String?,
      ipAdapterScale: (json['ip_adapter_scale'] as num?)?.toDouble(),
      poseImage: json['pose_image'] as String?,
      referenceStyleImage: json['reference_style_image'] as String?,
      roomImage: json['room_image'] as String?,
      styleName: json['style_name'] as String?,
      styleStrenghRadio: (json['style_strengh_radio'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SiliconflowItiReqToJson(SiliconflowItiReq instance) =>
    <String, dynamic>{
      'prompt': instance.prompt,
      'negative_prompt': instance.negativePrompt,
      'image': instance.image,
      'image_size': instance.imageSize,
      'batch_size': instance.batchSize,
      'num_inference_steps': instance.numInferenceSteps,
      'guidance_scale': instance.guidanceScale,
      'seed': instance.seed,
      'style_name': instance.styleName,
      'controlnet_conditioning_scale': instance.controlnetConditioningScale,
      'ip_adapter_scale': instance.ipAdapterScale,
      'enhance_face_region': instance.enhanceFaceRegion,
      'face_image': instance.faceImage,
      'pose_image': instance.poseImage,
      'style_strengh_radio': instance.styleStrenghRadio,
      'reference_style_image': instance.referenceStyleImage,
      'room_image': instance.roomImage,
    };
