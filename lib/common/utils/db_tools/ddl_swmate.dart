// ignore_for_file: constant_identifier_names

///
/// 数据库导出备份、db操作等相关关键字
/// db_helper、备份恢复页面能用到
///
// 导出表文件临时存放的文件夹
const DB_EXPORT_DIR = "db_export";
// 导出的表前缀
const DB_TABLE_PREFIX = "sm_";

/// AI Light Life 数据库中相关表的创建
class SWMateDdl {
  // db名称
  static String databaseName = "embedded_swmate.db";

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
      PRIMARY KEY("bill_item_id")
    );
    """;

  /// 2024-06-01 新增AI对话留存
  // 账单条目表
  static const tableNameOfChatHistory = '${DB_TABLE_PREFIX}chat_history';

  // 2024-06-14
  // 图像理解也有对话，所以新加一个对话类型栏位：aigc、image2text、text2image……
  // i2t_image_path 指图像理解时被参考的图片base64数据
  static const String ddlForChatHistory = """
    CREATE TABLE $tableNameOfChatHistory (
      uuid                TEXT    NOT NULL,
      title               TEXT    NOT NULL,
      gmt_create	        TEXT    NOT NULL,
      messages            TEXT    NOT NULL,
      llm_name            TEXT    NOT NULL,
      yun_platform_name   TEXT,
      i2t_image_path    TEXT,
      chat_type           TEXT    NOT NULL,
      PRIMARY KEY("uuid")
    );
    """;

  /// 2024-06-13 新增文生图简单内容流程
  // 账单条目表
  static const tableNameOfText2ImageHistory =
      '${DB_TABLE_PREFIX}text2image_history';

  static const String ddlForText2ImageHistory = """
    CREATE TABLE $tableNameOfText2ImageHistory (
      request_id      TEXT    NOT NULL,
      prompt          TEXT    NOT NULL,
      negative_prompt TEXT,
      style           TEXT    NOT NULL,
      image_urls      TEXT,
      gmt_create      TEXT    NOT NULL,
      llm_spec        TEXT    NOT NULL,
      PRIMARY KEY("request_id")
    );
    """;

  // 菜品基础表
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
}
