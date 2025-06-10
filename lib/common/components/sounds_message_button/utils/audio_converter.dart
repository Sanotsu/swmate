import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// 音频转换工具类，使用平台通道调用原生音频转换API
class AudioConverter {
  static const MethodChannel _channel = MethodChannel(
    'com.swmate/audio_converter',
  );

  /// 将m4a音频文件转换为pcm格式
  ///
  /// [inputPath] m4a音频文件路径
  /// [outputPath] 输出的pcm文件路径
  /// [sampleRate] 采样率，默认16000
  /// [isRawPcm] 是否为原始PCM格式，默认true。如果为false，则会添加WAV头
  ///
  /// 返回转换是否成功
  static Future<bool> convertM4aToPcm({
    required String inputPath,
    required String outputPath,
    int sampleRate = 16000,
    bool isRawPcm = true,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('convertM4aToPcm', {
        'inputPath': inputPath,
        'outputPath': outputPath,
        'sampleRate': sampleRate,
        'isRawPcm': isRawPcm,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('音频转换平台错误: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('音频转换错误: $e');
      return false;
    }
  }

  /// 将字节数据直接转换为PCM格式
  ///
  /// [inputData] 输入的音频字节数据
  /// [sampleRate] 采样率，默认16000
  /// [isRawPcm] 是否为原始PCM格式，默认true
  ///
  /// 返回转换后的PCM数据，如果转换失败则返回null
  static Future<Uint8List?> convertDataToPcm({
    required Uint8List inputData,
    int sampleRate = 16000,
    bool isRawPcm = true,
  }) async {
    try {
      // 为了防止直接传输大数据导致的性能问题，先写入临时文件
      final tempDir = await getTemporaryDirectory();
      final tempInputFile = File(
        '${tempDir.path}/temp_audio_input_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );
      final tempOutputFile = File(
        '${tempDir.path}/temp_audio_output_${DateTime.now().millisecondsSinceEpoch}.pcm',
      );

      // 写入临时输入文件
      await tempInputFile.writeAsBytes(inputData);

      // 调用文件转换方法
      final success = await convertM4aToPcm(
        inputPath: tempInputFile.path,
        outputPath: tempOutputFile.path,
        sampleRate: sampleRate,
        isRawPcm: isRawPcm,
      );

      if (success && await tempOutputFile.exists()) {
        // 读取转换后的数据
        final result = await tempOutputFile.readAsBytes();

        // 清理临时文件
        await tempInputFile.delete();
        await tempOutputFile.delete();

        return result;
      } else {
        // 清理临时文件
        if (await tempInputFile.exists()) await tempInputFile.delete();
        if (await tempOutputFile.exists()) await tempOutputFile.delete();

        return null;
      }
    } catch (e) {
      debugPrint('音频数据转换错误: $e');
      return null;
    }
  }

  /// 检查平台是否支持音频转换
  static Future<bool> isPlatformSupported() async {
    try {
      final result = await _channel.invokeMethod<bool>('isPlatformSupported');
      return result ?? false;
    } on PlatformException {
      return false;
    } catch (e) {
      return false;
    }
  }
}