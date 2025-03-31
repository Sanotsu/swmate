import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:markdown/markdown.dart' as md;

import 'tool_widget.dart';

/// 2025-03-29
/// 简单的自定义Markdown渲染器，专门用于大模型AI响应内容
/// 优化处理：
/// 1. 正常文本和表格中的LaTeX公式
/// 2. 代码高亮
/// 3. 表格布局(不够好，无法超过屏幕宽度，因为IntrinsicColumnWidth和一些组件渲染的限制)
///
/// 实际上，有个 gpt_markdown 库，更方便更专业，还有专门维护。
/// 但这里只是为了学习，还是自己实现一个【效果其实并不好，只做备用】。
/// 
class OptimizedCustomMarkdownRenderer extends StatefulWidget {
  final String text;
  final TextStyle? textStyle;
  final bool selectable;
  final MarkdownStyleSheet? styleSheet;
  final EdgeInsets contentPadding;
  final Map<String, TextStyle>? codeTheme;

  const OptimizedCustomMarkdownRenderer({
    super.key,
    required this.text,
    this.textStyle,
    this.selectable = true,
    this.styleSheet,
    this.contentPadding = EdgeInsets.zero,
    this.codeTheme,
  });

  @override
  State<OptimizedCustomMarkdownRenderer> createState() =>
      _OptimizedCustomMarkdownRendererState();
}

class _OptimizedCustomMarkdownRendererState
    extends State<OptimizedCustomMarkdownRenderer>
    with AutomaticKeepAliveClientMixin {
  // 缓存渲染结果
  Widget? _renderedContent;
  String? _lastText;
  TextStyle? _lastTextStyle;
  double? _lastFontSize;
  double? _lastScaleFactor;

  @override
  bool get wantKeepAlive => true; // 保持状态，避免滚动时重建

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 获取当前文本缩放因子
    final textScaleFactor = MediaQuery.of(context).textScaler.scale(1.0);
    final currentFontSize = widget.textStyle?.fontSize;

    // 检查是否需要重新渲染
    final needsRebuild = _renderedContent == null ||
        widget.text != _lastText ||
        widget.textStyle != _lastTextStyle ||
        currentFontSize != _lastFontSize ||
        textScaleFactor != _lastScaleFactor;

    if (needsRebuild) {
      _lastText = widget.text;
      _lastTextStyle = widget.textStyle;
      _lastFontSize = currentFontSize;
      _lastScaleFactor = textScaleFactor;

      // 构建内容
      _renderedContent = _buildContent(context);
    }

    return _renderedContent!;
  }

  // 构建Markdown内容
  Widget _buildContent(BuildContext context) {
    // 检查文本是否为空
    if (widget.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    // 处理Markdown内容
    return Padding(
      padding: widget.contentPadding,
      child: MarkdownBody(
        data: _preprocessMarkdown(widget.text),
        selectable: widget.selectable,
        styleSheet: widget.styleSheet ?? _createDefaultStyleSheet(context),
        extensionSet: md.ExtensionSet(
          md.ExtensionSet.gitHubWeb.blockSyntaxes,
          [
            _LatexSyntax(), // 自定义LaTeX语法
            md.EmojiSyntax(),
          ],
        ),
        onTapLink: (text, href, title) {
          if (href != null) launchStringUrl(href);
        },
        builders: {
          'latex': _LatexElementBuilder(),
          'code': AICodeBuilder(widget.textStyle, context, widget.codeTheme),
          'table': AITableBuilder(widget.textStyle, context),
        },
      ),
    );
  }

  // 创建默认的Markdown样式
  MarkdownStyleSheet _createDefaultStyleSheet(BuildContext context) {
    final theme = Theme.of(context);
    final baseTextStyle = widget.textStyle ?? theme.textTheme.bodyMedium!;

    return MarkdownStyleSheet(
      p: baseTextStyle,
      h1: baseTextStyle.copyWith(fontSize: 24.sp, fontWeight: FontWeight.bold),
      h2: baseTextStyle.copyWith(fontSize: 22.sp, fontWeight: FontWeight.bold),
      h3: baseTextStyle.copyWith(fontSize: 20.sp, fontWeight: FontWeight.bold),
      h4: baseTextStyle.copyWith(fontSize: 18.sp, fontWeight: FontWeight.bold),
      h5: baseTextStyle.copyWith(fontSize: 16.sp, fontWeight: FontWeight.bold),
      h6: baseTextStyle.copyWith(fontSize: 14.sp, fontWeight: FontWeight.bold),
      em: baseTextStyle.copyWith(fontStyle: FontStyle.italic),
      strong: baseTextStyle.copyWith(fontWeight: FontWeight.bold),
      code: baseTextStyle.copyWith(
        fontFamily: 'monospace',
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
      blockquote: baseTextStyle.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
      blockSpacing: 8.sp,
      listIndent: 24.sp,
      listBullet: baseTextStyle,
      tableBody: baseTextStyle,
      tableHead: baseTextStyle.copyWith(fontWeight: FontWeight.bold),
      // tableColumnWidth: const IntrinsicColumnWidth(),
      tableBorder: TableBorder.all(
        color: theme.colorScheme.outline.withValues(alpha: 0.5),
        width: 0.5,
      ),
      tableCellsPadding: EdgeInsets.all(8.sp),
      a: baseTextStyle.copyWith(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      codeblockPadding: EdgeInsets.all(8.sp),
      codeblockDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4.sp),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            width: 1.sp,
            color: theme.colorScheme.outline,
          ),
        ),
      ),
    );
  }

  // 预处理Markdown文本
