import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../apis/_self_model_list/index.dart';
import '../../common/components/tool_widget.dart';
import '../../common/llm_spec/cus_llm_model.dart';
import '../../common/llm_spec/cus_llm_spec.dart';
import '../../common/utils/db_tools/db_helper.dart';
import '../../services/cus_get_storage.dart';
import '_componets/custom_entrance_card.dart';
import '_helper/tools.dart';
import 'ai_tools/chat_bot/index.dart';
import 'ai_tools/chat_bot_group/index.dart';
import 'ai_tools/file_interpret/document_interpret.dart';
import 'ai_tools/file_interpret/image_interpret.dart';
import 'ai_tools/image_generation/iti_index.dart';
import 'ai_tools/image_generation/tti_index.dart';
import 'ai_tools/image_generation/word_art_index.dart';
import 'ai_tools/video_generation/cogvideox_index.dart';
import 'config_llm_list/index.dart';
import 'config_system_prompt/index.dart';

///
/// 规划一系列有AI加成的使用工具，这里是主入口
/// 可使用tab或者其他方式分类为：对话、图生文、文生图/图生图等
///
class AIToolIndex extends StatefulWidget {
  const AIToolIndex({super.key});

  @override
  State createState() => _AIToolIndexState();
}

class _AIToolIndexState extends State<AIToolIndex> {
  final DBHelper dbHelper = DBHelper();

  // 部分花费大的工具，默认先不开启了
  bool isEnableMyCose = false;

  // 2024-07-26
  // 默认的页面主体的缩放比例(对话太小了就可以等比放大)
  // 暂时就在“你问我答”页面测试，且只缩放问答列表(因为其他布局放大可能会有溢出问题)
  // ？？？后续可能作为配置，直接全局缓存，所有使用ChatListArea的地方都改了(现在不是所有地方都用的这个部件)
  double _textScaleFactor = 1.0;

  // db中是否存在模型列表

  List cusModelList = [];

  @override
  void initState() {
    initModelAndSysRole();

    super.initState();
  }

