// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../apis/get_app_key_helper.dart';
import '../../../common/components/tool_widget.dart';
import '../../../services/cus_get_storage.dart';

class ApiKeyConfig extends StatefulWidget {
  const ApiKeyConfig({super.key});

  @override
  State createState() => _ApiKeyConfigState();
}

class _ApiKeyConfigState extends State<ApiKeyConfig> {
  final _formKey = GlobalKey<FormBuilderState>();
  // 是否在编辑中
  bool _isEditing = false;
  // 密钥是否是隐藏状态(就不每个都弄，所有密钥单独一个就好了)
  bool _obscureText = true;

  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  _saveToCache() async {
    // 如果表单验证都通过了，保存数据到数据库，并返回上一页
    if (_formKey.currentState!.saveAndValidate()) {
      var temp = _formKey.currentState?.fields;

      try {
        // 保存token信息到缓存
        await MyGetStorage().setUserAKMap({
          SKN.baiduApiKey.name: temp?[SKN.baiduApiKey.name]?.value ?? "",
          SKN.baiduSecretKey.name: temp?[SKN.baiduSecretKey.name]?.value ?? "",
          SKN.tencentSecretId.name:
              temp?[SKN.tencentSecretId.name]?.value ?? "",
          SKN.tencentSecretKey.name:
              temp?[SKN.tencentSecretKey.name]?.value ?? "",
          SKN.aliyunAppId.name: temp?[SKN.aliyunAppId.name]?.value ?? "",
          SKN.aliyunApiKey.name: temp?[SKN.aliyunApiKey.name]?.value ?? "",
          SKN.xfyunAppId.name: temp?[SKN.xfyunAppId.name]?.value ?? "",
          SKN.xfyunApiSecret.name: temp?[SKN.xfyunApiSecret.name]?.value ?? "",
          SKN.xfyunApiKey.name: temp?[SKN.xfyunApiKey.name]?.value ?? "",
          SKN.xfyunApiPassword.name:
              temp?[SKN.xfyunApiPassword.name]?.value ?? "",
          SKN.siliconFlowAK.name: temp?[SKN.siliconFlowAK.name]?.value ?? "",
          SKN.lingyiwanwuAK.name: temp?[SKN.lingyiwanwuAK.name]?.value ?? "",
        });

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
        title: const Text('配置的各平台密钥'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                  _formKey.currentState
                      ?.patchValue(MyGetStorage().getUserAKMap());
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
                  _saveToCache();
                }
              });
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          Container(
            height: 80.sp,
            margin: EdgeInsets.fromLTRB(20, 0, 10.sp, 0.sp),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      """配置了本应用支持平台中自己的密钥，\n可以使用一些该平台上的付费的模型。\n密钥仅在设备本地缓存，确保值可用。""",
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    Divider(height: 10.sp, thickness: 1.sp),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: _toggle,
                ),
              ],
            ),
          ),
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
      initialValue: MyGetStorage().getUserAKMap(),
      // enabled: _isEditable,
      child: Column(
        children: [
          Card(
            child: Column(
              children: [
                buildField(SKN.baiduApiKey.name, "百度 API KEY"),
                buildField(SKN.baiduSecretKey.name, "百度 SECRET KEY"),
              ],
            ),
          ),
          SizedBox(height: 10.sp),
          Card(
            child: Column(
              children: [
                buildField(SKN.aliyunAppId.name, "阿里云 APP ID"),
                buildField(SKN.aliyunApiKey.name, "阿里云 API KEY"),
              ],
            ),
          ),
          SizedBox(height: 10.sp),
          Card(
            child: Column(
              children: [
                buildField(SKN.tencentSecretId.name, "腾讯 SECRET ID"),
                buildField(SKN.tencentSecretKey.name, "腾讯 SECRET KEY"),
              ],
            ),
          ),
          SizedBox(height: 10.sp),
          Card(
            child: Column(
              children: [
                buildField(SKN.xfyunAppId.name, "科大讯飞 APP ID"),
                buildField(SKN.xfyunApiSecret.name, "科大讯飞 API SECRET"),
                buildField(SKN.xfyunApiKey.name, "科大讯飞 API Key"),
                buildField(SKN.xfyunApiPassword.name, "科大讯飞 API PASSWORD"),
              ],
            ),
          ),
          SizedBox(height: 10.sp),
          Card(
            child: Column(
              children: [
                buildField(SKN.siliconFlowAK.name, "SiliconFlow AK"),
              ],
            ),
          ),
          SizedBox(height: 10.sp),
          Card(
            child: Column(
              children: [
                buildField(SKN.lingyiwanwuAK.name, "零一万物 AK"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  buildField(String name, String labelText) {
    // return cusFormBuilerTextField(
    //   name,
    //   labelText: labelText,
    //   isReadOnly: !_isEditing,
    //   isOutline: true,
    // );

    return Padding(
      padding: EdgeInsets.fromLTRB(10.sp, 5.sp, 10.sp, 5.sp),
      child: FormBuilderTextField(
        name: name,
        readOnly: !_isEditing,
        // 2023-12-04 没有传默认使用name，原本默认的.text会弹安全键盘，可能无法输入中文
        // 2023-12-21 enableSuggestions 设为 true后键盘类型为text就正常了。
        enableSuggestions: true,
        keyboardType: TextInputType.text,
        obscureText: _obscureText,
        decoration: InputDecoration(
          isDense: true,
          labelText: labelText,
          border: _isEditing ? null : InputBorder.none,
        ),
        style: TextStyle(fontSize: 18.sp, color: Colors.green),
      ),
    );
  }
}
