part of 'sounds_message_button.dart';

/// 聚合数据，用于整个UI的配置数据流通
class PolymerData {
  PolymerData(this.controller, this.data);

  /// 逻辑处理
  final SoundsRecorderController controller;

  /// 语音输入时遮罩配置
  final RecordingMaskOverlayData data;
}

/// 聚合状态
class PolymerState extends InheritedWidget {
  const PolymerState({
    super.key,
    required this.data,
    required super.child,
  });

  final PolymerData data;

  // 子树中的widget获取共享数据
  static PolymerData of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PolymerState>();
    return scope!.data;
  }

  @override
  bool updateShouldNotify(covariant PolymerState oldWidget) {
    return oldWidget.data != data;
  }
}

/// 录音时的遮罩视图
class RecordingStatusMaskView extends StatelessWidget {
  const RecordingStatusMaskView(
    this.polymerData, {
    super.key,
    this.onCancelSend,
    this.onVoiceSend,
    this.onTextSend,
  });

  // 聚合数据
  final PolymerData polymerData;
  // 取消发送
  final VoidCallback? onCancelSend;
  // 原音发送
  final VoidCallback? onVoiceSend;
  // 文字发送
  final VoidCallback? onTextSend;

  @override
  Widget build(BuildContext context) {
    final paddingSide =
        (ScreenUtil().screenWidth - polymerData.data.iconFocusSize * 3) / 3;

    final data = polymerData.data;

    return Material(
      // type: MaterialType.transparency,
      // color: Colors.transparent,
      color: Colors.black.withValues(alpha: 0.7),
      child: PolymerState(
        data: polymerData,
        // 状态监听
        child: ValueListenableBuilder(
          valueListenable: polymerData.controller.status,
          builder: (context, value, child) {
            /// 如果语音转文字已经完成时的布局(即长按松开滑向转文字后)
            if (value == SoundsMessageStatus.textProcessed) {
              return _MaskStackView(
                children: [
                  /// 从上往下、从左往右

                  /// 语音转文字显示的气泡
                  _Bubble(paddingSide: paddingSide),

                  /// 取消发送的按钮的位置
                  Positioned(
                    bottom: data.sendAreaHeight + data.iconFocusSize / 3,
                    right: paddingSide + data.iconFocusSize + 45 * 4,
                    child: _TextCancelSend(onCancelSend),
                  ),

                  /// 发送语音的按钮的位置
                  Positioned(
                    bottom: data.sendAreaHeight + data.iconFocusSize / 3,
                    right: paddingSide + data.iconFocusSize + 45,
                    child: _TextVoiceSend(onVoiceSend),
                  ),

                  /// 语言转文字发送的按钮的位置
                  Positioned(
                    bottom: polymerData.data.sendAreaHeight + 15,
                    right: paddingSide,
                    child: _TextProcessedCircle(
                      data: data,
                      onTap: onTextSend,
                      onLoading: () async {
                        // 2024-08-07 这里的一切都是按照正常成功的逻辑来写的；
                        // 如果发生了异常(比如网络不通什么的)，就没有处理

                        // 语音文件地址
                        var pathUrl = polymerData.controller.path.value ?? '';

                        /// 同一份语言有两个部分，一个是原始录制的m4a的格式，一个是转码厚的pcm格式
                        /// 前者用于语音识别，后者用于播放
                        String tempPath = path.join(
                          path.dirname(pathUrl),
                          path.basenameWithoutExtension(pathUrl),
                        );

                        var transcription =
                            await getTextFromAudioFromXFYun("$tempPath.pcm");

                        // 更新完文字之后，转换标志就为true了
                        polymerData.controller
                            .updateTextProcessed(transcription);

                        return true;
                      },
                    ),
                  ),
                ],
              );
            }

            /// 默认就是长按录制语言时的布局
            return _MaskStackView(
              children: [
                // 左侧取消按钮
                Positioned(
                  bottom: data.sendAreaHeight + 15,
                  left: paddingSide,
                  child: _CircleButton(
                    title: value.title,
                    isFocus: value == SoundsMessageStatus.canceling,
                  ),
                ),
                // 右侧转文字按钮
                Positioned(
                  bottom: data.sendAreaHeight + 15,
                  right: paddingSide,
                  child: _CircleButton(
                    title: value.title,
                    isFocus: value == SoundsMessageStatus.textProcessing,
                    isLeft: false,
                  ),
                ),
                // 上方录制语音的振幅气泡
                _Bubble(paddingSide: paddingSide),
                // 下方松开就发送的小扇形区域
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Visibility(
                      visible: value == SoundsMessageStatus.recording,
                      child: Text(value.title, style: data.maskTxtStyle),
                    ),
                    const SizedBox(height: 8),
                    CustomPaint(
                      size: Size(double.infinity, data.sendAreaHeight),
                      painter: _RecordingPainter(
                        value == SoundsMessageStatus.recording,
                      ),
                      child: Container(
                        width: double.infinity,
                        height: data.sendAreaHeight,
                        alignment: Alignment.center,
                        child: VoiceIcon(color: data.iconTxtColor),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 圆形按钮
class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.title,
    this.isFocus = false,
    this.isLeft = true,
  });

  final String title;

  /// 是否为焦点
  final bool isFocus;

  /// 是否为左边
  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    final polymerState = PolymerState.of(context);

    final data = polymerState.data;

    final size = isFocus ? data.iconFocusSize : data.iconSize;

    double marginSide =
        0 + (isFocus ? 0.5 : 1) * (data.iconFocusSize - data.iconSize);

    return Column(
      children: [
        Visibility(
          visible: isFocus,
          child: Text(title, style: data.maskTxtStyle),
        ),
        // const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          margin: EdgeInsets.all(marginSide),
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFocus ? data.iconFocusColor : data.iconColor,
            borderRadius: BorderRadius.circular(data.iconFocusSize),
          ),
          child: Transform.rotate(
            angle: isLeft ? -0.2 : 0.2,
            child: isLeft
                ? Icon(
                    Icons.close,
                    size: 28.sp,
                    color: isFocus ? data.iconFocusTxtColor : data.iconTxtColor,
                  )
                // : Icon(
                //     Icons.text_decrease,
                //     size: 28.sp,
                //     color:
                //         isFocus ? data.iconFocusTxtColor : data.iconTxtColor,
                //   )
                : Text(
                    '文',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color:
                          isFocus ? data.iconFocusTxtColor : data.iconTxtColor,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// 声音图标(其他地方也可以用)
class VoiceIcon extends StatelessWidget {
  const VoiceIcon({super.key, this.color, this.size});

  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: pi / 2,
      child: Icon(Icons.wifi_rounded, size: size ?? 26.w, color: color),
    );
  }
}

/// 绘制弹框背景
///   整个页面使用 Stack 布局更为简单，那背景就是一个渐变色叠层。
class _MaskStackView extends StatelessWidget {
  const _MaskStackView({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final polymerState = PolymerState.of(context);

    return GestureDetector(
      onTap: () {
        unfocusHandle();
      },
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0xFF474747),
                    Color(0x00474747),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            child: Container(
              height: polymerState.data.sendAreaHeight +
                  polymerState.data.iconFocusSize,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0xFF474747),
                    Color(0x22474747),
                  ],
                ),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

/// 语音转文字语音录制时的振幅样式的气泡
class _Bubble extends StatelessWidget {
  const _Bubble({required this.paddingSide});

  final double paddingSide;

  @override
  Widget build(BuildContext context) {
    final polymerState = PolymerState.of(context);

    final data = polymerState.data;
    final status = polymerState.controller.status.value;

    // 80 是气泡整体高度
    var height = 64.sp;
    Rect rect = Rect.fromLTRB(24.sp, 0, 24.sp, height);

    if (status == SoundsMessageStatus.recording) {
      rect = Rect.fromLTRB(
        paddingSide + data.iconFocusSize / 2,
        0,
        paddingSide + data.iconFocusSize / 2,
        height,
      );
    } else if (status == SoundsMessageStatus.canceling) {
      rect = Rect.fromLTRB(
        paddingSide - 5.sp,
        0,
        ScreenUtil().screenWidth - data.iconFocusSize - paddingSide - 10.sp,
        height,
      );
    }

    double bottom = 0;
    if (status == SoundsMessageStatus.textProcessing ||
        status == SoundsMessageStatus.textProcessed) {
      bottom = 20.sp;
    }

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Positioned(
      left: 0,
      right: 0,
      // 键盘高度
      bottom:
          max(keyboardHeight, data.sendAreaHeight * 2 + data.iconFocusSize) +
              20.sp,
      // bottom: data.sendAreaHeight * 2 + data.iconFocusSize,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        margin: EdgeInsets.only(left: rect.left, right: rect.right, bottom: 0),
        // height: rect.height,
        // width: rect.width,
        constraints: BoxConstraints(
          minHeight: rect.height + bottom,
          maxHeight: (rect.height + bottom) * 2,
          maxWidth: rect.width,
          minWidth: rect.width,
        ),
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _BubblePainter(data, status, paddingSide),
            child: Container(
              padding: EdgeInsets.all(10.sp),
              // 根据状态判断是否显示文字还是录制中的振幅动画
              child: status == SoundsMessageStatus.textProcessing ||
                      status == SoundsMessageStatus.textProcessed
                  ? const _TextProcessedContent()
                  : const _AmpContent(),
            ),
          ),
        ),
      ),
    );
  }
}

/// 振幅动画
class _AmpContent extends StatelessWidget {
  const _AmpContent();

  @override
  Widget build(BuildContext context) {
    final polymerState = PolymerState.of(context);
    return CustomPaint(
      painter: WavePainter(polymerState.controller.amplitudeList),
    );
  }
}

/// 绘制振幅波形动画(其他地方也可以用)
class WavePainter extends CustomPainter {
  WavePainter(this.items) : super(repaint: items);

  /// values 0.0 ~ 1.0
  final ValueNotifier<List<double>> items;

  @override
  void paint(Canvas canvas, Size size) {
    // 振幅数量
    const count = 13;
    const centerConut = count ~/ 2;

    final lineSize = Size(3, size.height - 10);
    const lineSpec = 3.0;
    const radius = Radius.circular(2);

    final center = Offset(size.width / 2, size.height / 2);

    final tempList = List.generate(count, (index) {
      if (index < items.value.length - 1) {
        return items.value[index];
      }
      return 0.0;
    });

    final paint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.fill;

    final height = lineSize.height;

    lineHeight(double scale) {
      return height * min(max(scale * 1.5, 0.1), 1);
    }

    // 中间值
    canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: lineSize.width,
            height: lineHeight(tempList[centerConut]),
          ),
          radius,
        ),
        paint);

    // 边缘值
    for (var i = 0; i <= centerConut; i++) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(
                  center.dx + (lineSize.width + lineSpec) * i, center.dy),
              width: lineSize.width,
              height: lineHeight(tempList[i]),
            ),
            radius,
          ),
          paint);

      canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(
                  center.dx - (lineSize.width + lineSpec) * i, center.dy),
              width: lineSize.width,
              height: lineHeight(tempList[i]),
            ),
            radius,
          ),
          paint);
    }
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(WavePainter oldDelegate) => false;
}

