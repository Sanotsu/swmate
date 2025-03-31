import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/theme_map.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 改造原始代码做一些简单自定义
/// A widget that displays code with syntax highlighting and a copy button.
///
/// The [CusCodeField] widget takes a [name] parameter which is displayed as a label
/// above the code block, and a [codes] parameter containing the actual code text
/// to display.
///
/// Features:
/// - Displays code in a Material container with rounded corners
/// - Shows the code language/name as a label
/// - Provides a copy button to copy code to clipboard
/// - Visual feedback when code is copied
/// - Themed colors that adapt to light/dark mode
class CusCodeField extends StatefulWidget {
  const CusCodeField({super.key, required this.name, required this.codes});
  final String name;
  final String codes;

  @override
  State<CusCodeField> createState() => _CusCodeFieldState();
}

class _CusCodeFieldState extends State<CusCodeField> {
  bool _copied = false;
  @override
  Widget build(BuildContext context) {
    return Material(
      // color: Theme.of(context).colorScheme.onInverseSurface,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(0),
                  child: Text(widget.name),
                ),
                const Spacer(),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    textStyle: const TextStyle(fontWeight: FontWeight.normal),
                  ),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: widget.codes),
                    ).then((value) {
                      setState(() {
                        _copied = true;
                      });
                    });
                    await Future.delayed(const Duration(seconds: 2));
                    setState(() {
                      _copied = false;
                    });
                  },
                  icon: Icon(
                    (_copied) ? Icons.done : Icons.content_paste,
                    size: 15.sp,
                  ),
                  label: Text((_copied) ? "Copied!" : "Copy"),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.all(4.sp),

            // 使用highlight 渲染有好的样式和高亮，但不可以背景透明
            child: HighlightView(
              widget.codes,
              language: widget.name,
              theme: themeMap['xcode'] ?? githubTheme,
            ),

            // 使用Text渲染没有好的样式和高亮，但可以背景透明
            // child: Text(widget.codes),
            // child: Text(
            //   widget.codes,
            //   style: TextStyle(
            //     fontFamily: 'JetBrains Mono',
            //     fontSize: 14,
            //     height: 1.5,
            //     color: Theme.of(context).colorScheme.onSurface,
            //   ),
            // ),
          ),
        ],
      ),
    );
  }
}
