// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../apis/_default_system_role_list/inner_system_prompt.dart';
import '../../apis/chat_completion/common_cc_apis.dart';
import '../../models/chat_competion/com_cc_resp.dart';
import '../constants.dart';
import '../llm_spec/cus_llm_model.dart';
import '../llm_spec/cus_llm_spec.dart';

/// 请求各种权限
/// 目前存储类的权限要分安卓版本，所以单独处理
/// 查询安卓媒体存储权限和其他权限不能同时进行
Future<bool> requestPermission({
  bool isAndroidMedia = true,
  List<Permission>? list,
}) async {
  // 如果是请求媒体权限
  if (isAndroidMedia) {
    // 2024-01-12 Android13之后，没有storage权限了，取而代之的是：
    // Permission.photos, Permission.videos or Permission.audio等
    // 参看:https://github.com/Baseflow/flutter-permission-handler/issues/1247
    if (Platform.isAndroid) {
      // 获取设备sdk版本
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      int sdkInt = androidInfo.version.sdkInt;

      if (sdkInt <= 32) {
        PermissionStatus storageStatus = await Permission.storage.request();
        return storageStatus.isGranted;
      } else {
        Map<Permission, PermissionStatus> statuses = await [
          // Permission.audio,
          // Permission.photos,
          // Permission.videos,
          Permission.manageExternalStorage,
        ].request();

        return (
            // statuses[Permission.audio]!.isGranted &&
            // statuses[Permission.photos]!.isGranted &&
            // statuses[Permission.videos]!.isGranted &&
            statuses[Permission.manageExternalStorage]!.isGranted);
      }
    } else if (Platform.isIOS) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.mediaLibrary,
        Permission.storage,
      ].request();
      return (statuses[Permission.mediaLibrary]!.isGranted &&
          statuses[Permission.storage]!.isGranted);
    }
    // ??? 还差其他平台的
  }

  // 如果有其他权限需要访问，则一一处理(没有传需要请求的权限，就直接返回成功)
  list = list ?? [];
  if (list.isEmpty) {
    return true;
  }
  Map<Permission, PermissionStatus> statuses = await list.request();
  // 如果每一个都授权了，那就返回授权了
  return list.every((p) => statuses[p]!.isGranted);
}

// 只请求内部存储访问权限(菜品导入、备份还原)
Future<bool> requestStoragePermission() async {
  if (Platform.isAndroid) {
    // 获取设备sdk版本
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    int sdkInt = androidInfo.version.sdkInt;

    if (sdkInt <= 32) {
      var storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    } else {
      var storageStatus = await Permission.manageExternalStorage.request();
      return (storageStatus.isGranted);
    }
  } else if (Platform.isIOS) {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.mediaLibrary,
      Permission.storage,
    ].request();
    return (statuses[Permission.mediaLibrary]!.isGranted &&
        statuses[Permission.storage]!.isGranted);
  } else {
    // 除了安卓和ios其他先不考虑
    return false;
  }
}

/// 请求麦克风权限
Future<bool> requestMicrophonePermission() async {
  final state = await Permission.microphone.request();

  return state == PermissionStatus.granted;
}

Future<PermissionStatus> getPermissionMicrophoneStatus() async {
  return await Permission.microphone.status;
}

// 根据数据库拼接的字符串值转回对应选项
List<CusLabel> genSelectedCusLabelOptions(
  String? optionsStr,
  List<CusLabel> cusLabelOptions,
) {
  // 如果为空或者空字符串，返回空列表
  if (optionsStr == null || optionsStr.isEmpty || optionsStr.trim().isEmpty) {
    return [];
  }

  List<String> selectedValues = optionsStr.split(',');
  List<CusLabel> selectedLabels = [];

  for (String selectedValue in selectedValues) {
    for (CusLabel option in cusLabelOptions) {
      if (option.value == selectedValue) {
        selectedLabels.add(option);
      }
    }
  }

  return selectedLabels;
}