// 在_preprocessMarkdown方法中添加LaTeX保护逻辑
  String _preprocessMarkdown(String text) {
    // 1. 先保护LaTeX公式
    text = _protectLatexFormulas(text);

    // 2. 然后处理其他内容
    text = _protectCodeBlocks(text);
    text = _preprocessTableLatex(text);
    text = _preprocessTableHtml(text);

    return text;
  }

  // 新增LaTeX保护方法
  String _protectLatexFormulas(String text) {
    // 保护行内公式 $...$ 和 \(...\)
    text = text.replaceAllMapped(RegExp(r'(\\?)(\$[^\$]+\$|\\\(.+?\\\))'),
        (match) {
      if (match.group(1)!.isNotEmpty) return match.group(0)!; // 已转义的不处理
      return '⏣LATEX⏣${base64Encode(utf8.encode(match.group(0)!))}⏣';
    });

    // 保护块级公式 $$...$$ 和 \[...\]
    text = text.replaceAllMapped(
        RegExp(r'(\\?)(\$\$[^\$]+\$\$|\\\[.+?\\\])', dotAll: true), (match) {
      if (match.group(1)!.isNotEmpty) return match.group(0)!; // 已转义的不处理
      return '⏣BLOCKLATEX⏣${base64Encode(utf8.encode(match.group(0)!))}⏣';
    });

    return text;
  }

  // 保护代码块中的特殊字符
  String _protectCodeBlocks(String text) {
    String processed = text;

    // 处理围栏式代码块 ```code```
    final codeBlockRegex = RegExp(r'```.*?```', dotAll: true);
    processed = processed.replaceAllMapped(codeBlockRegex, (match) {
      String code = match.group(0)!;
      code = code.replaceAll(r'$', r'\$');
      code = code.replaceAll(r'\[', r'\\[');
      code = code.replaceAll(r'\]', r'\\]');
      code = code.replaceAll(r'\(', r'\\(');
      code = code.replaceAll(r'\)', r'\\)');
      return code;
    });

    // 处理行内代码 `code`
    final inlineCodeRegex = RegExp(r'`[^`]+`');
    processed = processed.replaceAllMapped(inlineCodeRegex, (match) {
      String code = match.group(0)!;
      code = code.replaceAll(r'$', r'\$');
      return code;
    });

    return processed;
  }

  // 处理表格内的LaTeX公式
  String _preprocessTableLatex(String text) {
    // 查找表格行
    final tableRowRegex = RegExp(r'^\|.*\|$', multiLine: true);

    return text.replaceAllMapped(tableRowRegex, (rowMatch) {
      String row = rowMatch.group(0)!;

      // 将表格内的块级LaTeX公式转换为行内公式
      row = row.replaceAllMapped(RegExp(r'\$\$(.*?)\$\$', dotAll: true),
          (match) => '\\(${match.group(1)}\\)');

      row = row.replaceAllMapped(RegExp(r'\\\[(.*?)\\\]', dotAll: true),
          (match) => '\\(${match.group(1)}\\)');

      return row;
    });
  }

  // 处理表格内的HTML标签
  String _preprocessTableHtml(String text) {
    // 查找表格行
    final tableRowRegex = RegExp(r'^\|.*\|$', multiLine: true);

    return text.replaceAllMapped(tableRowRegex, (rowMatch) {
      String row = rowMatch.group(0)!;

      // 将<br>标签转换为特殊标记，避免破坏表格结构
      row = row.replaceAll('<br>', '⏎');

      return row;
    });
  }
}

