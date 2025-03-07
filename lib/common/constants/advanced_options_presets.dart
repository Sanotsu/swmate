// ignore_for_file: constant_identifier_names, avoid_print

import '../components/advanced_options_panel.dart';
import '../llm_spec/constant_llm_enum.dart';

///
///
/// 可复用的参数，构建成枚举，再构建高级选项，在放到指定平台和分类
/// AdvancedOptionEnum AOEnum
///
enum AOEnum {
  // cc、reasoner、vision 不同平台统一的就先这几个中选
  stream,
  stream_options,
  temperature,
  top_p,
  max_tokens,
  presence_penalty,
  frequency_penalty,
  response_format,

  // 少量指定平台支持的参数
  // 智谱
  do_sample,
}

/// 高级参数配置管理
/// 2025-03-05 这里只能按照代码设计中的平台和模型分类来配置参数。无法指定模型的参数来配置
/// 比如单独配置某个平台的deepseek-v3, 我配置的是该平台下 LLModelType 为cc的参数，而不是实际deepseek-v3支持的所有参数
/// 这个考虑是因为
///   - 很多高级参数对普通用户来讲没有必要避免产生干扰
///   - 同样的模型分类方便统一配置
///   - 如果不同平台对同一个模型支持的参数不一样，也不好配置
/// 此外，LLModelType 的分类也不是每个都单独配置，大体也分为对话、生图、生视频、生语音、全模态等
///
/// 2025-03-06 不同平台对同一个模型支持的参数不一样，兼容的思路
/// 【一】针对大部分都支持、但少部分平台不支持
///       1. 不管在平台是否支持，设置高级参数时都显示
///       2. 在构建为请求参数时，如果平台不支持，则忽略该参数(配置好 _parameterMappings)
/// 【二】针对少部分平台支持独特参数
///       1. 直接配置好 _platformOptions ，针对不同类型的独特参数
class AdvancedOptionsManager {
  ///
  /// 获取指定平台和模型类型的所有可用参数
  /// (组件展示可用高级选项时会用到)
  static List<AdvancedOption> getAvailableOptions(
    ApiPlatform platform,
    LLModelType modelType,
  ) {
    final List<AdvancedOption> options = [];

    // 1. 添加模型类型的参数（包含共享参数和特有参数）
    if (_commonTypeOptions.containsKey(modelType)) {
      options.addAll(_commonTypeOptions[modelType]!);
    }

    // 2. 添加平台特有参数
    if (_platformOptions.containsKey(platform) &&
        _platformOptions[platform]!.containsKey(modelType)) {
      options.addAll(_platformOptions[platform]![modelType]!);
    }

    return options;
  }

  /// 构建高级参数请求体
  /// (service会用到)
  static Map<String, dynamic> buildAdvancedParams(
    Map<String, dynamic> advancedOptions,
    ApiPlatform platform,
  ) {
    final params = <String, dynamic>{};

    print('构建高级参数, 输入: $advancedOptions');

    // 处理参数映射和嵌套对象
    advancedOptions.forEach((key, value) {
      // 1. 先检查是否需要特殊映射
      final mappedKey = _getParameterMapping(key, platform);

      // 如果映射后的key为null或空字符串，则跳过该参数
      if (mappedKey == null || mappedKey.isEmpty) {
        print('参数 $key 在平台 $platform 被忽略');
        return;
      }

      // 2. 检查是否需要构建嵌套对象
      final objectConfig = _objectConfigs[mappedKey];
      if (objectConfig != null) {
        // 如果是对象配置，构建嵌套对象
        params[mappedKey] = _buildNestedObject(objectConfig, value);
      } else {
        // 普通参数直接赋值
        params[mappedKey] = value;
      }

      print('参数映射: $key -> $mappedKey = ${params[mappedKey]}');
    });

    // 3. 针对平台特殊处理
    _handlePlatformSpecificParams(params, platform);

    print('构建高级参数, 输出: $params');
    return params;
  }

  /// 针对平台特殊处理
  static void _handlePlatformSpecificParams(
    Map<String, dynamic> params,
    ApiPlatform platform,
  ) {
    // 根据平台进行特殊处理
    switch (platform) {
      case ApiPlatform.zhipu:
        // 智谱的温度是[0,1],和其他的[0,2]不一样？？？该怎么处理
        params['temperature'] = params['temperature'] / 2;
        break;
      case ApiPlatform.aliyun:
        // 阿里云的温度是[0,2), 2会报错
        if (params['temperature'] == 2) {
          params['temperature'] = 1.99;
        }
        break;
      default:
        break;
    }
  }

