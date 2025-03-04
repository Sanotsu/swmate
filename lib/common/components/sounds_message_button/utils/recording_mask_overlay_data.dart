import 'package:flutter/material.dart';

/// 当正在录制的时候，页面显示的 `OverlayEntry`
class RecordingMaskOverlayData {
  /// 底部圆形的高度
  final double sendAreaHeight;

  /// 圆形图形大小
  final double iconSize;

  /// 圆形图形大小 - 响应
  final double iconFocusSize;

  /// 录音气泡大小
  // final EdgeInsets soundsMargin;

  /// 圆形图形颜色
  final Color iconColor;

  /// 圆形图形颜色 - 响应
  final Color iconFocusColor;

  /// 文字颜色
  final Color iconTxtColor;

  /// 文字颜色 - 响应
  final Color iconFocusTxtColor;

  /// 遮罩文字样式
  final TextStyle maskTxtStyle;

  const RecordingMaskOverlayData({
    this.sendAreaHeight = 120,
    this.iconSize = 68,
    this.iconFocusSize = 80,
    this.iconColor = const Color(0xff393939),
    this.iconFocusColor = const Color(0xffffffff),
    this.iconTxtColor = const Color(0xff909090),
    this.iconFocusTxtColor = const Color(0xff000000),
    // this.soundsMargin = const EdgeInsets.symmetric(horizontal: 24),
    this.maskTxtStyle = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Color(0xff909090),
    ),
  });
}