// 增加全局解码方法 - 放在类外面便于多处使用
String restoreLatexContent(String text) {
  // 恢复行内公式
  text = text.replaceAllMapped(RegExp(r'⏣LATEX⏣([^⏣]+)⏣'), (match) {
    try {
      return utf8.decode(base64Decode(match.group(1)!));
    } catch (e) {
      return match.group(0)!;
    }
  });

  // 恢复块级公式
  text = text.replaceAllMapped(RegExp(r'⏣BLOCKLATEX⏣([^⏣]+)⏣'), (match) {
    try {
      return utf8.decode(base64Decode(match.group(1)!));
    } catch (e) {
      return match.group(0)!;
    }
  });

  return text;
}

/// ===============================
/// 代码高亮构建器
/// ===============================
class AICodeBuilder extends MarkdownElementBuilder {
  final TextStyle? textStyle;
  final BuildContext context;
  final Map<String, TextStyle>? codeTheme;

  AICodeBuilder(this.textStyle, this.context, this.codeTheme);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    try {
      // 获取代码内容(解码可能存在的LaTeX标记，代码块中显示原本的LaTeX代码)
      final code = restoreLatexContent(element.textContent);

      // 检查是否是代码块
      final isCodeBlock = _isCodeBlock(element);

      // 获取语言
      String? language;
      if (isCodeBlock && element.attributes.containsKey('class')) {
        final classAttr = element.attributes['class']!;
        if (classAttr.startsWith('language-')) {
          language = classAttr.substring(9);
        }
      }

      // 渲染代码
      return isCodeBlock
          ? _buildCodeBlock(code, language, preferredStyle)
          : _buildInlineCode(code, preferredStyle);
    } catch (e) {
      debugPrint('Error in code builder: $e');
      return Text(element.textContent, style: preferredStyle);
    }
  }

  // 判断是否是代码块
  bool _isCodeBlock(md.Element element) {
    // 检查class属性
    if (element.attributes.containsKey('class')) {
      return true;
    }

    // 检查内容是否包含换行符
    return element.textContent.contains('\n');
  }

  // 构建行内代码
  Widget _buildInlineCode(String code, TextStyle? style) {
    final baseStyle =
        textStyle ?? style ?? Theme.of(context).textTheme.bodyMedium!;
    final codeStyle = baseStyle.copyWith(
      fontFamily: 'monospace',
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      fontSize: (baseStyle.fontSize ?? 14.0) * 0.9,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 2.sp),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4.sp),
      ),
      child: Text(code, style: codeStyle),
    );
  }

  // 构建代码块
  Widget _buildCodeBlock(String code, String? language, TextStyle? style) {
    final baseStyle =
        textStyle ?? style ?? Theme.of(context).textTheme.bodyMedium!;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 8.sp),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: HighlightView(
          code,
          language: language ?? 'plaintext',
          theme: codeTheme ?? githubTheme,
          textStyle: baseStyle.copyWith(
            fontFamily: 'monospace',
            fontSize: (baseStyle.fontSize ?? 14.0) * 0.9,
          ),
          padding: EdgeInsets.all(16.sp),
        ),
      ),
    );
  }
}

