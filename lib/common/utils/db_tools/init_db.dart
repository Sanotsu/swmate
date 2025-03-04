// ignore_for_file: avoid_print, constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import 'ddl_brief_ai_tool.dart';
import 'ddl_life_tool.dart';

///
/// 数据库导出备份、db操作等相关关键字
/// db_helper、备份恢复页面能用到
///
// 导出表文件临时存放的文件夹
const DB_EXPORT_DIR = "db_export";
// 导出的表前缀
const DB_TABLE_PREFIX = "swmate_";

/// 数据库中一下基本内容
class DBInitConfig {
  // db名称
  static String databaseName = "embedded_swmate.db";
}

class DBInit {
  ///
  /// 数据库初始化相关
  ///

  // 单例模式
  static final DBInit _dbInit = DBInit._createInstance();
  // 构造函数，返回单例
  factory DBInit() => _dbInit;
  // 数据库实例
  static Database? _database;

  // 创建sqlite的db文件成功后，记录该地址，以便删除时使用。
  var dbFilePath = "";

  // 命名的构造函数用于创建DatabaseHelper的实例
  DBInit._createInstance();

  // 获取数据库实例
  Future<Database> get database async => _database ??= await initializeDB();

  // 初始化数据库
  Future<Database> initializeDB() async {
    // 获取Android和iOS存储数据库的目录路径(用户看不到，在Android/data/……里看不到)。
    // Directory directory = await getApplicationDocumentsDirectory();

    // IOS不支持这个方法，所以可能取不到这个地址
    Directory? directory2 = await getExternalStorageDirectory();
    String path = "${directory2?.path}/${DBInitConfig.databaseName}";

    print("初始化 DB sqlite数据库存放的地址：$path");

    // 在给定路径上打开/创建数据库
    var dietaryDb = await openDatabase(path, version: 1, onCreate: _createDb);
    dbFilePath = path;
    return dietaryDb;
  }

  // 创建训练数据库相关表
  void _createDb(Database db, int newVersion) async {
    print("开始创建表 _createDb……");

    await db.transaction((txn) async {
      txn.execute(LifeToolDdl.ddlForBillItem);
      txn.execute(LifeToolDdl.ddlForDish);
      txn.execute(LifeToolDdl.ddlForAnimalBreed);
      txn.execute(BriefAIToolDdl.ddlForBriefChatHistory);
      txn.execute(BriefAIToolDdl.ddlForCusBriefLlmSpec);
      txn.execute(BriefAIToolDdl.ddlForMediaGenerationHistory);
    });
  }

  // 关闭数据库
  Future<bool> closeDB() async {
    Database db = await database;

    print("db.isOpen ${db.isOpen}");
    await db.close();
    print("db.isOpen ${db.isOpen}");

    // 删除db或者关闭db都需要重置db为null，
    // 否则后续会保留之前的连接，以致出现类似错误：Unhandled Exception: DatabaseException(database_closed 5)
    // https://github.com/tekartik/sqflite/issues/223
    _database = null;

    // 如果已经关闭了，返回ture
    return !db.isOpen;
  }

  // 删除sqlite的db文件（初始化数据库操作中那个path的值）
  Future<void> deleteDB() async {
    print("开始删除內嵌的 sqlite db文件，db文件地址：$dbFilePath");

    // 先删除，再重置，避免仍然存在其他线程在访问数据库，从而导致删除失败
    await deleteDatabase(dbFilePath);

    // 删除db或者关闭db都需要重置db为null，
    // 否则后续会保留之前的连接，以致出现类似错误：Unhandled Exception: DatabaseException(database_closed 5)
    // https://stackoverflow.com/questions/60848752/delete-database-when-log-out-and-create-again-after-log-in-dart
    _database = null;
  }

  // 显示db中已有的table，默认的和自建立的
  void showTableNameList() async {
    Database db = await database;
    var tableNames = (await db.query(
      'sqlite_master',
      where: 'type = ?',
      whereArgs: ['table'],
    ))
        .map((row) => row['name'] as String)
        .toList(growable: false);

    print("DB中拥有的表名:------------");
    print(tableNames);
  }

  // 导出所有数据
  Future<void> exportDatabase() async {
    // 获取应用文档目录路径
    Directory appDocDir = await getApplicationDocumentsDirectory();
    // 创建或检索 db_export 文件夹
    var tempDir = await Directory(
      p.join(appDocDir.path, DB_EXPORT_DIR),
    ).create();

    // 打开数据库
    Database db = await database;

    // 获取所有表名
    List<Map<String, dynamic>> tables =
        await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");

    // 遍历所有表
    for (Map<String, dynamic> table in tables) {
      String tableName = table['name'];
      // 不是自建的表，不导出
      if (!tableName.startsWith(DB_TABLE_PREFIX)) {
        continue;
      }

      String tempFilePath = p.join(tempDir.path, '$tableName.json');

      // 查询表中所有数据
      List<Map<String, dynamic>> result = await db.query(tableName);

      // 将结果转换为JSON字符串
      String jsonStr = jsonEncode(result);

      // 创建临时导出文件
      File tempFile = File(tempFilePath);

      // 将JSON字符串写入临时文件
      await tempFile.writeAsString(jsonStr);

      // print('表 $tableName 已成功导出到：$tempFilePath');
    }
  }
}
