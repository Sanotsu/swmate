// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../apis/get_app_key_helper.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../services/cus_get_storage.dart';

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

  // 是否在导入密钥中
  bool isLoading = true;

  // 表单初始值为空
  Map<String, dynamic> initData = {};

  @override
  void initState() {
    super.initState();
    initMapData();
  }

  initMapData() {
    // 初始化时，从缓存中取值
    setState(() {
      initData = MyGetStorage().getUserAKMap();
    });
  }

  // 导入各个平台的API
  Future<void> _openJsonFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'JSON'],
    );

    if (result != null) {
      setState(() => isLoading = true);

      File file = File(result.files.single.path!);

      print("result--$result");

      try {
        // 获取json文件中的各个key存入缓存
        var jsonData = json.decode(await file.readAsString());

        // 获取到json中的值了，把缓存中的都清除
        await MyGetStorage().setUserAKMap({});

        // 存入缓存
        await MyGetStorage().setUserAKMap({
          SKN.baiduApiKey.name: jsonData[SKN.baiduApiKey.name] ?? "",
          SKN.baiduSecretKey.name: jsonData[SKN.baiduSecretKey.name] ?? "",
          SKN.tencentSecretId.name: jsonData[SKN.tencentSecretId.name] ?? "",
          SKN.tencentSecretKey.name: jsonData[SKN.tencentSecretKey.name] ?? "",
          SKN.aliyunAppId.name: jsonData[SKN.aliyunAppId.name] ?? "",
          SKN.aliyunApiKey.name: jsonData[SKN.aliyunApiKey.name] ?? "",
          SKN.xfyunAppId.name: jsonData[SKN.xfyunAppId.name] ?? "",
          SKN.xfyunApiSecret.name: jsonData[SKN.xfyunApiSecret.name] ?? "",
          SKN.xfyunApiKey.name: jsonData[SKN.xfyunApiKey.name] ?? "",
          SKN.xfyunSparkLiteApiPassword.name:
              jsonData[SKN.xfyunSparkLiteApiPassword.name] ?? "",
          SKN.xfyunSparkProApiPassword.name:
              jsonData[SKN.xfyunSparkProApiPassword.name] ?? "",
          SKN.siliconFlowAK.name: jsonData[SKN.siliconFlowAK.name] ?? "",
          SKN.lingyiwanwuAK.name: jsonData[SKN.lingyiwanwuAK.name] ?? "",
          SKN.zhipuAK.name: jsonData[SKN.zhipuAK.name] ?? "",
        });

        setState(() {
          // 先重置掉表单的值
          final formState = _formKey.currentState;
          if (formState != null) {
            formState.reset();
          }
          // 再更新表单的值
          _formKey.currentState?.patchValue(MyGetStorage().getUserAKMap());
        });
      } catch (e) {
        // 弹出报错提示框
        if (!mounted) return;
        commonExceptionDialog(
          context,
          "json导入失败",
          "json解析失败:${file.path},\n${e.toString}",
        );

        setState(() => isLoading = false);
        rethrow;
      }

      setState(() => isLoading = false);
    } else {
      // User canceled the picker
      return;
    }
  }

  clearUserAK() async {
    await MyGetStorage().setUserAKMap(null);
    setState(() {
      initData = {};
      _formKey.currentState?.reset();
      _formKey.currentState?.patchValue(MyGetStorage().getUserAKMap());
    });
  }

  _saveToCache() async {
    // 如果表单验证都通过了，保存数据到数据库，并返回上一页
    if (_formKey.currentState!.saveAndValidate()) {
      var temp = _formKey.currentState?.fields;

      try {
        // 先清空缓存
        await MyGetStorage().setUserAKMap({});

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
          SKN.xfyunSparkLiteApiPassword.name:
              temp?[SKN.xfyunSparkLiteApiPassword.name]?.value ?? "",
          SKN.xfyunSparkProApiPassword.name:
              temp?[SKN.xfyunSparkProApiPassword.name]?.value ?? "",
          SKN.siliconFlowAK.name: temp?[SKN.siliconFlowAK.name]?.value ?? "",
          SKN.lingyiwanwuAK.name: temp?[SKN.lingyiwanwuAK.name]?.value ?? "",
          SKN.zhipuAK.name: temp?[SKN.zhipuAK.name]?.value ?? "",
        });

        setState(() {
          // 先重置掉表单的值
          final formState = _formKey.currentState;
          if (formState != null) {
            formState.reset();
          }
          // 再更新表单的值
          _formKey.currentState?.patchValue(MyGetStorage().getUserAKMap());

          _isEditing = !_isEditing;
        });
      } catch (e) {
        if (!mounted) return;
        // 插入失败上面弹窗显示
        commonExceptionDialog(context, "异常提醒", e.toString());
      }
    }
  }

  // 切换密钥可见性
  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('平台密钥'),
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("清空确认"),
                      content: const Text("确认清空缓存的密钥？"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("取消"),
                        ),
                        TextButton(
                          onPressed: () async {
                            await clearUserAK();
                            if (mounted) {
                              if (!context.mounted) return;
                              Navigator.of(context).pop(true);
                            }
                          },
                          child: const Text("确定"),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Icons.clear_all),
            ),
          if (!_isEditing)
            IconButton(
              onPressed: _openJsonFiles,
              icon: const Icon(Icons.upload_file),
            ),
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
      body: Column(
        children: [
          Container(
            height: 60.sp,
            margin: EdgeInsets.fromLTRB(20, 0, 0.sp, 0.sp),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  """配置了本应用支持平台中自己的密钥，\n可以使用一些该平台上的付费的模型。\n密钥仅在设备本地缓存，确保值可用。""",
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14.sp),
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
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: EdgeInsets.all(5.sp),
                  child: SingleChildScrollView(child: buildFormBuilder()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  buildFormBuilder() {
    return FormBuilder(
      key: _formKey,
      initialValue: initData,
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
                buildField(SKN.xfyunSparkLiteApiPassword.name,
                    "科大讯飞 Spark Lite API PASSWORD"),
                buildField(SKN.xfyunSparkProApiPassword.name,
                    "科大讯飞 Spark Pro API PASSWORD"),
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
              children: [buildField(SKN.lingyiwanwuAK.name, "零一万物 AK")],
            ),
          ),
          SizedBox(height: 10.sp),
          Card(
            child: Column(
              children: [buildField(SKN.zhipuAK.name, "智谱AI AK")],
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
