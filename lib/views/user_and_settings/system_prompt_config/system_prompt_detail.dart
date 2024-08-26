// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:uuid/uuid.dart';

import '../../../common/components/tool_widget.dart';
import '../../../common/llm_spec/cus_llm_model.dart';
import '../../../common/llm_spec/cus_llm_spec.dart';
import '../../../common/utils/db_tools/db_helper.dart';

class SystemPromptDetail extends StatefulWidget {
  // 有传就系统角色就是查看详情和修改，没有传就是新增
  final CusSysRoleSpec? sysRoleSpec;

  const SystemPromptDetail({super.key, this.sysRoleSpec});

  @override
  State createState() => _SystemPromptDetailState();
}

class _SystemPromptDetailState extends State<SystemPromptDetail> {
  final DBHelper _dbHelper = DBHelper();

  final _formKey = GlobalKey<FormBuilderState>();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();

    // 如果没有传系统角色信息，就是新增，设为可编辑
    if (widget.sysRoleSpec == null) {
      _isEditing = true;
    }
  }

  // 将菜品信息保存到数据库中
  _saveToDb() async {
    // 如果表单验证都通过了，保存数据到数据库，并返回上一页
    if (_formKey.currentState!.saveAndValidate()) {
      var temp = _formKey.currentState;

      print(
          "temp?.fields['sysRoleType']?.value--${temp?.fields['sysRoleType']?.value}");

      // 理论上这个type一定存在的
      var tempType = LLModelType.values
          .firstWhere((e) => e.name == temp?.fields['sysRoleType']?.value);

      CusSysRoleSpec tempSysRole = CusSysRoleSpec(
        cusSysRoleSpecId: const Uuid().v1(),
        label: temp?.fields['label']?.value,
        subtitle: temp?.fields['subtitle']?.value,
        name: null,
        hintInfo: '',
        systemPrompt: temp?.fields['systemPrompt']?.value,
        imageUrl: temp?.fields['imageUrl']?.value,
        sysRoleType: tempType,
        gmtCreate: DateTime.now(),
      );

      try {
        // 有旧菜品信息就是修改；没有就是新增
        if (widget.sysRoleSpec != null) {
          // 修改的话要保留原本的编号
          tempSysRole.cusSysRoleSpecId = widget.sysRoleSpec!.cusSysRoleSpecId;

          await _dbHelper.updateCusSysRoleSpec(tempSysRole);
        } else {
          await _dbHelper.insertCusSysRoleSpecList([tempSysRole]);
        }

        setState(() {
          _isEditing = !_isEditing;
        });
      } catch (e) {
        if (!mounted) return;
        // 插入失败上面弹窗显示
        commonExceptionDialog(context, "异常提醒", e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('系统角色详情'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              setState(() {
                if (!_isEditing) {
                  _isEditing = !_isEditing;
                } else {
                  // _formKey.currentState?.save();
                  _saveToDb();
                }
              });
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: FormBuilder(
                key: _formKey,
                initialValue: widget.sysRoleSpec?.toMap() ?? {},
                // enabled: _isEditable,
                child: Column(
                  children: [
                    FormBuilderTextField(
                      name: 'label',
                      readOnly: !_isEditing,
                      decoration: const InputDecoration(labelText: '*名称'),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                      ]),
                    ),
                    FormBuilderTextField(
                      name: 'imageUrl',
                      readOnly: !_isEditing,
                      decoration: const InputDecoration(labelText: '图片地址'),
                    ),
                    FormBuilderDropdown(
                      name: 'sysRoleType',
                      decoration: const InputDecoration(labelText: '*适用类型'),
                      items: [
                        LLModelType.cc.name,
                        LLModelType.iti.name,
                        LLModelType.tti.name,
                      ]
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                      ]),
                    ),
                    FormBuilderTextField(
                      name: 'subtitle',
                      readOnly: !_isEditing,
                      decoration: const InputDecoration(labelText: '简介'),
                      maxLines: 2,
                    ),
                    if (_isEditing)
                      FormBuilderTextField(
                        name: 'systemPrompt',
                        maxLines: 5,
                        decoration: const InputDecoration(labelText: '*系统提示词'),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                        ]),
                      ),
                    if (!_isEditing && widget.sysRoleSpec != null)
                      Padding(
                        padding: EdgeInsets.all(20.sp),
                        child: const Text("系统提示词"),
                      ),
                    if (!_isEditing && widget.sysRoleSpec != null)
                      MarkdownBody(
                        data: widget.sysRoleSpec!.systemPrompt,
                        selectable: true,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
