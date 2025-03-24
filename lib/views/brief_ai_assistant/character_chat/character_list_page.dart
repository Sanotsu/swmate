import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/utils/tools.dart';
import '../../../models/brief_ai_tools/character_chat/character_card.dart';
import '../../../models/brief_ai_tools/character_chat/character_chat_session.dart';
import '../../../models/brief_ai_tools/character_chat/character_store.dart';
import '../../../services/cus_get_storage.dart';
import 'components/character_card_item.dart';
import 'character_chat_page.dart';
import 'character_editor_page.dart';
import 'components/character_chat_background_picker.dart';

class CharacterListPage extends StatefulWidget {
  const CharacterListPage({super.key});

  @override
  State<CharacterListPage> createState() => _CharacterListPageState();
}

class _CharacterListPageState extends State<CharacterListPage> {
  final CharacterStore _store = CharacterStore();
  List<CharacterCard> _characters = [];
  List<CharacterCard> _filteredCharacters = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    setState(() => _isLoading = true);

    await _store.initialize();
    _characters = _store.characters;
    _applyFilter();

    setState(() => _isLoading = false);
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredCharacters = List.from(_characters);
    } else {
      _filteredCharacters = _characters.where((character) {
        return character.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            character.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            character.tags.any((tag) =>
                tag.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('角色列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.wallpaper),
            onPressed: _showBackgroundPicker,
          ),
          IconButton(
            icon: const Icon(Icons.import_export),
            onPressed: _showImportExportDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToCharacterEditor,
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: EdgeInsets.all(8.sp),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索角色...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.sp),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilter();
                });
              },
            ),
          ),

          // 角色卡列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCharacters.isEmpty
                    ? const Center(child: Text('没有找到角色卡'))
                    : GridView.builder(
                        padding: EdgeInsets.all(8.sp),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 6 / 9,
                          crossAxisSpacing: 10.sp,
                          mainAxisSpacing: 10.sp,
                        ),
                        itemCount: _filteredCharacters.length,
                        itemBuilder: (context, index) {
                          final character = _filteredCharacters[index];

                          return CharacterCardItem(
                            character: character,
                            onTap: () => _handleCharacterTap(character),
                            onEdit: () => _navigateToCharacterEditor(
                                character: character),
                            onDelete: () => _deleteCharacter(character),
                          );
                        },
                      ),
          ),

          // SizedBox(height: 68.sp),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCharacterEditor,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _handleCharacterTap(CharacterCard character) async {
    await _store.initialize();

    final characterSessions = _store.sessions
        .where((s) => s.characters.any((c) => c.id == character.id))
        .toList();

    characterSessions.sort((a, b) => b.updateTime.compareTo(a.updateTime));

    CharacterChatSession? session;
    if (characterSessions.isNotEmpty) {
      session = characterSessions.first;

      // 更新会话中的角色信息，确保使用最新的角色卡
      await _store.updateSessionCharacters(session);

      // 重新获取更新后的会话
      session = _store.sessions.firstWhere((s) => s.id == session!.id);
    } else {
      if (character.preferredModel == null) {
        EasyLoading.showToast('请先为该角色设置偏好模型\n长按角色卡点击"编辑角色"');
        return;
      }

      session = await _store.createSession(
        title: '与${character.name}的对话',
        characters: [character],
        activeModel: character.preferredModel,
      );
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CharacterChatPage(session: session!),
      ),
    ).then((_) {
      _loadCharacters();
    });
  }

  void _navigateToCharacterEditor({CharacterCard? character}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CharacterEditorPage(character: character),
      ),
    );

    if (result == true) {
      _loadCharacters();
    }
  }

  Future<void> _deleteCharacter(CharacterCard character) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除角色'),
        content: Text('确定要删除角色"${character.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _store.deleteCharacter(character.id);
      _loadCharacters();
    }
  }

  void _showImportExportDialog() async {
    bool isGranted = await requestStoragePermission();

    if (!mounted) return;
    if (!isGranted) {
      commonExceptionDialog(context, "异常提示", "无存储访问授权");
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入/导出'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.upload),
              title: const Text('导出角色'),
              onTap: () {
                Navigator.pop(context);
                _exportCharacters();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('导入角色'),
              onTap: () {
                Navigator.pop(context);
                _importCharacters();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCharacters() async {
    try {
      // 先让用户选择保存位置
      final directoryResult = await FilePicker.platform.getDirectoryPath();
      if (directoryResult == null) return; // 用户取消了选择

      final store = CharacterStore();
      final filePath =
          await store.exportCharacters(customPath: directoryResult);

      if (!mounted) return;

      commonHintDialog(context, '导出角色', '角色已导出到: $filePath');
    } catch (e) {
      if (!mounted) return;

      commonExceptionDialog(context, '导出角色', '导出失败: $e');
    }
  }

  Future<void> _importCharacters() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path;
      if (filePath == null) return;

      final store = CharacterStore();
      final importResult = await store.importCharacters(filePath);

      if (!mounted) return;

      String message;
      if (importResult.importedCount > 0) {
        message = '成功导入 ${importResult.importedCount} 个角色';
        if (importResult.skippedCount > 0) {
          message += '，跳过 ${importResult.skippedCount} 个已存在的角色';
        }
      } else {
        message = '没有导入任何角色，所有角色已存在';
      }

      commonHintDialog(context, '导入角色', message);

      // 刷新列表
      _loadCharacters();
    } catch (e) {
      if (!mounted) return;

      commonExceptionDialog(context, '导入角色', '导入失败: $e');
    }
  }

  // 显示背景选择器
  void _showBackgroundPicker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CharacterChatBackgroundPicker(),
      ),
    ).then((confirmed) async {
      // 只有在用户点击了确定按钮时才重新加载背景设置
      if (confirmed == true) {
        // 存储器
        final MyGetStorage storage = MyGetStorage();

        // 如果没有专属背景，则加载通用背景设置
        await storage.getCharacterChatBackground();
        await storage.getCharacterChatBackgroundOpacity();
      }
    });
  }
}
