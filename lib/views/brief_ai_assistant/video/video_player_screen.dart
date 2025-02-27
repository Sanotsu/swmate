import 'package:flutter/material.dart';

import 'video_preview.dart';

class NetworkVideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String? sourceType;

  const NetworkVideoPlayerScreen({
    super.key,
    required this.videoUrl,
    this.sourceType = 'file',
  });

  @override
  State<NetworkVideoPlayerScreen> createState() =>
      _NetworkVideoPlayerScreenState();
}

class _NetworkVideoPlayerScreenState extends State<NetworkVideoPlayerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('视频播放示例')),
      body: VideoPlayerWidget(
        videoUrl: widget.videoUrl,
        sourceType: widget.sourceType,
      ),
    );
  }
}
