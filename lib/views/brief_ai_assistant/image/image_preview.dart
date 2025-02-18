import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'show_media_info_dialog.dart';

class ImagePreviewScreen extends StatelessWidget {
  final AssetEntity asset;
  final VoidCallback? onDelete;

  const ImagePreviewScreen({
    super.key,
    required this.asset,
    this.onDelete,
  });

  // 分享图片
  Future<void> _shareImage(BuildContext context) async {
    try {
      final file = await asset.file;
      if (file == null) return;

      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: '思文AI绘图',
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

  // 删除图片
  Future<void> _deleteImage(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这张图片吗？'),
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
      // 实际从设备删除
      // var list = await PhotoManager.editor.deleteWithIds([asset.id]);

      // Android11+ 移动到垃圾桶，低于11的会报错
      var list = await PhotoManager.editor.android.moveToTrash([asset]);

      // 实际删除成功后，才执行传入的删除回调
      if (list.isNotEmpty) {
        EasyLoading.showSuccess('删除成功!');
        onDelete?.call();
      }

      if (!context.mounted) return;
      // 删除后返回
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
        title: const Text('图片预览'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareImage(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteImage(context),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showMediaInfoDialog(asset, context),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(5.sp),
        child: InteractiveViewer(
          child: Center(
            child: AssetEntityImage(
              asset,
              isOriginal: true,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
