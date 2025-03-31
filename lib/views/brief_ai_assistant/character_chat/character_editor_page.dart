import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../../common/components/tool_widget.dart';
import '../../../common/llm_spec/constant_llm_enum.dart';
import '../../../models/brief_ai_tools/character_chat/character_card.dart';
import '../../../models/brief_ai_tools/character_chat/character_store.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../services/model_manager_service.dart';
import '../_chat_components/_small_tool_widgets.dart';
import 'components/model_selector_dialog.dart';

class CharacterEditorPage extends StatefulWidget {
  final CharacterCard? character;

  const CharacterEditorPage({super.key, this.character});

  @override
  State<CharacterEditorPage> createState() => _CharacterEditorPageState();
}

class _CharacterEditorPageState extends State<CharacterEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _personalityController = TextEditingController();
  final _scenarioController = TextEditingController();
  final _firstMessageController = TextEditingController();
  final _exampleDialogueController = TextEditingController();
  final _tagsController = TextEditingController();

  String _avatarPath = '';
  String? _backgroundPath;
  double _backgroundOpacity = 0.2;
  CusBriefLLMSpec? _preferredModel;
  bool _isEditing = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.character != null;

    if (_isEditing) {
      _nameController.text = widget.character!.name;
      _descriptionController.text = widget.character!.description;
      _personalityController.text = widget.character!.personality;
      _scenarioController.text = widget.character!.scenario;
      _firstMessageController.text = widget.character!.firstMessage;
      _exampleDialogueController.text = widget.character!.exampleDialogue;
      _tagsController.text = widget.character!.tags.join(', ');
      _avatarPath = widget.character!.avatar;
      _backgroundPath = widget.character!.background;
      _backgroundOpacity = widget.character!.backgroundOpacity ?? 0.2;
      _preferredModel = widget.character!.preferredModel;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _personalityController.dispose();
    _scenarioController.dispose();
    _firstMessageController.dispose();
    _exampleDialogueController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _selectModel() async {
    final availableModels = await ModelManagerService.getAvailableModelByTypes([
      LLModelType.cc,
      LLModelType.vision,
      LLModelType.reasoner,
    ]);

    if (!mounted) return;
    final result = await showModalBottomSheet<CusBriefLLMSpec>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: ModelSelectorDialog(
          models: availableModels,
          selectedModel: _preferredModel,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _preferredModel = result;
      });
    }
  }

  Future<void> _saveCharacter() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isSaving = true);

    try {
      final store = CharacterStore();

      // 解析标签
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      if (_isEditing) {
        // 更新现有角色
        final updatedCharacter = CharacterCard(
          id: widget.character!.id,
          name: _nameController.text,
          avatar: _avatarPath,
          background: _backgroundPath,
          backgroundOpacity: _backgroundOpacity,
          description: _descriptionController.text,
          personality: _personalityController.text,
          scenario: _scenarioController.text,
          firstMessage: _firstMessageController.text,
          exampleDialogue: _exampleDialogueController.text,
          tags: tags,
          preferredModel: _preferredModel,
          createTime: widget.character!.createTime,
          isSystem: widget.character!.isSystem,
        );

        await store.updateCharacter(updatedCharacter);
      } else {
        // 创建新角色
        await store.createCharacter(
          CharacterCard(
            id: identityHashCode(_nameController.text).toString(),
            name: _nameController.text,
            avatar: _avatarPath,
            background: _backgroundPath,
            backgroundOpacity: _backgroundOpacity,
            description: _descriptionController.text,
            personality: _personalityController.text,
            scenario: _scenarioController.text,
            firstMessage: _firstMessageController.text,
            exampleDialogue: _exampleDialogueController.text,
            tags: tags,
            preferredModel: _preferredModel,
          ),
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      commonExceptionDialog(context, '保存角色', '保存失败: $e');
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑角色' : '创建角色'),
        actions: [
          TextButton(
            onPressed: _saveCharacter,
            child: Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.sp),
          children: [
            // 头像选择
            _buildAvatarSelector(),
            SizedBox(height: 16.sp),

            // 背景选择
            _buildBackgroundSelector(),
            SizedBox(height: 16.sp),

            Padding(
              padding: EdgeInsets.only(left: 8.sp, bottom: 16.sp),
              child: Text('角色ID: ${widget.character?.id ?? '<等待创建>'}'),
            ),

            // 基本信息
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '角色名称*',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入角色名称';
                }
                return null;
              },
            ),
            SizedBox(height: 16.sp),

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '角色描述*',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入角色描述';
                }
                return null;
              },
            ),
            SizedBox(height: 16.sp),

            // 模型选择
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade600),
                borderRadius: BorderRadius.circular(4.sp),
              ),
              child: ListTile(
                title: const Text('偏好模型'),
                subtitle: Text(_preferredModel?.name ?? '未设置'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _selectModel,
              ),
            ),

            SizedBox(height: 16.sp),

            // 高级设置
            ExpansionTile(
              title: const Text('高级设置'),
              initiallyExpanded: _isEditing,
              children: [
                TextFormField(
                  controller: _personalityController,
                  decoration: const InputDecoration(
                    labelText: '性格特点',
                    border: OutlineInputBorder(),
                    hintText: '例如：友好、耐心、幽默...',
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 16.sp),
                TextFormField(
                  controller: _scenarioController,
                  decoration: const InputDecoration(
                    labelText: '场景设定',
                    border: OutlineInputBorder(),
                    hintText: '角色所处的环境或背景...',
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 16.sp),
                TextFormField(
                  controller: _firstMessageController,
                  decoration: const InputDecoration(
                    labelText: '首条消息',
                    border: OutlineInputBorder(),
                    hintText: '角色的第一句话...',
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 16.sp),
                TextFormField(
                  controller: _exampleDialogueController,
                  decoration: const InputDecoration(
                    labelText: '对话示例',
                    border: OutlineInputBorder(),
                    hintText: '示例对话，帮助AI理解角色的说话方式...',
                  ),
                  maxLines: 4,
                ),
                SizedBox(height: 16.sp),
                TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: '标签',
                    border: OutlineInputBorder(),
                    hintText: '用逗号分隔，例如：幽默,科幻,助手',
                  ),
                ),
                SizedBox(height: 16.sp),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 头像选择
  Widget _buildAvatarSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _showAvatarOrBgOptions('avatar'),
          child: Container(
            width: 80.sp,
            height: 80.sp,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: buildAvatarClipOval(_avatarPath),
          ),
        ),
        Text(
          '点击头像选择',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12.sp),
        ),
      ],
    );
  }

  // 背景选择
  Widget _buildBackgroundSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('角色专属背景',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 8.sp),
        Row(
          children: [
            GestureDetector(
              onTap: () => _showAvatarOrBgOptions('bg'),
              child: Container(
                width: 120.sp,
                height: 80.sp,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.sp),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _buildBgChild(),
              ),
            ),
            SizedBox(width: 4.sp),
            Expanded(
              child: Text(
                '点击图片设置角色专属背景',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12.sp),
              ),
            ),
            if (_backgroundPath != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _backgroundPath = null;
                  });
                },
                tooltip: '移除背景',
              ),
          ],
        ),
        if (_backgroundPath != null) ...[
          SizedBox(height: 16.sp),
          Text('背景透明度', style: TextStyle(fontSize: 14.sp)),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _backgroundOpacity,
                  min: 0.1,
                  max: 1.0,
                  onChanged: (value) {
                    setState(() {
                      _backgroundOpacity = value;
                    });
                  },
                ),
              ),
              Text('${((_backgroundOpacity * 100).toInt())}%'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBgChild() {
    return _backgroundPath == null
        ? Center(
            child: Icon(Icons.add_photo_alternate,
                size: 32.sp, color: Colors.grey))
        : Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.sp),
                child: Opacity(
                  opacity: _backgroundOpacity,
                  child: buildCusImage(_backgroundPath!, fit: BoxFit.cover),
                ),
              ),
              Center(
                child: Container(
                  padding: EdgeInsets.all(8.sp),
                  // 用户的字体颜色和AI响应的字体颜色不一样
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '透明度: ${(_backgroundOpacity * 100).toInt()}%',
                        style: TextStyle(color: Colors.black),
                      ),
                      Text(
                        '透明度: ${(_backgroundOpacity * 100).toInt()}%',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
  }

  // 显示头像或背景选项
  void _showAvatarOrBgOptions(String type) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('相册'),
            onTap: () {
              Navigator.pop(context);
              _pickImageFromGallery(type);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('拍照'),
            onTap: () {
              Navigator.pop(context);
              _pickImageFromCamera(type);
            },
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('网络图片地址'),
            onTap: () {
              Navigator.pop(context);
              _inputNetworkImageUrl(type);
            },
          ),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('选择预设图片'),
            onTap: () {
              Navigator.pop(context);
              _showPresetAvatars(type);
            },
          ),
        ],
      ),
    );
  }

  // 从相册选择图片
  // type: avatar 头像, bg 背景
  Future<void> _pickImageFromGallery(String type) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // 复制图片到应用目录
      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          '${type == 'avatar' ? 'character_avatar' : 'character_bg'}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage =
          await File(pickedFile.path).copy('${appDir.path}/$fileName');

      setState(() {
        if (type == 'avatar') {
          _avatarPath = savedImage.path;
        } else {
          _backgroundPath = savedImage.path;
        }
      });
    }
  }

  // 使用相机拍照
  Future<void> _pickImageFromCamera(String type) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      // 复制图片到应用目录
      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          '${type == 'avatar' ? 'character_avatar' : 'character_bg'}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage =
          await File(pickedFile.path).copy('${appDir.path}/$fileName');

      setState(() {
        if (type == 'avatar') {
          _avatarPath = savedImage.path;
        } else {
          _backgroundPath = savedImage.path;
        }
      });
    }
  }

  // 输入网络图片地址
  void _inputNetworkImageUrl(String type) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('输入网络图片地址'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'https://example.com/image.jpg',
                labelText: '图片URL',
              ),
              keyboardType: TextInputType.url,
            ),
            SizedBox(height: 16.sp),
            // 预览区域
            if (textController.text.isNotEmpty)
              Container(
                width: 100.sp,
                height: 100.sp,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8.sp),
                ),
                child: Image.network(
                  textController.text,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                        child: Text('图片加载失败',
                            style: TextStyle(color: Colors.red)));
                  },
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                setState(() {
                  if (type == 'avatar') {
                    _avatarPath = textController.text;
                  } else {
                    _backgroundPath = textController.text;
                  }
                });
              }
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 显示预设头像或背景
  void _showPresetAvatars(String type) {
    final presetAvatars = (type == 'avatar')
        ? [
            'assets/characters/default_avatar.png',
            // ... 其他本地预设头像

            // 添加一些网络预设头像
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=256&auto=format&fit=crop',
            'https://images.unsplash.com/photo-1568602471122-7832951cc4c5?q=80&w=256&auto=format&fit=crop',
            'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?q=80&w=256&auto=format&fit=crop',
            'https://images.unsplash.com/photo-1564564321837-a57b7070ac4f?q=80&w=256&auto=format&fit=crop',
            'https://images.unsplash.com/photo-1567532939604-b6b5b0db2604?q=80&w=256&auto=format&fit=crop',
          ]
        : [
            'assets/chat_backgrounds/bg1.jpg',
            'assets/chat_backgrounds/bg2.jpg',
          ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('预设${type == 'avatar' ? '头像' : '背景'}(示例)'),
        content: SizedBox(
          width: 0.8.sw,
          height: 0.36.sh,
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8.sp,
              mainAxisSpacing: 8.sp,
            ),
            itemCount: presetAvatars.length,
            itemBuilder: (context, index) {
              final avatar = presetAvatars[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (type == 'avatar') {
                      _avatarPath = avatar;
                    } else {
                      _backgroundPath = avatar;
                    }
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: (type == 'avatar')
                      ? buildAvatarClipOval(avatar)
                      : buildAvatarClipOval(avatar,
                          clipBehavior: Clip.none, fit: BoxFit.scaleDown),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}
