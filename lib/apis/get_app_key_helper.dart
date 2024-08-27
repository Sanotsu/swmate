// 用户自定义输入的平台的密钥的相关key枚举，
// 在表单验证、保存到缓存、读取时都使用的关键字，避免过多魔法值出错
// SelfKeyName
import '../services/cus_get_storage.dart';

enum SKN {
  baiduApiKey,
  baiduSecretKey,
  tencentSecretId,
  tencentSecretKey,
  aliyunAppId,
  aliyunApiKey,
  xfyunAppId,
  xfyunApiSecret,
  xfyunApiKey,
  xfyunApiPassword,
  siliconFlowAK,
  lingyiwanwuAK,
  zhipuAK,
}

// 从缓存中获取用户自定义的密钥,没取到就用预设的
String getStoredUserKey(String key, String defaultValue) {
  return MyGetStorage().getUserAKMap()[key] != null &&
          MyGetStorage().getUserAKMap()[key]!.isNotEmpty
      ? MyGetStorage().getUserAKMap()[key]!
      : defaultValue;
}

// 从缓存中获取用户自定义的密钥(用于判断是否显示付费的模块:有就显示，没有就不显示)
String? getUserKey(String key) {
  return MyGetStorage().getUserAKMap()[key] != null &&
          MyGetStorage().getUserAKMap()[key]!.isNotEmpty
      ? MyGetStorage().getUserAKMap()[key]!
      : null;
}
