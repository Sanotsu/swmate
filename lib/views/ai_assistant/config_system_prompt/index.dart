import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/components/tool_widget.dart';
import '../../../common/llm_spec/cus_llm_model.dart';
import '../../../common/llm_spec/cus_llm_spec.dart';
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

  // 系统角色分类查询显示
  LLModelType? selectedType;

  @override
  void initState() {
    getSystemPromptSpecs();
    super.initState();
  }

  getSystemPromptSpecs() async {
    var sysroleLl = await _dbHelper.queryCusSysRoleSpecList(
      sysRoleType: selectedType,
    );
    setState(() {
      // 2024-08-26 目前系统角色中，文档解读和翻译解读预设的6个有name，过滤不显示(因为这6个和代码逻辑相关，不能被删除)，
      // 其他是没有的，用户新增删除可以自行管理
      sysRoleSpecs = sysroleLl.where((e) => e.name == null).toList();
    });
  }

  Widget _buildPopupMenuButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      // 调整弹出按钮的位置
      position: PopupMenuPosition.under,
      // 弹出按钮的偏移
      // offset: Offset(-25.sp, 0),
      onSelected: (String value) async {
        // 处理选中的菜单项
        if (value == 'import') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SystemPromptJsonImport(),
            ),
          ).then((value) {
            getSystemPromptSpecs();
          });
        } else if (value == 'info') {
          commonMDHintModalBottomSheet(
            context,
            "系统角色说明",
            """1. 预设了一些系统角色，也可自行创建、导入、删除。
2. 系统角色需指定使用场景(比如对话、文生图、图生图等)，且不是对所有的模型都有效。
3. 点击系统角色项次查看详情，长按项次进行删除。""",
            msgFontSize: 15.sp,
          );
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
        buildCusPopupMenuItem(context, "import", "导入", Icons.file_upload),
        buildCusPopupMenuItem(context, "info", "说明", Icons.info_outline),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("系统角色"),
        actions: [
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
          _buildPopupMenuButton(),
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.sp),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text("下拉筛选："),
                  SizedBox(
                    width: 160.sp,
                    child: buildDropdownButton2<LLModelType?>(
                      value: selectedType,
                      itemMaxHeight: 320.sp,
                      items: LLModelType.values,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedType = val;
                          });
                          getSystemPromptSpecs();
                        }
                      },
                      alignment: AlignmentDirectional.centerStart,
                      itemToString: (e) =>
                          "${MT_NAME_MAP[e]}: ${(e as LLModelType).name}",
                    ),
                  ),
                  SizedBox(
                    width: 100.sp,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          selectedType = null;
                        });
                        getSystemPromptSpecs();
                      },
                      child: const Text("显示全部"),
                    ),
                  ),
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
                      title: Text(
                        "${index + 1}_${MT_NAME_MAP[a.sysRoleType]}_${a.label}",
                      ),
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
