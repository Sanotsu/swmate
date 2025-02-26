import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mime/mime.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../../../common/utils/tools.dart';

abstract class MimeMediaPreviewBase extends StatelessWidget {
  final File file;
  final VoidCallback? onDelete;

  const MimeMediaPreviewBase({
    super.key,
    required this.file,
    this.onDelete,
  });

  // 子类需要实现的方法
  Widget buildPreviewContent();
  String get title;

  // 分享媒体
  Future<void> _shareMedia(BuildContext context) async {
    try {
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: '思文AI助手',
      );

      if (result.status == ShareResultStatus.success) {
        EasyLoading.showSuccess('分享成功!');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分享失败: $e')),
      );
    }
  }

  // 删除媒体
  Future<void> _deleteMedia(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个文件吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Android11+ 移动到垃圾桶，低于11的会报错
      // var list = await PhotoManager.editor.android.moveToTrash([asset]);
      final list = [1];
      // 实际删除成功后，才执行传入的删除回调
      if (list.isNotEmpty) {
        EasyLoading.showSuccess('删除成功!');
        onDelete?.call();
      }

      if (!context.mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareMedia(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteMedia(context),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showFileSimpleInfoDialog(file, context),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(5.sp),
        child: buildPreviewContent(),
      ),
    );
  }
}

// 显示文件简单信息弹窗
showFileSimpleInfoDialog(File asset, BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Text('详情'),
      content: SingleChildScrollView(
        child: SizedBox(
          height: 250.sp,
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.symmetric(horizontal: 5.sp),
            // itemExtent: 50.sp,
            children: <Widget>[
              ListTile(
                title: const Text("文件名称"),
                subtitle: Text(
                  asset.path.split('/').last,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                dense: true,
              ),
              ListTile(
                title: const Text("文件类型"),
                subtitle: Text(lookupMimeType(asset.path) ?? '未知'),
                dense: true,
              ),
              ListTile(
                title: const Text("文件大小"),
                subtitle: Text(
                  formatFileSize(asset.lengthSync()),
                  overflow: TextOverflow.ellipsis,
                ),
                dense: true,
              ),
              ListTile(
                title: const Text("文件路径"),
                subtitle: Text(
                  asset.path.replaceAll("/storage/emulated/0", "内部存储"),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                dense: true,
              ),
              ListTile(
                title: const Text("最后修改时间"),
                subtitle: Text(
                  asset.lastModifiedSync().toString().substring(0, 19),
                  overflow: TextOverflow.ellipsis,
                ),
                dense: true,
              ),
              ListTile(
                title: const Text("最后访问时间"),
                subtitle: Text(
                  asset.lastAccessedSync().toString().substring(0, 19),
                  overflow: TextOverflow.ellipsis,
                ),
                dense: true,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('确定'),
        ),
      ],
    ),
  );
}
