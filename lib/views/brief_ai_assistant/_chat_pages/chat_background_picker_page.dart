import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/cus_get_storage.dart';
import '../_chat_components/_small_tool_widgets.dart';

class ChatBackgroundPickerPage extends StatefulWidget {
  const ChatBackgroundPickerPage({
    super.key,
    required this.chatType,
    required this.title,
  });

  final String chatType;
  final String title;

  @override
  State<ChatBackgroundPickerPage> createState() =>
      _ChatBackgroundPickerPageState();
}

class _ChatBackgroundPickerPageState
    extends State<ChatBackgroundPickerPage> {
  final MyGetStorage _storage = MyGetStorage();
  String? _selectedBackground;
  double _opacity = 0.2;
  bool _isLoading = true;

  // 保存初始设置，用于取消时恢复
  String? _initialBackground;
  double _initialOpacity = 0.2;

  final List<String> _defaultBackgrounds = [
    'assets/chat_backgrounds/bg1.jpg',
    'assets/chat_backgrounds/bg2.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final background = widget.chatType == 'branch'
        ? await _storage.getBranchChatBackground()
        : await _storage.getCharacterChatBackground();
    final opacity = widget.chatType == 'branch'
        ? await _storage.getBranchChatBackgroundOpacity()
        : await _storage.getCharacterChatBackgroundOpacity();

    setState(() {
      _selectedBackground = background;
      _opacity = opacity ?? 0.2;
      // 保存初始值
      _initialBackground = background;
      _initialOpacity = opacity ?? 0.2;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: () {
              // 取消操作，恢复初始设置
              if (widget.chatType == 'branch') {
                _storage.saveBranchChatBackground(_initialBackground);
                _storage.saveBranchChatBackgroundOpacity(_initialOpacity);
              } else {
                _storage.saveCharacterChatBackground(_initialBackground);
                _storage.saveCharacterChatBackgroundOpacity(_initialOpacity);
              }
              Navigator.pop(context);
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // 确认操作，保存当前设置
              _saveBackground(_selectedBackground);
              _saveOpacity(_opacity);
              Navigator.pop(context, true);
            },
            child: const Text('确定'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 背景预览区域
          if (_selectedBackground != null)
            Expanded(
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.all(16.sp),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.sp),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.sp),
                      child: Opacity(
                        opacity: _opacity,
                        child: buildCusImage(
                          _selectedBackground!,
                          fit: BoxFit.scaleDown,
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.sp,
                          vertical: 8.sp,
                        ),
                        // decoration: BoxDecoration(
                        //   color: Colors.white.withOpacity(0.7),
                        //   borderRadius: BorderRadius.circular(8.sp),
                        // ),
                        // 用户的字体颜色和AI响应的字体颜色不一样
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '透明度: ${(_opacity * 100).toInt()}%',
                              style: TextStyle(color: Colors.black),
                            ),
                            Text(
                              '透明度: ${(_opacity * 100).toInt()}%',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(16.sp),
            child: Text(
              '预设背景',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 120.sp,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.sp),
              children: [
                // 无背景选项
                GestureDetector(
                  onTap: () => _selectBackground(null),
                  child: Container(
                    width: 67.sp, // 120:67 和16:9差不了多少
                    margin: EdgeInsets.only(right: 12.sp),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8.sp),
                      border: Border.all(
                        color: _selectedBackground == null
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                        width: 2.sp,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '无背景',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                // 默认背景选项
                ..._defaultBackgrounds.map((bg) => _buildBackgroundItem(bg)),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.sp),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '自定义背景',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _pickCustomBackground,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('选择图片'),
                ),
              ],
            ),
          ),
          if (_selectedBackground != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.sp),
              child: Text(
                '背景透明度',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.sp),
              child: Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _opacity,
                      min: 0.1,
                      max: 1.0,
                      onChanged: (value) {
                        setState(() {
                          _opacity = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 8.sp),
                  Text('${(_opacity * 100).toInt()}%'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBackgroundItem(String background) {
    final isSelected = _selectedBackground == background;

    return GestureDetector(
      onTap: () => _selectBackground(background),
      child: Container(
        width: 67.sp,
        margin: EdgeInsets.only(right: 12.sp),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.sp),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            width: 2.sp,
          ),
          image: DecorationImage(
            image: AssetImage(background),
            fit: BoxFit.scaleDown,
          ),
        ),
      ),
    );
  }

  void _selectBackground(String? background) {
    setState(() {
      _selectedBackground = background;
    });
  }

  Future<void> _pickCustomBackground() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedBackground = pickedFile.path;
      });
    }
  }

  Future<void> _saveBackground(String? path) async {
    if (widget.chatType == 'branch') {
      await _storage.saveBranchChatBackground(path);
    } else {
      await _storage.saveCharacterChatBackground(path);
    }
  }

  Future<void> _saveOpacity(double opacity) async {
    if (widget.chatType == 'branch') {
      await _storage.saveBranchChatBackgroundOpacity(opacity);
    } else {
      await _storage.saveCharacterChatBackgroundOpacity(opacity);
    }
  }
}
