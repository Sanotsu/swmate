import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ChatBackgroundPicker extends StatefulWidget {
  final String? currentImage;
  final double opacity;
  final Function(double) onOpacityChanged;

  const ChatBackgroundPicker({
    super.key,
    this.currentImage,
    required this.opacity,
    required this.onOpacityChanged,
  });

  @override
  State<ChatBackgroundPicker> createState() => _ChatBackgroundPickerState();
}

class _ChatBackgroundPickerState extends State<ChatBackgroundPicker> {
  late double _currentOpacity;

  @override
  void initState() {
    super.initState();
    _currentOpacity = widget.opacity;
  }

  // 预设的背景图片列表
  static const List<String> presetBackgrounds = [
    'assets/chat_backgrounds/bg1.jpg',
    'assets/chat_backgrounds/bg2.jpg',
    // ... 添加更多预设背景
  ];

  Future<String?> _pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // 将图片复制到应用目录
      final directory = await getApplicationDocumentsDirectory();
      final String path = '${directory.path}/chat_backgrounds';
      await Directory(path).create(recursive: true);

      final String fileName =
          'custom_bg_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File newImage = await File(image.path).copy('$path/$fileName');

      return newImage.path;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('选择背景', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),

          // 透明度调节
          Row(
            children: [
              const Text('背景透明度'),
              Expanded(
                child: Slider(
                  value: _currentOpacity,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (value) {
                    setState(() => _currentOpacity = value);
                    widget.onOpacityChanged(value);
                  },
                ),
              ),
              // 添加透明度数值显示
              Text('${(_currentOpacity * 100).toStringAsFixed(0)}%'),
            ],
          ),

          // 上传自定义背景按钮
          Row(
            children: [
              Expanded(
                child: ListTile(
                  leading: const Icon(Icons.upload),
                  title: const Text('上传图片'),
                  onTap: () async {
                    final path = await _pickImage(context);
                    if (path != null && context.mounted) {
                      Navigator.pop(context, path);
                    }
                  },
                ),
              ),

              // 移除背景按钮
              if (widget.currentImage != null &&
                  widget.currentImage!.isNotEmpty)
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('移除背景'),
                    onTap: () => Navigator.pop(context, ''),
                  ),
                ),
            ],
          ),

          Divider(height: 10.sp, thickness: 1.sp),

          // 预设背景列表
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemCount: presetBackgrounds.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () => Navigator.pop(context, presetBackgrounds[index]),
                  child: Image.asset(
                    presetBackgrounds[index],
                    fit: BoxFit.scaleDown,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
