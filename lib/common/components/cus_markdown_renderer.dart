import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gpt_markdown/custom_widgets/selectable_adapter.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

/// Markdown渲染工具类
///
/// 提供缓存机制和智能组件加载，优化性能
class CusMarkdownRenderer {
  // 私有构造函数，防止直接实例化
  CusMarkdownRenderer._();

  // 单例实例
  static final CusMarkdownRenderer _instance = CusMarkdownRenderer._();

  // 获取单例
  static CusMarkdownRenderer get instance => _instance;

  // Markdown缓存
  final Map<String, Widget> _markdownCache = {};

  // 缓存大小限制
  static const int _maxCacheSize = 200;

  // 预定义的所有组件列表
  final List<MarkdownComponent> _allComponents = [
    CodeBlockMd(),
    NewLines(),
    BlockQuote(),
    ImageMd(),
    ATagMd(),
    TableMd(),
    HTag(),
    UnOrderedList(),
    OrderedList(),
    RadioButtonMd(),
    CheckBoxMd(),
    HrLine(),
    StrikeMd(),
    BoldMd(),
    ItalicMd(),
    LatexMath(),
    LatexMathMultiLine(),
    HighlightedText(),
    SourceTag(),
    IndentMd(),
  ];

  // 预定义的所有内联组件
  final List<MarkdownComponent> _allInlineComponents = [
    ImageMd(),
    ATagMd(),
    TableMd(),
    StrikeMd(),
    BoldMd(),
    ItalicMd(),
    LatexMath(),
    LatexMathMultiLine(),
    HighlightedText(),
    SourceTag(),
  ];

  /// 渲染Markdown内容
  ///
  /// [text] 要渲染的Markdown文本
  /// [selectable] 是否可选择文本(默认不可选)
  /// [textColor] 文本颜色
  Widget render(String text, {Color? textColor, bool selectable = false}) {
    // 检查缓存中是否存在
    final cacheKey = '${selectable}_$text';
    if (_markdownCache.containsKey(cacheKey)) {
      return _markdownCache[cacheKey]!;
    }

    final widget = Builder(
      builder: (context) {
        Widget child = GptMarkdown(
          text,
          style: TextStyle(color: textColor),
          onLinkTab: (url, title) {
            debugPrint(url);
            debugPrint(title);
          },
          highlightBuilder: (context, text, style) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 2.sp),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(4.sp),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.5),
                  width: 1.sp,
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize:
                      style.fontSize != null ? style.fontSize! * 0.9 : 13.5.sp,
                  height: style.height,
                ),
              ),
            );
          },
          latexWorkaround: (tex) {
            List<String> stack = [];
            tex = tex.splitMapJoin(
              RegExp(r"\\text\{|\{|\}|\_"),
              onMatch: (p) {
                String input = p[0] ?? "";
                if (input == r"\text{") {
                  stack.add(input);
                }
                if (stack.isNotEmpty) {
                  if (input == r"{") {
                    stack.add(input);
                  }
                  if (input == r"}") {
                    stack.removeLast();
                  }
                  if (input == r"_") {
                    return r"\_";
                  }
                }
                return input;
              },
            );
            return tex.replaceAllMapped(
                RegExp(r"align\*"), (match) => "aligned");
          },
          imageBuilder: (context, url) {
            return Image.network(
              url,
              width: 100.sp,
              height: 100.sp,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
            );
          },
          latexBuilder: (context, tex, textStyle, inline) {
            if (tex.contains(r"\begin{tabular}")) {
              // return table.
              String tableString = "|${(RegExp(
                    r"^\\begin\{tabular\}\{.*?\}(.*?)\\end\{tabular\}$",
                    multiLine: true,
                    dotAll: true,
                  ).firstMatch(tex)?[1] ?? "").trim()}|";
              tableString = tableString
                  .replaceAll(r"\\", "|\n|")
                  .replaceAll(r"\hline", "")
                  .replaceAll(RegExp(r"(?<!\\)&"), "|");
              var tableStringList = tableString.split("\n")..insert(1, "|---|");
              tableString = tableStringList.join("\n");
              return GptMarkdown(tableString);
            }
            var controller = ScrollController();
            Widget child = Math.tex(tex, textStyle: textStyle);
            if (!inline) {
              child = Padding(
                padding: EdgeInsets.all(0.sp),
                child: Material(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                  child: Padding(
                    padding: EdgeInsets.all(8.sp),
                    child: Scrollbar(
                      controller: controller,
                      child: SingleChildScrollView(
                        controller: controller,
                        scrollDirection: Axis.horizontal,
                        child: Math.tex(tex, textStyle: textStyle),
                      ),
                    ),
                  ),
                ),
              );
            }
            child = SelectableAdapter(
              selectedText: tex,
              child: Math.tex(tex),
            );
            child = InkWell(
              onTap: () {
                debugPrint("LaTeX content: $tex");
              },
              child: child,
            );
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: child,
            );
          },
          sourceTagBuilder: (buildContext, string, textStyle) {
            var value = int.tryParse(string);
            value ??= -1;
            value += 1;
            return SizedBox(
              height: 20.sp,
              width: 20.sp,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10.sp),
                ),
                child: Center(child: Text("$value")),
              ),
            );
          },
          linkBuilder: (context, label, path, style) {
            return Text(
              label,
              style: style.copyWith(color: Colors.blue),
            );
          },
          // 始终使用全部组件，而不是只加载部分组件
          // 这是因为部分组件缺失会导致某些渲染效果不正确
          components: _allComponents,
          inlineComponents: _allInlineComponents,
        );

        // 处理可选择性
        if (selectable) {
          child = SelectionArea(child: child);
        }

        return child;
      },
    );

    // 缓存结果
    _addToCache(cacheKey, widget);

    return widget;
  }

  /// 添加到缓存
  void _addToCache(String key, Widget widget) {
    // 缓存大小控制
    if (_markdownCache.length >= _maxCacheSize) {
      _markdownCache.remove(_markdownCache.keys.first);
    }
    _markdownCache[key] = widget;
  }

  /// 清除全部缓存
  void clearCache() {
    _markdownCache.clear();
  }

  /// 从缓存中移除特定项
  void removeFromCache(String text) {
    _markdownCache.remove(text);
    _markdownCache.remove('true_$text');
    _markdownCache.remove('false_$text');
  }

  /// 获取当前缓存大小
  int get cacheSize => _markdownCache.length;
}

/// 向后兼容的API，调用单例的render方法
Widget buildmd(String text) {
  return CusMarkdownRenderer.instance.render(text);
}
