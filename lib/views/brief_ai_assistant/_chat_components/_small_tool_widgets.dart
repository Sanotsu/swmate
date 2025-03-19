// 构建角色头像,如果区分是本地图片或内部资源图片
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/constants/constants.dart';

// 构建空提示
Widget buildEmptyHint() {
  return Padding(
    padding: EdgeInsets.all(32.sp),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat, size: 36.sp, color: Colors.blue),
          Text(
            '嗨，我是思文',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '我可以帮您完成很多任务，让我们开始吧！',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    ),
  );
}

// 调整对话列表中显示的文本大小
void adjustTextScale(
  BuildContext context,
  double textScaleFactor,
  Function(double) onTextScaleChanged,
) async {
  var tempScaleFactor = textScaleFactor;
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          '调整对话列表中文字大小',
          style: TextStyle(fontSize: 18.sp),
        ),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: tempScaleFactor,
                  min: 0.6,
                  max: 2.0,
                  divisions: 14,
                  label: tempScaleFactor.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      tempScaleFactor = value;
                    });
                  },
                ),
                Text(
                  '当前文字比例: ${tempScaleFactor.toStringAsFixed(1)}',
                  textScaler: TextScaler.linear(tempScaleFactor),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            child: const Text('取消'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('确定'),
            onPressed: () async {
              // 点击确定时，才把缩放比例存入缓存，并更新当前比例值
              onTextScaleChanged(tempScaleFactor);
            },
          ),
        ],
      );
    },
  );
}

// 优化菜单项样式
Widget buildMenuItemWithIcon({
  required IconData icon,
  required String text,
  Color? color,
}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center, // 居中对齐
    children: [
      Icon(icon, size: 16.sp, color: color),
      SizedBox(width: 8.sp),
      Text(
        text,
        style: TextStyle(
          fontSize: 14.sp,
          color: color,
        ),
      ),
    ],
  );
}

///
/// 主要角色对话中用到
///
// 构建角色头像
Image buildAssetOrFileImage(String avatar, {BoxFit fit = BoxFit.scaleDown}) {
  return avatar.startsWith('assets/')
      ? buildAssetImage(avatar, fit: fit)
      : buildFileImage(avatar, fit: fit);
}

Image buildAssetImage(String path, {BoxFit fit = BoxFit.scaleDown}) {
  return Image.asset(
    path,
    fit: fit,
    errorBuilder: (context, error, stackTrace) {
      return Image.asset(placeholderImageUrl, fit: BoxFit.scaleDown);
    },
  );
}

Image buildFileImage(String path, {BoxFit fit = BoxFit.scaleDown}) {
  return Image.file(
    File(path),
    fit: fit,
    errorBuilder: (context, error, stackTrace) {
      return Image.asset(placeholderImageUrl, fit: BoxFit.scaleDown);
    },
  );
}

// 获取角色头像的ImageProvider
ImageProvider? getAvatarProvider(String avatar) {
  if (avatar.isEmpty) {
    return null;
  } else if (avatar.startsWith('assets/')) {
    return AssetImage(avatar);
  } else {
    return FileImage(File(avatar));
  }
}

// 构建角色头像，如果图片加载失败，则显示默认头像
Widget buildCharacterCircleAvatar(
  String avatar, {
  double? radius,
  Widget? child,
}) {
  return CircleAvatar(
    radius: radius ?? 20.sp,
    backgroundImage: getAvatarProvider(avatar),
    onBackgroundImageError: (_, __) {
      print('构建角色头像失败: $avatar');
    },
    child: child,
  );
}
