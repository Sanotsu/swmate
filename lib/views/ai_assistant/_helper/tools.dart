import 'package:uuid/uuid.dart';

import '../../../apis/_self_model_and_system_role_list/_self_system_role_list.dart';
import '../../../apis/get_app_key_helper.dart';
import '../../../common/llm_spec/cus_llm_model.dart';
import '../../../common/llm_spec/cus_llm_spec.dart';
import '../../../common/utils/db_tools/db_helper.dart';

final DBHelper _dbHelper = DBHelper();

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
  if (getUserKey(SKN.xfyunApiPassword.name) != null) {
    llmSpecList.addAll(
        tempList.where((s) => s.platform == ApiPlatform.xfyun && !s.isFree));
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

final DBHelper dbHelper = DBHelper();

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
  var sysroleList = DEFAULT_SysRole_LIST.map((e) {
    e.cusSysRoleSpecId = const Uuid().v4();
    e.gmtCreate = DateTime.now();
    return e;
  }).toList();
  await dbHelper.insertCusSysRoleSpecList(sysroleList);

/*
  ///
  /// 下面是将列表转为json，再转为列表，再存入数据库的测试。
  /// 实际发布时不必，直接存入数据库即可，列表文件不上传就好。
  ///
  final tempDir = Directory('/storage/emulated/0/swmate/jsons');

  ///
  /// 初始化模型信息
  ///

  // 定义文件路径
  const String filePath = 'iti_spec_list.json';

  if (!await tempDir.exists()) {
    await tempDir.create(recursive: true);
  }
  final file = File('${tempDir.path}/$filePath');

  // 将列表转换为 JSON 并写入文件
  writeListToJsonFile(cslist, file.path);

  /// 后续没有上面转的这一步，直接从这里开始从文件读取
  // 从文件中读取存入数据库
  var list = await readListFromJsonFile(file.path);
  list = list.map((e) {
    e.cusLlmSpecId = const Uuid().v4();
    e.gmtCreate = DateTime.now();
    return e;
  }).toList();

  dbHelper.clearCusLLMSpecs();

  await dbHelper.insertCusLLMSpecList(list);

  ///
  /// 初始化系统角色
  ///

  // 定义文件路径
  const String sysroleFilePath = 'sysrole_spec_list.json';

  if (!await tempDir.exists()) {
    await tempDir.create(recursive: true);
  }
  final sysroleFile = File('${tempDir.path}/$sysroleFilePath');

  // 将列表转换为 JSON 并写入文件
  writeSysRoleListToJsonFile(DEFAULT_SysRole_LIST, sysroleFile.path);

  ///
  /// 后续没有上面转的这一步，直接从这里开始从文件读取
  // 从文件中读取存入数据库
  var sysroleList = await readSysRoleListFromJsonFile(sysroleFile.path);

  sysroleList = sysroleList.map((e) {
    e.cusSysRoleSpecId = const Uuid().v4();
    e.gmtCreate = DateTime.now();
    return e;
  }).toList();

  dbHelper.clearCusSysRoleSpecs();
  await dbHelper.insertCusSysRoleSpecList(sysroleList);
*/
}
