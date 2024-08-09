import 'package:get_storage/get_storage.dart';

final box = GetStorage();

class MyGetStorage {
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
}
