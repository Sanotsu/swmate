import 'dart:io';

import 'package:docx_to_text/docx_to_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_charset_detector/flutter_charset_detector.dart';
import 'package:logger/logger.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

var l = Logger();

/// 从文件中读完文本
Future<String?> readFileContent(PlatformFile file) async {
  try {
    switch (file.extension) {
      case 'txt':
        // return File(file.path!).readAsString();

        // // 1  目前只看utf8的
        // var bytes = File(file.path!).readAsBytesSync();
        // var aa = utf8.decode(bytes, allowMalformed: true);
        // l.i(aa);
        // return aa;

        // // 2  使用预设的几种编码来转码(但utf8的文本latin1也能解，只不过乱码而已)
        // final content = File(file.path!).readAsBytesSync();

        // // 尝试不同的编码格式
        // // 2024-07-22 目前好像就这几种默认的
        // List<Encoding> encodings = [
        //   utf8,
        //   ascii,
        //   latin1,
        // ];

        // String decodedContent = "";
        // for (var encoding in encodings) {
        //   try {
        //     decodedContent = encoding.decode(content);
        //     print('Successfully decoded using ${encoding.name}');
        //     print(decodedContent);
        //     break;
        //   } catch (e) {
        //     print('Failed to decode using ${encoding.name}: $e');
        //   }
        // }

        // if (decodedContent.isEmpty) {
        //   print('Failed to decode the file with all supported encodings.');
        // }

        // return decodedContent;

        // 3 使用第三方库来自动识别和转换
        var bytes = File(file.path!).readAsBytesSync();
        DecodingResult result = await CharsetDetector.autoDecode(bytes);
        debugPrint(result.charset); // => e.g. 'SHIFT_JIS'
        debugPrint(result.string); // => e.g. '日本語'

        return result.string;

      case 'pdf':
        final pdfDocument =
            PdfDocument(inputBytes: File(file.path!).readAsBytesSync());

        // 从文档中提取文本行集合
        final textLines = PdfTextExtractor(pdfDocument).extractTextLines();

        var text = "";
        for (var line in textLines) {
          text += line.text;
        }

        pdfDocument.dispose();
        return text;
      case 'docx':
        final bytes = await File(file.path!).readAsBytes();
        final text = docxToText(bytes);

        l.i('DOCX 解析出来的内容：$text');

        return text;
      // 2024-07-20 如果上层使用了compute来后台处理，这个插件就会报错：
      // Bad state: The BackgroundIsolateBinaryMessenger.instance value is invalid until
      // BackgroundIsolateBinaryMessenger.ensureInitialized is executed.
      // 为了能正常显示loading圈，就暂时不支持这个doc文档的解析了
      // case 'doc':
      //   String? extractedText =
      //       await DocText().extractTextFromDoc(file.path!);

      //   if (extractedText != null) {
      //     l.i('DOC解析出来的内容：$extractedText');

      //     return extractedText;
      //   } else {
      //     l.e('Failed to extract text from document.');
      //     return null;
      //   }

      default:
        return null;
    }
  } catch (e) {
    l.e("解析文档出错:${e.toString()}");
    rethrow;
  }
}

///
/// 如果像上面把文本读取放在一个函数内，可能出现不同库的一些其他问题，比如
///    2024-07-20 如果上层使用了compute来后台处理，这个插件就会报错：
///      Bad state: The BackgroundIsolateBinaryMessenger.instance value is invalid until
///      BackgroundIsolateBinaryMessenger.ensureInitialized is executed.
/// 所以根据分类，有些用上compute，有些用不上，所以拆开来
///
Future<String> extractTextFromPdf(String path) async {
  final pdfDocument = PdfDocument(inputBytes: File(path).readAsBytesSync());

  // 实测直接获取文档全部内容，可能会挤在一起，单词都无法区分开了
  // String text = PdfTextExtractor(pdfDocument).extractText();

  // 从文档中提取文本行集合
  final textLines = PdfTextExtractor(pdfDocument).extractTextLines();

  var text = "";
  for (var line in textLines) {
    text += line.text;
  }

  pdfDocument.dispose();
  return text;
}
