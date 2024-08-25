// ignore_for_file: avoid_print, constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../../common/components/tool_widget.dart';

import '../../../common/utils/db_tools/db_helper.dart';
import '../../../common/utils/db_tools/ddl_swmate.dart';
import '../../../common/utils/tools.dart';
import '../../../models/base_model/brief_accounting_state.dart';
import '../../../models/base_model/dish_state.dart';
import '../../../models/chat_competion/com_cc_state.dart';
import '../../../models/text_to_image/com_ig_state.dart';

///
/// 2023-12-26 备份恢复还可以优化，就暂时不做
///
///
// 全量备份导出的文件的前缀(_时间戳.zip)
const ZIP_FILE_PREFIX = "智能轻生活全量数据备份_";
// 导出文件要压缩，临时存放的地址
const ZIP_TEMP_DIR_AT_EXPORT = "temp_zip";
const ZIP_TEMP_DIR_AT_UNZIP = "temp_de_zip";
const ZIP_TEMP_DIR_AT_RESTORE = "temp_auto_zip";

class BackupAndRestore extends StatefulWidget {
  const BackupAndRestore({super.key});

  @override
  State<BackupAndRestore> createState() => _BackupAndRestoreState();
}

class _BackupAndRestoreState extends State<BackupAndRestore> {
  final DBHelper _dbHelper = DBHelper();

  bool isLoading = false;

  // 是否获得了存储权限(没获得就无法备份恢复)
  bool isPermissionGranted = false;

  // 2024-06-05 测试用，z50u没法调试，build之后在页面显示权限结果
  String tempPermMsg = "";

  String note = """'全量备份' 是把应用本地数据库中的所有数据导出保存在本地，包括用智能助手的对话历史、账单列表、菜品列表。
\n'覆写恢复' 是把 '全量备份' 导出的压缩包，重新导入到应用中，覆盖应用本地数据库中的所有数据。
""";

  @override
  void initState() {
    super.initState();

    _getPermission();
  }

  _getPermission() async {
    bool flag = await requestStoragePermission();
    setState(() {
      isPermissionGranted = flag;
    });
  }

  ///
  /// 全量备份：导出db中所有的数据
  ///
  /// 1. 询问是否有范围内部存储的权限
  /// 2. 用户选择要导出的文件存放的位置
  /// 3. 处理备份
  ///   3.1 先创建一个内部临时保存备份文件的地址
  ///          不直接保存到用户指定地址，是避免万一导出很久还没完用户就删掉了，整个过程就无法控制
  ///   3.2 dbhelper导出table数据为各个json文件
  ///   3.3 将这些json文件压缩到各个创建的内部临时地址
  ///   3.4 将临时地址的压缩文件，复制到用户指定的文件
  ///   3.5 删除临时地址的压缩文件
  ///
  exportAllData() async {
    // 用户没有授权，简单提示一下
    if (!mounted) return;
    if (!isPermissionGranted) {
      showSnackMessage(
        context,
        "用户已禁止访问内部存储,无法进行json文件导入。\n如需启用，请到应用的权限管理中授权读写手机存储。",
      );
      return;
    }

    // 用户选择指定文件夹
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    // 如果有选中文件夹，执行导出数据库的json文件，并添加到压缩档。
    if (selectedDirectory != null) {
      if (isLoading) return;

      setState(() {
        isLoading = true;
      });

      // 获取应用文档目录路径
      Directory appDocDir = await getApplicationDocumentsDirectory();
      // 临时存放zip文件的路径
      var tempZipDir = await Directory(
        p.join(appDocDir.path, ZIP_TEMP_DIR_AT_EXPORT),
      ).create();
      // zip 文件的名称
      String zipName =
          "$ZIP_FILE_PREFIX${DateTime.now().millisecondsSinceEpoch}.zip";

      try {
        // 执行将db数据导出到临时json路径和构建临时zip文件(？？？应该有错误检查)
        await _backupDbData(zipName, tempZipDir.path);

        // 移动临时文件到用户选择的位置
        File sourceFile = File(p.join(tempZipDir.path, zipName));
        File destinationFile = File(p.join(selectedDirectory, zipName));

        // 如果目标文件已经存在，则先删除
        if (destinationFile.existsSync()) {
          destinationFile.deleteSync();
        }

        // 把文件从缓存的位置放到用户选择的位置
        sourceFile.copySync(p.join(selectedDirectory, zipName));
        print('文件已成功复制到：${p.join(selectedDirectory, zipName)}');

        // 删除临时zip文件
        if (sourceFile.existsSync()) {
          // 如果目标文件已经存在，则先删除
          sourceFile.deleteSync();
        }

        setState(() {
          isLoading = false;
        });

        if (!mounted) return;
        showSnackMessage(
          context,
          "已经保存到$selectedDirectory",
          backgroundColor: Colors.green,
        );
      } catch (e) {
        print('保存操作出现错误: $e');
        setState(() {
          isLoading = false;
        });
      }
    } else {
      print('保存操作已取消');
      return;
    }
  }

