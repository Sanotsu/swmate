import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

/// 讯飞平台的 WebAPI 通用鉴权
//@hostUrl : 比如语言识别的 wss://iat-api.xfyun.cn/v2/iat
//@apiKey : apiKey
//@apiSecret : apiSecret
//@method :get 或者post请求
String genXfyunAssembleAuthUrl(
  String hosturl,
  String apiKey,
  String apiSecret,
  String method,
) {
  var ul = Uri.parse(hosturl);

  // 签名时间
  String date = HttpDate.format(DateTime.now().toUtc());

  // 参与签名的字段 host, date, request-line
  List<String> signString = [
    "host: ${ul.host}",
    "date: $date",
    // "GET ${ul.path} HTTP/1.1",
    "$method ${ul.path} HTTP/1.1",
  ];

  // 拼接签名字符串
  String sgin = signString.join("\n");

  // 签名结果
  String sha = hmacSha256ToBase64(sgin, apiSecret);

  // 构建请求参数 此时不需要urlencoding
  String authUrl =
      'api_key="$apiKey", algorithm="hmac-sha256", headers="host date request-line", signature="$sha"';

  // 将请求参数使用base64编码
  String authorization = base64Encode(utf8.encode(authUrl));

  // 将编码后的字符串url encode后添加到url后面
  String callurl =
      '$hosturl?host=${Uri.encodeComponent(ul.host)}&date=${Uri.encodeComponent(date)}&authorization=${Uri.encodeComponent(authorization)}';

  return callurl;
}

String hmacSha256ToBase64(String data, String key) {
  var keyBytes = utf8.encode(key);
  var dataBytes = utf8.encode(data);
  var hmacSha256 = Hmac(sha256, keyBytes);
  var digest = hmacSha256.convert(dataBytes);
  return base64Encode(digest.bytes);
}