/// ===============================
/// 表格构建器
/// ===============================
class AITableBuilder extends MarkdownElementBuilder {
  final TextStyle? textStyle;
  final BuildContext context;

  AITableBuilder(this.textStyle, this.context);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    try {
      // 提取表格结构
      final rows = element.children;
      if (rows == null || rows.isEmpty) return null;

      // 从table元素中提取信息
      return _buildTableWidget(element, preferredStyle);
    } catch (e) {
      debugPrint('表格构建错误: $e');
      return Text(element.textContent, style: preferredStyle);
    }
  }

  Widget _buildTableWidget(md.Element tableElement, TextStyle? preferredStyle) {
    // 获取表头行
    final List<TableColumn> columns = _extractTableColumns(tableElement);

    // 获取表格数据行
    final List<List<AITableCellData>> rows = _extractTableRows(tableElement);

    // 构建表格
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.sp),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(4.sp),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.sp),
        child: _buildMarkdownTable(columns, rows, preferredStyle),
      ),
    );
  }

  // 提取表格列信息
  List<TableColumn> _extractTableColumns(md.Element tableElement) {
    final List<TableColumn> columns = [];

    try {
      // 查找thead元素
      md.Element? theadElement;
      for (final child in tableElement.children!) {
        if (child is md.Element && child.tag == 'thead') {
          theadElement = child;
          break;
        }
      }

      if (theadElement != null && theadElement.children != null) {
        // 从thead > tr > th获取列信息
        for (final trElement in theadElement.children!) {
          if (trElement is md.Element &&
              trElement.tag == 'tr' &&
              trElement.children != null) {
            for (final thElement in trElement.children!) {
              if (thElement is md.Element && thElement.tag == 'th') {
                columns.add(TableColumn(content: thElement.textContent));
              }
            }
            break; // 只处理第一个tr
          }
        }
      } else {
        // 尝试从第一行获取列信息
        for (final child in tableElement.children!) {
          if (child is md.Element &&
              child.tag == 'tr' &&
              child.children != null) {
            for (final cellElement in child.children!) {
              if (cellElement is md.Element &&
                  (cellElement.tag == 'th' || cellElement.tag == 'td')) {
                columns.add(TableColumn(content: cellElement.textContent));
              }
            }
            break; // 只处理第一个tr
          }
        }
      }
    } catch (e) {
      debugPrint('提取表格列信息错误: $e');
    }

    return columns;
  }

  // 提取表格行数据
  List<List<AITableCellData>> _extractTableRows(md.Element tableElement) {
    final List<List<AITableCellData>> rows = [];

    try {
      // 查找tbody元素
      md.Element? tbodyElement;
      for (final child in tableElement.children!) {
        if (child is md.Element && child.tag == 'tbody') {
          tbodyElement = child;
          break;
        }
      }

      if (tbodyElement != null && tbodyElement.children != null) {
        // 从tbody > tr > td获取行数据
        for (final trElement in tbodyElement.children!) {
          if (trElement is md.Element &&
              trElement.tag == 'tr' &&
              trElement.children != null) {
            final List<AITableCellData> row = [];
            for (final tdElement in trElement.children!) {
              if (tdElement is md.Element && tdElement.tag == 'td') {
                row.add(AITableCellData.fromElement(tdElement));
              }
            }
            if (row.isNotEmpty) {
              rows.add(row);
            }
          }
        }
      } else {
        // 直接从tr > td获取行数据（跳过第一行，因为第一行是表头）
        bool isFirstRow = true;
        for (final child in tableElement.children!) {
          if (child is md.Element &&
              child.tag == 'tr' &&
              child.children != null) {
            if (isFirstRow) {
              isFirstRow = false;
              continue;
            }

            final List<AITableCellData> row = [];
            for (final cellElement in child.children!) {
              if (cellElement is md.Element && cellElement.tag == 'td') {
                row.add(AITableCellData.fromElement(cellElement));
              }
            }
            if (row.isNotEmpty) {
              rows.add(row);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('提取表格行数据错误: $e');
    }

    return rows;
  }

  // 构建Markdown表格
  Widget _buildMarkdownTable(List<TableColumn> columns,
      List<List<AITableCellData>> rows, TextStyle? preferredStyle) {
    final theme = Theme.of(context);

    // 如果没有列或行，返回空组件
    if (columns.isEmpty) {
      return const SizedBox();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 0.8.sw),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 表头
            Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Row(
                children: columns.map((column) {
                  return Expanded(
                    child: Container(
                      padding: EdgeInsets.all(8.sp),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.5),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: _buildRichTableCell(
                          column.content,
                          preferredStyle?.copyWith(fontWeight: FontWeight.bold),
                          true),
                    ),
                  );
                }).toList(),
              ),
            ),

            // 数据行
            ...rows.map((row) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(columns.length, (index) {
                  // 确保不越界
                  final cell =
                      index < row.length ? row[index] : AITableCellData('');

                  return Expanded(
                    child: Container(
                      padding: EdgeInsets.all(8.sp),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.5),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: _buildRichTableCell(
                          cell.content, preferredStyle, false),
                    ),
                  );
                }),
              );
            }),
          ],
        ),
      ),
    );
  }

  // 构建富表格单元格 - 支持公式和特殊格式
