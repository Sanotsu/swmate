import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';

import '../../apis/_self_model_list/index.dart';
import '../../common/constants.dart';
import '../../common/utils/db_tools/db_helper.dart';
import '../../services/cus_get_storage.dart';
import '../ai_assistant/_helper/tools.dart';
import '../home.dart';
import 'backup_and_restore/index.dart';

final DBHelper dbHelper = DBHelper();

class UserAndSettings extends StatefulWidget {
  const UserAndSettings({super.key});

  @override
  State<UserAndSettings> createState() => _UserAndSettingsState();
}

class _UserAndSettingsState extends State<UserAndSettings> {
  // 用户头像路径
  String? _avatarPath = MyGetStorage().getUserAvatarPath();

  // 修改头像
  // 选择图片来源
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      await MyGetStorage().setUserAvatarPath(pickedFile.path);
      setState(() {
        _avatarPath = pickedFile.path;
      });
    }
  }

  // 长按5秒启动作者测试的模型(但是付费的还是用不了，没有加载作者的密钥)
  Timer? _timer;
  void _startTimer() {
    _timer = Timer(const Duration(seconds: 3), () async {
      await testInitModelAndSysRole(SELF_MODELS);
      EasyLoading.showInfo("已启用作者的测试模型列表");
    });
  }

  void _cancelTimer() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 计算屏幕剩余的高度
    // 设备屏幕的总高度
    //  - 屏幕顶部的安全区域高度，即状态栏的高度
    //  - 屏幕底部的安全区域高度，即导航栏的高度或者虚拟按键的高度
    //  - 应用程序顶部的工具栏（如 AppBar）的高度
    //  - 应用程序底部的导航栏的高度
    //  - 组件的边框间隔(不一定就是2)
    double screenBodyHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom -
        kToolbarHeight -
        kBottomNavigationBarHeight;

    debugPrint("screenBodyHeight--------$screenBodyHeight");

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPressStart: (_) => _startTimer(),
          onLongPressEnd: (_) => _cancelTimer(),
          child: const Text('用户设置'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(
                      "选择头像来源",
                      style: TextStyle(fontSize: 18.sp),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _pickImage(ImageSource.camera);
                        },
                        child: const Text("拍照"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _pickImage(ImageSource.gallery);
                        },
                        child: const Text("相册"),
                      ),
                    ],
                  );
                },
              );
            },
            child: const Text("更换头像"),
          ),
        ],
      ),
      body: ListView(
        children: [
          /// 用户基本信息展示区域
          ..._buildBaseUserInfoArea(),

          SizedBox(height: 50.sp),
          // 备份还原和更多设置
          SizedBox(
            // height: (screenBodyHeight - 250 - 20),
            height: 160.sp,
            child: Center(child: _buildBakAndRestoreAndMoreSettingRow()),
          ),
        ],
      ),
    );
  }

  // 用户基本信息展示区域
  _buildBaseUserInfoArea() {
    return [
      SizedBox(height: 10.sp),
      Stack(
        alignment: Alignment.center,
        children: [
          // 没有修改头像，就用默认的
          if (_avatarPath == null)
            CircleAvatar(
              maxRadius: 60.sp,
              backgroundColor: Colors.transparent,
              backgroundImage: const AssetImage(brandImageUrl),
              // y圆形头像的边框线
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 2.sp,
                  ),
                ),
              ),
            ),
          if (_avatarPath != null)
            GestureDetector(
              onTap: () {
                // 这个直接弹窗显示图片可以缩放
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return Dialog(
                      backgroundColor: Colors.transparent, // 设置背景透明
                      child: PhotoView(
                        imageProvider: FileImage(File(_avatarPath!)),
                        // 设置图片背景为透明
                        backgroundDecoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        // 可以旋转
                        // enableRotation: true,
                        // 缩放的最大最小限制
                        minScale: PhotoViewComputedScale.contained * 0.8,
                        maxScale: PhotoViewComputedScale.covered * 2,
                        errorBuilder: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    );
                  },
                );
              },
              child: CircleAvatar(
                maxRadius: 60.sp,
                backgroundImage: FileImage(File(_avatarPath!)),
              ),
            ),
        ],
      ),
    ];
  }

  _buildBakAndRestoreAndMoreSettingRow() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: SizedBox(
            height: 80.sp,
            child: NewCusSettingCard(
              leadingIcon: Icons.backup_outlined,
              title: "备份恢复",
              onTap: () {
                // 处理相应的点击事件
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BackupAndRestore(),
                  ),
                );
              },
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 80.sp,
            child: NewCusSettingCard(
              leadingIcon: Icons.question_mark,
              title: '常见问题(TBD)',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'SWMate',
                  children: [
                    const Text("author: SanotSu"),
                    const Text("wechat: SanotSu"),
                    const Text("github: https://github.com/Sanotsu/swmate"),
                  ],
                );
              },
            ),
          ),
        )
      ],
    );
  }
}

// 每个设置card抽出来复用
class NewCusSettingCard extends StatelessWidget {
  final IconData leadingIcon;
  final String title;
  final VoidCallback onTap;

  const NewCusSettingCard({
    super.key,
    required this.leadingIcon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(2.sp),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.sp),
        ),
        child: Center(
          child: ListTile(
            leading: Icon(leadingIcon),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

// 重新加载应用程序以更新UI
void reloadApp(BuildContext context) {
  // ???2024-07-12 这里有问题，新版本在切换语言后重载，会出现OnBackInvokedCallback is not enabled for the application.
  // 即便已经在manifest文件进行配置了，现象类似：https://github.com/flutter/flutter/issues/146132
  // 这会导致在连续的pop 例如Navigator.of(context)..pop()..pop();
  //    或者两个Navigator.of(context).pop();Navigator.of(context).pop(); 的地方出现白屏，找不到路径的现象
  // 暂未解决
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const HomePage()),
    (route) => false,
  );
}
