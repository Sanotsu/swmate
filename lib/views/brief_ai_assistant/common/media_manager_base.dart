import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mime/mime.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../../../common/components/tool_widget.dart';
import '../../../common/constants.dart';
import 'mime_media_manager_base.dart';

abstract class MediaManagerBase extends StatefulWidget {
  const MediaManagerBase({super.key});
}

abstract class MediaManagerBaseState<T extends MediaManagerBase>
    extends State<T> {
  // 媒体列表
  List<AssetEntity> mediaList = [];
  // 选中的媒体
  final Set<AssetEntity> selectedMedia = {};
  // 是否加载中
  bool isLoading = true;
  // 是否多选模式
  bool isMultiSelectMode = false;

  // 子类需要实现的方法
  String get title;
  RequestType get mediaType;
  Widget buildPreviewScreen(AssetEntity asset);

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  // 加载媒体文件
  Future<void> _loadMedia() async {
    setState(() => isLoading = true);

    try {
      // 请求权限
      final permitted = await PhotoManager.requestPermissionExtend();

      debugPrint('请求权限: ${permitted.hasAccess}');

      if (!permitted.hasAccess) {
        throw Exception('没有访问权限');
      }

      // 获取所有相册
      final albums = await PhotoManager.getAssetPathList(
        type: mediaType,
        // 移除这个过滤器，让它每次都重新扫描
        filterOption: FilterOptionGroup(
          // containsPathModified: true,
          orders: [OrderOption(type: OrderOptionType.createDate, asc: false)],
        ),
      );

      // for (var element in albums) {
      //   print("相册: ${element.name}");
      // }

      // 查找AI生成的媒体目录
      AssetPathEntity? aiMediaPath;
      List<AssetEntity> media = [];
      try {
        aiMediaPath = albums.firstWhere(
          (entity) => entity.name == getAIMediaDirName(),
        );

        // 获取AI生成媒体文件列表
        media = await aiMediaPath.getAssetListRange(start: 0, end: 1000);

        // 设置媒体列表
        if (mounted && media.isNotEmpty) {
          setState(() => mediaList = media);
        }
      } catch (e) {
        // if (!mounted) return;
        // commonExceptionDialog(context, title, "AI生成目录为空");
        return;
      }

      ///
      /// 测试
      /// 2025-02-21 测试发现，实际的文件数量和photo manager获取的文件数量不一致，原因未知
      ///
      final files = await classifyFilesByMimeType(getAIMediaDir());

      List<File> mimeFiles = mediaType == RequestType.image
          ? files[CusMimeCls.IMAGE]!
          : mediaType == RequestType.video
              ? files[CusMimeCls.VIDEO]!
              : [];

      debugPrint('mimeFiles中数量: ${mimeFiles.length}; media中数量:${media.length}');

      // 找出存在于 mimeFiles 中，但不存在于 media 中的文件
      final notInMedia = mimeFiles
          .where((image) =>
              !media.any((m) => m.title == image.path.split('/').last))
          .toList();

      for (var i = 0; i < notInMedia.length; i++) {
        final mimeType = lookupMimeType(
          notInMedia[i].path,
          headerBytes: await notInMedia[i].openRead(0, 512).first,
        );

        debugPrint(
          '存在于 mimeFiles 中，但不存在于 media 中的文件 $i: mimeType: $mimeType; 路径: ${notInMedia[i].path}',
        );
      }

      // 找出存在于 media 中，但不存在于 mimeFiles 中的文件
      final notInMimeFiles = media
          .where(
              (m) => !mimeFiles.any((i) => i.path.split('/').last == m.title))
          .toList();

      for (var i = 0; i < notInMimeFiles.length; i++) {
        debugPrint(
          '存在于 media 中，但不存在于 mimeFiles 中的文件 $i: ${notInMimeFiles[i].title}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      // print("查询AI绘图历史记录失败: $e");
      commonExceptionDialog(context, "解析AI生成目录失败", e.toString());
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // 添加刷新功能
  Future<void> refreshMediaList() async {
    await _loadMedia();
  }

  // 获取AI生成媒体目录
  String getAIMediaDir() {
    switch (mediaType) {
      case RequestType.image:
        return LLM_IG_DIR_V2.path;
      case RequestType.video:
        return LLM_VG_DIR_V2.path;
      default:
        return "";
    }
  }

  // 获取AI生成媒体目录名称
  String getAIMediaDirName() {
    return getAIMediaDir().split("/").last;
  }

  // 分享选中的媒体
  Future<void> _shareSelectedMedia() async {
    try {
      final files = await Future.wait(selectedMedia.map((m) => m.file));

      final xFiles =
          files.where((f) => f != null).map((f) => XFile(f!.path)).toList();

      if (xFiles.isEmpty) return;

      final result = await Share.shareXFiles(
        xFiles,
        text: '思文智能助手',
      );

      if (result.status == ShareResultStatus.success) {
        EasyLoading.showSuccess('分享成功!');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分享失败: $e')),
      );
    }
  }

  // 删除选中的媒体
  Future<void> _deleteSelectedMedia() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的${selectedMedia.length}个文件吗？'),
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
      // Android11+ 移动到垃圾桶
      final list = await PhotoManager.editor.android.moveToTrash(
        selectedMedia.toList(),
      );

      if (list.isNotEmpty && mounted) {
        setState(() {
          mediaList.removeWhere(selectedMedia.contains);
          selectedMedia.clear();
          isMultiSelectMode = false;
        });
        EasyLoading.showSuccess('删除成功!');
      }
    } catch (e) {
      if (!mounted) return;
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
          // 添加刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshMediaList,
          ),
          if (isMultiSelectMode) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareSelectedMedia,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelectedMedia,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  isMultiSelectMode = false;
                  selectedMedia.clear();
                });
              },
            ),
          ],
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : mediaList.isEmpty
              ? const Center(child: Text('暂无内容'))
              : GridView.builder(
                  padding: EdgeInsets.all(8.sp),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8.sp,
                    crossAxisSpacing: 8.sp,
                  ),
                  itemCount: mediaList.length,
                  itemBuilder: (context, index) {
                    final asset = mediaList[index];
                    final isSelected = selectedMedia.contains(asset);

                    return buildMediaGridItem(asset, isSelected);
                  },
                ),
    );
  }

  // 构建媒体网格
  Widget buildMediaGrid() {
    if (mediaList.isEmpty) {
      return const Center(child: Text('暂无媒体文件'));
    }

    return GridView.builder(
      padding: EdgeInsets.all(8.sp),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8.sp,
        crossAxisSpacing: 8.sp,
      ),
      itemCount: mediaList.length,
      itemBuilder: (context, index) {
        final asset = mediaList[index];
        final isSelected = selectedMedia.contains(asset);

        return buildMediaGridItem(asset, isSelected);
      },
    );
  }

  // 构建媒体网格项
  Widget buildMediaGridItem(AssetEntity asset, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (isMultiSelectMode) {
          setState(() {
            if (isSelected) {
              selectedMedia.remove(asset);
              if (selectedMedia.isEmpty) {
                isMultiSelectMode = false;
              }
            } else {
              selectedMedia.add(asset);
            }
          });
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => buildPreviewScreen(asset),
            ),
          );
        }
      },
      onLongPress: () {
        if (!isMultiSelectMode) {
          setState(() {
            isMultiSelectMode = true;
            selectedMedia.add(asset);
          });
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          AssetEntityImage(
            asset,
            isOriginal: false,
            thumbnailSize: const ThumbnailSize.square(300),
            fit: BoxFit.cover,
          ),
          if (isSelected)
            Container(
              color: Colors.blue.withOpacity(0.3),
              alignment: Alignment.center,
              child: Icon(Icons.check_circle, color: Colors.white, size: 30.sp),
            ),
        ],
      ),
    );
  }
}
