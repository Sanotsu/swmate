import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../constants/constants.dart';

/// 按住说话最后发送的类型(转换后的文本还是原音频文件)
enum SendContentType {
  voice,
  text,
}

/// 录音过程中，UI对应的状态枚举
enum SoundsMessageStatus {
  /// 默认状态 未交互/交互完成
  none,

  /// 录制中
  recording,

  /// 取消录制
  canceling,

  /// 语音转文字中
  textProcessing,

  /// 语音转文字完成
  textProcessed;

  /// 按钮显示的文字内容
  String get title {
    switch (this) {
      case none:
        return '按住 说话';
      case recording:
        return '松开 发送';
      case canceling:
        return '松开 取消';
      case textProcessing:
      case textProcessed:
        return '转文字';
    }
  }
}

/// 录音类
class SoundsRecorderController {
  SoundsRecorderController();

  // 录音控制器
  RecorderController? recorderController;
  // 修改语音转文字的内容
  final textProcessedController = TextEditingController();
  // 是否完成了语音转文字的操作
  bool isTranslated = false;
  // 音频地址
  final path = ValueNotifier<String?>('');
  // 录音操作的状态
  final status = ValueNotifier(SoundsMessageStatus.none);
  // 录音操作时间内的音频振幅集合，最新值在前 [0.0 ~ 1.0]
  final amplitudeList = ValueNotifier<List<double>>([]);
  // 录音时长
  final duration = ValueNotifier<Duration>(Duration.zero);
  // 录制结束后的处理回调
  Function(String? path, Duration duration)? _onAllCompleted;

  /// 录制
  beginRec({
    // 录制状态
    ValueChanged<RecorderState>? onStateChanged,
    // 录制时间
    ValueChanged<Duration>? onDurationChanged,
    // 结束录制（录制时长超过60s时，自动断开的处理）
    required Function(String? path, Duration duration) onCompleted,
  }) async {
    try {
      // 重置录音时长
      reset();

      // 将录制结束后的处理回调保存起来
      _onAllCompleted = onCompleted;

      /// 2024-08-03 配合讯飞语音听写的格式（好像无法直接支持，只能转码）
      /// https://www.xfyun.cn/doc/asr/voicedictation/API.html
      recorderController = RecorderController()
        ..androidEncoder = AndroidEncoder.aac
        ..androidOutputFormat = AndroidOutputFormat.mpeg4
        ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
        ..sampleRate = 16000;

      // 更新录制状态
      updateStatus(SoundsMessageStatus.recording);

      // 录制状态变化监听
      recorderController?.onRecorderStateChanged.listen((state) {
        onStateChanged?.call(state);
      });

      // 录制时间变化监听
      recorderController?.onCurrentDuration.listen((value) {
        // 实时更新时长
        duration.value = value;

        // 录制时长超过60s，自动断开
        if (value.inSeconds >= 60) {
          endRec();
        }

        // 录制时长有变化实时更新
        onDurationChanged?.call(value);

        // 音频振幅(绘制振幅画布时用到)
        amplitudeList.value = recorderController!.waveData.reversed.toList();
      });

      // 外部存储权限的获取在按下说话按钮前就判断了，能到这里来一定是有权限了
      // 翻译保存的文本，放到设备外部存储固定位置，不存在文件夹则先创建
      if (!await CHAT_AUDIO_DIR.exists()) {
        await CHAT_AUDIO_DIR.create(recursive: true);
      }
      final file = File(
        '${CHAT_AUDIO_DIR.path}/${DateTime.now().microsecondsSinceEpoch}.m4a',
      );

      // 录制(path参数 是可选的，这里指定固定位置)
      await recorderController!.record(path: file.path);
    } catch (e) {
      debugPrint(e.toString());
    } finally {}
  }

  /// 停止录音
  Future endRec() async {
    // 2024-08-03 首次按住说话可以会弹出请求录音许可，此时还没有录音控制器，所以要先判断录音控制器是否存在
    if (recorderController != null && recorderController!.isRecording) {
      path.value = await recorderController!.stop();

      // 需要转为pcm让讯飞能够识别（但播放时，pcm就无法播放了）
      var time = path.value?.split("/").last.split(".").first;
      final pcmPath = '${CHAT_AUDIO_DIR.path}/$time.pcm';

      debugPrint("转换后的地址--$pcmPath");

      if (path.value?.isNotEmpty == true) {
        debugPrint(path.value);
        debugPrint("Recorded file size: ${File(path.value!).lengthSync()}");

        // 停止录制后，音频转个码，讯飞才能识别
        await convertToPcm(
          inputPath: path.value!,
          outputPath: pcmPath,
          sampleRate: 16000,
        );
      }

      _onAllCompleted?.call(path.value, duration.value);
      // 返回的是转码后的文件路径
      // _onAllCompleted?.call(pcmPath, duration.value);
    } else {
      _onAllCompleted?.call(null, Duration.zero);
    }
    reset();
  }

  /// 重置(录制时长归零)
  reset() {
    duration.value = Duration.zero;
  }

  /// 释放控制器
  dispose() {
    recorderController?.dispose();
  }

  /// 权限
  Future<bool> hasPermission() async {
    final state = await Permission.microphone.request();
    return state == PermissionStatus.granted;
  }

  /// 更新状态
  updateStatus(SoundsMessageStatus value) {
    status.value = value;
  }

  /// 语音转文字
  void updateTextProcessed(String text) {
    isTranslated = true;
    textProcessedController.text = text;
  }
}

// 讯飞识别时需要pcm
Future<void> convertToPcm({
  required String inputPath,
  required String outputPath,
  required int sampleRate,
}) async {
  final command = '-i $inputPath -ac 1 -ar $sampleRate -f s16le $outputPath';
  final session = await FFmpegKit.execute(command);
  final returnCode = await session.getReturnCode();
  if (!ReturnCode.isSuccess(returnCode)) {
    throw Exception('FFmpeg m4a 转 pcm 失败');
  }
}

// 播放时，转换后的pcn audio_waveforms 无法播放，又得转回去
Future<void> convertToM4a({
  required String inputPath,
  required String outputPath,
}) async {
  final command = '-f s16le -ar 16000 -ac 1 -i $inputPath $outputPath';
  final session = await FFmpegKit.execute(command);
  final returnCode = await session.getReturnCode();
  if (!ReturnCode.isSuccess(returnCode)) {
    throw Exception('FFmpeg pcm 转 m4a 失败');
  }
}
