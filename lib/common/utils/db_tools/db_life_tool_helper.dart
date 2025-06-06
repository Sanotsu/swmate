// ignore_for_file: avoid_print

import 'package:sqflite/sqflite.dart';

import '../../../models/life_tools/animal_lover/the_dog_cat_api_breed.dart';
import '../../../models/life_tools/brief_accounting_state.dart';
import '../../../models/life_tools/dish_state.dart';
import '../../constants/constants.dart';
import 'init_db.dart';
import 'ddl_life_tool.dart';

///
/// 生活工具相关数据库操作
///
class DBLifeToolHelper {
  // 单例模式
  static final DBLifeToolHelper _dbBriefHelper =
      DBLifeToolHelper._createInstance();
  // 构造函数，返回单例
  factory DBLifeToolHelper() => _dbBriefHelper;

  // 命名的构造函数用于创建DatabaseHelper的实例
  DBLifeToolHelper._createInstance();

  // 获取数据库实例
  Future<Database> get database async => DBInit().database;

  ///***********************************************/
  /// BillItem 的相关操作
  ///

  // 新增(只有单个的时候就一个值得数组)
  Future<List<Object?>> insertBillItemList(List<BillItem> billItems) async {
    var batch = (await database).batch();
    for (var item in billItems) {
      batch.insert(LifeToolDdl.tableNameOfBillItem, item.toMap());
    }

    // print("新增账单条目了$billItems");
    return await batch.commit();
  }

  // 修改单条
  Future<int> updateBillItem(BillItem item) async => (await database).update(
        LifeToolDdl.tableNameOfBillItem,
        item.toMap(),
        where: 'bill_item_id = ?',
        whereArgs: [item.billItemId],
      );

  // 删除单条
  Future<int> deleteBillItemById(String billItemId) async =>
      (await database).delete(
        LifeToolDdl.tableNameOfBillItem,
        where: "bill_item_id=?",
        whereArgs: [billItemId],
      );

  // 清空所有
  Future<int> clearBillItems() async => (await database).delete(
        LifeToolDdl.tableNameOfBillItem,
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
      LifeToolDdl.tableNameOfBillItem,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      limit: pageSize,
      offset: offset,
      orderBy: "date DESC",
    );

    // 数据是分页查询的，但这里带上满足条件的一共多少条
    String sql = 'SELECT COUNT(*) FROM ${LifeToolDdl.tableNameOfBillItem}';
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
          FROM ${LifeToolDdl.tableNameOfBillItem} AS sub  
          WHERE strftime("$formatStr", sub."date") = strftime("$formatStr", b."date")) AS expend_total,  
          (SELECT ROUND(SUM(CASE WHEN "item_type" = 0 THEN "value" ELSE 0.0 END), 2)  
          FROM ${LifeToolDdl.tableNameOfBillItem} AS sub  
          WHERE strftime("$formatStr", sub."date") = strftime("$formatStr", b."date")) AS income_total  
      FROM ${LifeToolDdl.tableNameOfBillItem} AS b
      $rangeWhere 
      ORDER BY b."date" DESC  
      LIMIT $pageSize 
      OFFSET $offset
      """;

    try {
      final rows = await db.rawQuery(sql3);

      // 数据是分页查询的，但这里带上满足条件的一共多少条
      String sql = 'SELECT COUNT(*) FROM ${LifeToolDdl.tableNameOfBillItem}';
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
      FROM ${LifeToolDdl.tableNameOfBillItem} 
      order by `date` DESC 
      """,
    );
  }

  // 账单中存在的日期范围，用筛选
  Future<SimplePeriodRange> queryDateRangeList() async {
    var list = await (await database).rawQuery(
      """
      SELECT MIN("date") AS min_date, MAX("date") AS max_date  
      FROM ${LifeToolDdl.tableNameOfBillItem} 
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
          FROM ${LifeToolDdl.tableNameOfBillItem}   
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
        ${LifeToolDdl.tableNameOfBillItem} 
    $dateWhere 
    GROUP BY period 
      """;

    var rows = await (await database).rawQuery(sql);
    return rows.map((row) => BillPeriodCount.fromMap(row)).toList();
  }

  ///***********************************************/
  /// dish 的相关操作
  ///

  // 新增多条食物(只有单个的时候就一个值得数组)
  Future<List<Object?>> insertDishList(List<Dish> dishes) async {
    var batch = (await database).batch();
    for (var item in dishes) {
      batch.insert(LifeToolDdl.tableNameOfDish, item.toMap());
    }
    return await batch.commit();
  }

  // 修改单条基础
  Future<int> updateDish(Dish dish) async => (await database).update(
        LifeToolDdl.tableNameOfDish,
        dish.toMap(),
        where: 'dish_id = ?',
        whereArgs: [dish.dishId],
      );

  // 删除单条
  Future<int> deleteDishById(String dishId) async => (await database).delete(
        LifeToolDdl.tableNameOfDish,
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
      LifeToolDdl.tableNameOfDish,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      limit: pageSize,
      offset: offset,
    );

    // 这个只有食物名称的关键字查询结果
    int? totalCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${LifeToolDdl.tableNameOfDish} '
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
      LifeToolDdl.tableNameOfDish,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'RANDOM()',
      limit: size,
    );

    return randomRows.map((row) => Dish.fromMap(row)).toList();
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

    final rows = await db.query(
      LifeToolDdl.tableNameOfAnimalBreed,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: "breed ASC",
    );

    return rows.map((row) => Breed.fromMap(row)).toList();
  }

  // 删除单条
  Future<int> deleteAnimalBreedById(String id) async => (await database).delete(
        LifeToolDdl.tableNameOfAnimalBreed,
        where: "id = ?",
        whereArgs: [id],
      );

  // 清空所有
  Future<int> clearAnimalBreeds() async => (await database).delete(
        LifeToolDdl.tableNameOfAnimalBreed,
        where: "id != ?",
        whereArgs: ["id"],
      );

  // 修改单条
  Future<int> updateAnimalBreed(Breed breed) async => (await database).update(
        LifeToolDdl.tableNameOfAnimalBreed,
        breed.toMap(),
        where: 'id = ?',
        whereArgs: [breed.id],
      );

  // 新增(只有单个的时候就一个值的数组，理论上不会批量插入)
  Future<List<Object?>> insertAnimalBreedList(List<Breed> rsts) async {
    var batch = (await database).batch();
    for (var item in rsts) {
      batch.insert(
        LifeToolDdl.tableNameOfAnimalBreed,
        item.toMap(),
      );
    }
    return await batch.commit();
  }
}
