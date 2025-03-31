// 检查URL是否为有效的图片
import 'package:dio/dio.dart';

Future<bool> isValidImageUrl(String url) async {
  final dio = Dio(); // 创建 Dio 实例
  try {
    // 发送 HEAD 请求
    final response = await dio.head(url);
    // 检查响应头中的 content-type
    final contentType = response.headers['content-type']?.first;
    return contentType != null && contentType.startsWith('image/');
  } catch (e) {
    return false; // 如果发生异常，返回 false
  }
}
