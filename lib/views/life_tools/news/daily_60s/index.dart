import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../common/constants.dart';
import '../../../../common/utils/tools.dart';

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

  // 直接获取图片、可直接显示的地址（不稳定）
  String imageUrl() =>
      "https://api.03c3.cn/api/zb?random=${DateTime.now().millisecondsSinceEpoch}";
  // 获取图片二进制，需要进一步处理数据的地址
  // 2024-11-04 这个不能用了
  String imageDataUrl = 'https://api.jun.la/60s.php?format=image';

  @override
  void initState() {
    super.initState();
  }

  Future<Uint8List> fetchImageBytes() async {
    final response = await Dio().get(
      imageUrl(),
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
      // 2024-11-04 这个直接获取图片二进制的也不行了
      // body: FutureBuilder<Uint8List>(
      //   future: fetchImageBytes(),
      //   builder: (context, snapshot) {
      //     if (snapshot.connectionState == ConnectionState.waiting) {
      //       return const Center(child: CircularProgressIndicator());
      //     } else if (snapshot.hasError) {
      //       return Center(child: Text('Error: ${snapshot.error}'));
      //     } else if (!snapshot.hasData || snapshot.data == null) {
      //       return const Center(child: Text('No image found'));
      //     } else {
      //       return SingleChildScrollView(
      //         child: Image.memory(
      //           snapshot.data!,
      //           width: 1.sw,
      //           fit: BoxFit.fitWidth,
      //         ),
      //       );
      //     }
      //   },
      // ),
      // 2024-10-23 这个图片地址突然不能用了，原因不知
      // 2024-10-04 添加长按保存
      body: SingleChildScrollView(
        child: GestureDetector(
          // 长按保存到相册
          onLongPress: () async {
            // 网络图片就保存都指定位置
            await saveImageToLocal(
              imageUrl(),
              prefix: "每天60秒读懂世界",
              imageName:
                  "${DateFormat(constDateFormat).format(DateTime.now())}.jpg",
              dlDir: DL_DIR,
            );
          },
          child: CachedNetworkImage(
            imageUrl: widget.imageUrl ?? imageUrl(),
            // width: MediaQuery.of(context).size.width,
            width: 1.sw,
            fit: BoxFit.fitWidth,
            placeholder: (context, url) => SizedBox(
              height: 200.sp,
              child: Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Text("图片暂时无法显示，请稍候重试。"),
            ),
          ),
        ),
      ),
    );
  }
}
