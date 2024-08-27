import 'dart:convert';
import 'package:crypto/crypto.dart';

String zhipuGenerateToken(String apikey) {
  try {
    var parts = apikey.split(".");
    if (parts.length != 2) {
      throw Exception("invalid apikey");
    }
    String id = parts[0];
    String secret = parts[1];

    int expSeconds = DateTime.now().millisecond;

    var payload = {
      "api_key": id,
      "exp": DateTime.now().millisecondsSinceEpoch + expSeconds * 1000,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    };

    String encodedPayload = base64Url.encode(utf8.encode(jsonEncode(payload)));
    String header = base64Url.encode(utf8.encode(jsonEncode({
      "alg": "HS256",
      "sign_type": "SIGN",
    })));

    String toSign = "$header.$encodedPayload";
    var hmac = Hmac(sha256, utf8.encode(secret));
    var digest = hmac.convert(utf8.encode(toSign));
    String signature = base64Url.encode(digest.bytes);

    return "$toSign.$signature";
  } catch (e) {
    throw Exception("Error generating token: $e");
  }
}
