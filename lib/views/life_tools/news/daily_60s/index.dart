import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Daily60S extends StatelessWidget {
  final String? title;
  final String? imageUrl;

  const Daily60S({super.key, this.imageUrl, this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? '每天60秒读懂世界'),
      ),
      body: SingleChildScrollView(
        child: CachedNetworkImage(
          imageUrl: imageUrl ??
              'https://api.03c3.cn/api/zb?random=${DateTime.now().millisecondsSinceEpoch}',
          // width: MediaQuery.of(context).size.width,
          width: 1.sw,
          fit: BoxFit.fitWidth,
          placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
    );
  }
}
