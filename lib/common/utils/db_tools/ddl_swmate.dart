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
      PRIMARY KEY(bill_item_id)
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
      i2t_image_path      TEXT,
      chat_type           TEXT    NOT NULL,
      PRIMARY KEY(uuid)
    );
    """;

  /// 2024-06-13 新增文生图简单内容流程
  static const tableNameOfImageGenerationHistory =
      '${DB_TABLE_PREFIX}image_generation_history';

  static const String ddlForImageGenerationHistory = """
    CREATE TABLE $tableNameOfImageGenerationHistory (
      request_id      TEXT    NOT NULL,
      prompt          TEXT    NOT NULL,
      negative_prompt TEXT,
      task_id         TEXT,
      is_finish       INTEGER,
      style           TEXT    NOT NULL,
      image_urls      TEXT,
      gmt_create      TEXT    NOT NULL,
      llm_spec        TEXT    NOT NULL,
      PRIMARY KEY(request_id)
    );
    """;

  // 2024-08-25
  // 保存模型信息(以前cus_llm_spec里面大模型的规格数组，存入json，初始化到数据库,后续使用从数据库查询)
  // 省事，用驼峰命名栏位
  static const tableNameOfCusLlmSpec = '${DB_TABLE_PREFIX}cus_llm_spec';

  static const String ddlForCusLlmSpec = """
    CREATE TABLE $tableNameOfCusLlmSpec (
      cusLlmSpecId   TEXT    NOT NULL,
      platform       TEXT    NOT NULL,
      model          TEXT    NOT NULL,
      cusLlm         TEXT    NOT NULL,
      name           TEXT    NOT NULL,
      contextLength  INTEGER,
      isFree         INTEGER NOT NULL,
      inputPrice     REAL,
      outputPrice    REAL,
      feature        TEXT,
      useCase        TEXT,
      modelType      TEXT    NOT NULL,
      costPer        REAL,
      gmtCreate      TEXT    NOT NULL,
      PRIMARY KEY(cusLlmSpecId),
      UNIQUE(platform,model,modelType)
    );
    """;

  // 2024-08-26
  // 保存自定义系统角色型信息(以前 system_prompt_list.dart预设的系统提示词数组，存入json，初始化到数据库,后续使用从数据库查询)
  // 省事，用驼峰命名栏位
  static const tableNameOfCusSysRoleSpec =
      '${DB_TABLE_PREFIX}cus_system_role_spec';

  static const String ddlForCusSySroleSpec = """
    CREATE TABLE $tableNameOfCusSysRoleSpec (
      cusSysRoleSpecId    TEXT    NOT NULL,
      label               TEXT    NOT NULL,
      subtitle            TEXT,
      name                TEXT,
      hintInfo            TEXT,
      systemPrompt        TEXT    NOT NULL,
      negativePrompt      TEXT,
      imageUrl            TEXT,
      sysRoleType         TEXT,
      gmtCreate           TEXT    NOT NULL,
      PRIMARY KEY(cusSysRoleSpecId),
      UNIQUE(label,sysRoleType,name)
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
}