String getTimePeriod() {
  DateTime now = DateTime.now();
  if (now.hour >= 0 && now.hour < 9) {
    return '早餐';
  } else if (now.hour >= 9 && now.hour < 11) {
    return '早茶';
  } else if (now.hour >= 11 && now.hour < 14) {
    return '午餐';
  } else if (now.hour >= 14 && now.hour < 16) {
    return '下午茶';
  } else if (now.hour >= 16 && now.hour < 20) {
    return '晚餐';
  } else {
    return '夜宵';
  }
}

// 指定范围内生成一个整数
int generateRandomInt(int min, int max) {
  if (min > max) {
    throw ArgumentError('最小值必须小于或等于最大值。');
  }

  var random = Random();
  // +1 因为 nextInt 包含 min 但不包含 max
  return min + random.nextInt(max - min + 1);
}

// 转换文件大小为字符串显示
String formatFileSize(int bytes, {int decimals = 2}) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB"];
  var i = (log(bytes) / log(1024)).floor();
  return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
}

/// 保存文本文件到外部存储(如果是pdf等还需要改造，传入保存方法等)
Future<void> saveTextFileToStorage(
  String text,
  Directory dir,
  String title, {
  String? extension = 'txt',
}) async {
  try {
    // 首先获取设备外部存储管理权限
    if (!(await requestStoragePermission())) {
      return EasyLoading.showError("未授权访问设备外部存储，无法保存文档");
    }

    // 翻译保存的文本，放到设备外部存储固定位置，不存在文件夹则先创建
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final file = File(
      '${dir.path}/$title-${DateTime.now().microsecondsSinceEpoch}.$extension',
    );

    await file.writeAsString(text);

    // 保存成功/失败弹窗提示
    EasyLoading.showSuccess(
      '文档已保存到 ${file.path}',
      duration: const Duration(seconds: 5),
    );
  } catch (e) {
    return EasyLoading.showError(
      "保存文档失败: ${e.toString()}",
      duration: const Duration(seconds: 5),
    );
  }
}

/// 打印长文本(不会截断)
void printWrapped(String text) {
  final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
  pattern.allMatches(text).forEach((match) => print(match.group(0)));
}

/// 判断字符串是否为json字符串
bool isJsonString(String str) {
  // 去除字符串中的空白字符和注释
  final cleanedStr =
      str.replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'//.*'), '');

  try {
    json.decode(cleanedStr);
    return true;
  } on FormatException {
    return false;
  }
}

// 文生图保存base64图片到本地(讯飞云返回的是base64,阿里云、sf返回的是云盘上的地址)
Future<File> saveTtiBase64ImageToLocal(
  String base64Image, {
  String? prefix, // 传前缀要全，比如带上底斜线_
}) async {
  final bytes = base64Decode(base64Image);

  if (!await LLM_IG_DIR.exists()) {
    await LLM_IG_DIR.create(recursive: true);
  }
  final file = File(
    '${LLM_IG_DIR.path}/${prefix ?? ""}${DateFormat(constDatetimeSuffix).format(DateTime.now())}.png',
  );

  await file.writeAsBytes(bytes);

  return file;
}