// 修改AITableBuilder中的_buildRichTableCell方法
  Widget _buildRichTableCell(String content, TextStyle? style, bool isHeader) {
    content = content.replaceAll('⏎', '\n');

    // 检查是否包含我们保护的LaTeX标记
    if (content.contains('⏣LATEX⏣') || content.contains('⏣BLOCKLATEX⏣')) {
      return _buildProtectedLatexCell(content, style);
    }

    return Text(content, style: style, textAlign: TextAlign.center);
  }

  Widget _buildProtectedLatexCell(String content, TextStyle? style) {
    final parts = content.split(RegExp(r'⏣(LATEX|BLOCKLATEX)⏣'));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: parts.map((part) {
        if (part.endsWith('⏣')) {
          final encoded = part.substring(0, part.length - 1);
          try {
            final tex = utf8.decode(base64Decode(encoded));
            return _LatexElementBuilder()._buildMathWidget(tex, style);
          } catch (e) {
            return Text(encoded, style: style);
          }
        } else if (part.isNotEmpty) {
          return Text(part, style: style);
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }
}

/// ===============================
/// 辅助类
/// ===============================

// 表格列数据
class TableColumn {
  final String content;

  TableColumn({required this.content});
}

// 表格单元格数据
class AITableCellData {
  final String content;

  AITableCellData(this.content);

  factory AITableCellData.fromElement(md.Element element) {
    return AITableCellData(element.textContent);
  }
}

// 新增LaTeX语法识别
class _LatexSyntax extends md.InlineSyntax {
  _LatexSyntax() : super(r'⏣(LATEX|BLOCKLATEX)⏣(.+?)⏣');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final content = utf8.decode(base64Decode(match.group(2)!));
    parser.addNode(md.Element.text('latex', content));
    return true;
  }
}

// 新增LaTeX元素构建器
class _LatexElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? style) {
    final texContent = element.textContent;
    return _buildMathWidget(
      _processLatexContent(texContent), // 完整处理流程
      style,
    );
  }

  String _processLatexContent(String texContent) {
    return texContent
        .replaceAll(RegExp(r'^\\[(\[]|\\[)\]]$|^\$+|\$+$'), '')
        .trim();
  }

  Widget _buildMathWidget(String rawLatex, TextStyle? style) {
    try {
      // 可横向滚动
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Math.tex(
          rawLatex,
          textStyle: style,
          mathStyle: _getMathStyle(rawLatex),
          onErrorFallback: (error) {
            debugPrint('LaTeX渲染错误: $error\n处理后的内容: $rawLatex');
            return Text(rawLatex, style: style?.copyWith(color: Colors.red));
          },
        ),
      );
    } catch (e) {
      return Text(rawLatex, style: style?.copyWith(color: Colors.red));
    }
  }

  MathStyle _getMathStyle(String rawLatex) {
    return rawLatex.contains('\n') ? MathStyle.display : MathStyle.text;
  }
}
