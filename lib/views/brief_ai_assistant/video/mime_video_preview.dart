import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';
import '../common/mime_media_preview_base.dart';

class MimeVideoPreview extends MimeMediaPreviewBase {
  const MimeVideoPreview({
    super.key,
    required super.file,
    super.onDelete,
  });

  @override
  String get title => 'MIME视频预览';

  @override
  Widget buildPreviewContent() {
    return FutureBuilder<File?>(
      future: Future.value(file),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return VideoPlayerWidget(videoUrl: file.path);
      },
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String? sourceType;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.sourceType = 'file',
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    if (widget.sourceType == "network") {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        ..initialize().then((_) {
          setState(() => _isInitialized = true);
          _controller.play();
        });
    } else {
      _controller = VideoPlayerController.file(File(widget.videoUrl))
        ..initialize().then((_) {
          setState(() => _isInitialized = true);
          _controller.play();
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        VideoProgressIndicator(_controller, allowScrubbing: true),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                _controller.value.isPlaying
                    ? Icons.pause_circle
                    : Icons.play_circle,
                size: 32.sp,
              ),
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.replay_circle_filled, size: 32.sp),
              onPressed: () {
                _controller.seekTo(Duration.zero);
                _controller.play();
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
