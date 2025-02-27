import 'package:flutter/material.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../common/media_preview_base.dart';

class ImagePreviewScreen extends MediaPreviewBase {
  const ImagePreviewScreen({
    super.key,
    required super.asset,
    super.onDelete,
  });

  @override
  String get title => '图片预览';

  @override
  Widget buildPreviewContent() {
    return InteractiveViewer(
      child: Center(
        child: AssetEntityImage(
          asset,
          isOriginal: true,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
