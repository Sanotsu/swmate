import 'dart:io';

import 'package:flutter/material.dart';

import '../../../common/constants/constants.dart';
import '../common/mime_media_manager_base.dart';
import 'mime_video_preview.dart';

class MimeVideoManager extends MimeMediaManagerBase {
  const MimeVideoManager({super.key});

  @override
  State<MimeVideoManager> createState() => _VideoManagerScreenState();
}

class _VideoManagerScreenState
    extends MimeMediaManagerBaseState<MimeVideoManager> {
  @override
  String get title => 'MIME视频管理';

  @override
  CusMimeCls get mediaType => CusMimeCls.VIDEO;

  @override
  Widget buildPreviewScreen(File file) {
    return MimeVideoPreview(
      file: file,
      onDelete: () {
        setState(() {
          mediaList.remove(file);
        });
      },
    );
  }
}
