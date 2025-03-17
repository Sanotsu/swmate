import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../common/llm_spec/constant_llm_enum.dart';
import '../../../models/brief_ai_tools/character_chat/character_card.dart';
import '../../../models/brief_ai_tools/character_chat/character_store.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../services/model_manager_service.dart';
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
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: CircleAvatar(
                  radius: 50.sp,
                  backgroundImage: _getAvatarProvider(),
                  child: _avatarPath.isEmpty
                      ? Icon(Icons.add_a_photo, size: 40.sp)
                      : null,
                ),
              ),
            ),
            SizedBox(height: 16.sp),

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

                // 模型选择
                ListTile(
                  title: const Text('偏好模型'),
                  subtitle: Text(_preferredModel?.name ?? '未设置'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _selectModel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _getAvatarProvider() {
    if (_avatarPath.isEmpty) {
      return null;
    } else if (_avatarPath.startsWith('assets/')) {
      return AssetImage(_avatarPath);
    } else {
      return FileImage(File(_avatarPath));
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // 复制图片到应用目录
      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          'character_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage =
          await File(pickedFile.path).copy('${appDir.path}/$fileName');

      setState(() {
        _avatarPath = savedImage.path;
      });
    }
  }

  Future<void> _selectModel() async {
    final availableModels = await ModelManagerService.getAvailableModelByTypes([
      LLModelType.cc,
      LLModelType.vision,
      LLModelType.reasoner,
    ]);

    if (!mounted) return;

    final result = await showDialog<CusBriefLLMSpec>(
      context: context,
      builder: (context) => ModelSelectorDialog(
        models: availableModels,
        selectedModel: _preferredModel,
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
          name: _nameController.text,
          avatar: _avatarPath,
          description: _descriptionController.text,
          personality: _personalityController.text,
          scenario: _scenarioController.text,
          firstMessage: _firstMessageController.text,
          exampleDialogue: _exampleDialogueController.text,
          tags: tags,
          preferredModel: _preferredModel,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }
}