// 保存文生图的图片到本地
saveImageToLocal(
  String netImageUrl, {
  String? prefix,
  // 指定保存的名称，比如 xxx.png
  String? imageName,
  Directory? dlDir,
}) async {
// 首先获取设备外部存储管理权限
  if (!(await requestStoragePermission())) {
    return EasyLoading.showError("未授权访问设备外部存储，无法保存图片");
  }

  // print("原图片地址---$netImageUrl");

  // 2024-09-04 文生图片一般有一个随机的名称，就只使用它就好(可以避免同一个保存了多份)
  // 注意，像阿里云这种地址会带上过期日期token信息等参数内容，所以下载保存的文件名要过滤掉，只保留图片地址信息
  // 目前硅基流动、智谱等没有额外信息，问号分割后也不影响
  // 2024-11-04 如果有指定保存的图片名称，则不用从url获取
  imageName ??= netImageUrl.split("?").first.split('/').last;

  // print("新获取的图片地址---$saveImageUrl");

  try {
    // 2024-09-14 支持自定义下载的文件夹
    var dir = dlDir ?? LLM_IG_DIR;

    // 2024-08-17 直接保存文件到指定位置
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // 传入的前缀有强制带上下划线
    final file = File('${dir.path}/${prefix ?? ""}$imageName');

    EasyLoading.show(status: '【图片保存中...】');
    var response = await Dio().get(
      netImageUrl,
      options: Options(responseType: ResponseType.bytes),
    );

    await file.writeAsBytes(response.data);

    EasyLoading.showToast("图片已保存在手机下/${file.path.split("/0/").last}");
  } finally {
    EasyLoading.dismiss();
  }

  // 用这个自定义的，阿里云地址会报403错误，原因不清楚
  // var respData = await HttpUtils.get(
  //   path: netImageUrl,
  //   showLoading: true,
  //   responseType: CusRespType.bytes,
  // );

  // await file.writeAsBytes(respData);
  // EasyLoading.showToast("图片已保存${file.path}");
}

/// 获取网络图片的base64字符串
Future<String> getBase64FromNetworkImage(String imageUrl) async {
  // 下载图片
  var response = await Dio().get(
    imageUrl,
    options: Options(responseType: ResponseType.bytes),
  );

  if (response.statusCode == 200) {
    // 获取应用的临时目录
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/temp_image.png';

    // 将图片保存为文件
    final file = File(filePath);
    await file.writeAsBytes(response.data);

    // 读取文件并转换为 Base64 字符串
    final bytes = await file.readAsBytes();
    final base64String = base64Encode(bytes);

    // 删除临时文件
    await file.delete();

    return base64String;
  } else {
    throw Exception('加载图片失败');
  }
}

// 保存文生视频的视频到本地
savevgVideoToLocal(String netVideoUrl, {String? prefix}) async {
// 首先获取设备外部存储管理权限
  if (!(await requestStoragePermission())) {
    return EasyLoading.showError("未授权访问设备外部存储，无法保存视频");
  }

  try {
    // 2024-08-17 直接保存文件到指定位置
    if (!await LLM_VG_DIR.exists()) {
      await LLM_VG_DIR.create(recursive: true);
    }
    // 2024-09-04 智谱文生视频有一个随机的名称，就只使用它就好(可以避免同一个视频保存了多个)
    final filePath =
        '${LLM_VG_DIR.path}/${prefix ?? ""}_${netVideoUrl.split('/').last}';

    EasyLoading.show(status: '【视频保存中...】');
    await Dio().download(netVideoUrl, filePath);

    // 保存的地址在 /storage/emulated/0/SWMate/…… 前面一节就不显示了
    EasyLoading.showToast("视频已保存在手机下/${filePath.split("/0/").last}");
  } finally {
    EasyLoading.dismiss();
  }

  // 用这个自定义的，阿里云地址会报403错误，原因不清楚
  // var respData = await HttpUtils.get(
  //   path: netImageUrl,
  //   showLoading: true,
  //   responseType: CusRespType.bytes,
  // );

  // await file.writeAsBytes(respData);
  // EasyLoading.showToast("图片已保存${file.path}");
}

/// 获取图片的base64编码
Future<String?> getImageBase64String(File? image) async {
  if (image == null) return null;
  var tempStr = base64Encode(await image.readAsBytes());
  return "data:image/png;base64,$tempStr";
}

///
/// 将自定义模型系统角色数据导出为指定路径的json文件，
/// 和把指定路径的json文件导入为自定义模型和角色列表
///
void writeListToJsonFile(List<CusLLMSpec> list, String filePath) {
  final jsonList = list.map((spec) => spec.toMap()).toList();
  final jsonString = jsonEncode(jsonList);
  File(filePath).writeAsStringSync(jsonString);
}

Future<List<CusLLMSpec>> readListFromJsonFile(String filePath) async {
  final jsonString = await File(filePath).readAsString();
  final jsonList = jsonDecode(jsonString) as List;
  return jsonList.map((map) => CusLLMSpec.fromMap(map)).toList();
}

