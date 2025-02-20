import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../../../common/constants.dart';

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
      if (!permitted.hasAccess) {
        throw Exception('没有访问权限');
      }

      // 获取指定目录下的媒体文件
      final albums = await PhotoManager.getAssetPathList(
        type: mediaType,
        // filterOption: FilterOptionGroup(
        //   containsPathModified: true,
        //   orders: [OrderOption(type: OrderOptionType.createDate, asc: false)],
        // ),
      );

      // 查找AI生成的媒体目录（找不到就让它报错）
      final aiMediaPath = albums.firstWhere(
        (entity) => entity.name == getAIMediaDirName(),
      );

      print('得到的AI生成媒体的目录: $aiMediaPath ${await aiMediaPath.assetCountAsync}');

      final media = await aiMediaPath.getAssetListRange(
        start: 0,
        // ???2025-02-19 取这个值和实际的文件数量不一致
        // end: await aiMediaPath.assetCountAsync,
        end: 1000,
      );

      for (var i = 0; i < media.length; i++) {
        print('媒体文件[$i]: ${media[i].title}');
      }

      setState(() => mediaList = media);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('查询AI绘图历史记录失败: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 获取AI生成媒体目录名
  String getAIMediaDirName() {
    switch (mediaType) {
      case RequestType.image:
        return LLM_IG_DIR_V2.path.split("/").last;
      case RequestType.video:
        return LLM_VG_DIR.path.split("/").last;
      default:
        return "";
    }
  }

  // 分享选中的媒体
  Future<void> _shareSelectedMedia() async {
    try {
      final files = await Future.wait(
        selectedMedia.map((asset) => asset.file),
      );

      final xFiles =
          files.where((f) => f != null).map((f) => XFile(f!.path)).toList();

      if (xFiles.isEmpty) return;

      final result = await Share.shareXFiles(
        xFiles,
        text: '思文AI助手',
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

      if (list.isNotEmpty) {
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
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title:
            Text(isMultiSelectMode ? '已选择 ${selectedMedia.length} 项' : title),
        actions: [
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
      body: buildMediaGrid(),
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
