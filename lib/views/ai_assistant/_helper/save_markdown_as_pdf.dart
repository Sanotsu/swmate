// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:intl/intl.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf;

import '../../../common/constants.dart';
import '../../../common/utils/tools.dart';

///
/// 将md文本转为pdf并下载
/// 1 首先，预览的md和转换后的pdf可能格式会有一些出入
///   因为pdf是解析md文件，然后一条一条重新绘制的，字体大小也是手动确定的
/// 2 其次，解析md得到的node，不一定和原版md文件就能一一对应上
///   比如第2级列表在pdf解析是会合并到第1级去
///

Future<void> saveMarkdownAsPdf(String mdString, File imageFile) async {
  // print("传入pdf的markdown文本 --$mdString");

  final pdfDoc = pdf.Document(
    pageMode: PdfPageMode.fullscreen,
    theme: pdf.ThemeData.withFont(
      // 谷歌字体不一定能够访问,但肯定是联网下载，且存在内存中，下一次导出会需要重新下载
      // https://github.com/DavBfr/dart_pdf/wiki/Fonts-Management
      // base: await PdfGoogleFonts.notoSerifHKRegular(),
      // bold: await PdfGoogleFonts.notoSerifHKBold(),
      // 但是使用知道的本地字体，会增加app体积
      base: pdf.Font.ttf(await rootBundle.load("assets/MiSans-Regular.ttf")),
      fontFallback: [
        pdf.Font.ttf(await rootBundle.load('assets/MiSans-Regular.ttf'))
      ],
    ),
  );

  // ??? 2024-07-18 实测这里没法正确处理多级列表，会把下一级的合到第一级去
  final List<md.Node> nodes = md.Document().parse(mdString);
  final List<pdf.Widget> widgets = nodes.map((node) {
    // print("node--$node  --${(node as md.Element).tag} --${node.textContent}");
    return _buildPdfWidget(node);
  }).toList();

  // 这个只能构建单页PDF
  // pdfDoc.addPage(
  //   pdf.Page(
  //     pageFormat: PdfPageFormat.a4,
  //     build: (pdf.Context context) {
  //       return pdf.Column(
  //         crossAxisAlignment: pdf.CrossAxisAlignment.start,
  //         children: [
  //           pdf.Center(
  //             // 上方显示图片
  //             child: pdf.Image(
  //               pdf.MemoryImage(
  //                 imageFile.readAsBytesSync(),
  //               ),
  //             ),
  //           ),
  //           pdf.SizedBox(height: 20),
  //           // 下面显示翻译后的文本
  //           ...widgets,
  //         ],
  //       );
  //     },
  //   ),
  // );

  // 这个可以构建多页PDF
  pdfDoc.addPage(
    pdf.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return [
          // 上方显示图片
          pdf.Center(
            child: pdf.SizedBox(
              height: 400.sp,
              child: pdf.Image(
                pdf.MemoryImage(imageFile.readAsBytesSync()),
              ),
            ),
          ),
          pdf.Center(child: pdf.Text("原图片如上")),
          pdf.SizedBox(height: 20),
          ...widgets,
        ];
      },
      // 页首内容
      header: (context) {
        return pdf.Header(
          level: 0,
          child: pdf.Row(
            mainAxisAlignment: pdf.MainAxisAlignment.spaceBetween,
            children: [
              pdf.Text('本文件由<swmate>自动生成'),
              pdf.Text(DateFormat.yMMMEd().format(DateTime.now())),
            ],
          ),
        );
      },
      // 页脚内容
      footer: (context) {
        return pdf.Container(
          alignment: pdf.Alignment.centerRight,
          margin: pdf.EdgeInsets.only(top: 10.sp),
          child: pdf.Column(
            children: [
              pdf.Divider(height: 1.sp),
              pdf.Row(
                mainAxisAlignment: pdf.MainAxisAlignment.spaceBetween,
                children: [
                  pdf.Text('https://github.com/Sanotsu/swmate'),
                  pdf.Text(
                    '第 ${context.pageNumber} / ${context.pagesCount} 页',
                    style: const pdf.TextStyle(fontSize: 12),
                  ),
                ],
              )
            ],
          ),
        );
      },
    ),
  );

  /// 这个有个打印预览的步骤
  // await Printing.layoutPdf(
  //   onLayout: (PdfPageFormat format) async => pdfDoc.save(),
  //   // 设置默认文件名
  //   name: '保存图片翻译文档-${DateTime.now().microsecondsSinceEpoch}.pdf',
  // );

  /// 这个直接下载到设备指定文件夹
  try {
    // 首先获取设备外部存储管理权限
    if (!(await requestStoragePermission())) {
      return EasyLoading.showError("未授权访问设备外部存储，无法保存文档");
    }

    // 翻译保存的文本，放到设备外部存储固定位置，不存在文件夹则先创建
    if (!await SAVE_IMAGE_INTERPRET_DIR.exists()) {
      await SAVE_IMAGE_INTERPRET_DIR.create(recursive: true);
    }
    // 将字符串直接保存为指定路径文件
    final file = File(
      '${SAVE_IMAGE_INTERPRET_DIR.path}/保存图片解读文档-${DateTime.now().microsecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdfDoc.save());

    // 保存成功/失败弹窗提示
    EasyLoading.showSuccess(
      '文件已保存到 ${file.path}',
      duration: const Duration(seconds: 5),
    );
  } catch (e) {
    return EasyLoading.showError(
      "保存文档失败: ${e.toString()}",
      duration: const Duration(seconds: 5),
    );
  }
}

