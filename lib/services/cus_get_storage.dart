import 'package:get_storage/get_storage.dart';

import '../common/llm_spec/constant_llm_enum.dart';
import '../common/llm_spec/cus_brief_llm_model.dart';

final box = GetStorage();

class MyGetStorage {
  static const String _firstLaunchKey = 'is_first_launch';
  static const String _chatBackgroundKey = 'chat_background';
  static const String _chatBackgroundOpacityKey = 'chat_background_opacity';

  // 检查是否首次启动
  bool isFirstLaunch() {
    return box.read(_firstLaunchKey) == null;
  }

  // 标记已启动
  Future<void> markLaunched() async {
    await box.write(_firstLaunchKey, false);
  }

  // 用户头像地址
  Future<void> setUserAvatarPath(String? flag) async {
    await box.write("user_avatar_path", flag);
  }

  String? getUserAvatarPath() => box.read("user_avatar_path");

  // 文本对话的对话列表的缩放比例
  Future<void> setChatListAreaScale(double? flag) async {
    await box.write("chat_list_area_scale", flag);
  }

  double getChatListAreaScale() => box.read("chat_list_area_scale") ?? 1.0;

  // 百度的token(每次获取有效期是30天，每次申请后都保存最新的，避免重复类)
  Future<void> setBaiduTokenInfo(Map<String, String>? info) async {
    await box.write("baidu_token_info", info);
  }

  Map<String, String> getBaiduTokenInfo() =>
      Map<String, String>.from(box.read("baidu_token_info") ?? {});

// 文本生图，临时保存每次生成的图片地址
  Future<void> setImageGenerationUrl(String url) async {
    List<String> list = List<String>.from(box.read("text_to_image_urls") ?? []);
    list.add(url);
    await box.write("image_generation_urls", list);
  }

  List<String> getImageGenerationUrl() {
    List<dynamic> list = box.read("image_generation_urls") ?? [];
    return List<String>.from(list);
  }

  /// 如果用户有输入自己的API KEY的话，就存入缓存中
  Future<void> setUserAKMap(Map<String, String>? info) async {
    await box.write("user_ak_map", info);
  }

  Map<String, String> getUserAKMap() =>
      Map<String, String>.from(box.read("user_ak_map") ?? {});

  // 清空用户的 API Keys
  Future<void> clearUserAKMap() async {
    await box.remove('user_ak_map'); // 直接删除整个 map
  }

  // 删除单个 API Key
  Future<void> removeUserAK(String key) async {
    if (key.startsWith('USER_')) {
      await box.remove(key);
    }
  }

  // 大模型高级选项的启用状态
  Future<void> setAdvancedOptionsEnabled(
    CusBriefLLMSpec model,
    bool enabled,
  ) async {
    await box.write(
      "advanced_options_enabled_${model.platform.name}_${model.modelType.name}",
      enabled,
    );
  }

  bool getAdvancedOptionsEnabled(CusBriefLLMSpec model) =>
      box.read(
          "advanced_options_enabled_${model.platform.name}_${model.modelType.name}") ??
      false;

  // 高级选项的参数值
  Future<void> setAdvancedOptions(
    CusBriefLLMSpec model,
    Map<String, dynamic>? options,
  ) async {
    final key =
        "advanced_options_${model.platform.name}_${model.modelType.name}";
    if (options != null) {
      await box.write(key, options);
    } else {
      await box.remove(key);
    }
  }

  Map<String, dynamic>? getAdvancedOptions(CusBriefLLMSpec model) {
    final data = box.read(
        "advanced_options_${model.platform.name}_${model.modelType.name}");
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  Future<String?> getChatBackground() async {
    return box.read(_chatBackgroundKey);
  }

  Future<void> saveChatBackground(String? path) async {
    if (path == null || path.isEmpty) {
      await box.remove(_chatBackgroundKey);
    } else {
      await box.write(_chatBackgroundKey, path);
    }
  }

  Future<double?> getChatBackgroundOpacity() async {
    return box.read(_chatBackgroundOpacityKey);
  }

  Future<void> saveChatBackgroundOpacity(double opacity) async {
    await box.write(_chatBackgroundOpacityKey, opacity);
  }

  /// 更新指定平台的 API Key
  Future<void> updatePlatformApiKey(ApiPlatformAKLabel label, String apiKey) async {
    final userKeys = getUserAKMap();
    userKeys[label.name] = apiKey;
    await setUserAKMap(userKeys);
  }
}
