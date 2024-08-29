import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/components/tool_widget.dart';
import '../../../common/constants.dart';

///
/// 翻译和总结做为预设功能，不需要多轮对话，只需要点击功能按钮即可
///
class DefaultSysRoleButtonRow extends StatelessWidget {
  // 是否显示语言切换部件
  final bool isShowLanguageSwitch;
  // 如果是翻译模式，则需要选择目标语言
  final TargetLanguage? targetLang;
  // 如果翻译的语言变了，要触发目标语言的修改
  final Function(TargetLanguage)? onLanguageChanged;
  // 同时也会修改显示的语言标签
  final Map<TargetLanguage, String>? langLabel;

  // 正在翻译或者正在总结的按钮关键字
  final String labelKeyword;

  // 是否可以点击功能按钮
  final bool isConfirmClickable;
  // 点击了功能确认按钮
  final Function() onConfirmPressed;

  const DefaultSysRoleButtonRow({
    super.key,
    this.isShowLanguageSwitch = true,
    this.targetLang,
    this.onLanguageChanged,
    this.langLabel,
    this.labelKeyword = "AI翻译",
    required this.onConfirmPressed,
    this.isConfirmClickable = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32.sp,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(width: 5.sp),
          if (isShowLanguageSwitch)
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(
                    width: 60.sp,
                    child: const Icon(Icons.swap_vert),
                  ),
                  Expanded(
                    child: buildDropdownButton2<TargetLanguage?>(
                      value: targetLang,
                      itemMaxHeight: 200.sp,
                      items: TargetLanguage.values,
                      onChanged: (val) {
                        if (val != null && onLanguageChanged != null) {
                          onLanguageChanged!(val);
                        }
                      },
                      itemToString: (e) => langLabel?[e]! ?? "<未选择>",
                    ),
                  ),
                ],
              ),
            ),
          if (!isShowLanguageSwitch) Expanded(flex: 3, child: Container()),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(80.sp, 32.sp),
                    padding: EdgeInsets.symmetric(horizontal: 10.sp),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.sp),
                    ),
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: !isConfirmClickable
                      ? null
                      : () {
                          unfocusHandle();
                          onConfirmPressed();
                        },
                  child: Text(
                    labelKeyword,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
