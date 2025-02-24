import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:uuid/uuid.dart';

import '../../../apis/_default_system_role_list/index.dart';
import '../../../apis/get_app_key_helper.dart';
import '../../../common/llm_spec/cus_llm_model.dart';
import '../../../common/llm_spec/cus_llm_spec.dart';
import '../../../common/utils/db_tools/db_ai_tool_helper.dart';

final DBAIToolHelper _dbHelper = DBAIToolHelper();

///
/// 获取所有平台中支持的模型列表
/// @targetType 用于对话cc、视觉理解vision、文生图、tti、图生图iti、艺术字体tti_word等
/// 如果用户有保存自己的密钥，则展示付费的模型；没有就是用我的账号就只显示免费的
/// 【2024-08-27 实际上一点不严谨，所有数据都在本地，想办法把本地数据库中付费的改为免费的，用户一样免费用】
///
Future<List<CusLLMSpec>> fetchCusLLMSpecList(LLModelType targetType) async {
  // 所有支持文生图的模型列表(用于下拉的平台和该平台拥有的模型列表也从这里来)
  List<CusLLMSpec> llmSpecList = [];

  // 首先获取对应的模型列表和初始化模型
  var specs = await _dbHelper.queryCusLLMSpecList();
  var tempList = specs.where((spec) => spec.modelType == targetType).toList();

  // 先得到免费的模型，不分平台
  llmSpecList = tempList.where((spec) => spec.isFree).toList();

  // 在根据不同平台是否用自定义密钥，添加对应平台的付费模型
  if (getUserKey(SKN.baiduApiKey.name) != null &&
      getUserKey(SKN.baiduSecretKey.name) != null) {
    llmSpecList.addAll(
        tempList.where((s) => s.platform == ApiPlatform.baidu && !s.isFree));
  }
  if (getUserKey(SKN.aliyunAppId.name) != null &&
      getUserKey(SKN.aliyunApiKey.name) != null) {
    llmSpecList.addAll(
        tempList.where((s) => s.platform == ApiPlatform.aliyun && !s.isFree));
  }
  if (getUserKey(SKN.tencentSecretId.name) != null &&
      getUserKey(SKN.tencentSecretKey.name) != null) {
    llmSpecList.addAll(
        tempList.where((s) => s.platform == ApiPlatform.tencent && !s.isFree));
  }
  // 2024-09-02 讯飞每个模型的API密钥还不一样
  // lite 已经在免费的时候加过了，有密钥也不做什么
  // 加载spark-pro
  if (getUserKey(SKN.xfyunSparkProApiPassword.name) != null) {
    llmSpecList
        .addAll(tempList.where((s) => s.cusLlm == CusLLM.xfyun_Spark_Pro));
  }
  // 加载讯飞tti，需要appid，APIKey， APISecret
  if (getUserKey(SKN.xfyunAppId.name) != null &&
      getUserKey(SKN.xfyunApiKey.name) != null &&
      getUserKey(SKN.xfyunApiSecret.name) != null) {
    llmSpecList.addAll(tempList.where((s) => s.cusLlm == CusLLM.xfyun_TTI));
  }
  if (getUserKey(SKN.siliconFlowAK.name) != null) {
    llmSpecList.addAll(tempList
        .where((s) => s.platform == ApiPlatform.siliconCloud && !s.isFree));
  }
  if (getUserKey(SKN.lingyiwanwuAK.name) != null) {
    llmSpecList.addAll(tempList
        .where((s) => s.platform == ApiPlatform.lingyiwanwu && !s.isFree));
  }
  if (getUserKey(SKN.zhipuAK.name) != null) {
    llmSpecList.addAll(
        tempList.where((s) => s.platform == ApiPlatform.zhipu && !s.isFree));
  }
  if (getUserKey(SKN.infiniAK.name) != null) {
    llmSpecList.addAll(
        tempList.where((s) => s.platform == ApiPlatform.infini && !s.isFree));
  }

  // 固定平台排序后模型名排序
  llmSpecList.sort((a, b) {
    // 先比较 平台名称
    int compareA = a.platform.name.compareTo(b.platform.name);
    if (compareA != 0) {
      return compareA;
    }

    // 如果 平台名称 相同，再比较 模型名称
    return a.name.compareTo(b.name);
  });

  return llmSpecList;
}

/// 获取指定类型的系统角色
Future<List<CusSysRoleSpec>> fetchCusSysRoleSpecList(
  LLModelType? roleType,
) async {
  return (await _dbHelper.queryCusSysRoleSpecList(sysRoleType: roleType))
      .toList();
}

final DBAIToolHelper dbHelper = DBAIToolHelper();

/// 将预设的大模型数据导入数据库
Future testInitModelAndSysRole(List<CusLLMSpec> cslist) async {
  dbHelper.clearCusLLMSpecs();

  // 列表中没有uuid和创建时间
  cslist = cslist.map((e) {
    e.cusLlmSpecId = const Uuid().v4();
    e.gmtCreate = DateTime.now();
    return e;
  }).toList();

  await dbHelper.insertCusLLMSpecList(cslist);

  dbHelper.clearCusSysRoleSpecs();

  // 预设角色不用传，就默认的，反正都不花钱
  // 列表中没有uuid和创建时间
  var sysroleList = DEFAULT_SysRole_Prompt_LIST.map((e) {
    e.cusSysRoleSpecId = const Uuid().v4();
    e.gmtCreate = DateTime.now();
    return e;
  }).toList();
  await dbHelper.insertCusSysRoleSpecList(sysroleList);
}

///
/// 通用的查询任务状态的方法
/// 就是先提交了task，然后默认会查询task，这里就是等待查询结果的方法
/// 2024-09-02 目前阿里云的文生图、智谱的文生视频都会用到
Future<T?> timedTaskStatus<T>(
  String taskId,
  Function onTimeOut,
  Duration maxWaitDuration,
  Future<T> Function(String) queryTaskStatus,
  bool Function(T) isTaskComplete,
) async {
  bool isMaxWaitTimeExceeded = false;

  Timer timer = Timer(maxWaitDuration, () {
    onTimeOut();

    EasyLoading.showError(
      "生成超时，请稍候重试！",
      duration: const Duration(seconds: 5),
    );

    isMaxWaitTimeExceeded = true;
    debugPrint('任务处理耗时，状态查询终止。');
  });

  bool isRequestSuccessful = false;
  while (!isRequestSuccessful && !isMaxWaitTimeExceeded) {
    try {
      var result = await queryTaskStatus(taskId);

      if (isTaskComplete(result)) {
        isRequestSuccessful = true;
        debugPrint('任务处理完成!');
        timer.cancel();

        return result;
      } else {
        debugPrint('任务还在处理中，请稍候重试……');
        await Future.delayed(const Duration(seconds: 5));
      }
    } catch (e) {
      debugPrint('发生异常: $e');
      await Future.delayed(const Duration(seconds: 5));
    }
  }
  return null;
}
