// ignore_for_file: avoid_print, constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import '../../../models/base_model/animal_lover/the_dog_cat_api_breed.dart';
import '../../../models/base_model/brief_accounting_state.dart';
import '../../../models/base_model/dish_state.dart';
import '../../../models/chat_competion/com_cc_state.dart';
import '../../../models/text_to_image/com_ig_state.dart';
import '../../../views/ai_assistant/_helper/constants.dart';
import '../../constants.dart';
import '../../llm_spec/cus_brief_llm_model.dart';
import '../../llm_spec/cus_llm_spec.dart';
import '../../llm_spec/cus_llm_model.dart';
import 'ddl_swmate.dart';
import '../../../models/image_generation/image_generation_history.dart';

class DBHelper {
  ///
  /// 数据库初始化相关
  ///

  // 单例模式
  static final DBHelper _dbHelper = DBHelper._createInstance();
  // 构造函数，返回单例
  factory DBHelper() => _dbHelper;
  // 数据库实例
  static Database? _database;

  // 创建sqlite的db文件成功后，记录该地址，以便删除时使用。
  var dbFilePath = "";

  // 命名的构造函数用于创建DatabaseHelper的实例
  DBHelper._createInstance();

  // 获取数据库实例
  Future<Database> get database async => _database ??= await initializeDB();

