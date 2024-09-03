import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:htmltopdfwidgets/htmltopdfwidgets.dart' as htp;
import 'package:intl/intl.dart';
import 'package:markdown/markdown.dart' as md;

import '../../../common/constants.dart';
import '../../../common/utils/tools.dart';

///
/// 使用插件先把markdown文本转html(这比之前使用parse转为List<Node>处理更方便)
/// 然后直接用新部件把html转为pdf
///   由于本地缓存的图片，在html字符串中直接加<img>标签无效，所以图片添加和之前一样
/// 这个方法多级列表不会被合到一起去
///

Future<void> saveMarkdownHtmlAsPdf(String mdString, File imageFile) async {
  var mdHtml = md.markdownToHtml(mdString);

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

    final newpdf = htp.Document(
      pageMode: htp.PdfPageMode.fullscreen,
      theme: htp.ThemeData.withFont(
        // 谷歌字体不一定能够访问,但肯定是联网下载，且存在内存中，下一次导出会需要重新下载
        // https://github.com/DavBfr/dart_pdf/wiki/Fonts-Management
        // base: await PdfGoogleFonts.notoSerifHKRegular(),
        // bold: await PdfGoogleFonts.notoSerifHKBold(),
        // 但是使用知道的本地字体，会增加app体积
        base: htp.Font.ttf(await rootBundle.load("assets/MiSans-Regular.ttf")),
        fontFallback: [
          htp.Font.ttf(await rootBundle.load('assets/MiSans-Regular.ttf'))
        ],
      ),
    );
    List<htp.Widget> widgets = await htp.HTMLToPdf().convert(mdHtml);
    newpdf.addPage(
      htp.MultiPage(
        maxPages: 200,
        build: (context) {
          return [
            // 最上方显示图片
            htp.Center(
              child: htp.SizedBox(
                height: 400.sp,
                child: htp.Image(htp.MemoryImage(imageFile.readAsBytesSync())),
              ),
            ),
            htp.Center(child: htp.Text("原图片如上")),
            htp.SizedBox(height: 20.sp),
            ...widgets,
          ];
        },
        // 页首内容
        header: (context) {
          return htp.Header(
            level: 0,
            child: htp.Row(
              mainAxisAlignment: htp.MainAxisAlignment.spaceBetween,
              children: [
                htp.Text('本文件由<swmate>自动生成'),
                htp.Text(DateFormat.yMMMEd().format(DateTime.now())),
              ],
            ),
          );
        },
        // 页脚内容
        footer: (context) {
          return htp.Container(
            alignment: htp.Alignment.centerRight,
            margin: htp.EdgeInsets.only(top: 10.sp),
            child: htp.Column(
              children: [
                htp.Divider(height: 1.sp),
                htp.Row(
                  mainAxisAlignment: htp.MainAxisAlignment.spaceBetween,
                  children: [
                    htp.Text('https://github.com/Sanotsu/swmate'),
                    htp.Text(
                      '第 ${context.pageNumber} / ${context.pagesCount} 页',
                      style: const htp.TextStyle(fontSize: 12),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
    await file.writeAsBytes(await newpdf.save());

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
