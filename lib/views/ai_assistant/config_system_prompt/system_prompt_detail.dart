import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:uuid/uuid.dart';

import '../../../common/components/tool_widget.dart';
import '../../../common/llm_spec/cus_llm_model.dart';
import '../../../common/llm_spec/cus_llm_spec.dart';
import '../../../common/utils/db_tools/db_ai_tool_helper.dart';

class SystemPromptDetail extends StatefulWidget {
  // 有传就系统角色就是查看详情和修改，没有传就是新增
  final CusSysRoleSpec? sysRoleSpec;

  const SystemPromptDetail({super.key, this.sysRoleSpec});

  @override
  State createState() => _SystemPromptDetailState();
}

class _SystemPromptDetailState extends State<SystemPromptDetail> {
  final DBAIToolHelper _dbHelper = DBAIToolHelper();

  final _formKey = GlobalKey<FormBuilderState>();
  bool _isEditing = false;

  CusSysRoleSpec? currentRole;

  @override
  void initState() {
    super.initState();

    // 如果没有传系统角色信息，就是新增，设为可编辑
    if (widget.sysRoleSpec == null) {
      _isEditing = true;
    } else {
      currentRole = widget.sysRoleSpec;
    }
  }

  _saveToDb() async {
    // 如果表单验证都通过了，保存数据到数据库，并返回上一页
    if (_formKey.currentState!.saveAndValidate()) {
      var temp = _formKey.currentState;

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
        if (currentRole != null) {
          // 修改的话要保留原本的编号
          tempSysRole.cusSysRoleSpecId = currentRole!.cusSysRoleSpecId;

          await _dbHelper.updateCusSysRoleSpec(tempSysRole);
        } else {
          await _dbHelper.insertCusSysRoleSpecList([tempSysRole]);
        }

        setState(() {
          _isEditing = !_isEditing;

          currentRole = tempSysRole;
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
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                  _formKey.currentState?.patchValue(
                    currentRole?.toMap() ?? {},
                  );
                });
              },
            ),
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
            padding: EdgeInsets.all(5.sp),
            child: SingleChildScrollView(
              child: buildFormBuilder(),
            ),
          ),
        ],
      ),
    );
  }

  buildFormBuilder() {
    return FormBuilder(
      key: _formKey,
      initialValue: currentRole?.toMap() ?? {},
      // enabled: _isEditable,
      child: Column(
        children: [
          buildField("label", "*名称"),
          buildField("imageUrl", "图片地址", required: false),
          FormBuilderDropdown(
            name: 'sysRoleType',
            enabled: _isEditing,
            decoration: const InputDecoration(labelText: '*适用类型'),
            items: LLModelType.values
                .map((type) => DropdownMenuItem(
                      value: type.name,
                      child: Text(
                        "${MT_NAME_MAP[type]}: ${type.name}",
                        style: const TextStyle(color: Colors.green),
                      ),
                    ))
                .toList(),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
            ]),
          ),
          buildField("subtitle", "简介", maxLines: 2),
          if (_isEditing) buildField("systemPrompt", "*系统提示词", maxLines: 5),
          if (!_isEditing && currentRole != null)
            Padding(
              padding: EdgeInsets.all(10.sp),
              child: Column(
                children: [
                  Divider(height: 10.sp),
                  const Text("系统提示词", style: TextStyle(color: Colors.green)),
                  Divider(height: 10.sp),
                  MarkdownBody(
                    data: currentRole!.systemPrompt,
                    selectable: true,
                    // styleSheet: MarkdownStyleSheet(
                    //   p: const TextStyle(color: Colors.green),
                    // ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  buildField(
    String name,
    String labelText, {
    int? maxLines,
    bool required = true,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(10.sp, 5.sp, 10.sp, 5.sp),
      child: FormBuilderTextField(
        name: name,
        readOnly: !_isEditing,
        // 2023-12-04 没有传默认使用name，原本默认的.text会弹安全键盘，可能无法输入中文
        // 2023-12-21 enableSuggestions 设为 true后键盘类型为text就正常了。
        enableSuggestions: true,
        keyboardType: TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          isDense: true,
          labelText: labelText,
          border: _isEditing ? null : InputBorder.none,
        ),
        style: TextStyle(color: _isEditing ? Colors.black : Colors.green),
        validator: required
            ? FormBuilderValidators.compose([FormBuilderValidators.required()])
            : null,
      ),
    );
  }
}
