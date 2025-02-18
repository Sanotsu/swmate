import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../common/constants.dart';
import 'image_preview.dart';

class ImageManagerScreen extends StatefulWidget {
  const ImageManagerScreen({super.key});

  @override
  State<ImageManagerScreen> createState() => _ImageManagerScreenState();
}

class _ImageManagerScreenState extends State<ImageManagerScreen> {
  // AI绘图生成的图片列表
  List<AssetEntity> _images = [];
  // 选中的图片
  final Set<AssetEntity> _selectedImages = {};
  // 是否加载中
  bool _isLoading = true;
  // 是否多选模式
  bool _isMultiSelectMode = false;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  // 加载图片
  Future<void> _loadImages() async {
    setState(() => _isLoading = true);

    try {
      // 请求权限
      final permitted = await PhotoManager.requestPermissionExtend();
      if (!permitted.isAuth) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('需要存储权限来管理图片')),
          );
        }
        return;
      }

      // // 获取所有图片路径
      // final List<AssetPathEntity> directories =
      //     await PhotoManager.getAssetPathList(
      //   type: RequestType.image,
      //   // 添加过滤条件后非常慢，因为只需要获取所有图片目录，然后找到AI生成的图片目录，所以不添加过滤条件
      //   //   filterOption: FilterOptionGroup(
      //   //     containsPathModified: true,
      //   //     orders: [OrderOption(type: OrderOptionType.createDate, asc: false)],
      //   //   ),
      // );

      // // 遍历所有目录，找到AI生成的图片目录，然后获取该目录下的所有图片
      // var assets = <AssetEntity>[];
      // for (final directory in directories) {
      //   if (directory.name.contains("image")) {
      //     print("查询到的图片目录: ${directory.name}  ${LLM_IG_DIR_V2.path}");
      //   }

      //   // 如果目录名是AI生成的图片目录，则获取该目录下的所有图片
      //   if (directory.name == LLM_IG_DIR_V2.path.split("/").last) {
      //     // assets = await directory.getAssetListRange(start: 0, end: 10000);
      //     final List<AssetEntity> images = await directory.getAssetListRange(
      //       start: 0,
      //       end: (await directory.assetCountAsync),
      //     );

      //     for (final image in images) {
      //       print("查询到的图片: ${image.relativePath}");
      //     }

      //     assets.addAll(images);
      //   }
      // }

      // // 设置图片列表
      // setState(() => _images = assets);

      ///
      /// ===========
      ///
      // 获取图片目录
      final directories = await PhotoManager.getAssetPathList(
        type: RequestType.image,
      );

      // 查找AI生成的图片目录
      var aiImagePath = directories.firstWhere(
        (entity) => entity.name == LLM_IG_DIR_V2.path.split("/").last,
      );

      final assets = await aiImagePath.getAssetListRange(start: 0, end: 10000);
      setState(() => _images = assets);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('查询AI绘图历史记录失败: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 删除选中的图片
  Future<void> _deleteSelectedImages() async {
    if (_selectedImages.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedImages.length} 张图片吗？'),
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
      await PhotoManager.editor.deleteWithIds(
        _selectedImages.map((e) => e.id).toList(),
      );

      // Android11+ 移动到垃圾桶，低于11的会报错
      var list = await PhotoManager.editor.android.moveToTrash(
        _selectedImages.map((e) => e).toList(),
      );

      if (list.isNotEmpty) {
        setState(() {
          _images.removeWhere((img) => _selectedImages.contains(img));
          _selectedImages.clear();
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  // 分享选中的图片
  Future<void> _shareSelectedImages() async {
    if (_selectedImages.isEmpty) return;

    try {
      final files = await Future.wait(
        _selectedImages.map((asset) => asset.file),
      );

      final result = await Share.shareXFiles(
        files.whereType<File>().map((f) => XFile(f.path)).toList(),
        text: '思文AI绘图',
      );

      if (result.status == ShareResultStatus.success) {
        EasyLoading.showSuccess('分享成功!');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isMultiSelectMode ? '已选择 ${_selectedImages.length} 项' : '图片管理',
        ),
        actions: [
          if (_isMultiSelectMode) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareSelectedImages,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelectedImages,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isMultiSelectMode = false;
                  _selectedImages.clear();
                });
              },
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _images.isEmpty
              ? const Center(child: Text('暂无图片'))
              : GridView.builder(
                  padding: EdgeInsets.all(8.sp),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8.sp,
                    crossAxisSpacing: 8.sp,
                  ),
                  itemCount: _images.length,
                  itemBuilder: (context, index) =>
                      _buildImageItem(_images[index]),
                ),
    );
  }

  Widget _buildImageItem(AssetEntity asset) {
    final isSelected = _selectedImages.contains(asset);
    return GestureDetector(
      onTap: () {
        if (_isMultiSelectMode) {
          // 多选模式下点击切换选择状态
          setState(() {
            if (isSelected) {
              _selectedImages.remove(asset);
              // 如果没有选中项了，退出多选模式
              if (_selectedImages.isEmpty) {
                _isMultiSelectMode = false;
              }
            } else {
              _selectedImages.add(asset);
            }
          });
        } else {
          // 非多选模式下进入预览
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ImagePreviewScreen(
                asset: asset,
                onDelete: () {
                  setState(() {
                    _images.remove(asset);
                    _selectedImages.remove(asset);
                  });
                },
              ),
            ),
          );
        }
      },
      onLongPress: () {
        // 长按进入多选模式
        setState(() {
          _isMultiSelectMode = true;
          _selectedImages.add(asset);
        });
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