/// 文字输入和振幅动画
class _TextProcessedContent extends StatefulWidget {
  const _TextProcessedContent();

  @override
  State<_TextProcessedContent> createState() => _TextProcessedContentState();
}

class _TextProcessedContentState extends State<_TextProcessedContent> {
  final focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final polymerState = PolymerState.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        focusNode.requestFocus();
      },
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: TextField(
              style: const TextStyle(fontSize: 16),
              focusNode: focusNode,
              controller: polymerState.controller.textProcessedController,
              decoration: const InputDecoration(
                fillColor: Colors.red,
                border: InputBorder.none,
                // border: OutlineInputBorder(),
                hintText: '语音转文字...',
                hintStyle:
                    TextStyle(color: ui.Color.fromARGB(148, 107, 104, 104)),
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              maxLines: null,
            ),
          ),
          Visibility(
            visible: polymerState.controller.status.value ==
                SoundsMessageStatus.textProcessing,
            child: const Positioned(
              right: 40,
              bottom: 5,
              child: _AmpContent(),
            ),
          )
        ],
      ),
    );
  }
}

/// 转文字的等待按钮
class _TextProcessedCircle extends StatelessWidget {
  const _TextProcessedCircle({
    required this.data,
    this.onLoading,
    this.onTap,
  });

