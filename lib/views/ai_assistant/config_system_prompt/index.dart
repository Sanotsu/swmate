import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/llm_spec/cus_llm_model.dart';
import '../../../common/utils/db_tools/db_helper.dart';
import 'import_json.dart';
import 'system_prompt_detail.dart';

class SystemPromptIndex extends StatefulWidget {
  const SystemPromptIndex({super.key});

  @override
  State<SystemPromptIndex> createState() => _SystemPromptIndexState();
}

class _SystemPromptIndexState extends State<SystemPromptIndex> {
  final DBHelper _dbHelper = DBHelper();

  List<CusSysRoleSpec> sysRoleSpecs = [];

  @override
  void initState() {
    getSystemPromptSpecs();
    super.initState();
  }

  getSystemPromptSpecs() async {
    var sysroleLl = await _dbHelper.queryCusSysRoleSpecList();
    setState(() {
      // 2024-08-26 目前系统角色中，文档解读和翻译解读预设的6个有name，过滤不显示(因为这6个和代码逻辑相关，不能被删除)，
      // 其他是没有的，用户新增删除可以自行管理
      sysRoleSpecs = sysroleLl.where((e) => e.name == null).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "系统角色列表",
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SystemPromptJsonImport(),
                ),
              ).then((value) {
                getSystemPromptSpecs();
              });
            },
            icon: const Icon(Icons.upload_file),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SystemPromptDetail(),
                ),
              ).then((value) {
                getSystemPromptSpecs();
              });
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Container(
        // height: MediaQuery.of(context).size.height / 4 * 3,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15.sp),
            topRight: Radius.circular(15.sp),
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 100.sp,
              margin: EdgeInsets.fromLTRB(20, 0, 10.sp, 0.sp),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text("说明：", style: TextStyle(fontSize: 15.sp)),
                      ),
                    ],
                  ),
                  Text(
                    """内部预设一些系统角色，用户可以自行创建、导入、删除。\n系统角色需要指定不同使用场景，但不是所有模型都适配。\n(cc: 智能对话; tti: 文本生图; iti: 图片生图)。""",
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  Divider(height: 10.sp, thickness: 1.sp),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: sysRoleSpecs.length,
                itemBuilder: (BuildContext context, int index) {
                  var a = sysRoleSpecs[index];

                  var subtitle = a.name != null
                      ? "${a.name}"
                      : a.subtitle != null
                          ? "${a.subtitle}"
                          : "";

                  return Card(
                    child: ListTile(
                      title: Text("[${a.sysRoleType?.name}]__${a.label}"),
                      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
                      dense: true,
                      // 点击进入详情页(详情页中可以修改？？)
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SystemPromptDetail(
                              sysRoleSpec: a,
                            ),
                          ),
                        ).then((value) {
                          getSystemPromptSpecs();
                        });
                      },
                      // 长按删除
                      onLongPress: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(
                                "删除确认",
                                style: TextStyle(fontSize: 20.sp),
                              ),
                              content: Text("确认删除系统角色：\n${a.label}？"),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                  },
                                  child: const Text("取消"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(true);
                                  },
                                  child: const Text("确定"),
                                ),
                              ],
                            );
                          },
                        ).then((value) async {
                          if (value == true) {
                            await _dbHelper
                                .deleteCusSysRoleSpecById(a.cusSysRoleSpecId!);

                            await getSystemPromptSpecs();
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
