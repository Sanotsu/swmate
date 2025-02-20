import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../common/media_manager_base.dart';
import 'image_preview.dart';

class ImageManagerScreen extends MediaManagerBase {
  const ImageManagerScreen({super.key});

  @override
  State<ImageManagerScreen> createState() => _ImageManagerScreenState();
}

class _ImageManagerScreenState
    extends MediaManagerBaseState<ImageManagerScreen> {
  @override
  String get title => '图片管理';

  @override
  RequestType get mediaType => RequestType.image;

  @override
  Widget buildPreviewScreen(AssetEntity asset) {
    return ImagePreviewScreen(
      asset: asset,
      onDelete: () {
        setState(() {
          mediaList.remove(asset);
        });
      },
    );
  }
}