  // 初始化数据库
  Future<Database> initializeDB() async {
    // 获取Android和iOS存储数据库的目录路径(用户看不到，在Android/data/……里看不到)。
    // Directory directory = await getApplicationDocumentsDirectory();

    // IOS不支持这个方法，所以可能取不到这个地址
    Directory? directory2 = await getExternalStorageDirectory();
    String path = "${directory2?.path}/${SWMateDdl.databaseName}";

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
      txn.execute(SWMateDdl.ddlForChatHistory);
      txn.execute(SWMateDdl.ddlForGroupChatHistory);
      txn.execute(SWMateDdl.ddlForIGVGHistory);
      txn.execute(SWMateDdl.ddlForCusLlmSpec);
      txn.execute(SWMateDdl.ddlForCusBriefLlmSpec);
      txn.execute(SWMateDdl.ddlForCusSySroleSpec);
      txn.execute(SWMateDdl.ddlForBillItem);
      txn.execute(SWMateDdl.ddlForDish);
      txn.execute(SWMateDdl.ddlForAnimalBreed);
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

  ///
  ///  Helper 的相关方法
  ///

  ///***********************************************/
  /// BillItem 的相关操作
  ///

  // 新增(只有单个的时候就一个值得数组)
  Future<List<Object?>> insertBillItemList(List<BillItem> billItems) async {
    var batch = (await database).batch();
    for (var item in billItems) {
      batch.insert(SWMateDdl.tableNameOfBillItem, item.toMap());
    }

    // print("新增账单条目了$billItems");
    return await batch.commit();
  }

  // 修改单条
  Future<int> updateBillItem(BillItem item) async => (await database).update(
        SWMateDdl.tableNameOfBillItem,
        item.toMap(),
        where: 'bill_item_id = ?',
        whereArgs: [item.billItemId],
      );

  // 删除单条
  Future<int> deleteBillItemById(String billItemId) async =>
      (await database).delete(
        SWMateDdl.tableNameOfBillItem,
        where: "bill_item_id=?",
        whereArgs: [billItemId],
      );

  // 清空所有
  Future<int> clearBillItems() async => (await database).delete(
        SWMateDdl.tableNameOfBillItem,
        where: "bill_item_id != ?",
        whereArgs: ["bill_item_id"],
      );

  // 账单查询默认查询所有不分页(全部查询到但加载时上滑显示更多；还是上滑时再查询？？？)
  // 但前端不会显示查询所有的选项，而是会指定日期范围
  // 一般是当日、当月、当年、最近3年，更多自定义范围根据需要来看是否支持
  Future<CusDataResult> queryBillItemList({
    String? billItemId,
    int? itemType, // 0 收入，1 支出
    String? itemKeyword, // 条目关键字
    String? startDate, // 日期范围
    String? endDate,
    double? minValue, // 金额范围
    double? maxValue,
    int? page,
    int? pageSize, // 不传就默认为10
  }) async {
    Database db = await database;

    // 分页相关处理
    page ??= 1;
    // 如果size为0,则查询所有(暂时这个所有就10w吧)
    if (pageSize == 0) {
      pageSize = 100000;
    } else if (pageSize == null || pageSize < 1 && pageSize != 0) {
      pageSize = 10;
    }

    final offset = (page - 1) * pageSize;

    // print("账单查询传入的条件：");
    // print("billItemId $billItemId");
    // print("itemType $itemType");
    // print("itemKeyword $itemKeyword");
    // print("startDate $startDate");
    // print("endDate $endDate");
    // print("page $page");
    // print("pageSize $pageSize");
    // print("offset $offset");

    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (billItemId != null) {
      where.add('bill_item_id = ?');
      whereArgs.add(billItemId);
    }

    if (itemType != null) {
      where.add('item_type = ?');
      whereArgs.add(itemType);
    }

    if (itemKeyword != null) {
      where.add('item LIKE ?');
      whereArgs.add("%$itemKeyword%");
    }

    if (startDate != null && startDate != "") {
      where.add(" date >= ? ");
      whereArgs.add(startDate);
    }
    if (endDate != null && endDate != "") {
      where.add(" date <= ? ");
      whereArgs.add(endDate);
    }

    if (minValue != null) {
      where.add(" value >= ? ");
      whereArgs.add(minValue);
    }
    if (maxValue != null) {
      where.add(" value <= ? ");
      whereArgs.add(maxValue);
    }

    final rows = await db.query(
      SWMateDdl.tableNameOfBillItem,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      limit: pageSize,
      offset: offset,
      orderBy: "date DESC",
    );

    // 数据是分页查询的，但这里带上满足条件的一共多少条
    String sql = 'SELECT COUNT(*) FROM ${SWMateDdl.tableNameOfBillItem}';
    if (where.isNotEmpty) {
      sql += ' WHERE ${where.join(' AND ')}';
    }

    int totalCount =
        Sqflite.firstIntValue(await db.rawQuery(sql, whereArgs)) ?? 0;

    var dishes = rows.map((row) => BillItem.fromMap(row)).toList();

    return CusDataResult(data: dishes, total: totalCount);
  }

  Future<CusDataResult> queryBillItemWithBillCountList({
    String? startDate, // 日期范围
    String? endDate,
    int? page,
    int? pageSize, // 不传就默认为10
  }) async {
    Database db = await database;

    // 分页相关处理
    page ??= 1;
    // 如果size为0,则查询所有(暂时这个所有就10w吧)
    if (pageSize == 0) {
      pageSize = 100000;
    } else if (pageSize == null || pageSize < 1 && pageSize != 0) {
      pageSize = 10;
    }

    final offset = (page - 1) * pageSize;

    // print("queryBillItemWithBillCountList 账单查询传入的条件：");
    // print("startDate $startDate");
    // print("endDate $endDate");
    // print("page $page");
    // print("pageSize $pageSize");
    // print("offset $offset");

    final where = <String>[];
    final whereArgs = <dynamic>[];

    var formatStr = "%Y-%m";
    var rangeWhere = "";
    if (startDate != null && endDate != null) {
      rangeWhere = 'WHERE "date" BETWEEN "$startDate" AND "$endDate"';
    }

    // var sql2 = """
    //   SELECT
    //       *,
    //       strftime("$formatStr", "date") AS month,
    //       SUM(CASE WHEN "item_type" = 1 THEN "value" ELSE 0 END) OVER (PARTITION BY strftime("$formatStr", "date")) AS expend_total,
    //       SUM(CASE WHEN "item_type" = 0 THEN "value" ELSE 0 END) OVER (PARTITION BY strftime("$formatStr", "date")) AS income_total
    //   FROM ${BriefAccountingDdl.tableNameOfBillItem}
    //   $rangeWhere
    //   ORDER BY "date" DESC
    //   LIMIT $pageSize
    //   OFFSET $offset
    //   """;

    // sql2语句中的OVER、PARTITION等新特性好像 sqflite: 2.3.2 不支持,而且这个查询很耗性能
    var sql3 = """
      SELECT       
          b.*,  
        strftime("$formatStr", "date") AS month,
          (SELECT ROUND(SUM(CASE WHEN "item_type" = 1 THEN "value" ELSE 0.0 END), 2) 
          FROM ${SWMateDdl.tableNameOfBillItem} AS sub  
          WHERE strftime("$formatStr", sub."date") = strftime("$formatStr", b."date")) AS expend_total,  
          (SELECT ROUND(SUM(CASE WHEN "item_type" = 0 THEN "value" ELSE 0.0 END), 2)  
          FROM ${SWMateDdl.tableNameOfBillItem} AS sub  
          WHERE strftime("$formatStr", sub."date") = strftime("$formatStr", b."date")) AS income_total  
      FROM ${SWMateDdl.tableNameOfBillItem} AS b
      $rangeWhere 
      ORDER BY b."date" DESC  
      LIMIT $pageSize 
      OFFSET $offset
      """;

    try {
      final rows = await db.rawQuery(sql3);

      // 数据是分页查询的，但这里带上满足条件的一共多少条
      String sql = 'SELECT COUNT(*) FROM ${SWMateDdl.tableNameOfBillItem}';
      if (where.isNotEmpty) {
        sql += ' WHERE ${where.join(' AND ')}';
      }

      int totalCount =
          Sqflite.firstIntValue(await db.rawQuery(sql, whereArgs)) ?? 0;

      var dishes = rows.map((row) => BillItem.fromMap(row)).toList();

      return CusDataResult(data: dishes, total: totalCount);
    } catch (e) {
      print("queryBillItemWithBillCountList查询异常：$e");

      return CusDataResult(data: [], total: 1);
    }
  }

  /// 查询当前账单记录中存在的年月数据，供下拉筛选
  Future<List<Map<String, Object?>>> queryMonthList() async {
    return (await database).rawQuery(
      """
      SELECT DISTINCT strftime('%Y-%m', `date`) AS month     
      FROM ${SWMateDdl.tableNameOfBillItem} 
      order by `date` DESC 
      """,
    );
  }

  // 账单中存在的日期范围，用筛选
  Future<SimplePeriodRange> queryDateRangeList() async {
    var list = await (await database).rawQuery(
      """
      SELECT MIN("date") AS min_date, MAX("date") AS max_date  
      FROM ${SWMateDdl.tableNameOfBillItem} 
      """,
    );

    // 默认起止范围为当前
    var range = SimplePeriodRange(
      minDate: DateTime.now(),
      maxDate: DateTime.now(),
    );

    // 如果有账单记录，则获取到最大最小值
    if (list.isNotEmpty &&
        list.first["min_date"] != null &&
        list.first["max_date"] != null) {
      range = SimplePeriodRange.fromMap(list.first);
    }
    return range;
  }

  /// 查询月度、年度统计数据
  Future<List<BillPeriodCount>> queryBillCountList({
    // 年度统计year 或者月度统计 month
    String? countType,
    // 查询日期范围固定为年月日的完整日期格式，只是统计结果时才切分到年或月
    // 所有月度统计2024-04,但起止范围为2024-04-10 ~ 2024-04-15,也只是这5天的范围
    String? startDate,
    String? endDate,
  }) async {
    // 默认是月度统计，除非指定到年度统计
    var formatStr = "%Y-%m";
    if (countType == "year") {
      formatStr = "%Y";
    }

    // 默认统计所有，除非有指定范围
    var dateWhere = "";
    if (startDate != null && endDate != null) {
      dateWhere = ' "date" BETWEEN "$startDate" AND "$endDate" AND';
    }

    var sql = """
      SELECT         
          period,        
          round(SUM(expend_total_value), 2) AS expend_total_value,        
          round(SUM(income_total_value), 2) AS income_total_value,      
          CASE       
              WHEN SUM(income_total_value) = 0.0 THEN 0.0      
              ELSE round(SUM(expend_total_value) / NULLIF(SUM(income_total_value), 0.0), 5)      
          END AS ratio      
      FROM   
          (SELECT   
              strftime("$formatStr", "date") AS period,   
              CASE WHEN item_type = 1 THEN value ELSE 0.0 END AS expend_total_value,  
              CASE WHEN item_type = 0 THEN value ELSE 0.0 END AS income_total_value  
          FROM ${SWMateDdl.tableNameOfBillItem}   
          WHERE $dateWhere item_type IN (0, 1)) AS combined_data  
      GROUP BY period        
      ORDER BY period ASC;
      """;

    var rows = await (await database).rawQuery(sql);
    return rows.map((row) => BillPeriodCount.fromMap(row)).toList();
  }

  // 简单统计每月、每年、每日的收支总计
  Future<List<BillPeriodCount>> querySimpleBillCountList({
    // 年度统计year 或者月度统计 month
    String? countType,
    // 查询日期范围固定为年月日的完整日期格式，只是统计结果时才切分到年或月
    // 所有月度统计2024-04,但起止范围为2024-04-10 ~ 2024-04-15,也只是这5天的范围
    String? startDate,
    String? endDate,
  }) async {
    // 默认是月度统计，除非指定到年度统计
    var formatStr = "%Y-%m";
    if (countType == "year") {
      formatStr = "%Y";
    } else if (countType == "day") {
      formatStr = "%Y-%m-%d";
    }

    // 默认统计所有，除非有指定范围
    var dateWhere = "";
    if (startDate != null && endDate != null) {
      dateWhere = ' WHERE "date" BETWEEN "$startDate" AND "$endDate" ';
    }

    var sql = """
      SELECT  
        strftime('$formatStr', "date") AS period,  
        round(SUM(CASE WHEN "item_type" = 1 THEN "value" ELSE 0.0 END), 2) AS expend_total_value,  
        round(SUM(CASE WHEN "item_type" = 0 THEN "value" ELSE 0.0 END), 2) AS income_total_value  
    FROM  
        ${SWMateDdl.tableNameOfBillItem} 
    $dateWhere 
    GROUP BY period 
      """;

    var rows = await (await database).rawQuery(sql);
    return rows.map((row) => BillPeriodCount.fromMap(row)).toList();
  }

  ///***********************************************/
  /// AI chat 的相关操作
  ///

  // 查询所有对话记录
  Future<List<ChatHistory>> queryChatList({
    String? uuid,
    String? keyword,
    String? chatType = 'cc',
  }) async {
    Database db = await database;

    // print("对话历史记录查询参数：");
    // print("uuid $uuid");
    // print("keyword $keyword");
    // print("chatType $chatType");

    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (uuid != null) {
      where.add('uuid = ?');
      whereArgs.add(uuid);
    }

    if (keyword != null) {
      where.add('title LIKE ?');
      whereArgs.add("%$keyword%");
    }

    if (chatType != null) {
      where.add('chatType = ?');
      whereArgs.add(chatType);
    }

    final rows = await db.query(
      SWMateDdl.tableNameOfChatHistory,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: "gmtModified DESC", // 以修改时间倒序排序
    );

    return rows.map((row) => ChatHistory.fromMap(row)).toList();
  }

  // 删除单条
  Future<int> deleteChatById(String uuid) async => (await database).delete(
        SWMateDdl.tableNameOfChatHistory,
        where: "uuid=?",
        whereArgs: [uuid],
      );

  // 新增(只有单个的时候就一个值的数组，理论上不会批量插入,备份恢复除外)
  Future<List<Object?>> insertChatList(List<ChatHistory> chats) async {
    var batch = (await database).batch();
    for (var item in chats) {
      batch.insert(SWMateDdl.tableNameOfChatHistory, item.toMap());
    }
    return await batch.commit();
  }

  // 修改单条(只让修改标题其实)
  Future<int> updateChatHistory(ChatHistory item) async =>
      (await database).update(
        SWMateDdl.tableNameOfChatHistory,
        item.toMap(),
        where: 'uuid = ?',
        whereArgs: [item.uuid],
      );

  ///***********************************************/
  /// AI group chat 智能群聊的相关操作
  ///

  // 查询所有对话记录
  Future<List<GroupChatHistory>> queryGroupChatList({
    String? uuid,
    String? keyword,
  }) async {
    Database db = await database;

    // print("对话历史记录查询参数：");
    // print("uuid $uuid");
    // print("keyword $keyword");

    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (uuid != null) {
      where.add('uuid = ?');
      whereArgs.add(uuid);
    }

    if (keyword != null) {
      where.add('title LIKE ?');
      whereArgs.add("%$keyword%");
    }

    final rows = await db.query(
      SWMateDdl.tableNameOfGroupChatHistory,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: "gmtModified DESC", // 以修改时间倒序排序
    );

    return rows.map((row) => GroupChatHistory.fromMap(row)).toList();
  }

  // 删除单条
  Future<int> deleteGroupChatById(String uuid) async => (await database).delete(
        SWMateDdl.tableNameOfGroupChatHistory,
        where: "uuid=?",
        whereArgs: [uuid],
      );

  // 新增(只有单个的时候就一个值的数组)
  Future<List<Object?>> insertGroupChatList(
      List<GroupChatHistory> items) async {
    var batch = (await database).batch();
    for (var item in items) {
      batch.insert(SWMateDdl.tableNameOfGroupChatHistory, item.toMap());
    }
    return await batch.commit();
  }

  // 修改单条(只让修改标题其实)
  Future<int> updateGroupChatHistory(GroupChatHistory item) async =>
      (await database).update(
        SWMateDdl.tableNameOfGroupChatHistory,
        item.toMap(),
        where: 'uuid = ?',
        whereArgs: [item.uuid],
      );

  ///***********************************************/
  /// AI 文生图的相关操作
  /// 2024-09-02 文生视频也用这个
  ///

// 查询所有记录
  Future<List<LlmIGVGResult>> queryIGVGResultList({
    String? requestId,
    String? prompt,
    String? modelType, // 在调用处取枚举的name
  }) async {
    Database db = await database;

    // print("文生图历史记录查询参数：");
    // print("uuid $requestId");
    // print("正向提示词关键字 $prompt");
    // print("modelType $modelType");

    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (requestId != null) {
      where.add('requestId = ?');
      whereArgs.add(requestId);
    }

    if (modelType != null) {
      where.add('modelType = ?');
      whereArgs.add(modelType);
    }

    if (prompt != null) {
      where.add('prompt LIKE ?');
      whereArgs.add("%$prompt%");
    }

    final rows = await db.query(
      SWMateDdl.tableNameOfIGVGHistory,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: "gmtCreate DESC",
    );

    return rows.map((row) => LlmIGVGResult.fromMap(row)).toList();
  }

  // 删除单条
  Future<int> deleteIGVGResultById(String requestId) async =>
      (await database).delete(
        SWMateDdl.tableNameOfIGVGHistory,
        where: "requestId=?",
        whereArgs: [requestId],
      );

  // 新增(只有单个的时候就一个值的数组，理论上不会批量插入)
  Future<List<Object?>> insertIGVGResultList(List<LlmIGVGResult> rsts) async {
    var batch = (await database).batch();
    for (var item in rsts) {
      batch.insert(
        SWMateDdl.tableNameOfIGVGHistory,
        item.toMap(),
      );
    }
    return await batch.commit();
  }

  // 如果先生成任务，后查询任务结果的文生图，就会在提交任务后新增记录，生成结果后修改数据
  Future<int> updateIGVGResultById(LlmIGVGResult igvgRst) async =>
      (await database).update(
        SWMateDdl.tableNameOfIGVGHistory,
        igvgRst.toMap(),
        where: "taskId=?",
        whereArgs: [igvgRst.taskId],
      );

  ///***********************************************/
  /// 自定义的LLM信息管理
  ///

  // 查询所有模型信息
  Future<List<CusLLMSpec>> queryCusLLMSpecList({
    String? cusLlmSpecId, // 模型规格编号
    ApiPlatform? platform, // 平台
    CusLLM? cusLlm, // 模型枚举
    String? name, // 模型名称
    LLModelType? modelType, // 模型分类枚举
    bool? isFree, // 是否收费(0要收费，1不收费)
  }) async {
    Database db = await database;

    // print("模型规格查询参数：");
    // print("uuid $cusLlmSpecId");
    // print("平台 $platform");
    // print("cusLlm $cusLlm");
    // print("name $name");
    // print("modelType $modelType");
    // print("isFree $isFree");

    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (cusLlmSpecId != null) {
      where.add('cusLlmSpecId = ?');
      whereArgs.add(cusLlmSpecId);
    }

    if (platform != null) {
      where.add('platform = ?');
      whereArgs.add(platform.toString());
    }
    if (cusLlm != null) {
      where.add('cusLlm = ?');
      whereArgs.add(cusLlm.toString());
    }
    if (name != null) {
      where.add('name = ?');
      whereArgs.add(name);
    }
    if (modelType != null) {
      where.add('modelType = ?');
      whereArgs.add(modelType.toString());
    }

    if (cusLlmSpecId != null) {
      where.add('isFree = ?');
      whereArgs.add(isFree == true ? 1 : 0);
    }

    final rows = await db.query(
      SWMateDdl.tableNameOfCusLlmSpec,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: "gmtCreate ASC",
    );

    return rows.map((row) => CusLLMSpec.fromMap(row)).toList();
  }

  // 删除单条
  Future<int> deleteCusLLMSpecById(String cusLlmSpecId) async =>
      (await database).delete(
        SWMateDdl.tableNameOfCusLlmSpec,
        where: "cusLlmSpecId = ?",
        whereArgs: [cusLlmSpecId],
      );

  // 清空所有模型信息
  Future<int> clearCusLLMSpecs() async => (await database).delete(
        SWMateDdl.tableNameOfCusLlmSpec,
        where: "cusLlmSpecId != ?",
        whereArgs: ["cusLlmSpecId"],
      );

  // 新增(只有单个的时候就一个值的数组，理论上不会批量插入)
  Future<List<Object?>> insertCusLLMSpecList(List<CusLLMSpec> rsts) async {
    var batch = (await database).batch();
    for (var item in rsts) {
      batch.insert(
        SWMateDdl.tableNameOfCusLlmSpec,
        item.toMap(),
      );
    }
    return await batch.commit();
  }

  ///***********************************************/
  /// 2025-02-14 简洁版本的 自定义的LLM信息管理
  ///

  // 查询所有模型信息
  Future<List<CusBriefLLMSpec>> queryCusBriefLLMSpecList({
    String? cusLlmSpecId, // 模型规格编号
    ApiPlatform? platform, // 平台
    String? name, // 模型名称
    LLModelType? modelType, // 模型分类枚举
    bool? isFree, // 是否收费(0要收费，1不收费)
    bool? isBuiltin, // 是否内置(0不是，1是)
  }) async {
    Database db = await database;

    // print("模型规格查询参数：");
    // print("uuid $cusLlmSpecId");
    // print("平台 $platform");
    // print("cusLlm $cusLlm");
    // print("name $name");
    // print("modelType $modelType");
    // print("isFree $isFree");

    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (cusLlmSpecId != null) {
      where.add('cusLlmSpecId = ?');
      whereArgs.add(cusLlmSpecId);
    }

    if (platform != null) {
      where.add('platform = ?');
      whereArgs.add(platform.toString());
    }
    if (name != null) {
      where.add('name = ?');
      whereArgs.add(name);
    }
    if (modelType != null) {
      where.add('modelType = ?');
      whereArgs.add(modelType.toString());
    }

    if (cusLlmSpecId != null) {
      where.add('isFree = ?');
      whereArgs.add(isFree == true ? 1 : 0);
    }

    if (isBuiltin != null) {
      where.add('isBuiltin = ?');
      whereArgs.add(isBuiltin == true ? 1 : 0);
    }

    final rows = await db.query(
      SWMateDdl.tableNameOfCusBriefLlmSpec,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: "gmtCreate ASC",
    );

    return rows.map((row) => CusBriefLLMSpec.fromMap(row)).toList();
  }

  // 删除单条
  Future<int> deleteCusBriefLLMSpecById(String cusLlmSpecId) async =>
      (await database).delete(
        SWMateDdl.tableNameOfCusBriefLlmSpec,
        where: "cusLlmSpecId = ?",
        whereArgs: [cusLlmSpecId],
      );

  // 清空所有模型信息
  Future<int> clearCusBriefLLMSpecs() async => (await database).delete(
        SWMateDdl.tableNameOfCusBriefLlmSpec,
        where: "cusLlmSpecId != ?",
        whereArgs: ["cusLlmSpecId"],
      );

  // 新增
  Future<List<Object?>> insertCusBriefLLMSpecList(
      List<CusBriefLLMSpec> rsts) async {
    var batch = (await database).batch();
    for (var item in rsts) {
      batch.insert(
        SWMateDdl.tableNameOfCusBriefLlmSpec,
        item.toMap(),
      );
    }
    return await batch.commit();
  }

  ///***********************************************/
  /// 自定义的系统角色信息管理
  ///

  // 查询所有系统角色信息
  Future<List<CusSysRoleSpec>> queryCusSysRoleSpecList({
    String? cusSysRoleSpecId, // 编号
    String? labelKeyword, // 名称关键字
    String? systemPromptKeyword, // 系统提示词关键字
    CusSysRole? name, // 系统角色的枚举名称(目前仅仅文档处理有两个)
    LLModelType? sysRoleType, // 模型角色适用类型枚举
  }) async {
    Database db = await database;

    // print("自定义的系统角色查询参数：");
    // print("cusSysRoleSpecId $cusSysRoleSpecId");
    // print("labelKeyword $labelKeyword");
    // print("systemPromptKeyword $systemPromptKeyword");
    // print("name $name");
    // print("sysRoleType $sysRoleType");

    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (cusSysRoleSpecId != null) {
      where.add('cusSysRoleSpecId = ?');
      whereArgs.add(cusSysRoleSpecId);
    }

    if (labelKeyword != null) {
      where.add('labelKeyword LIKE ?');
      whereArgs.add("%$labelKeyword%");
    }
    if (systemPromptKeyword != null) {
      where.add('prompt systemPromptKeyword ?');
      whereArgs.add("%$systemPromptKeyword%");
    }
    if (name != null) {
      where.add('name = ?');
      whereArgs.add(name.toString());
    }
    if (sysRoleType != null) {
      where.add('sysRoleType = ?');
      whereArgs.add(sysRoleType.name);
    }

    // print("where $where");
    // print("whereArgs $whereArgs");

    final rows = await db.query(
      SWMateDdl.tableNameOfCusSysRoleSpec,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: "gmtCreate ASC",
    );

    return rows.map((row) => CusSysRoleSpec.fromMap(row)).toList();
  }

  // 删除单条
  Future<int> deleteCusSysRoleSpecById(String cusSysRoleSpecId) async =>
      (await database).delete(
        SWMateDdl.tableNameOfCusSysRoleSpec,
        where: "cusSysRoleSpecId = ?",
        whereArgs: [cusSysRoleSpecId],
      );

  // 清空所有模型信息
  Future<int> clearCusSysRoleSpecs() async => (await database).delete(
        SWMateDdl.tableNameOfCusSysRoleSpec,
        where: "cusSysRoleSpecId != ?",
        whereArgs: ["cusSysRoleSpecId"],
      );

  // 修改单条
  Future<int> updateCusSysRoleSpec(CusSysRoleSpec sysRole) async =>
      (await database).update(
        SWMateDdl.tableNameOfCusSysRoleSpec,
        sysRole.toMap(),
        where: 'cusSysRoleSpecId = ?',
        whereArgs: [sysRole.cusSysRoleSpecId],
      );

  // 新增(只有单个的时候就一个值的数组，理论上不会批量插入)
  Future<List<Object?>> insertCusSysRoleSpecList(
      List<CusSysRoleSpec> rsts) async {
    var batch = (await database).batch();
    for (var item in rsts) {
      batch.insert(
        SWMateDdl.tableNameOfCusSysRoleSpec,
        item.toMap(),
      );
    }
    return await batch.commit();
  }

  ///***********************************************/
  /// 动物品种管理，公共api用来获取图片
  /// 2024-09-14 暂时没用到
  ///

  // 查询所有系统角色信息
  Future<List<Breed>> queryAnimalBreedList({
    String? id, // 编号
    String? breedKeyword, // 名称关键字
  }) async {
    Database db = await database;

    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (id != null) {
      where.add('id = ?');
      whereArgs.add(id);
    }

    if (breedKeyword != null) {
      where.add('breed LIKE ? OR subBreed LIKE ?');
      whereArgs.add(["%$breedKeyword%", "%$breedKeyword%"]);
    }

    print("where $where");
    print("whereArgs $whereArgs");

    final rows = await db.query(
      SWMateDdl.tableNameOfAnimalBreed,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: "breed ASC",
    );

    return rows.map((row) => Breed.fromMap(row)).toList();
  }

  // 删除单条
  Future<int> deleteAnimalBreedById(String id) async => (await database).delete(
        SWMateDdl.tableNameOfAnimalBreed,
        where: "id = ?",
        whereArgs: [id],
      );

  // 清空所有
  Future<int> clearAnimalBreeds() async => (await database).delete(
        SWMateDdl.tableNameOfAnimalBreed,
        where: "id != ?",
        whereArgs: ["id"],
      );

  // 修改单条
  Future<int> updateAnimalBreed(Breed breed) async => (await database).update(
        SWMateDdl.tableNameOfAnimalBreed,
        breed.toMap(),
        where: 'id = ?',
        whereArgs: [breed.id],
      );

  // 新增(只有单个的时候就一个值的数组，理论上不会批量插入)
  Future<List<Object?>> insertAnimalBreedList(List<Breed> rsts) async {
    var batch = (await database).batch();
    for (var item in rsts) {
      batch.insert(
        SWMateDdl.tableNameOfAnimalBreed,
        item.toMap(),
      );
    }
    return await batch.commit();
  }

  ///***********************************************/
  /// dish 的相关操作
  ///

  // 新增多条食物(只有单个的时候就一个值得数组)
  Future<List<Object?>> insertDishList(List<Dish> dishes) async {
    var batch = (await database).batch();
    for (var item in dishes) {
      batch.insert(SWMateDdl.tableNameOfDish, item.toMap());
    }
    return await batch.commit();
  }

  // 修改单条基础
  Future<int> updateDish(Dish dish) async => (await database).update(
        SWMateDdl.tableNameOfDish,
        dish.toMap(),
        where: 'dish_id = ?',
        whereArgs: [dish.dishId],
      );

  // 删除单条
  Future<int> deleteDishById(String dishId) async => (await database).delete(
        SWMateDdl.tableNameOfDish,
        where: "dish_id=?",
        whereArgs: [dishId],
      );

  // 条件查询食物列表
  Future<CusDataResult> queryDishList({
    String? dishId,
    String? dishName,
    List<String>? tags, // 食物的分类和餐次查询为多个，只有一个就一个值的数组
    List<String>? mealCategories,
    int? page,
    int? pageSize,
  }) async {
    Database db = await database;

    // f分页相关处理
    page ??= 1;
    pageSize ??= 10;

    final offset = (page - 1) * pageSize;

    // print("菜品条件查询传入的条件：");
    // print("dishId $dishId");
    // print("dishName $dishName");
    // print("tags $tags");
    // print("mealCategories $mealCategories");
    // print("page $page");
    // print("pageSize $pageSize");
    // print("offset $offset");

    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (dishId != null) {
      where.add('dish_id = ?');
      whereArgs.add(dishId);
    }

    if (dishName != null) {
      where.add('dish_name LIKE ?');
      whereArgs.add("%$dishName%");
    }

    // 这里应该是内嵌的or
    if (tags != null && tags.isNotEmpty) {
      for (var tag in tags) {
        where.add('tags LIKE ?');
        whereArgs.add("%$tag%");
      }
    }

    if (mealCategories != null && mealCategories.isNotEmpty) {
      for (var cate in mealCategories) {
        where.add('meal_categories LIKE ?');
        whereArgs.add("%$cate%");
      }
    }

    final dishRows = await db.query(
      SWMateDdl.tableNameOfDish,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      limit: pageSize,
      offset: offset,
    );

    // 这个只有食物名称的关键字查询结果
    int? totalCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${SWMateDdl.tableNameOfDish} '
        'WHERE dish_name LIKE ? ',
        ['%$dishName%'],
      ),
    );

