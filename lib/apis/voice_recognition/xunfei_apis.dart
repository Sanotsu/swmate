// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../models/voice_recognition/xunfei_voice_dictation.dart';
import '../_self_keys.dart';
import '../gen_access_token/xfyun_signature.dart';

const voiceRegUrl = "wss://iat-api.xfyun.cn/v2/iat";

Future<String> sendAudioToServer(String audioPath) async {
  // 生成鉴权url
  var authUrl = genXfyunAssembleAuthUrl(
    voiceRegUrl,
    XUNFEI_ALL_API_KEY,
    XUNFEI_ALL_API_SECRET,
  );

  //  把音频文件转为base64
  final file = File(audioPath);
  final audioBytes = await file.readAsBytes();
  final audioBase64 = base64Encode(audioBytes);

  // 建立WebSocket连接
  final channel = WebSocketChannel.connect(Uri.parse(authUrl));

  print("channel--${channel.protocol}");

  String transcription = '';
  final completer = Completer<String>();

  try {
    await channel.ready;
  } catch (e) {
    print("channel.ready error: $e");
  }

  channel.stream.listen(
    (message) {
      print("这里是 message--$message");

      ///？？？ 2024-08-03 保存的时候类型就是 String而不是Map<String, dynamic>
      if (message.runtimeType == String) {
        message = json.decode(message);
      }

      var data = XunfeiVoiceDictation.fromJson(message);

      print(jsonEncode(data));

      transcription = data.data?.result?.ws
              ?.map((e) => e.cw?.map((e) => e.w).join())
              .join() ??
          "";

      print("这里是 transcription--$transcription");

      completer.complete(transcription);
    },
    onDone: () {
      print("这里是onDone--transcription$transcription");
      if (!completer.isCompleted) {
        completer.complete(transcription);
      }
    },
    onError: (error) {
      print('WebSocket error: ${error.toString()}');
      completer.completeError(error);
    },
  );

  // 发送参数
  var params = {
    'common': {
      'app_id': XUNFEI_ALL_APPID,
    },
    'business': {
      // 语种。zh_cn：中文（支持简单的英文识别）
      'language': 'zh_cn',
      // 应用领域。iat：日常用语
      'domain': 'iat',
      // 方言，当前仅在language为中文时，支持方言选择。
      'accent': 'mandarin', // 默认中文普通话
      // 设置端点检测的静默时间，单位是毫秒。
      // 'vad_eos': 5000,
      // 动态修正返回参数
      // 'dwa': 'wpgs',
    },
    'data': {
      // 音频的状态。0 :第一帧音频； 1 :中间的音频；2 :最后一帧音频，最后一帧必须要发送
      'status': 0,
      // 音频的采样率支持16k和8k
      'format': 'audio/L16;rate=16000',
      // 音频数据格式：raw、speex、speex-wb、lame
      'encoding': 'raw',
      // 音频内容，采用base64编码
      'audio': audioBase64,
    },
  };
  channel.sink.add(jsonEncode(params));

// 发送结束信号
  var endParams = {
    'data': {'status': 2},
  };
  channel.sink.add(jsonEncode(endParams));

  return completer.future;
}