  // 备份db中数据到指定文件夹
  Future<void> _backupDbData(
    // 会把所有json文件打包成1个压缩包，这是压缩包的名称
    String zipName,
    // 在构建zip文件时，会先放到临时文件夹，构建完成后才复制到用户指定的路径去
    String tempZipPath,
  ) async {
    // 等到所有文件导出，都默认放在同一个文件夹下，所以就不用返回路径了
    await _dbHelper.exportDatabase();

    // 创建或检索压缩包临时存放的文件夹
    var tempZipDir = await Directory(tempZipPath).create();

    // 获取临时文件夹目录(在导出函数中是固定了的，所以这里也直接取就好)
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String tempJsonsPath = p.join(appDocDir.path, DB_EXPORT_DIR);
    // 临时存放所有json文件的文件夹
    Directory tempDirectory = Directory(tempJsonsPath);

    // 创建压缩文件
    final encoder = ZipFileEncoder();
    encoder.create(p.join(tempZipDir.path, zipName));

    // 遍历临时文件夹中的所有文件和子文件夹，并将它们添加到压缩文件中
    await for (FileSystemEntity entity in tempDirectory.list(recursive: true)) {
      if (entity is File) {
        encoder.addFile(entity);
      } else if (entity is Directory) {
        encoder.addDirectory(entity);
      }
    }

    // 完成并关闭压缩文件
    encoder.close();

    // 压缩完成后，清空临时json文件夹中文件
    await _deleteFilesInDirectory(tempJsonsPath);
  }

// 删除指定文件夹下所有文件
  Future<void> _deleteFilesInDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (await directory.exists()) {
      await for (var file in directory.list()) {
        if (file is File) {
          await file.delete();
        }
      }
    }
  }

  ///
  /// 2023-12-11 恢复的话，简单需要导出时同名的zip压缩包
  ///
  /// 1. 获取用户选择的压缩文件
  /// 2. 判断选中的文件是否符合导出的文件格式(匹配前缀和后缀，不符合不做任何操作)
  /// 3. 处理导入过程
  ///   3.1 先解压压缩包，读取json文件
  ///   3.2 先将数据库中的数据备份到临时文件夹中(避免恢复失败数据就找不回来了)
  ///   3.3 临时备份完成，删除数据库，再新建数据库(插入时会自动新建)
  ///   3.4 将json文件依次导入数据库
  ///   3.5 json文件导入成功，则删除临时备份文件
  ///
  Future<void> restoreDataFromBackup() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result != null) {
      if (isLoading) return;

      setState(() {
        isLoading = true;
      });

      // 不允许多选，理论就是第一个文件，且不为空
      File file = File(result.files.first.path!);

      print("获取的上传zip文件路径：${p.basename(file.path)}");
      print("获取的上传zip文件路径 result： $result");

      // 这个判断虽然不准确，但先这样
      if (p.basename(file.path).toUpperCase().startsWith(ZIP_FILE_PREFIX) &&
          p.basename(file.path).toLowerCase().endsWith('.zip')) {
        try {
          // 等待解压完成
          // 遍历解压后的文件，取得里面的文件(可能会有嵌套文件夹和其他格式的文件，不过这里没有)
          List<File> jsonFiles = Directory(await _unzipFile(file.path))
              .listSync()
              .where(
                  (entity) => entity is File && entity.path.endsWith('.json'))
              .map((entity) => entity as File)
              .toList();

          print("解压得到的jsonFiles：$jsonFiles");

          /// 删除前可以先备份一下到临时文件，避免出错后完成无法使用(最多确认恢复成功之后再删除就好了)

          // 获取应用文档目录路径
          Directory appDocDir = await getApplicationDocumentsDirectory();
          // 临时存放zip文件的路径
          var tempZipDir = await Directory(
            p.join(appDocDir.path, ZIP_TEMP_DIR_AT_RESTORE),
          ).create();
          // zip 文件的名称
          String zipName =
              "$ZIP_FILE_PREFIX${DateTime.now().millisecondsSinceEpoch}.zip";
          // 执行将db数据导出到临时json路径和构建临时zip文件(？？？应该有错误检查)
          await _backupDbData(zipName, tempZipDir.path);

          // 恢复旧数据之前，删除现有数据库
          await _dbHelper.deleteDB();

          // 保存恢复的数据(应该检查的？？？)
          await _saveJsonFileDataToDb(jsonFiles);

          // 成功恢复后，删除临时备份的zip
          File sourceFile = File(p.join(tempZipDir.path, zipName));
          // 删除临时zip文件
          if (sourceFile.existsSync()) {
            // 如果目标文件已经存在，则先删除
            sourceFile.deleteSync();
          }

          setState(() {
            isLoading = false;
          });

          if (!mounted) return;
          showSnackMessage(
            context,
            "原有数据已删除，备份数据已恢复。",
            backgroundColor: Colors.green,
          );
        } catch (e) {
          // 弹出报错提示框
          if (!mounted) return;

          commonHintDialog(
            context,
            "导入json文件出错",
            "文件名称:\n${file.path}\n\n错误信息:\n${e.toString()}",
          );

          setState(() {
            isLoading = false;
          });
          // 中止操作
          return;
        }
      } else {
        if (!mounted) return;
        showSnackMessage(
          context,
          "用于恢复的备份文件格式不对，恢复已取消。",
          backgroundColor: Colors.red,
        );
      }
      // 这个判断不准确，但先这样
      setState(() {
        isLoading = false;
      });
    } else {
      // User canceled the picker
      return;
    }
  }

  // 解压zip文件
  Future<String> _unzipFile(String zipFilePath) async {
    try {
      // 获取临时目录路径
      Directory tempDir = await getTemporaryDirectory();

      // 创建或检索压缩包临时存放的文件夹
      String tempPath = (await Directory(
        p.join(tempDir.path, ZIP_TEMP_DIR_AT_UNZIP),
      ).create())
          .path;

      // 读取zip文件
      File file = File(zipFilePath);
      List<int> bytes = file.readAsBytesSync();

      // 解压缩
      Archive archive = ZipDecoder().decodeBytes(bytes);
      for (ArchiveFile file in archive) {
        String filename = '$tempPath/${file.name}';
        if (file.isFile) {
          File outFile = File(filename);
          outFile = await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content);

          print("解压时的outFile：$outFile");
        } else {
          Directory dir = Directory(filename);
          await dir.create(recursive: true);
        }
      }
      print('解压完成');

      return tempPath;
    } catch (e) {
      print('解压失败: $e');
      throw Exception(e);
    }
  }

  // 将恢复的json数据存入db中
  _saveJsonFileDataToDb(List<File> jsonFiles) async {
    // 解压之后获取到所有的json文件，逐个添加到数据库，会先清空数据库的数据
    for (File file in jsonFiles) {
      print("执行json保存到db时对应的json文件：${file.path}");

      String jsonData = await file.readAsString();
      // db导出时json文件是列表
      List jsonMapList = json.decode(jsonData);

      var filename = p.basename(file.path).toLowerCase();

      // 根据不同文件名，构建不同的数据
      if (filename == "${DB_TABLE_PREFIX}bill_item.json") {
        await _dbHelper.insertBillItemList(
          jsonMapList.map((e) => BillItem.fromMap(e)).toList(),
        );
      } else if (filename == "${DB_TABLE_PREFIX}chat_history.json") {
        await _dbHelper.insertChatList(
          jsonMapList.map((e) => ChatSession.fromMap(e)).toList(),
        );
      } else if (filename == "${DB_TABLE_PREFIX}image_eneration_history.json") {
        await _dbHelper.insertImageGenerationResultList(
          jsonMapList.map((e) => LlmIGResult.fromMap(e)).toList(),
        );
      } else if (filename == "${DB_TABLE_PREFIX}dish.json") {
        await _dbHelper.insertDishList(
          jsonMapList.map((e) => Dish.fromMap(e)).toList(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("备份恢复"),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(
                      "备份恢复说明",
                      style: TextStyle(fontSize: 18.sp),
                    ),
                    content: Text(note),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("确定"),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.help),
          ),
        ],
      ),
      body: isLoading ? buildLoader(isLoading) : buildBackupButton(),
    );
  }

  buildBackupButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Text(tempPermMsg),
          TextButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("全量备份"),
                    content: const Text("确认导出所有数据?"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          if (!mounted) return;
                          Navigator.pop(context, false);
                        },
                        child: const Text("取消"),
                      ),
                      TextButton(
                        onPressed: () {
                          if (!mounted) return;
                          Navigator.pop(context, true);
                        },
                        child: const Text("确定"),
                      ),
                    ],
                  );
                },
              ).then((value) {
                if (value != null && value) exportAllData();
              });
            },
            icon: const Icon(Icons.backup),
            label: Text(
              "全量备份",
              style: TextStyle(fontSize: 20.sp),
            ),
          ),
          SizedBox(height: 10.sp),
          TextButton.icon(
            onPressed: restoreDataFromBackup,
            icon: const Icon(Icons.restore),
            label: Text(
              "覆写恢复",
              style: TextStyle(fontSize: 20.sp),
            ),
          ),
        ],
      ),
    );
  }
}
