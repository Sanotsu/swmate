// ignore_for_file: avoid_print,

import 'package:sqflite/sqflite.dart';

import '../../../models/chat_competion/com_cc_state.dart';
import '../../../models/text_to_image/com_ig_state.dart';
import '../../../views/ai_assistant/_helper/constants.dart';
import '../../llm_spec/cus_llm_spec.dart';
import '../../llm_spec/cus_llm_model.dart';
import 'init_db.dart';
import 'ddl_ai_tool.dart';

///
/// AI工具相关数据库操作
///
class DBAIToolHelper {
  // 单例模式
  static final DBAIToolHelper _dbHelper = DBAIToolHelper._createInstance();
  // 构造函数，返回单例
  factory DBAIToolHelper() => _dbHelper;

  // 命名的构造函数用于创建DatabaseHelper的实例
  DBAIToolHelper._createInstance();

  // 数据库实例
  Future<Database>? _databaseFuture;

  // 获取数据库实例
  Future<Database> get database async => _databaseFuture ??= DBInit().database;

  ///
  ///  Helper 的相关方法
  ///

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
      AIToolDdl.tableNameOfChatHistory,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: "gmtModified DESC", // 以修改时间倒序排序
    );

    return rows.map((row) => ChatHistory.fromMap(row)).toList();
  }

  // 删除单条
  Future<int> deleteChatById(String uuid) async => (await database).delete(
        AIToolDdl.tableNameOfChatHistory,
        where: "uuid=?",
        whereArgs: [uuid],
      );

  // 新增(只有单个的时候就一个值的数组，理论上不会批量插入,备份恢复除外)
  Future<List<Object?>> insertChatList(List<ChatHistory> chats) async {
    var batch = (await database).batch();
    for (var item in chats) {
      batch.insert(AIToolDdl.tableNameOfChatHistory, item.toMap());
    }
    return await batch.commit();
  }

  // 修改单条(只让修改标题其实)
  Future<int> updateChatHistory(ChatHistory item) async =>
      (await database).update(
        AIToolDdl.tableNameOfChatHistory,
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
      AIToolDdl.tableNameOfGroupChatHistory,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: "gmtModified DESC", // 以修改时间倒序排序
    );

    return rows.map((row) => GroupChatHistory.fromMap(row)).toList();
  }

  // 删除单条
  Future<int> deleteGroupChatById(String uuid) async => (await database).delete(
        AIToolDdl.tableNameOfGroupChatHistory,
        where: "uuid=?",
        whereArgs: [uuid],
      );

  // 新增(只有单个的时候就一个值的数组)
  Future<List<Object?>> insertGroupChatList(
      List<GroupChatHistory> items) async {
    var batch = (await database).batch();
    for (var item in items) {
      batch.insert(AIToolDdl.tableNameOfGroupChatHistory, item.toMap());
    }
    return await batch.commit();
  }

  // 修改单条(只让修改标题其实)
  Future<int> updateGroupChatHistory(GroupChatHistory item) async =>
      (await database).update(
        AIToolDdl.tableNameOfGroupChatHistory,
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
      AIToolDdl.tableNameOfIGVGHistory,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: "gmtCreate DESC",
    );

    return rows.map((row) => LlmIGVGResult.fromMap(row)).toList();
  }

  // 删除单条
  Future<int> deleteIGVGResultById(String requestId) async =>
      (await database).delete(
        AIToolDdl.tableNameOfIGVGHistory,
        where: "requestId=?",
        whereArgs: [requestId],
      );

  // 新增(只有单个的时候就一个值的数组，理论上不会批量插入)
  Future<List<Object?>> insertIGVGResultList(List<LlmIGVGResult> rsts) async {
    var batch = (await database).batch();
    for (var item in rsts) {
      batch.insert(
        AIToolDdl.tableNameOfIGVGHistory,
        item.toMap(),
      );
    }
    return await batch.commit();
  }

  // 如果先生成任务，后查询任务结果的文生图，就会在提交任务后新增记录，生成结果后修改数据
  Future<int> updateIGVGResultById(LlmIGVGResult igvgRst) async =>
      (await database).update(
        AIToolDdl.tableNameOfIGVGHistory,
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
      AIToolDdl.tableNameOfCusLlmSpec,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: "gmtCreate ASC",
    );

    return rows.map((row) => CusLLMSpec.fromMap(row)).toList();
  }

  // 删除单条
  Future<int> deleteCusLLMSpecById(String cusLlmSpecId) async =>
      (await database).delete(
        AIToolDdl.tableNameOfCusLlmSpec,
        where: "cusLlmSpecId = ?",
        whereArgs: [cusLlmSpecId],
      );

  // 清空所有模型信息
  Future<int> clearCusLLMSpecs() async => (await database).delete(
        AIToolDdl.tableNameOfCusLlmSpec,
        where: "cusLlmSpecId != ?",
        whereArgs: ["cusLlmSpecId"],
      );

  // 新增(只有单个的时候就一个值的数组，理论上不会批量插入)
  Future<List<Object?>> insertCusLLMSpecList(List<CusLLMSpec> rsts) async {
    var batch = (await database).batch();
    for (var item in rsts) {
      batch.insert(
        AIToolDdl.tableNameOfCusLlmSpec,
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
      AIToolDdl.tableNameOfCusSysRoleSpec,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: "gmtCreate ASC",
    );

    return rows.map((row) => CusSysRoleSpec.fromMap(row)).toList();
  }

  // 删除单条
  Future<int> deleteCusSysRoleSpecById(String cusSysRoleSpecId) async =>
      (await database).delete(
        AIToolDdl.tableNameOfCusSysRoleSpec,
        where: "cusSysRoleSpecId = ?",
        whereArgs: [cusSysRoleSpecId],
      );

  // 清空所有模型信息
  Future<int> clearCusSysRoleSpecs() async => (await database).delete(
        AIToolDdl.tableNameOfCusSysRoleSpec,
        where: "cusSysRoleSpecId != ?",
        whereArgs: ["cusSysRoleSpecId"],
      );

  // 修改单条
  Future<int> updateCusSysRoleSpec(CusSysRoleSpec sysRole) async =>
      (await database).update(
        AIToolDdl.tableNameOfCusSysRoleSpec,
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
        AIToolDdl.tableNameOfCusSysRoleSpec,
        item.toMap(),
      );
    }
    return await batch.commit();
  }
}