  final RecordingMaskOverlayData data;

  /// 解析语音的延时操作
  final Future<bool> Function()? onLoading;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final size = data.iconFocusSize;

    double marginSide = 0.5 * (data.iconFocusSize - data.iconSize);

    return FutureBuilder<bool>(
      future: onLoading?.call(),
      builder: (context, snapshot) {
        Widget icon = const CircularProgressIndicator(
          strokeWidth: 3,
          color: Colors.orange,
        );
        if (snapshot.data == true) {
          icon = Icon(
            Icons.check_rounded,
            size: data.iconFocusSize / 2.2,
            color: Colors.orange,
          );
        }

        return GestureDetector(
          onTap: () {
            if (snapshot.data == true) {
              onTap?.call();
            }
          },
          child: Container(
            margin: EdgeInsets.all(marginSide),
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: data.iconFocusColor,
              borderRadius: BorderRadius.circular(data.iconFocusSize),
            ),
            child: icon,
          ),
        );
      },
    );
  }
}

/// 语音转文字时 - 发送语音
class _TextVoiceSend extends StatelessWidget {
  const _TextVoiceSend(this.onTap);

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: Column(
        children: [
          VoiceIcon(color: Colors.white, size: 20.sp),
          SizedBox(height: 5.sp),
          Text(
            '发送原语音',
            style: TextStyle(fontSize: 13.sp, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// 语音转文字时 - 取消发送
class _TextCancelSend extends StatelessWidget {
  const _TextCancelSend(this.onTap);

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: Column(
        children: [
          Icon(Icons.close_rounded, size: 20.sp, color: Colors.white),
          SizedBox(height: 5.sp),
          Text(
            '取消',
            style: TextStyle(fontSize: 13.sp, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
