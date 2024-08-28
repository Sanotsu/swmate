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

  return llmSpecList;
}

/// 获取指定类型的系统角色
Future<List<CusSysRoleSpec>> fetchCusSysRoleSpecList(
  LLModelType? roleType,
) async {
  return (await _dbHelper.queryCusSysRoleSpecList(sysRoleType: roleType))
      .toList();
}
