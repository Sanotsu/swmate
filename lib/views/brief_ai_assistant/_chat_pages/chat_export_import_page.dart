import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:swmate/common/components/tool_widget.dart';
import '../../../../models/brief_ai_tools/branch_chat/branch_chat_export_data.dart';
import '../../../../models/brief_ai_tools/branch_chat/branch_store.dart';
import '../../../models/brief_ai_tools/character_chat/character_store.dart';

class ChatExportImportPage extends StatefulWidget {
  const ChatExportImportPage({super.key, required this.chatType});

  final String chatType;

  @override
  State<ChatExportImportPage> createState() => _ChatExportImportPageState();
}

class _ChatExportImportPageState extends State<ChatExportImportPage> {
  bool isExporting = false;
  bool isImporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.chatType == 'branch' ? '分支对话' : '角色对话'}导出导入'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildExportSection(),
            SizedBox(height: 32.sp),
            _buildImportSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('导出对话', style: TextStyle(fontSize: 18.sp)),
                Spacer(),
                ElevatedButton.icon(
                  onPressed: isExporting
                      ? null
                      : (widget.chatType == 'branch'
                          ? _handleBranchChatExport
                          : _handleCharacterChatExport),
                  icon: isExporting
                      ? SizedBox(
                          width: 20.sp,
                          height: 20.sp,
                          child: const CircularProgressIndicator(),
                        )
                      : const Icon(Icons.file_download),
                  label: Text(isExporting ? '导出中...' : '导出对话'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.sp),
            Text(
              '将所有对话记录导出为JSON文件。',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
            SizedBox(height: 16.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildImportSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('导入对话', style: TextStyle(fontSize: 18.sp)),
                Spacer(),
                ElevatedButton.icon(
                  onPressed: isImporting
                      ? null
                      : (widget.chatType == 'branch'
                          ? _handleBranchChatImport
                          : _handleCharacterChatImport),
                  icon: isImporting
                      ? SizedBox(
                          width: 20.sp,
                          height: 20.sp,
                          child: const CircularProgressIndicator(),
                        )
                      : const Icon(Icons.file_upload),
                  label: Text(isImporting ? '导入中...' : '导入对话'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.sp),
            Text(
              '从JSON文件导入对话记录，并合并到现有对话中。',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
            SizedBox(height: 16.sp),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBranchChatExport() async {
    setState(() => isExporting = true);

    try {
      // 1. 获取所有会话数据
      final store = await BranchStore.create();
      final sessions = store.sessionBox.getAll();

      // 2. 转换为导出格式
      final exportData = BranchChatExportData(
        sessions: sessions
            .map((session) => BranchChatSessionExport.fromSession(session))
            .toList(),
      );

      // 3. 获取下载目录并创建文件
      final fileName = '高级助手对话记录_${DateTime.now().millisecondsSinceEpoch}.json';

      try {
        // 先尝试使用 FilePicker 选择保存位置
        final result = await FilePicker.platform.getDirectoryPath(
          dialogTitle: '选择保存位置',
        );

        if (result != null) {
          final file = File('$result${Platform.pathSeparator}$fileName');
          await file.writeAsString(
            const JsonEncoder.withIndent('  ').convert(exportData.toJson()),
          );

          EasyLoading.showSuccess("导出成功：${file.path}");
        }
      } catch (e) {
        if (!mounted) return;
        commonExceptionDialog(context, '选择目录失败', '选择目录失败: $e');

        // 如果选择目录失败，则使用默认下载目录
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final downloadsDir = Directory('${directory.path}/Downloads');
          if (!downloadsDir.existsSync()) {
            downloadsDir.createSync(recursive: true);
          }

          final file =
              File('${downloadsDir.path}${Platform.pathSeparator}$fileName');
          await file.writeAsString(
            const JsonEncoder.withIndent('  ').convert(exportData.toJson()),
          );

          if (!mounted) return;
          commonHintDialog(context, '导出成功', '导出成功：${file.path}');
        } else {
          throw Exception('无法获取存储目录');
        }
      }
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, '导出失败', '导出失败: $e');
    } finally {
      if (mounted) {
        setState(() => isExporting = false);
      }
    }
  }

  // 导出所有会话历史
  Future<void> _handleCharacterChatExport() async {
    setState(() => isExporting = true);

    try {
      // 先让用户选择保存位置
      final directoryResult = await FilePicker.platform.getDirectoryPath();
      if (directoryResult == null) return; // 用户取消了选择

      final store = CharacterStore();
      final filePath = await store.exportAllSessionsHistory(
        customPath: directoryResult,
      );

      if (!mounted) return;

      commonHintDialog(context, '导出会话历史', '所有会话历史已导出到: $filePath');
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, '导出会话历史', '导出失败: $e');
    } finally {
      if (mounted) {
        setState(() => isExporting = false);
      }
    }
  }

  Future<void> _handleBranchChatImport() async {
    setState(() => isImporting = true);

    try {
      // 1. 选择文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        // 2. 读取文件内容
        final file = File(result.files.single.path!);
        final store = await BranchStore.create();
        final importResult = await store.importSessionHistory(file);

        final importedCount = importResult.importedCount;
        final skippedCount = importResult.skippedCount;

        if (!mounted) return;

        // 根据导入结果显示不同的提示
        if (importedCount > 0) {
          String message = '成功导入 $importedCount 个会话';
          if (skippedCount > 0) {
            message += '，跳过 $skippedCount 个重复会话';
          }
          EasyLoading.showInfo(message);
        } else if (skippedCount > 0) {
          EasyLoading.showInfo('所有会话($skippedCount 个)均已存在，未导入任何内容');
        }
      }
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, '导入失败', e.toString());
    } finally {
      if (mounted) {
        setState(() => isImporting = false);
      }
    }
  }

  // 导入会话历史
  Future<void> _handleCharacterChatImport() async {
    setState(() => isImporting = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path;
      if (filePath == null) return;

      final store = CharacterStore();
      final importResult = await store.importSessionHistory(filePath);

      if (!mounted) return;

      String message;
      if (importResult.importedSessions > 0) {
        message = '成功导入 ${importResult.importedSessions} 个会话';
        if (importResult.skippedSessions > 0) {
          message += '，跳过 ${importResult.skippedSessions} 个已存在的会话';
        }
      } else {
        message = '没有导入任何会话，所有会话已存在';
      }

      commonHintDialog(context, '导入会话历史', message);
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, '导入会话历史', '导入失败: $e');
    } finally {
      if (mounted) {
        setState(() => isImporting = false);
      }
    }
  }
}
