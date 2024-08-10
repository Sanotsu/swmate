// ignore_for_file: avoid_print

import 'package:logger/logger.dart';

class NoLimitLogPrinter extends LogPrinter {
  final LogPrinter _defaultPrinter;

  NoLimitLogPrinter(this._defaultPrinter);

  @override
  List<String> log(LogEvent event) {
    final lines = _defaultPrinter.log(event);
    return lines.map((line) => line.replaceAll('\n', ' ')).toList();
  }
}

class NoLimitLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      print(line); // 使用 print 输出日志，没有长度限制
    }
  }
}

var logger = Logger(
  output: NoLimitLogOutput(), // 使用自定义的 LogOutput
  printer: NoLimitLogPrinter(PrettyPrinter()), // 使用自定义的 LogPrinter
);
