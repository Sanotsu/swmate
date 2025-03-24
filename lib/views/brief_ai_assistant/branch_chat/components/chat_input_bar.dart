import 'dart:io';

import 'package:doc_text/doc_text.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_charset_detector/flutter_charset_detector.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import '../../../../apis/voice_recognition/xunfei_apis.dart';
import '../../../../common/components/sounds_message_button/button_widget/sounds_message_button.dart';
import '../../../../common/components/sounds_message_button/utils/sounds_recorder_controller.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/llm_spec/constant_llm_enum.dart';
import '../../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../../common/utils/document_parser.dart';
import '../../../../common/utils/tools.dart';

// 定义消息数据类
class MessageData {
  final String text;
  final List<XFile>? images;
  final XFile? audio;
  final PlatformFile? file;
  final String? fileContent;
  final List<XFile>? videos;
  // 可以根据需要添加更多类型

  const MessageData({
    required this.text,
    this.images,
    this.audio,
    this.file,
    this.fileContent,
    this.videos,
  });
}

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(MessageData) onSend;
  final VoidCallback? onCancel;
  final bool isEditing;
  final bool isStreaming;
  final VoidCallback? onStop;
  final FocusNode? focusNode;
  final CusBriefLLMSpec? model;
  // 输入框高度变化回调
  // (切换模型后，可能会展开/收起更多工具栏，导致整个输入区域变化。
  // 而主页面的悬浮开启新对话、滚动到底部按钮是相对固定在输入框上面一点
  // 输入框高度变化了，也要通知父组件，让父组件重新布局悬浮按钮)
  final ValueChanged<double>? onHeightChanged;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onCancel,
    this.isEditing = false,
    this.isStreaming = false,
    this.onStop,
    this.focusNode,
    this.model,
    this.onHeightChanged,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _showToolbar = false;
  final _picker = ImagePicker();
  List<XFile>? _selectedImages;
  XFile? _selectedAudio;
  // 被选中的文件
  PlatformFile? _selectedFile;
  // 文件是否在解析中
  bool isLoadingDocument = false;
  // 解析后的文件内容
  String fileContent = '';

  bool _isVoiceMode = false;

  // 获取当前模型支持的工具列表
  List<ToolItem> get _toolItems {
    if (widget.model == null) return [];

    final List<ToolItem> tools = [
      // 基础工具 - 所有模型都支持
      ToolItem(
        icon: Icons.file_open,
        label: '文档',
        type: 'upload_file',
        onTap: _handleFileUpload,
        color: Colors.grey,
      ),
    ];

    // 根据模型类型添加特定工具
    switch (widget.model!.modelType) {
      case LLModelType.vision:
        tools.addAll([
          ToolItem(
            icon: Icons.image,
            label: '相册',
            type: 'upload_image',
            onTap: () => _handleImagePick(ImageSource.gallery),
          ),
          ToolItem(
            icon: Icons.camera_alt,
            label: '拍照',
            type: 'take_photo',
            onTap: () => _handleImagePick(ImageSource.camera),
          ),
        ]);
        break;
      case LLModelType.audio:
        tools.add(
          ToolItem(
            icon: Icons.mic,
            label: '音频',
            type: 'upload_audio',
            onTap: _handleAudioUpload,
          ),
        );
        break;
      case LLModelType.cc:
      default:
        break;
    }

    return tools;
  }

  // 添加一个变量记录上次通知给父组件输入框的高度
  // (高度有变化后才重新通知，避免在didUpdateWidget中重复通知)
  double _lastNotifiedHeight = 0;

  final GlobalKey _containerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 初始化时获取输入框高度
    _notifyHeightChange();
  }

  Future<bool> _checkPermissions() async {
    if (!(await requestMicrophonePermission())) {
      if (!mounted) return false;
      commonExceptionDialog(
        context,
        '未授权语音录制权限',
        '未授权语音录制权限，无法语音输入',
      );
      return false;
    }
    if (!(await requestStoragePermission())) {
      if (!mounted) return false;
      commonExceptionDialog(
        context,
        '未授权访问设备外部存储',
        '未授权访问设备外部存储，无法进行语音识别',
      );
      return false;
    }
    return true;
  }

  // 通知父组件输入框高度变化，重新布局悬浮按钮
  void _notifyHeightChange() {
    // 等待下一帧布局完成后再获取高度
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox renderBox =
          _containerKey.currentContext!.findRenderObject() as RenderBox;
      final height = renderBox.size.height;

      // 只在高度真正发生变化时才通知
      if (height != _lastNotifiedHeight) {
        debugPrint('ChatInput height changed: $_lastNotifiedHeight -> $height');
        _lastNotifiedHeight = height;
        widget.onHeightChanged?.call(height);
      }
    });
  }

  // 处理图片选择
  Future<void> _handleImagePick(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final images = await _picker.pickMultiImage();
        if (images.isNotEmpty) {
          setState(() => _selectedImages = images);
        }
      } else {
        final image = await _picker.pickImage(source: source);
        if (image != null) {
          setState(() => _selectedImages = [image]);
        }
      }
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, '选择图片失败', '选择图片失败: $e');
    }
  }

  // 处理文件上传
  Future<void> _handleFileUpload() async {
    // 只支持单个文件，如果点击上传按钮，就无论如何都清空旧的选中
    setState(() {
      isLoadingDocument = false;
      fileContent = '';
      _selectedFile = null;
    });

    /// 选择文件，并解析出文本内容
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'docx', 'doc'],
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        isLoadingDocument = true;
        fileContent = '';
        _selectedFile = null;
      });

      PlatformFile file = result.files.first;

      try {
        var text = "";
        switch (file.extension) {
          case 'txt':
            DecodingResult result = await CharsetDetector.autoDecode(
              File(file.path!).readAsBytesSync(),
            );
            text = result.string;
          case 'pdf':
            text = await compute(extractTextFromPdf, file.path!);
          case 'docx':
            text =
                await compute(docxToText, File(file.path!).readAsBytesSync());
          case 'doc':
            text = await DocText().extractTextFromDoc(file.path!) ?? "";
          default:
            debugPrint("默认的,暂时啥都不做");
        }

        if (!mounted) return;
        setState(() {
          _selectedFile = file;
          fileContent = text;
          isLoadingDocument = false;
        });
      } catch (e) {
        if (!mounted) return;
        commonExceptionDialog(context, '文件解析失败', '文件解析失败: $e');

        setState(() {
          _selectedFile = file;
          fileContent = "";
          isLoadingDocument = false;
        });
        rethrow;
      }
    }
  }

  // 处理音频上传
  Future<void> _handleAudioUpload() async {
    // TODO: 实现音频上传
  }

  // 清理选中的媒体文件
  void _clearSelectedMedia() {
    setState(() {
      _selectedImages = null;
      _selectedAudio = null;
      _selectedFile = null;

      // 一般取消、发送完之后都会清除媒体资源，同时也收起工具栏，并通知父组件修改悬浮按钮位置
      _showToolbar = false;
      _notifyHeightChange();
    });
  }

  // 处理发送消息
  void _handleSend() {
    final text = widget.controller.text.trim();
    if (text.isEmpty &&
        _selectedImages == null &&
        _selectedAudio == null &&
        _selectedFile == null) {
      return;
    }

    // 创建消息数据
    final messageData = MessageData(
      text: text,
      images: _selectedImages,
      audio: _selectedAudio,
      file: _selectedFile,
    );

    // 发送消息
    widget.onSend(messageData);

    // 清理状态
    setState(() {
      _clearSelectedMedia();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: _containerKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        /// 选中的媒体预览
        if (_selectedImages != null) _buildImagePreviewArea(),

        if (isLoadingDocument || _selectedFile != null)
          Container(
            height: 100.sp,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1.sp),
            ),
            child: buildFilePreviewArea(),
          ),

        /// 输入栏
        Container(
          padding: EdgeInsets.symmetric(vertical: 4.sp),
          decoration: BoxDecoration(
            color: Colors.transparent,
            // color: Colors.white,
            // boxShadow: [
            //   BoxShadow(
            //     color: Colors.grey.withOpacity(0.2),
            //     blurRadius: 4,
            //     offset: const Offset(0, -2),
            //   ),
            // ],
          ),
          child: Row(
            children: [
              /// 工具栏切换按钮
              if (!widget.isStreaming && widget.model != null)
                IconButton(
                  icon: Icon(
                    _showToolbar ? Icons.keyboard_arrow_down : Icons.add,
                    color: _showToolbar ? Theme.of(context).primaryColor : null,
                  ),
                  onPressed: () {
                    setState(() => _showToolbar = !_showToolbar);
                    _notifyHeightChange();
                  },
                  tooltip: _showToolbar ? '收起工具栏' : '展开工具栏',
                ),

              /// 输入区域
              Expanded(child: _buildInputArea()),

              /// 发送/终止按钮
              IconButton(
                icon: Icon(
                  widget.isStreaming
                      ? Icons.stop
                      : (widget.isEditing ? Icons.check : Icons.send),
                ),
                onPressed: widget.isStreaming ? widget.onStop : _handleSend,
                tooltip: widget.isStreaming
                    ? '停止生成'
                    : (widget.isEditing ? '确认编辑' : '发送'),
              ),
            ],
          ),
        ),

        /// 工具栏
        if (_showToolbar && _toolItems.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: 4.sp),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ..._toolItems.map((tool) => _buildToolButton(tool)),
              ],
            ),
            // child: SingleChildScrollView(
            //   scrollDirection: Axis.horizontal,
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.start,
            //     children:
            //         _toolItems.map((tool) => _buildToolButton(tool)).toList(),
            //     // [
            //     //   _buildVoiceModeButton(),
            //     //   ..._toolItems.map((tool) => _buildToolButton(tool)),
            //     // ],
            //   ),
            // ),
          ),
      ],
    );
  }

  // 选中的图片预览区域
  Widget _buildImagePreviewArea() {
    _notifyHeightChange();

    return Container(
      height: 100.sp,
      padding: EdgeInsets.symmetric(vertical: 8.sp),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages!.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.sp),
            child: Stack(
              children: [
                Image.file(
                  File(_selectedImages![index].path),
                  height: 80.sp,
                  width: 80.sp,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  right: -16,
                  top: -16,
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 20.sp,
                      color: Colors.blue,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedImages!.removeAt(index);
                        if (_selectedImages!.isEmpty) {
                          _selectedImages = null;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 上传文件按钮和上传的文件名
  Widget buildFilePreviewArea() {
    _notifyHeightChange();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        if (!isLoadingDocument)
          IconButton(
            onPressed: _handleFileUpload,
            icon: const Icon(Icons.file_upload),
          ),
        Expanded(
          child: _selectedFile != null
              ? GestureDetector(
                  onTap: () {
                    previewDocumentContent();
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFile?.name ?? "",
                        maxLines: 2,
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      RichText(
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: formatFileSize(_selectedFile?.size ?? 0),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12.sp,
                              ),
                            ),
                            TextSpan(
                              text: " 文档解析完成 ",
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 15.sp,
                              ),
                            ),
                            TextSpan(
                              text: "共有 ${fileContent.length} 字符",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Text(
                    isLoadingDocument ? "文档解析中,请勿操作..." : "可点击左侧按钮上传文件",
                    // style: const TextStyle(color: Colors.grey),
                  ),
                ),
        ),
        if (_selectedFile != null)
          SizedBox(
            width: 48.sp,
            child: IconButton(
              onPressed: () {
                setState(() {
                  fileContent = "";
                  _selectedFile = null;
                  _notifyHeightChange();
                });
              },
              icon: const Icon(Icons.clear),
            ),
          ),
      ],
    );
  }

  /// 点击上传文档名称，可预览文档内容
  void previewDocumentContent() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SizedBox(
          height: 0.8.sh,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.sp),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('解析后文档内容预览', style: TextStyle(fontSize: 18.sp)),
                    TextButton(
                      child: const Text('关闭'),
                      onPressed: () {
                        Navigator.pop(context);
                        unfocusHandle();
                      },
                    ),
                  ],
                ),
              ),
              Divider(height: 2.sp, thickness: 2.sp),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(10.sp),
                    // 2025-03-22 这里解析出来的内容可能包含非法字符，所以就算使用Text或者Text.rich，都会报错
                    // 使用MarkdownBody也会报错，但能显示出来，上面是无法显示
                    child: fileContent.length > 8000
                        ? Text(
                            "解析后内容过长${fileContent.length}字符，只展示前8000字符\n\n${fileContent.substring(0, 8000)}\n <已截断...>",
                          )
                        : MarkdownBody(
                            data: String.fromCharCodes(fileContent.runes),
                            // selectable: true,
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 切换语音输入或文本输入按钮
  Widget _buildVoiceModeButton() {
    return IconButton(
      icon: Icon(
        _isVoiceMode ? Icons.keyboard : Icons.keyboard_voice,
        size: 20.sp,
        color: Colors.lightBlue,
      ),
      onPressed: widget.isStreaming
          ? null
          : () async {
              if (!_isVoiceMode && !await _checkPermissions()) {
                return;
              }
              setState(() => _isVoiceMode = !_isVoiceMode);
            },
    );
  }

  // 输入区域
  Widget _buildInputArea() {
    if (_isVoiceMode) {
      var smButton = SoundsMessageButton(
        showBorder: false,
        onChanged: (status) {},
        onSendSounds: widget.isStreaming
            ? (type, content) {
                commonExceptionDialog(
                  context,
                  '提示',
                  '等待响应完成或终止后再输入',
                );
              }
            : (type, content) async {
                if (content.isEmpty) {
                  commonExceptionDialog(
                    context,
                    '提示',
                    '请输入消息内容',
                  );
                  return;
                }

                if (type == SendContentType.text) {
                  // 如果输入的是语音转换后的文字，直接发送文字
                  final messageData = MessageData(
                    text: content,
                    images: _selectedImages,
                    audio: _selectedAudio,
                    file: _selectedFile,
                  );

                  widget.onSend(messageData);
                } else if (type == SendContentType.voice) {
                  // 如果直接输入的语音，要显示转换后的文本，也要保留语音文件
                  String tempPath = path.join(
                    path.dirname(content),
                    path.basenameWithoutExtension(content),
                  );

                  var transcription =
                      await getTextFromAudioFromXFYun("$tempPath.pcm");

                  final messageData = MessageData(
                    text: transcription,
                    images: _selectedImages,
                    audio: XFile("$tempPath.m4a"),
                    file: _selectedFile,
                  );

                  widget.onSend(messageData);
                }

                // 清理状态
                setState(() {
                  _clearSelectedMedia();
                });
              },
      );

      return Container(
        height: 58.sp,
        decoration: BoxDecoration(
          // color: Colors.white,
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey, width: 1.sp),
        ),
        child: Row(
          children: [
            _buildVoiceModeButton(),
            Expanded(
              child: smButton,
            ),
            // 占位宽度，眼睛看的，大概让“按住说话”几个字居中显示
            SizedBox(width: 40.sp),
          ],
        ),
      );
    } else {
      return TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        enabled: !widget.isStreaming,
        maxLines: 3,
        minLines: 1,
        decoration: InputDecoration(
          hintText: widget.isEditing ? '编辑消息...' : '输入消息...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          prefixIcon: (widget.isEditing && widget.onCancel != null)
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _clearSelectedMedia();
                    });
                    widget.onCancel?.call();
                  },
                  tooltip: '取消编辑',
                )
              : _buildVoiceModeButton(),
        ),
      );
    }
  }

  // 工具项按钮
  Widget _buildToolButton(ToolItem tool) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.sp),
      child: InkWell(
        onTap: tool.onTap,
        borderRadius: BorderRadius.circular(8.sp),
        child: Container(
          color: Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: 12.sp,
            vertical: 6.sp,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tool.icon, size: 24.sp, color: tool.color),
              SizedBox(height: 4.sp),
              Text(
                tool.label,
                style: TextStyle(fontSize: 12.sp, color: tool.color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 工具项数据类
class ToolItem {
  final IconData icon;
  final String label;
  final String type;
  final VoidCallback onTap;
  final Color? color;
  const ToolItem({
    required this.icon,
    required this.label,
    required this.type,
    required this.onTap,
    this.color,
  });
}
