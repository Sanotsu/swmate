import 'package:sqflite/sqflite.dart';

import '../../../models/chat_competion/com_cc_state.dart';
import '../../../models/media_generation_history/media_generation_history.dart';

import '../../llm_spec/cus_brief_llm_model.dart';
import '../../llm_spec/cus_llm_spec.dart';

import 'init_db.dart';
import 'ddl_brief_ai_tool.dart';

///
/// 简洁版AI工具相关数据库操作
///
class DBBriefAIToolHelper {
  // 单例模式
  static final DBBriefAIToolHelper _dbBriefHelper =
      DBBriefAIToolHelper._createInstance();
  // 构造函数，返回单例
  factory DBBriefAIToolHelper() => _dbBriefHelper;

  // 命名的构造函数用于创建DatabaseHelper的实例
  DBBriefAIToolHelper._createInstance();

  // 缓存数据库实例
  Future<Database>? _databaseFuture;
  Future<Database> get database async => _databaseFuture ??= DBInit().database;

  ///
  ///  Helper 的相关方法
  ///

  ///***********************************************/
  /// 2025-02-14 简洁版本的 自定义的LLM信息管理
  ///

  // 查询所有模型信息
  Future<List<CusBriefLLMSpec>> queryBriefCusLLMSpecList({
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
      BriefAIToolDdl.tableNameOfCusBriefLlmSpec,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: "gmtCreate ASC",
    );

    return rows.map((row) => CusBriefLLMSpec.fromMap(row)).toList();
  }

  // 删除单条
  Future<int> deleteBriefCusLLMSpecById(String cusLlmSpecId) async =>
      (await database).delete(
        BriefAIToolDdl.tableNameOfCusBriefLlmSpec,
        where: "cusLlmSpecId = ?",
        whereArgs: [cusLlmSpecId],
      );

  // 清空所有模型信息
  Future<int> clearBriefCusLLMSpecs() async => (await database).delete(
        BriefAIToolDdl.tableNameOfCusBriefLlmSpec,
        where: "cusLlmSpecId != ?",
        whereArgs: ["cusLlmSpecId"],
      );

  // 新增
  Future<List<Object?>> insertBriefCusLLMSpecList(
      List<CusBriefLLMSpec> rsts) async {
    var batch = (await database).batch();
    for (var item in rsts) {
      batch.insert(
        BriefAIToolDdl.tableNameOfCusBriefLlmSpec,
        item.toMap(),
      );
    }
    return await batch.commit();
  }

  ///***********************************************/
  /// AI 简洁版智能助手历史记录的相关操作
  ///

  // 查询所有对话记录
  Future<List<BriefChatHistory>> queryBriefChatHistoryList({
    String? uuid,
    String? keyword,
    List<LLModelType>? modelTypes,
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

    if (modelTypes != null && modelTypes.isNotEmpty) {
      where.add(
        'modelType IN (${List.filled(modelTypes.length, '?').join(',')})',
      );
      whereArgs.addAll(modelTypes.map((e) => e.toString()));
    }

    final rows = await db.query(
      BriefAIToolDdl.tableNameOfBriefChatHistory,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: "gmtModified DESC", // 以修改时间倒序排序
    );

    return rows.map((row) => BriefChatHistory.fromMap(row)).toList();
  }

  // 删除单条
  Future<int> deleteBriefChatHistoryById(String uuid) async =>
      (await database).delete(
        BriefAIToolDdl.tableNameOfBriefChatHistory,
        where: "uuid=?",
        whereArgs: [uuid],
      );

  // 新增(只有单个的时候就一个值的数组，理论上不会批量插入,备份恢复除外)
  Future<List<Object?>> insertBriefChatHistoryList(
      List<BriefChatHistory> briefChatHistories) async {
    var batch = (await database).batch();
    for (var item in briefChatHistories) {
      batch.insert(
        BriefAIToolDdl.tableNameOfBriefChatHistory,
        item.toMap(),
      );
    }
    return await batch.commit();
  }

  // 修改单条(只让修改标题其实)
  Future<int> updateBriefChatHistory(BriefChatHistory item) async =>
      (await database).update(
        BriefAIToolDdl.tableNameOfBriefChatHistory,
        item.toMap(),
        where: 'uuid = ?',
        whereArgs: [item.uuid],
      );

  ///***********************************************/
  /// AI 媒体资源生成的相关操作
  /// 文生视频（后续语音合成也可能）也用这个
  ///

  // 插入图片生成历史
  Future<String> insertMediaGenerationHistory(
    MediaGenerationHistory history,
  ) async {
    Database db = await database;
    await db.insert(
      BriefAIToolDdl.tableNameOfMediaGenerationHistory,
      history.toMap(),
    );
    return history.requestId;
  }

  // 指定requestId更新图片生成历史
  Future<void> updateMediaGenerationHistoryByRequestId(
    String requestId,
    Map<String, dynamic> values,
  ) async {
    Database db = await database;
    await db.update(
      BriefAIToolDdl.tableNameOfMediaGenerationHistory,
      values,
      where: 'requestId = ?',
      whereArgs: [requestId],
    );
  }

  Future<void> updateMediaGenerationHistory(
    MediaGenerationHistory item,
  ) async {
    Database db = await database;
    await db.update(
      BriefAIToolDdl.tableNameOfMediaGenerationHistory,
      item.toMap(),
      where: 'requestId = ?',
      whereArgs: [item.requestId],
    );
  }

  // 指定requestId更新图片生成历史
  Future<void> deleteMediaGenerationHistoryByRequestId(
    String requestId,
  ) async {
    Database db = await database;
    await db.delete(
      BriefAIToolDdl.tableNameOfMediaGenerationHistory,
      where: 'requestId = ?',
      whereArgs: [requestId],
    );
  }

  // 查询图片生成历史
  Future<List<MediaGenerationHistory>> queryMediaGenerationHistory({
    bool? isSuccess,
    bool? isProcessing,
    bool? isFailed,
    List<LLModelType>? modelTypes, // 在调用处取枚举，可多个
  }) async {
    Database db = await database;

    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (isSuccess != null) {
      where.add('isSuccess = ?');
      whereArgs.add(isSuccess ? 1 : 0);
    }

    if (isProcessing != null) {
      where.add('isProcessing = ?');
      whereArgs.add(isProcessing ? 1 : 0);
    }

    if (isFailed != null) {
      where.add('isFailed = ?');
      whereArgs.add(isFailed ? 1 : 0);
    }

    if (modelTypes != null && modelTypes.isNotEmpty) {
      where.add(
        'modelType IN (${List.filled(modelTypes.length, '?').join(',')})',
      );
      whereArgs.addAll(modelTypes.map((e) => e.toString()));
    }

    final rows = await db.query(
      BriefAIToolDdl.tableNameOfMediaGenerationHistory,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    return rows.map((row) => MediaGenerationHistory.fromMap(row)).toList();
  }
}