  /// 构建嵌套对象
  static Map<String, dynamic> _buildNestedObject(
    ObjectConfig config,
    dynamic value,
  ) {
    final result = <String, dynamic>{};

    // 根据配置构建对象
    switch (config.type) {
      case ObjectType.streamOptions:
        result['include_usage'] = value;
        break;
      case ObjectType.responseFormat:
        result['type'] = value;
        break;
      // ... 其他对象类型
    }

    return result;
  }

  /// 获取参数映射后的键名
  /// 返回 null 或空字符串表示该参数将被忽略
  static String? _getParameterMapping(String key, ApiPlatform platform) {
    final mapping = _parameterMappings[platform];
    if (mapping == null) return key;

    // 如果映射值为 null 或空字符串，表示该参数需要被忽略
    return mapping.containsKey(key) ? mapping[key] : key;
  }

  /// 高级参数配置
  /// 如果说不同的模型分类，预设值不一样，再配置分类时重新配置就好。
  /// 比如vision的最大token和cc就不一样
  static final Map<AOEnum, AdvancedOption> aoCommonMap = {
    AOEnum.stream: AdvancedOption(
      key: AOEnum.stream.name,
      label: '流式输出',
      description: '是否启用流式响应',
      type: OptionType.toggle,
      defaultValue: true,
    ),
    AOEnum.stream_options: AdvancedOption(
      key: AOEnum.stream_options.name,
      label: '流式选项(包含Token用量)',
      description: '流式响应的附加选项',
      type: OptionType.toggle,
      defaultValue: false,
    ),
    AOEnum.temperature: AdvancedOption(
      key: AOEnum.temperature.name,
      label: '温度(temperature)',
      description: '值越大,回复越随机创新;值越小,回复越确定',
      type: OptionType.slider,
      defaultValue: 0.7,
      // 大多数是 [0,2] : 零一万物、正常的百度、硅基流动、混元lite、
      // 智谱的是 [0,1] -> 特殊处理
      // 阿里是 [0,2), 2会报错 -> 特殊处理
      // 百度正常[0,2], 但DS R系列是 (0, 1.0],不能为0 -> 暂时不管
      min: 0,
      max: 2,
      divisions: 20,
    ),
    AOEnum.top_p: AdvancedOption(
      key: AOEnum.top_p.name,
      label: '采样阈值(topP)',
      description: '控制词汇采样范围,影响回复的多样性',
      type: OptionType.slider,
      defaultValue: 1.0,
      min: 0.1,
      max: 1,
      divisions: 9,
    ),
    AOEnum.max_tokens: AdvancedOption(
      key: AOEnum.max_tokens.name,
      label: '最大回复Token数',
      description: '限制模型回复的最大长度',
      type: OptionType.slider,
      defaultValue: 2000,
      min: 512,
      max: 8192,
      divisions: 15,
      isNeedInt: true,
    ),
    AOEnum.presence_penalty: AdvancedOption(
      key: AOEnum.presence_penalty.name,
      label: '存在惩罚(presence_penalty)',
      description: '降低模型谈论相同主题的概率',
      type: OptionType.slider,
      defaultValue: 0.0,
      min: -2,
      max: 2,
      divisions: 40,
    ),
    AOEnum.frequency_penalty: AdvancedOption(
      key: AOEnum.frequency_penalty.name,
      label: '频率惩罚(frequency_penalty)',
      description: '降低模型重复使用相同词汇的概率',
      type: OptionType.slider,
      defaultValue: 0.0,
      min: -2,
      max: 2,
      divisions: 40,
    ),
    AOEnum.response_format: AdvancedOption(
      key: AOEnum.response_format.name,
      label: '响应格式',
      description: '选择JSON格式需明确告知‘按JSON格式回复’(已自动补上)，否则报错',
      type: OptionType.select,
      defaultValue: 'json_object',
      items: [
        OptionItem('文本', 'text'),
        OptionItem('JSON对象', 'json_object'),
      ],
    ),
  };

  static final Map<AOEnum, AdvancedOption> aoSpecialMap = {
    AOEnum.do_sample: AdvancedOption(
      key: AOEnum.do_sample.name,
      label: '采样生成',
      description: '是否启用采样生成',
      type: OptionType.toggle,
      defaultValue: true,
    ),
  };

