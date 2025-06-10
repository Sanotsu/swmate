package com.swm.swmate

import android.content.Context
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.os.Build
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.io.RandomAccessFile
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * 音频转换插件
 * 用于将m4a格式的音频转换为pcm格式，以便用于语音识别
 */
class AudioConverterPlugin(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        private const val CHANNEL_NAME = "com.swmate/audio_converter"
        private const val TIMEOUT_US = 10000L
        private const val BUFFER_SIZE = 8192

        fun registerWith(flutterEngine: FlutterEngine, context: Context) {
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            channel.setMethodCallHandler(AudioConverterPlugin(context))
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "convertM4aToPcm" -> {
                val inputPath = call.argument<String>("inputPath")
                val outputPath = call.argument<String>("outputPath")
                val sampleRate = call.argument<Int>("sampleRate") ?: 16000
                val isRawPcm = call.argument<Boolean>("isRawPcm") ?: true

                if (inputPath == null || outputPath == null) {
                    result.error("INVALID_ARGUMENTS", "输入或输出路径不能为空", null)
                    return
                }

                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        val success = convertM4aToPcm(inputPath, outputPath, sampleRate, isRawPcm)
                        result.success(success)
                    } else {
                        result.error("UNSUPPORTED_DEVICE", "设备不支持此操作，需要API 21及以上", null)
                    }
                } catch (e: Exception) {
                    result.error("CONVERSION_ERROR", "转换过程中发生错误: ${e.message}", null)
                }
            }
            "isPlatformSupported" -> {
                result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * 将m4a音频文件转换为pcm格式
     *
     * @param inputPath m4a文件路径
     * @param outputPath 输出的pcm文件路径
     * @param sampleRate 采样率
     * @param isRawPcm 是否为原始PCM格式，如果为false则添加WAV头
     * @return 转换是否成功
     */
    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun convertM4aToPcm(
        inputPath: String,
        outputPath: String,
        sampleRate: Int,
        isRawPcm: Boolean
    ): Boolean {
        val extractor = MediaExtractor()
        val codec: MediaCodec
        val outputFile = File(outputPath)

        return try {
            // 设置音频源
            extractor.setDataSource(inputPath)

            // 获取音频轨道
            val audioTrackIndex = selectAudioTrack(extractor)
            if (audioTrackIndex < 0) {
                return false
            }

            // 选择音频轨道
            extractor.selectTrack(audioTrackIndex)
            val format = extractor.getTrackFormat(audioTrackIndex)

            // 创建解码器
            val mime = format.getString(MediaFormat.KEY_MIME)
            codec = MediaCodec.createDecoderByType(mime!!)

            // 配置解码器
            codec.configure(format, null, null, 0)
            codec.start()

            // 创建输出文件
            FileOutputStream(outputFile).use { outputStream ->
                // 如果不是原始PCM，则写入WAV头
                if (!isRawPcm) {
                    val channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                    val bitsPerSample = 16 // PCM 16-bit
                    writeWavHeader(outputStream, channels, sampleRate, bitsPerSample)
                }

                // 解码过程
                val info = MediaCodec.BufferInfo()
                var sawInputEOS = false
                var sawOutputEOS = false

                while (!sawOutputEOS) {
                    // 处理输入
                    if (!sawInputEOS) {
                        val inputBufferId = codec.dequeueInputBuffer(TIMEOUT_US)
                        if (inputBufferId >= 0) {
                            val inputBuffer = codec.getInputBuffer(inputBufferId)
                            val sampleSize = extractor.readSampleData(inputBuffer!!, 0)

                            if (sampleSize < 0) {
                                codec.queueInputBuffer(
                                    inputBufferId, 0, 0,
                                    0, MediaCodec.BUFFER_FLAG_END_OF_STREAM
                                )
                                sawInputEOS = true
                            } else {
                                codec.queueInputBuffer(
                                    inputBufferId, 0, sampleSize,
                                    extractor.sampleTime, 0
                                )
                                extractor.advance()
                            }
                        }
                    }

                    // 处理输出
                    val outputBufferId = codec.dequeueOutputBuffer(info, TIMEOUT_US)
                    if (outputBufferId >= 0) {
                        val outputBuffer = codec.getOutputBuffer(outputBufferId)
                        val size = info.size

                        if (size > 0 && outputBuffer != null) {
                            // 写入PCM数据
                            val pcmData = ByteArray(size)
                            outputBuffer.get(pcmData)
                            outputStream.write(pcmData)
                        }

                        codec.releaseOutputBuffer(outputBufferId, false)

                        if ((info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                            sawOutputEOS = true
                        }
                    }
                }
            }

            // 释放资源
            codec.stop()
            codec.release()
            extractor.release()

            true
        } catch (e: Exception) {
            e.printStackTrace()
            if (outputFile.exists()) {
                outputFile.delete()
            }
            false
        }
    }

    /**
     * 选择音频轨道
     *
     * @param extractor 媒体提取器
     * @return 音频轨道索引，如果没有找到则返回-1
     */
    private fun selectAudioTrack(extractor: MediaExtractor): Int {
        for (i in 0 until extractor.trackCount) {
            val format = extractor.getTrackFormat(i)
            val mime = format.getString(MediaFormat.KEY_MIME)
            if (mime?.startsWith("audio/") == true) {
                return i
            }
        }
        return -1
    }

    /**
     * 写入WAV文件头
     *
     * @param outputStream 输出流
     * @param channels 声道数
     * @param sampleRate 采样率
     * @param bitsPerSample 每个样本的位数
     */
    @Throws(IOException::class)
    private fun writeWavHeader(
        outputStream: FileOutputStream,
        channels: Int,
        sampleRate: Int,
        bitsPerSample: Int
    ) {
        // 先写入一个临时头，后面再更新文件大小
        val header = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN)

        // RIFF标识
        header.put("RIFF".toByteArray())
        // 文件大小，先写入0，稍后更新
        header.putInt(0)
        // WAVE标识
        header.put("WAVE".toByteArray())
        // fmt子块标识
        header.put("fmt ".toByteArray())
        // 子块大小
        header.putInt(16)
        // 音频格式，PCM=1
        header.putShort(1)
        // 声道数
        header.putShort(channels.toShort())
        // 采样率
        header.putInt(sampleRate)
        // 字节率 = 采样率 * 声道数 * 每个样本的字节数
        val byteRate = sampleRate * channels * bitsPerSample / 8
        header.putInt(byteRate)
        // 块对齐 = 声道数 * 每个样本的字节数
        val blockAlign = (channels * bitsPerSample / 8).toShort()
        header.putShort(blockAlign)
        // 每个样本的位数
        header.putShort(bitsPerSample.toShort())
        // data子块标识
        header.put("data".toByteArray())
        // 数据大小，先写入0，稍后更新
        header.putInt(0)

        // 写入头部
        outputStream.write(header.array())
    }

    /**
     * 更新WAV文件头中的文件大小字段
     *
     * @param wavFile WAV文件
     */
    @Throws(IOException::class)
    private fun updateWavHeader(wavFile: File) {
        val fileSize = wavFile.length()
        val dataSize = fileSize - 44

        // 更新文件头
        RandomAccessFile(wavFile, "rw").use { randomAccessFile ->
            // 更新RIFF块大小
            randomAccessFile.seek(4)
            val riffSize = fileSize - 8
            randomAccessFile.write(
                ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
                    .putInt(riffSize.toInt()).array()
            )

            // 更新data块大小
            randomAccessFile.seek(40)
            randomAccessFile.write(
                ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
                    .putInt(dataSize.toInt()).array()
            )
        }
    }
} 