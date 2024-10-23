import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Daily60S extends StatefulWidget {
  final String? title;
  final String? imageUrl;

  const Daily60S({super.key, this.imageUrl, this.title});

  @override
  State<Daily60S> createState() => _Daily60SState();
}

class _Daily60SState extends State<Daily60S> {
  var list = [
    "https://api.jun.la/60s.php?format=image",
    "https://api.03c3.cn/api/zb?random=${DateTime.now().millisecondsSinceEpoch}",
  ];

  @override
  void initState() {
    super.initState();
    fetchImageBytes();
  }

  Future<Uint8List> fetchImageBytes() async {
    final response = await Dio().get(
      'https://api.jun.la/60s.php?format=image',
      options: Options(responseType: ResponseType.bytes),
    );
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Failed to load image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? '每天60秒读懂世界'),
      ),
      body: FutureBuilder<Uint8List>(
        future: fetchImageBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No image found'));
          } else {
            return SingleChildScrollView(
              child: Image.memory(
                snapshot.data!,
                width: 1.sw,
                fit: BoxFit.fitWidth,
              ),
            );
          }
        },
      ),
      // 2024-10-23 这个图片地址突然不能用了，原因不知
      // SingleChildScrollView(
      //   child: CachedNetworkImage(
      //     imageUrl: widget.imageUrl ??
      //         "https://api.03c3.cn/api/zb?random=${DateTime.now().millisecondsSinceEpoch}",
      //     // width: MediaQuery.of(context).size.width,
      //     width: 1.sw,
      //     fit: BoxFit.fitWidth,
      //     placeholder: (context, url) =>
      //         const Center(child: CircularProgressIndicator()),
      //     errorWidget: (context, url, error) => const Icon(Icons.error),
      //   ),
      // ),
    );
  }
}