  /// 1 模型类型参数配置
  static final Map<LLModelType, List<AdvancedOption>> _commonTypeOptions = {
    // 文本对话模型 (包含共享参数和特有参数)
    LLModelType.cc: [
      aoCommonMap[AOEnum.stream]!,
      aoCommonMap[AOEnum.stream_options]!,
      aoCommonMap[AOEnum.temperature]!,
      aoCommonMap[AOEnum.top_p]!,
      aoCommonMap[AOEnum.max_tokens]!,
      aoCommonMap[AOEnum.presence_penalty]!,
      aoCommonMap[AOEnum.frequency_penalty]!,
      aoCommonMap[AOEnum.response_format]!,
    ],

    // 深度思考模型
    LLModelType.reasoner: [
      aoCommonMap[AOEnum.stream]!,
      aoCommonMap[AOEnum.stream_options]!,
      aoCommonMap[AOEnum.max_tokens]!,
    ],

    // 视觉对话模型 (包含共享参数)
    LLModelType.vision: [
      aoCommonMap[AOEnum.stream]!,
      aoCommonMap[AOEnum.temperature]!,
      aoCommonMap[AOEnum.top_p]!,
      aoCommonMap[AOEnum.stream_options]!,
      aoCommonMap[AOEnum.response_format]!,
      aoCommonMap[AOEnum.presence_penalty]!,
    ],

    // 图像生成模型（完全独立的参数配置）
    LLModelType.image: [
      AdvancedOption(
        key: 'size',
        label: '图片尺寸',
        type: OptionType.select,
        defaultValue: '1024x1024',
        items: [
          OptionItem('256x256', '256x256'),
          OptionItem('512x512', '512x512'),
          OptionItem('1024x1024', '1024x1024'),
        ],
      ),
      AdvancedOption(
        key: 'quality',
        label: '图片质量',
        type: OptionType.select,
        defaultValue: 'standard',
        items: [
          OptionItem('standard', '标准'),
          OptionItem('hd', '高清'),
        ],
      ),
    ],

    // 其他类型模型...
    LLModelType.tti: [],
    LLModelType.iti: [],
    LLModelType.ttv: [],
    LLModelType.itv: [],
    LLModelType.audio: [],
    LLModelType.video: [],
    LLModelType.omni: [],
  };

  /// 2 指定平台、指定模型类型特有参数配置
  /// 即在这里针对指定平台，增加_commonOptions中没有的参数
  static final Map<ApiPlatform, Map<LLModelType, List<AdvancedOption>>>
      _platformOptions = {
    ApiPlatform.baidu: {
      LLModelType.cc: [
        // AdvancedOption(
        //   key: 'web_search',
        //   label: '联网搜索',
        //   description: '是否启用联网搜索功能',
        //   type: OptionType.toggle,
        //   defaultValue: false,
        // ),
        // AdvancedOption(
        //   key: 'parallel_tool_calls',
        //   label: '并行工具调用数',
        //   type: OptionType.number,
        //   defaultValue: 1,
        // ),
      ],
    },
    ApiPlatform.zhipu: {
      LLModelType.cc: [
        aoSpecialMap[AOEnum.do_sample]!,
      ],
      LLModelType.vision: [
        aoSpecialMap[AOEnum.do_sample]!,
      ],
    },
  };

  /// 3 特殊参数名映射配置（值为 null 或空字符串表示该参数在该平台将被忽略）
  /// 即在这里针对指定平台，配置删除虽然有显示给用户进行设置，但平台不支持的参数
  static final Map<ApiPlatform, Map<String, String?>> _parameterMappings = {
    ApiPlatform.baidu: {
      // 百度使用不同的参数名(把前者换成后者)
      'max_tokens': 'max_completion_tokens',
    },
    ApiPlatform.tencent: {
      'max_tokens': 'max_completion_tokens',
    },
    ApiPlatform.siliconCloud: {
      // 硅基流动CC不支持的参数
      'stream_options': '',
      'presence_penalty': '',
      'response_format': '',
    },
    ApiPlatform.zhipu: {
      'stream_options': '',
      'presence_penalty': null,
      'frequency_penalty': null,
    },
  };

  /// 对象参数配置(暂时只处理这两个简单的对象)
  static final Map<String, ObjectConfig> _objectConfigs = {
    'stream_options': ObjectConfig(
      type: ObjectType.streamOptions,
      key: 'include_usage',
    ),
    'response_format': ObjectConfig(
      type: ObjectType.responseFormat,
      key: 'type',
    ),
    // ... 其他对象配置
  };
}

/// 对象参数类型
enum ObjectType {
  streamOptions,
  responseFormat,
  // ... 其他类型
}

/// 对象参数配置
class ObjectConfig {
  final ObjectType type;
  final String key; // 对象中的键名

  const ObjectConfig({
    required this.type,
    required this.key,
  });
}
