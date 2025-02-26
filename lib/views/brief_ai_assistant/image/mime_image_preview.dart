import 'package:flutter/material.dart';

import '../common/mime_media_preview_base.dart';

class MimeImagePreview extends MimeMediaPreviewBase {
  const MimeImagePreview({
    super.key,
    required super.file,
    super.onDelete,
  });

  @override
  String get title => 'MIME图片预览';

  @override
  Widget buildPreviewContent() {
    return InteractiveViewer(
      child: Center(
        child: Image.file(
          file,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
