import 'dart:io';

import 'package:flutter/material.dart';

import '../../../common/constants.dart';
import '../common/mime_media_manager_base.dart';
import 'mime_image_preview.dart';

class MimeImageManager extends MimeMediaManagerBase {
  const MimeImageManager({super.key});

  @override
  State<MimeImageManager> createState() => _MimeImageManagerState();
}

class _MimeImageManagerState
    extends MimeMediaManagerBaseState<MimeImageManager> {
  @override
  String get title => 'MIME图片管理';

  @override
  CusMimeCls get mediaType => CusMimeCls.IMAGE;

  @override
  Widget buildPreviewScreen(File file) {
    return MimeImagePreview(
      file: file,
      onDelete: () {
        setState(() {
          mediaList.remove(file);
        });
      },
    );
  }
}
