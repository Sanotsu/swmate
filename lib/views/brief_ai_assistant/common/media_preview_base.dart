import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'show_media_info_dialog.dart';

abstract class MediaPreviewBase extends StatelessWidget {
  final AssetEntity asset;
  final VoidCallback? onDelete;

  const MediaPreviewBase({
    super.key,
    required this.asset,
    this.onDelete,
  });

  // 子类需要实现的方法
  Widget buildPreviewContent();
  String get title;

  // 分享媒体
  Future<void> _shareMedia(BuildContext context) async {
    try {
      final file = await asset.file;
      if (file == null) return;

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
      var list = await PhotoManager.editor.android.moveToTrash([asset]);

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
            onPressed: () => showMediaInfoDialog(asset, context),
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
