import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../common/media_manager_base.dart';
import 'video_preview.dart';

class VideoManagerScreen extends MediaManagerBase {
  const VideoManagerScreen({super.key});

  @override
  State<VideoManagerScreen> createState() => _VideoManagerScreenState();
}

class _VideoManagerScreenState
    extends MediaManagerBaseState<VideoManagerScreen> {
  @override
  String get title => '视频管理';

  @override
  RequestType get mediaType => RequestType.video;

  @override
  Widget buildPreviewScreen(AssetEntity asset) {
    return VideoPreviewScreen(
      asset: asset,
      onDelete: () {
        setState(() {
          mediaList.remove(asset);
        });
      },
    );
  }
}
