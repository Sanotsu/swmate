import 'dart:io';

import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../../../common/constants.dart';
import '../../../common/utils/tools.dart';

Future<void> saveMarkdownAsTxt(String mdString) async {
  // 首先获取设备外部存储管理权限
  if (!(await requestStoragePermission())) {
    return EasyLoading.showError("未授权访问设备外部存储，无法保存文档");
  }

  // 翻译保存的文本，放到设备外部存储固定位置，不存在文件夹则先创建
  if (!await SAVE_IMAGE_INTERPRET_DIR.exists()) {
    await SAVE_IMAGE_INTERPRET_DIR.create(recursive: true);
  }

  try {
    // 将字符串直接保存为指定路径文件
    final file = File(
      '${SAVE_IMAGE_INTERPRET_DIR.path}/保存图片解读文档-${DateTime.now().microsecondsSinceEpoch}.txt',
    );
    await file.writeAsString(mdString.trim());

    // 保存成功/失败弹窗提示
    EasyLoading.showSuccess(
      '文件已保存到 ${file.path}',
      duration: const Duration(seconds: 5),
    );
  } catch (e) {
    return EasyLoading.showError(
      "保存文档失败: ${e.toString()}",
      duration: const Duration(seconds: 5),
    );
  }
}
