import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as path;

import '../../../../apis/voice_recognition/xunfei_apis.dart';
import '../../tool_widget.dart';
import '../utils/recording_mask_overlay_data.dart';
import '../utils/sounds_recorder_controller.dart';

part 'recording_status_mask.dart';
part 'custom_canvas.dart';

///
/// 语音发送按钮
///
class SoundsMessageButton extends StatefulWidget {
  const SoundsMessageButton({
    super.key,
    this.maskData = const RecordingMaskOverlayData(),
    this.builder,
    this.onChanged,
    this.onSendSounds,
    this.customDecoration,
  });

  /// 自定义发送按钮视图
  final Function(
    BuildContext context,
    SoundsMessageStatus status,
  )? builder;

  /// 状态监听， 回调到外部自定义处理
  final Function(SoundsMessageStatus status)? onChanged;

  /// 发送音频 / 发送音频文字
  final Function(SendContentType type, String content)? onSendSounds;

  /// 语音输入时遮罩配置
  final RecordingMaskOverlayData maskData;

  /// 2025-03-27 自定义的按钮装饰
  final Decoration? customDecoration;

  @override
  State<SoundsMessageButton> createState() => _SoundsMessageButtonState();
}

class _SoundsMessageButtonState extends State<SoundsMessageButton> {
  /// 屏幕大小
  final scSize = Size(ScreenUtil().screenWidth, ScreenUtil().screenHeight);

  /// 遮罩图层
  OverlayEntry? _entry;

  /// 录音控制器
  final _soundsRecorder = SoundsRecorderController();

  @override
  void initState() {
    super.initState();

    _soundsRecorder.status.addListener(() {
      widget.onChanged?.call(_soundsRecorder.status.value);
    });
  }

  @override
  void dispose() {
    _soundsRecorder.reset();
    _soundsRecorder.dispose();
    super.dispose();
  }

  // 移除录音时的遮罩
  _removeMask() {
    // 不过是取消、发送原语言还是发送了转换后的文本，操作完成之后都重置转换后的文本为空
    setState(() {
      _soundsRecorder.textProcessedController.text = "";
    });

    // 如果遮罩存在，则移除，并更新当前状态为未录音
    if (_entry != null) {
      _entry!.remove();
      _entry = null;
      _soundsRecorder.updateStatus(SoundsMessageStatus.none);
    }
  }

  // 按住说话时显示遮罩
  _showRecordingMask() {
    _entry = OverlayEntry(
      builder: (context) {
        return RepaintBoundary(
          child: RecordingStatusMaskView(
            PolymerData(_soundsRecorder, widget.maskData),
            onCancelSend: () {
              _removeMask();
            },
            onVoiceSend: () {
              widget.onSendSounds?.call(
                SendContentType.voice,
                _soundsRecorder.path.value ?? '',
              );
              _removeMask();
            },
            onTextSend: () {
              widget.onSendSounds?.call(
                SendContentType.text,
                _soundsRecorder.textProcessedController.text,
              );
              _removeMask();
            },
          ),
        );
      },
    );
    Overlay.of(context).insert(_entry!);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () async {
        // 2024-08-07 我在点击说话按钮前已经有必须授权的设定了，所以这里不需要再次判断
        // 直接显示语音输入UI
        _showRecordingMask();

        // 录制
        _soundsRecorder.beginRec(
          onStateChanged: (state) {
            debugPrint('________  onStateChanged: $state ');
          },
          onDurationChanged: (duration) {
            debugPrint('________  onDurationChanged: $duration ');
          },
          onCompleted: (path, duration) {
            debugPrint('________  onCompleted: $path , $duration ');

            if (duration.inSeconds < 1) {
              _removeMask();
              showDialog(
                context: context,
                builder: (context) {
                  return CupertinoAlertDialog(
                    title: const Text('录制时间过短'),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('确定'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
              return;
            }

            // 录制状态松开/超过时长 直接发送语音内容
            if (_soundsRecorder.status.value == SoundsMessageStatus.recording) {
              widget.onSendSounds?.call(SendContentType.voice, path!);
              _removeMask();
            }
            // 取消发送
            else if (_soundsRecorder.status.value ==
                SoundsMessageStatus.canceling) {
              _removeMask();
            }
            // 转文字时完成语音输入，则包含额外的选择操作(取消、发送原语音、发送)
            // 这里默认是能转换完成，(如果转换失败什么的，一直在textProcessing中可能就会显示的和实际的不一致了)
            else if (_soundsRecorder.status.value ==
                SoundsMessageStatus.textProcessing) {
              _soundsRecorder.updateStatus(SoundsMessageStatus.textProcessed);
            }
          },
        );
      },
      // 录音状态下的手势移动处理(注意长按下移动的位置要对得上各自功能区域)
      onLongPressMoveUpdate: (details) {
        if (_soundsRecorder.status.value == SoundsMessageStatus.none) {
          return;
        }
        final offset = details.globalPosition;
        // 如果滑到了录音扇形区域之外
        if ((scSize.height - offset.dy.abs()) >
            widget.maskData.sendAreaHeight) {
          final cancelOffset = offset.dx < scSize.width / 2;
          // 左边是取消、右边是语言转文字
          if (cancelOffset) {
            _soundsRecorder.updateStatus(SoundsMessageStatus.canceling);
          } else {
            _soundsRecorder.updateStatus(SoundsMessageStatus.textProcessing);
          }
        } else {
          // 还在录音扇形区域之内就继续录音
          _soundsRecorder.updateStatus(SoundsMessageStatus.recording);
        }
      },
      // 长按结束时结束录音
      onLongPressEnd: (details) async {
        _soundsRecorder.endRec();
      },
      // 按钮组件
      child: ValueListenableBuilder(
        valueListenable: _soundsRecorder.status,
        builder: (context, value, child) {
          if (widget.builder != null) {
            return widget.builder?.call(context, value);
          }

          return Container(
            // margin: EdgeInsets.symmetric(horizontal: 16.sp),
            height: 44.sp,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: widget.customDecoration ??
                BoxDecoration(
                  borderRadius: BorderRadius.circular(4.sp),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey, width: 1.sp),
                  boxShadow: const [
                    BoxShadow(color: Color(0xffeeeeee), blurRadius: 2)
                  ],
                ),
            child: Text(
              value.title,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}
