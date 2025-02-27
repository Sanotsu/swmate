// ignore_for_file: constant_identifier_names

import 'init_db.dart';

/// 数据库中【AI工具】相关表的创建
class AIToolDdl {
  /// 2024-06-01 新增AI对话留存
  static const tableNameOfChatHistory = '${DB_TABLE_PREFIX}chat_history';

  // 2024-06-14
  // 图像理解也有对话，所以新加一个对话类型栏位：aigc、image2text、text2image……
  // i2t_image_path 指图像理解时被参考的图片base64数据
  static const String ddlForChatHistory = """
    CREATE TABLE $tableNameOfChatHistory (
      uuid                TEXT    NOT NULL,
      title               TEXT    NOT NULL,
      gmtCreate	          TEXT    NOT NULL,
      gmtModified	        TEXT    NOT NULL,
      messages            TEXT    NOT NULL,
      llmName             TEXT    NOT NULL,
      cloudPlatformName   TEXT,
      chatType            TEXT    NOT NULL,
      i2tImagePath        TEXT,
      PRIMARY KEY(uuid)
    );
    """;

  /// 2024-08-30 新增AI群聊对话留存
  static const tableNameOfGroupChatHistory =
      '${DB_TABLE_PREFIX}group_chat_history';

  // 单纯为了省事，直接把智能群聊中的msgMap和messages转为字符串存入数据库
  // 读取后再转为对应格式，所以内容可能会非常打
  static const String ddlForGroupChatHistory = """
    CREATE TABLE $tableNameOfGroupChatHistory (
      uuid                TEXT    NOT NULL,
      title               TEXT    NOT NULL,
      messages            TEXT    NOT NULL,
      modelMsgMap         TEXT    NOT NULL,
      gmtCreate	          TEXT    NOT NULL,
      gmtModified	        TEXT    NOT NULL,
      PRIMARY KEY(uuid)
    );
    """;

  /// 2024-06-13 新增文生图简单内容流程
  /// 2024-09-02 图片生成，视频生成都放在这里面，通过 modelType 来区分
  /// igvi =>  Image Generation Video Generation
  static const tableNameOfIGVGHistory = '${DB_TABLE_PREFIX}igvg_history';

  static const String ddlForIGVGHistory = """
    CREATE TABLE $tableNameOfIGVGHistory (
      requestId           TEXT    NOT NULL,
      prompt              TEXT    NOT NULL,
      negativePrompt      TEXT,
      taskId              TEXT,
      isFinish            INTEGER,
      style               TEXT,
      imageUrls           TEXT,
      videoUrls           TEXT,
      videoCoverImageUrls TEXT,
      refImageUrls        TEXT,
      gmtCreate           TEXT    NOT NULL,
      llmSpec             TEXT    NOT NULL,
      modelType           TEXT    NOT NULL,
 
      PRIMARY KEY(requestId)
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
}
