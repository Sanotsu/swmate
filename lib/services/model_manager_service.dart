import '../common/constants/default_models.dart';
import '../common/llm_spec/cus_brief_llm_model.dart';
import '../common/llm_spec/constant_llm_enum.dart';
import '../common/utils/db_tools/db_brief_ai_tool_helper.dart';

import 'cus_get_storage.dart';

class ModelManagerService {
  static final DBBriefAIToolHelper _dbHelper = DBBriefAIToolHelper();

  // 初始化内置模型
  static Future<void> initBuiltinModels() async {
    final models = defaultModels.map((model) {
      model.gmtCreate = DateTime.now();
      model.isBuiltin = true;
      return model;
    }).toList();

    for (final model in models) {
      final exists = await _dbHelper.queryBriefCusLLMSpecList(
        cusLlmSpecId: model.cusLlmSpecId,
      );

      if (exists.isEmpty) {
        await _dbHelper.insertBriefCusLLMSpecList([model]);
      }
    }
  }

  // 初始化内置模型(测试用,删除全部内置模型重新加入)
  static Future<void> initBuiltinModelsTest() async {
    final models = defaultModels.map((model) {
      model.gmtCreate = DateTime.now();
      model.isBuiltin = true;
      return model;
    }).toList();

    // 删除全部内置模型
    final exists = await _dbHelper.queryBriefCusLLMSpecList(isBuiltin: true);
    for (final model in exists) {
      await _dbHelper.deleteBriefCusLLMSpecById(model.cusLlmSpecId);
    }

    await _dbHelper.insertBriefCusLLMSpecList(models);
  }

  // 获取可用的模型列表(有对应平台 AK 的模型)
  static Future<List<CusBriefLLMSpec>> getAvailableModels() async {
    final allModels = await _dbHelper.queryBriefCusLLMSpecList();
    final userKeys = MyGetStorage().getUserAKMap();

    return allModels.where((model) {
      if (model.cusLlmSpecId.endsWith('_builtin')) {
        // 内置模型总是可用
        return true;
      }

      // 检查用户是否配置了该平台的 AK
      switch (model.platform) {
        case ApiPlatform.aliyun:
          return userKeys[ApiPlatformAKLabel.USER_ALIYUN_API_KEY.name]
                  ?.isNotEmpty ??
              false;
        case ApiPlatform.baidu:
          return userKeys[ApiPlatformAKLabel.USER_BAIDU_API_KEY_V2.name]
                  ?.isNotEmpty ??
              false;
        case ApiPlatform.tencent:
          return userKeys[ApiPlatformAKLabel.USER_TENCENT_API_KEY.name]
                  ?.isNotEmpty ??
              false;

        case ApiPlatform.deepseek:
          return userKeys[ApiPlatformAKLabel.USER_DEEPSEEK_API_KEY.name]
                  ?.isNotEmpty ??
              false;
        case ApiPlatform.lingyiwanwu:
          return userKeys[ApiPlatformAKLabel.USER_LINGYIWANWU_API_KEY.name]
                  ?.isNotEmpty ??
              false;
        case ApiPlatform.zhipu:
          return userKeys[ApiPlatformAKLabel.USER_ZHIPU_API_KEY.name]
                  ?.isNotEmpty ??
              false;

        case ApiPlatform.siliconCloud:
          return userKeys[ApiPlatformAKLabel.USER_SILICONCLOUD_API_KEY.name]
                  ?.isNotEmpty ??
              false;
        case ApiPlatform.infini:
          return userKeys[
                      ApiPlatformAKLabel.USER_INFINI_GEN_STUDIO_API_KEY.name]
                  ?.isNotEmpty ??
              false;
        case ApiPlatform.volcengine:
          return userKeys[ApiPlatformAKLabel.USER_VOLCENGINE_API_KEY.name]
                  ?.isNotEmpty ??
              false;
        case ApiPlatform.volcesBot:
          return userKeys[ApiPlatformAKLabel.USER_VOLCESBOT_API_KEY.name]
                  ?.isNotEmpty ??
              false;
        // 2025-04-11 默认就是自定义模型(云平台不在我预设中)，密钥和地址在模型规格中，直接返回true
        default:
          return true;
      }
    }).toList();
  }

  // 指定模型分类来获取可用的模型列表
  static Future<List<CusBriefLLMSpec>> getAvailableModelByTypes(
    List<LLModelType> modelTypes,
  ) async {
    final allModels = await getAvailableModels();

    // 然后过滤出指定类型的模型
    List<CusBriefLLMSpec> list = allModels
        .where((model) => modelTypes.contains(model.modelType))
        .toList();

    // 固定平台排序后模型名排序
    list.sort((a, b) {
      // 先比较 平台名称
      int compareA = a.platform.name.compareTo(b.platform.name);
      if (compareA != 0) {
        return compareA;
      }

      // 如果 平台名称 相同，再比较 模型名称
      return a.name?.compareTo(b.name ?? b.model) ?? 0;
    });

    return list;
  }

  // 验证用户导入的模型配置
  static bool validateModelConfig(Map<String, dynamic> json) {
    try {
      // 验证平台是否支持（这里找不到就会报错，在catch中会返回false）
      ApiPlatform.values.firstWhere(
        (e) => e.name == json['platform'],
        orElse: () => throw Exception('不支持的云平台'),
      );

      // 2025-03-07 字段验证简化一下，就平台、模型、模型类型即可
      if (json['platform'] == null ||
          (json['platform'] as String).trim().isEmpty ||
          json['model'] == null ||
          (json['model'] as String).trim().isEmpty ||
          json['modelType'] == null ||
          (json['modelType'] as String).trim().isEmpty) {
        return false;
      }

      // 如果是自定义平台，还需要baseurl 和 apikey
      if (json['platform'] == ApiPlatform.custom.name) {
        if (json['baseUrl'] == null ||
            (json['baseUrl'] as String).trim().isEmpty ||
            json['apiKey'] == null ||
            (json['apiKey'] as String).trim().isEmpty) {
          return false;
        }
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }

  // 删除用户导入的模型(内置模型不能删除)
  static Future<bool> deleteUserModel(String modelId) async {
    // 如果有其他同类型的模型，可以删除内置的
    // if (modelId.endsWith('_builtin')) return false;

    await _dbHelper.deleteBriefCusLLMSpecById(modelId);
    return true;
  }

  // 清空用户导入的模型(保留内置模型)
  static Future<void> clearUserModels() async {
    final models = await _dbHelper.queryBriefCusLLMSpecList();
    for (final model in models) {
      if (!model.cusLlmSpecId.endsWith('_builtin')) {
        await _dbHelper.deleteBriefCusLLMSpecById(model.cusLlmSpecId);
      }
    }
  }
}