  // 初始化模型和系统角色信息到数据库
  // 后续文件还是别的东西看情况放
  initModelAndSysRole() async {
    // 如果数据库中已经有模型信息了，就不用再导入了
    var ll = await dbHelper.queryCusLLMSpecList();
    if (ll.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        cusModelList = ll;
      });
      return;
    }

    ///
    /// 初始化模型信息和系统角色
    /// (后续默认可能是从asset中导入一次json文件，但可以在配置中导入支持的平台支持的模型)
    /// 要考虑万一用户导入收费模型使用，顶不顶得住
    ///
    await testInitModelAndSysRole(FREE_all_MODELS);

    var afterList = await dbHelper.queryCusLLMSpecList();

    setState(() {
      cusModelList = afterList;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 计算屏幕剩余的高度
    // 设备屏幕的总高度
    //  - 屏幕顶部的安全区域高度，即状态栏的高度
    //  - 屏幕底部的安全区域高度，即导航栏的高度或者虚拟按键的高度
    //  - 应用程序顶部的工具栏（如 AppBar）的高度
    //  - 应用程序底部的导航栏的高度
    //  - 组件的边框间隔(不一定就是2)
    double screenBodyHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom -
        kToolbarHeight -
        kBottomNavigationBarHeight;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('AI 智能助手'),
        actions: [
          IconButton(
            onPressed: () async {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SystemPromptIndex(),
                ),
              );
            },
            icon: const Icon(Icons.face),
          ),
          IconButton(
            onPressed: () async {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ModelListIndex(),
                ),
              );
            },
            icon: const Icon(Icons.list_alt),
          ),
          IconButton(
            onPressed: () async {
              if (!mounted) return;
              setState(() {
                if (_textScaleFactor < 2.2) {
                  _textScaleFactor += 0.2;
                } else if (_textScaleFactor == 2.2) {
                  _textScaleFactor = 0.6; // 循环回最小值
                } else if (_textScaleFactor < 0.6) {
                  _textScaleFactor = 0.6; // 如果不小心越界，纠正回最小值
                }

                // 使用了数学取余运算 (remainder) 来确保 _textScaleFactor 总是在 [0.6 ,2.2) 的范围(闭开区间)内循环，
                // 即使在多次连续点击的情况下也能保持正确的值。
                _textScaleFactor =
                    (_textScaleFactor - 0.6).remainder(1.6) + 0.6;

                EasyLoading.showInfo(
                  "对话文字缩放 ${_textScaleFactor.toStringAsFixed(1)} 倍",
                );
              });
              // 缩放比例存入缓存
              await MyGetStorage().setChatListAreaScale(
                _textScaleFactor,
              );
            },
            icon: const Icon(Icons.format_size_outlined),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "服务生成的所有内容均由人工智能模型生成，无法确保内容的真实性、准确性和完整性，仅供参考，且不代表开发者的态度或观点。",
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
          SizedBox(height: 10.sp),
          // 入口按钮

          if (cusModelList.isNotEmpty)
            SizedBox(
              height: screenBodyHeight - 50.sp,
              child: GridView.count(
                primary: false,
                padding: EdgeInsets.symmetric(horizontal: 5.sp),
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                crossAxisCount: 2,
                childAspectRatio: 2 / 1,
                children: <Widget>[
                  CustomEntranceCard(
                    title: '智能对话',
                    subtitle: "多个平台多种模型",
                    icon: Icons.chat_outlined,
                    onTap: () async {
                      await navigateToToolScreen(
                        context,
                        LLModelType.cc,
                        (llmSpecList, cusSysRoleSpecs) => ChatBot(
                          llmSpecList: llmSpecList,
                          cusSysRoleSpecs: cusSysRoleSpecs,
                        ),
                        roleType: LLModelType.cc,
                      );
                    },
                  ),

                  CustomEntranceCard(
                    title: '智能多聊',
                    subtitle: "一个问题多模型回答",
                    icon: Icons.balance_outlined,
                    onTap: () async {
                      await navigateToToolScreen(
                        context,
                        LLModelType.cc,
                        (llmSpecList, cusSysRoleSpecs) => const ChatBotGroup(),
                        roleType: LLModelType.cc,
                      );
                    },
                  ),

                  // 文档解读和图片解读不传系统角色类型
                  CustomEntranceCard(
                    title: '文档解读',
                    subtitle: "文档翻译总结提问",
                    icon: Icons.newspaper_outlined,
                    onTap: () async {
                      await navigateToToolScreen(
                        context,
                        LLModelType.cc,
                        (llmSpecList, cusSysRoleSpecs) => DocumentInterpret(
                          llmSpecList: llmSpecList,
                          cusSysRoleSpecs: cusSysRoleSpecs,
                        ),
                      );
                    },
                  ),

                  CustomEntranceCard(
                    title: '图片解读',
                    subtitle: "图片翻译总结问答",
                    icon: Icons.image_outlined,
                    onTap: () async {
                      await navigateToToolScreen(
                        context,
                        LLModelType.vision,
                        (llmSpecList, cusSysRoleSpecs) => ImageInterpret(
                          llmSpecList: llmSpecList,
                          cusSysRoleSpecs: cusSysRoleSpecs,
                        ),
                      );
                    },
                  ),

                  CustomEntranceCard(
                    title: '文本生图',
                    subtitle: "根据文字描述绘图",
                    icon: Icons.photo_album_outlined,
                    onTap: () async {
                      await navigateToToolScreen(
                        context,
                        LLModelType.tti,
                        (llmSpecList, cusSysRoleSpecs) => CommonTTIScreen(
                          llmSpecList: llmSpecList,
                          cusSysRoleSpecs: cusSysRoleSpecs,
                        ),
                        roleType: LLModelType.tti,
                      );
                    },
                  ),

                  CustomEntranceCard(
                    title: '创意文字',
                    subtitle: "纹理变形姓氏创作",
                    icon: Icons.text_fields_outlined,
                    onTap: () async {
                      await navigateToToolScreen(
                        context,
                        LLModelType.tti_word,
                        (llmSpecList, cusSysRoleSpecs) => AliyunWordArtScreen(
                          llmSpecList: llmSpecList,
                          cusSysRoleSpecs: cusSysRoleSpecs,
                        ),
                        roleType: LLModelType.tti_word,
                      );
                    },
                  ),

                  CustomEntranceCard(
                    title: '图片生图',
                    subtitle: "结合参考图片绘图",
                    icon: Icons.photo_library_outlined,
                    onTap: () async {
                      await navigateToToolScreen(
                        context,
                        LLModelType.iti,
                        (llmSpecList, cusSysRoleSpecs) => CommonITIScreen(
                          llmSpecList: llmSpecList,
                          cusSysRoleSpecs: cusSysRoleSpecs,
                        ),
                        roleType: LLModelType.iti,
                      );
                    },
                  ),

                  CustomEntranceCard(
                    title: '文生视频',
                    subtitle: "文本或图生成视频",
                    icon: Icons.video_call,
                    onTap: () async {
                      await navigateToToolScreen(
                        context,
                        LLModelType.ttv,
                        (llmSpecList, cusSysRoleSpecs) => CogVideoXScreen(
                          llmSpecList: llmSpecList,
                          cusSysRoleSpecs: cusSysRoleSpecs,
                        ),
                        roleType: LLModelType.ttv,
                      );
                    },
                  ),

                  // buildToolEntrance(
                  //   "[全部]",
                  //   icon: const Icon(Icons.chat_outlined),
                  //   color: Colors.blue[100],
                  //   onTap: () async {},
                  // ),

                  // buildAIToolEntrance(
                  //   "功能\n占位(TODO)",
                  //   icon: const Icon(Icons.search),
                  // ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

void writeListToJsonFile(List<CusLLMSpec> list, String filePath) {
  final jsonList = list.map((spec) => spec.toMap()).toList();
  final jsonString = jsonEncode(jsonList);
  File(filePath).writeAsStringSync(jsonString);
}

Future<List<CusLLMSpec>> readListFromJsonFile(String filePath) async {
  final jsonString = await File(filePath).readAsString();
  final jsonList = jsonDecode(jsonString) as List;
  return jsonList.map((map) => CusLLMSpec.fromMap(map)).toList();
}

void writeSysRoleListToJsonFile(List<CusSysRoleSpec> list, String filePath) {
  final jsonList = list.map((spec) => spec.toMap()).toList();
  final jsonString = jsonEncode(jsonList);
  File(filePath).writeAsStringSync(jsonString);
}

Future<List<CusSysRoleSpec>> readSysRoleListFromJsonFile(
    String filePath) async {
  final jsonString = await File(filePath).readAsString();
  final jsonList = jsonDecode(jsonString) as List;
  return jsonList.map((map) => CusSysRoleSpec.fromMap(map)).toList();
}

///
/// 点击智能助手的入口，跳转到子页面
///
Future<void> navigateToToolScreen(
  BuildContext context,
  LLModelType modelType,
  Widget Function(List<CusLLMSpec>, List<CusSysRoleSpec>) pageBuilder, {
  LLModelType? roleType,
}) async {
  // 获取对话的模型列表(具体逻辑看函数内部)
  List<CusLLMSpec> llmSpecList = await fetchCusLLMSpecList(modelType);

  // 获取系统角色列表
  List<CusSysRoleSpec> cusSysRoleSpecs =
      await fetchCusSysRoleSpecList(roleType);

  if (!context.mounted) return;
  if (llmSpecList.isEmpty) {
    return commonHintDialog(context, "提示", "无可用的模型，该功能不可用");
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => pageBuilder(llmSpecList, cusSysRoleSpecs),
      ),
    );
  }
}
