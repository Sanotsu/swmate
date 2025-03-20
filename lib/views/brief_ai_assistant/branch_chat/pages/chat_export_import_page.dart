import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:swmate/common/components/tool_widget.dart';
import '../../../../models/brief_ai_tools/chat_branch/chat_branch_message.dart';
import '../../../../models/brief_ai_tools/chat_branch/chat_export_data.dart';
import '../../../../models/brief_ai_tools/chat_branch/branch_store.dart';

class ChatExportImportPage extends StatefulWidget {
  const ChatExportImportPage({super.key});

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
        title: Text('分支对话导出导入'),
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
                  onPressed: isExporting ? null : _handleExport,
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
              '将所有对话记录导出为JSON文件，包括分支结构和媒体文件路径。',
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
                  onPressed: isImporting ? null : _handleImport,
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
              '从JSON文件导入对话记录，将合并到现有对话中。',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
            SizedBox(height: 16.sp),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExport() async {
    setState(() => isExporting = true);

    try {
      // 1. 获取所有会话数据
      final store = await BranchStore.create();
      final sessions = store.sessionBox.getAll();

      // 2. 转换为导出格式
      final exportData = ChatExportData(
        sessions: sessions
            .map((session) => ChatSessionExport.fromSession(session))
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

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('导出成功：${file.path}')),
          );
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

  Future<void> _handleImport() async {
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
        final jsonString = await file.readAsString();
        final jsonData = json.decode(jsonString);

        // 3. 解析数据
        final importData = ChatExportData.fromJson(jsonData);

        // 4. 导入到数据库
        final store = await BranchStore.create();

        // 获取现有会话列表
        final existingSessions = store.sessionBox.getAll();
        int importedCount = 0;
        int skippedCount = 0;

        // 遍历要导入的会话
        for (final sessionExport in importData.sessions) {
          // 检查是否存在相同的会话
          final isExisting = existingSessions.any((existing) {
            return existing.createTime.toIso8601String() ==
                    sessionExport.createTime.toIso8601String() &&
                existing.title == sessionExport.title;
          });

          // 如果会话已存在，跳过
          if (isExisting) {
            skippedCount++;
            continue;
          }

          // 创建新会话(注意，因为用于判断是否重复的逻辑里面有创建时间，所以这里需要传入创建时间)
          // 不传入更新时间，因为导入会话的消息列表时，会更新会话的更新时间
          final session = await store.createSession(
            sessionExport.title,
            llmSpec: sessionExport.llmSpec,
            modelType: sessionExport.modelType,
            createTime: sessionExport.createTime,
          );

          // 创建消息映射表(用于建立父子关系)
          final messageMap = <String, ChatBranchMessage>{};

          // 按深度排序消息，确保父消息先创建
          final sortedMessages = sessionExport.messages.toList()
            ..sort((a, b) => a.depth.compareTo(b.depth));

          // 创建消息
          for (final msgExport in sortedMessages) {
            final parentMsg = msgExport.parentMessageId != null
                ? messageMap[msgExport.parentMessageId]
                : null;

            // 因为对会话记录添加消息也是修改了会话，所以导入会话记录成功后，会话的修改时间也会更新
            final message = await store.addMessage(
              session: session,
              content: msgExport.content,
              role: msgExport.role,
              parent: parentMsg,
              reasoningContent: msgExport.reasoningContent,
              thinkingDuration: msgExport.thinkingDuration,
              modelLabel: msgExport.modelLabel,
              branchIndex: msgExport.branchIndex,
              contentVoicePath: msgExport.contentVoicePath,
              imagesUrl: msgExport.imagesUrl,
              videosUrl: msgExport.videosUrl,
            );

            messageMap[msgExport.messageId] = message;
          }

          importedCount++;
        }

        if (!mounted) return;

        // 根据导入结果显示不同的提示
        if (importedCount > 0) {
          String message = '成功导入 $importedCount 个会话';
          if (skippedCount > 0) {
            message += '，跳过 $skippedCount 个重复会话';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        } else if (skippedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('所有会话($skippedCount 个)均已存在，未导入任何内容')),
          );
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
}