pdf.Widget _buildPdfWidget(md.Node node, [int indent = 0]) {
  if (node is md.Element) {
    switch (node.tag) {
      case 'p':
        return pdf.Padding(
          padding: pdf.EdgeInsets.only(bottom: 10.sp),
          child: buildNodeText(node.textContent, 12.sp),
        );
      case 'h1':
        return buildNodeText(node.textContent, 24.sp, isBold: true);
      case 'h2':
        return buildNodeText(node.textContent, 22.sp, isBold: true);
      case 'h3':
        return buildNodeText(node.textContent, 20.sp, isBold: true);
      case 'h4':
        return buildNodeText(node.textContent, 18.sp, isBold: true);
      case 'h5':
        return buildNodeText(node.textContent, 16.sp, isBold: true);
      case 'h6':
        return buildNodeText(node.textContent, 14.sp, isBold: true);
      case 'ul':
      case 'ol':
        return pdf.Column(
          crossAxisAlignment: pdf.CrossAxisAlignment.start,
          children: node.children!
              .map((child) => _buildPdfWidget(child, indent + 1))
              .toList(),
        );
      case 'li':
        return pdf.Row(
          crossAxisAlignment: pdf.CrossAxisAlignment.start,
          children: [
            buildNodeText('· ' * indent, 12.sp),
            pdf.Expanded(
              child: buildNodeText(node.textContent, 12.sp),
            ),
          ],
        );
      case 'pre':
        return pdf.Container(
          width: double.infinity,
          padding: const pdf.EdgeInsets.all(10),
          color: PdfColors.grey100,
          child: buildNodeText(
            // 代码中有html转义符，需要先转回来
            HtmlUnescape().convert(node.textContent),
            12.sp,
            font: pdf.Font.courier(),
          ),
        );
      case 'code':
        return buildNodeText(
          HtmlUnescape().convert(node.textContent),
          12.sp,
          font: pdf.Font.courier(),
        );
      default:
        return buildNodeText(node.textContent, 12.sp);
    }
  } else if (node is md.Text) {
    return buildNodeText(node.text, 12.sp);
  }
  return pdf.SizedBox.shrink();
}

buildNodeText(
  String text,
  double fontSize, {
  bool? isBold,
  pdf.Font? font,
}) =>
    pdf.Text(
      text,
      style: pdf.TextStyle(
        fontSize: fontSize,
        fontWeight: isBold == true ? pdf.FontWeight.bold : null,
        font: font,
      ),
    );
