// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

/// 这里是生成签名的方案
/// 内容局限在使用hunyuan-lite大模型的时候。
/// 参看 https://github.com/TencentCloud/signature-process-demo/blob/main/signature-v3/dart/lib/app.dart
/// 对照此处“签名示例”进行部分内容修改
/// https://console.cloud.tencent.com/api/explorer?Product=hunyuan&Version=2023-09-01&Action=ChatCompletions
Map<String, Object> genHunyuanLiteSignatureHeaders(
  String payloadString,
  String id,
  String key,
) {
  // 密钥参数
  // 2024-06-16 支持用户自行输入自己的id和key
  var secretId = id;
  var secretKey = key;

  const service = 'hunyuan';
  const host = 'hunyuan.tencentcloudapi.com';
  const endpoint = 'https://$host';
  // const region = 'ap-guangzhou';
  const action = 'ChatCompletions';
  const version = '2023-09-01';
  const algorithm = 'TC3-HMAC-SHA256';
  // 获取当前时间戳
  final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  // const timestamp = 1717057782;

  final date = DateFormat('yyyy-MM-dd').format(
    DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true),
  );

  // ************* 步骤 1：拼接规范请求串 *************
  const httpRequestMethod = 'POST';
  const canonicalUri = '/';
  const canonicalQuerystring = '';
  const contentType = 'application/json; charset=utf-8';
  var payload = payloadString;

  final canonicalHeaders =
      'content-type:$contentType\nhost:$host\nx-tc-action:${action.toLowerCase()}\n';
  const signedHeaders = 'content-type;host;x-tc-action';
  final hashedRequestPayload = sha256.convert(utf8.encode(payload));

  final canonicalRequest = '''
$httpRequestMethod
$canonicalUri
$canonicalQuerystring
$canonicalHeaders
$signedHeaders
$hashedRequestPayload''';

  print("步骤 1：拼接规范请求串:==============");
  print(canonicalRequest);

  // ************* 步骤 2：拼接待签名字符串 *************
  final credentialScope = '$date/$service/tc3_request';
  final hashedCanonicalRequest = sha256.convert(utf8.encode(canonicalRequest));
  final stringToSign = '''
$algorithm
$timestamp
$credentialScope
$hashedCanonicalRequest''';

  print("步骤 2：拼接待签名字符串:=============");
  print(stringToSign);

  // ************* 步骤 3：计算签名 *************
  List<int> sign(List<int> key, String msg) {
    final hmacSha256 = Hmac(sha256, key);
    return hmacSha256.convert(utf8.encode(msg)).bytes;
  }

  final secretDate = sign(utf8.encode('TC3$secretKey'), date);
  final secretService = sign(secretDate, service);
  final secretSigning = sign(secretService, 'tc3_request');
  final signature =
      Hmac(sha256, secretSigning).convert(utf8.encode(stringToSign)).toString();

  print("步骤 3：计算签名:=============");
  print(signature);

  // ************* 步骤 4：拼接 Authorization *************
  final authorization =
      '$algorithm Credential=$secretId/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature';

  print("步骤 4：拼接 Authorization:=============");

  print(authorization);

  print("在构建签名中的打印---------------------------");
  print(
    'curl -X POST $endpoint'
    ' -H "Authorization: $authorization"'
    ' -H "Content-Type: $contentType"'
    ' -H "Host: $host"'
    ' -H "X-TC-Action: $action"'
    ' -H "X-TC-Timestamp: $timestamp"'
    ' -H "X-TC-Version: $version"'
    // ' -H "X-TC-Region: $region"'
    ' -d \'$payload\'',
  );

  // 拼接header
  var headers = {
    "X-TC-Action": action,
    "X-TC-Version": version,
    "X-TC-Timestamp": timestamp,
    "Content-Type": contentType,
    "Authorization": authorization,
  };

  return headers;
}