void writeSysRoleListToJsonFile(List<CusSysRoleSpec> list, String filePath) {
  final jsonList = list.map((spec) => spec.toMap()).toList();
  final jsonString = jsonEncode(jsonList);
  File(filePath).writeAsStringSync(jsonString);
}

Future<List<CusSysRoleSpec>> readSysRoleListFromJsonFile(
    String filePath) async {
  final jsonString = await File(filePath).readAsString();
  final jsonList = jsonDecode(jsonString) as List;
  return jsonList.map((map) => CusSysRoleSpec.fromMap(map)).toList();
}

/// 非常简化，使用文本对话大模型，调用同步响应API，得到翻译结果
Future<String> getAITranslation(
  String text, {
  ApiPlatform? plat,
  String? model,
  TargetLanguage? tl,
  String? systemPrompt,
}) async {
  List<CCMessage> msgs = [
    CCMessage(
      content: systemPrompt ?? translateToChinese(),
      role: CusRole.system.name,
    ),
    CCMessage(content: text, role: CusRole.user.name),
  ];

  // 完全没处理错误情况
  var cc = await useAkCCResp(
    msgs,
    // plat ?? ApiPlatform.siliconCloud,
    // model ?? "Qwen/Qwen2-7B-Instruct",
    plat ?? ApiPlatform.zhipu,
    model ?? "glm-4-flash",
    webSearch: false,
  );
  return cc.cusText;
}

String formatTimeAgo(String timeString) {
  if (timeString.isEmpty) return "未知";

  DateTime dateTime = DateTime.parse(timeString);
  DateTime now = DateTime.now();
  Duration difference = now.difference(dateTime);

  if (difference.inDays > 365) {
    int years = (difference.inDays / 365).floor();
    return '$years年前';
  } else if (difference.inDays > 30) {
    int months = (difference.inDays / 30).floor();
    return '$months月前';
  } else if (difference.inDays > 0) {
    return '${difference.inDays}天前';
  } else if (difference.inHours > 0) {
    return '${difference.inHours}小时前';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes}分钟前';
  } else {
    return '${difference.inSeconds}秒前';
  }
}

// 英文显示有单数复数之分
String formatTimeAgoEn(String timeString) {
  DateTime dateTime = DateTime.parse(timeString);
  DateTime now = DateTime.now();
  Duration difference = now.difference(dateTime);

  if (difference.inDays > 365) {
    int years = (difference.inDays / 365).floor();
    return '$years year${years > 1 ? 's' : ''} ago';
  } else if (difference.inDays > 30) {
    int months = (difference.inDays / 30).floor();
    return '$months month${months > 1 ? 's' : ''} ago';
  } else if (difference.inDays > 0) {
    return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
  } else if (difference.inHours > 0) {
    return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
  } else {
    return '${difference.inSeconds} second${difference.inSeconds > 1 ? 's' : ''} ago';
  }
}

// 把各种时间字符串格式化指定格式的字符串
String formatDateTimeString(
  String timeString, {
  String? formatType,
}) {
  if (timeString.isEmpty) return "未知";

  return DateFormat(formatType ?? constDatetimeFormat)
      .format(DateTime.tryParse(timeString) ?? DateTime.now());
}

// 10位的时间戳转字符串
String formatTimestampToString(String? timestamp, {String? format}) {
  if (timestamp == null || timestamp.isEmpty) {
    return "";
  }

  if (timestamp.trim().length == 10) {
    timestamp = "${timestamp}000";
  }

  if (timestamp.trim().length != 13) {
    return "输入的时间戳不是10位或者13位的整数";
  }

  return DateFormat(format ?? constDatetimeFormat).format(
    DateTime.fromMillisecondsSinceEpoch(
      // 如果传入的时间戳字符串转型不对，就使用 1970-01-01 23:59:59 的毫秒数
      int.tryParse(timestamp) ?? 57599000,
    ),
  );
}