    var dishes = dishRows.map((row) => Dish.fromMap(row)).toList();

    return CusDataResult(data: dishes, total: totalCount ?? 0);
  }

  // 随机查询10条数据
  // 主页显示的时候需要，可以传餐次和数量
  Future<List<Dish>> queryRandomDishList({String? cate, int? size = 10}) async {
    Database db = await database;

    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (cate != null) {
      where.add('meal_categories like ?');
      whereArgs.add('%$cate%');
    }

    List<Map<String, dynamic>> randomRows = await db.query(
      SWMateDdl.tableNameOfDish,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'RANDOM()',
      limit: size,
    );

    return randomRows.map((row) => Dish.fromMap(row)).toList();
  }

  ///***********************************************/
  /// AI 文生图的相关操作
  /// 2025-02-17 文生视频也用这个，重构后也是一样的类，只不过换了名字
  ///

  // 插入图片生成历史
  Future<String> insertImageGenerationHistory(
    ImageGenerationHistory history,
  ) async {
    Database db = await database;
    await db.insert(
      SWMateDdl.tableNameOfIGVGHistory,
      history.toMap(),
    );
    return history.requestId;
  }

  // 指定requestId更新图片生成历史
  Future<void> updateImageGenerationHistoryByRequestId(
    String requestId,
    Map<String, dynamic> values,
  ) async {
    Database db = await database;
    await db.update(
      SWMateDdl.tableNameOfIGVGHistory,
      values,
      where: 'requestId = ?',
      whereArgs: [requestId],
    );
  }

  // 指定requestId更新图片生成历史
  Future<void> deleteImageGenerationHistoryByRequestId(
    String requestId,
  ) async {
    Database db = await database;
    await db.delete(
      SWMateDdl.tableNameOfIGVGHistory,
      where: 'requestId = ?',
      whereArgs: [requestId],
    );
  }

  // 查询图片生成历史
  Future<List<ImageGenerationHistory>> queryImageGenerationHistoryByIsFinish({
    bool? isFinish,
    List<LLModelType>? modelTypes, // 在调用处取枚举，可多个
  }) async {
    Database db = await database;

    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (isFinish != null) {
      where.add('isFinish = ?');
      whereArgs.add(isFinish ? 1 : 0);
    }

    if (modelTypes != null && modelTypes.isNotEmpty) {
      where.add(
        'modelType IN (${List.filled(modelTypes.length, '?').join(',')})',
      );
      whereArgs.addAll(modelTypes.map((e) => e.toString()));
    }

    print("where $where");
    print("whereArgs $whereArgs");

    final rows = await db.query(
      SWMateDdl.tableNameOfIGVGHistory,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    print('<<<<<<<<<<<<<rows: ${rows.first}');

    return rows.map((row) => ImageGenerationHistory.fromMap(row)).toList();
  }
}
