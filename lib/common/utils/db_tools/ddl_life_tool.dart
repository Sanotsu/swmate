// ignore_for_file: constant_identifier_names

import 'init_db.dart';

/// 数据库中【生活工具】相关表的创建
class LifeToolDdl {
// 账单条目表
  static const tableNameOfBillItem = '${DB_TABLE_PREFIX}bill_item';

  static const String ddlForBillItem = """
    CREATE TABLE $tableNameOfBillItem (
      bill_item_id  TEXT      NOT NULL,
      item_type     INTEGER   NOT NULL,
      date	        TEXT,
      category      TEXT,
      item          TEXT      NOT NULL,
      value         REAL      NOT NULL,
      gmt_modified  TEXT      NOT NULL,
      PRIMARY KEY(bill_item_id)
    );
    """;

  ///
  /// 菜品基础表
  ///
  static const tableNameOfDish = '${DB_TABLE_PREFIX}dish';

  // 2023-03-10 避免导入时重复导入，还是加一个unique
  static const String ddlForDish = """
    CREATE TABLE $tableNameOfDish (
      dish_id           TEXT      NOT NULL PRIMARY KEY,
      dish_name         TEXT      NOT NULL,
      description       TEXT,
      photos            TEXT,
      videos            TEXT,
      tags              TEXT,
      meal_categories   TEXT,
      recipe            TEXT,
      recipe_picture    TEXT,
      UNIQUE(dish_name,tags)
    );
    """;

  ///
  /// 动物的品种，简单保留品种和亚种即可(统一的话就一个品种信息，品种亚种都有则保留有更详细的)
  /// 2024-09-14 暂时没用到
  ///
  static const tableNameOfAnimalBreed = '${DB_TABLE_PREFIX}animal_breed';

  static const String ddlForAnimalBreed = """
    CREATE TABLE $tableNameOfAnimalBreed (
      id                  TEXT    NOT NULL,
      breed               TEXT    NOT NULL,
      subBreed            TEXT,
      temperament         TEXT,
      origin              TEXT,
      description         TEXT,
      lifeSpan            TEXT,
      altNames            TEXT,
      wikipediaUrl        TEXT,
      referenceImageUrl   TEXT,
      dataSource          TEXT,
      PRIMARY KEY(id)
    );
    """;
}
