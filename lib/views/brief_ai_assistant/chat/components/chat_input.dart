import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../apis/voice_recognition/xunfei_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../../common/llm_spec/constant_llm_enum.dart';
import '../../../../common/utils/tools.dart';
import '../../../../common/components/sounds_message_button/button_widget/sounds_message_button.dart';
import '../../../../common/components/sounds_message_button/utils/sounds_recorder_controller.dart';
import '../../../../common/components/voice_chat_bubble.dart';

class ChatInput extends StatefulWidget {
  // 模型规格(根据模型类型判断是否展示一些工具按钮)
  final CusBriefLLMSpec? model;
  // 发送消息(当文本输入或者选择了图片音频等，调用此方法发送消息)
  final Function(String text, {File? image, File? voice}) onSend;
  // 取消响应(流式响应过程中，用户点击了终止按钮，调用此方法)
  final VoidCallback? onCancel;
  // 是否正在流式响应中(如果在响应中，不允许发送、输入文本等操作)
  final bool isStreaming;
  // 输入框高度变化回调
  // (切换模型后，可能会展开/收起更多工具栏，导致整个输入区域变化。
  // 而主页面的悬浮开启新对话、滚动到底部按钮是相对固定在输入框上面一点
  // 输入框高度变化了，也要通知父组件，让父组件重新布局悬浮按钮)
  final ValueChanged<double>? onHeightChanged;
  // 输入框控制器(编辑用户信息时直接传入控制器方便赋值到输入框)
  final TextEditingController controller;
  // 是否是编辑用户消息(重新编辑用户消息和正常对话输入发送要稍做区别)
  final bool isEditing;
  // 取消编辑回调(当取消编辑用户信息时，调用此方法)
  final VoidCallback? onEditCancel;
  // 输入框焦点控制(编辑用户消息时自动弹出键盘，取消时收起键盘)
  final FocusNode? focusNode;

  const ChatInput({
    super.key,
    required this.model,
    required this.onSend,
    required this.controller,
    this.onCancel,
    this.isStreaming = false,
    this.onHeightChanged,
    this.isEditing = false,
    this.onEditCancel,
    this.focusNode,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  bool _isRecording = false;
  final _audioRecorder = AudioRecorder();
  File? _selectedImage;
  File? _selectedVoice;
  bool _isVoiceMode = false;
  bool _showTools = true;
  final GlobalKey _containerKey = GlobalKey();

  // 添加一个变量记录上次通知给父组件输入框的高度
  // (高度有变化后才重新通知，避免在didUpdateWidget中重复通知)
  double _lastNotifiedHeight = 0;

  @override
  void initState() {
    super.initState();
    // 初始化时获取输入框高度
    _notifyHeightChange();
  }

  @override
  void didUpdateWidget(ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只在模型改变时更新高度，因为模型改变可能影响工具栏状态
    if (oldWidget.model?.cusLlmSpecId != widget.model?.cusLlmSpecId) {
      _notifyHeightChange();
    }
    // 当进入编辑模式时,设置输入框内容
    if (widget.isEditing && !oldWidget.isEditing) {
      widget.controller.text = widget.controller.text;
    }
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

  @override
  Widget build(BuildContext context) {
    final hasVisionAbility = widget.model?.modelType == LLModelType.vision;
    final hasVoiceAbility = widget.model?.modelType == LLModelType.audio;
    final hasTools =
        (hasVisionAbility || hasVoiceAbility) && !widget.isStreaming;

    return Column(
      key: _containerKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_selectedImage != null || _selectedVoice != null)
          _buildPreviewArea(),
        Container(
          padding: EdgeInsets.all(8.sp),
          child: Column(
            // mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (hasTools)
                    IconButton(
                      icon: Icon(
                        _showTools ? Icons.expand_less : Icons.expand_more,
                      ),
                      onPressed: () {
                        setState(() => _showTools = !_showTools);
                        // 切换工具栏后，重新获取输入框高度，让父组件重新布局
                        _notifyHeightChange();
                      },
                    ),
                  if (!hasTools) _buildVoiceModeButton(),
                  _buildInputArea(),
                  _buildSendButton(),
                ],
              ),
              if (_showTools && hasTools) ...[
                SizedBox(height: 8.sp),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildVoiceModeButton(isHidden: hasTools),
                    if (hasVisionAbility) ...[
                      _buildVisionToolButton(
                          Icons.image, ImageSource.gallery, '图片'),
                      _buildVisionToolButton(
                          Icons.camera, ImageSource.camera, '相机'),
                    ],
                    if (hasVoiceAbility)
                      IconButton(
                        icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                        onPressed: _handleVoiceInput,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // 切换语音输入或文本输入按钮
  Widget _buildVoiceModeButton({bool? isHidden}) {
    return IconButton(
      icon: Icon(
        _isVoiceMode ? Icons.keyboard : Icons.keyboard_voice,
      ),
      onPressed: widget.isStreaming
          ? null
          : () async {
              if (!_isVoiceMode && !await _checkPermissions()) {
                return;
              }
              setState(() => _isVoiceMode = !_isVoiceMode);
              // 切换输入模式后，隐藏工具栏(其他的不必，因为语音输入的overlay是固定顶部区域的)
              if (isHidden != null) {
                setState(() => _showTools = !_showTools);
              }
            },
    );
  }

  // 输入区域
  // 如果是语音模式，则显示按住说话语音按钮
  // 如果是文本模式，则显示输入框
  Widget _buildInputArea() {
    return Expanded(
      child: _isVoiceMode
          ? SizedBox(
              height: 56.sp,
              child: SoundsMessageButton(
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
                          widget.onSend(
                            content,
                            image: _selectedImage,
                            voice: _selectedVoice,
                          );
                        } else if (type == SendContentType.voice) {
                          // 如果直接输入的语音，要显示转换后的文本，也要保留语音文件
                          String tempPath = path.join(
                            path.dirname(content),
                            path.basenameWithoutExtension(content),
                          );

                          var transcription =
                              await getTextFromAudioFromXFYun("$tempPath.pcm");

                          widget.onSend(
                            transcription,
                            image: _selectedImage,
                            voice: File("$tempPath.m4a"),
                          );
                        }

                        setState(() {
                          _selectedImage = null;
                          _selectedVoice = null;
                        });
                      },
              ),
            )
          : TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              enabled: !widget.isStreaming,
              decoration: InputDecoration(
                hintText: widget.isEditing ? '编辑消息' : '给智能助手发送消息',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.sp),
                ),
                prefixIcon: widget.isEditing
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          widget.onEditCancel?.call();
                          widget.focusNode?.unfocus();
                        },
                      )
                    : null,
              ),
              maxLines: 3,
              minLines: 1,
            ),
    );
  }

  // 发送按钮(如果是语音输入，则占位符)
  Widget _buildSendButton() {
    return !_isVoiceMode
        ? IconButton(
            icon: Icon(widget.isStreaming ? Icons.stop : Icons.send),
            onPressed: widget.isStreaming ? widget.onCancel : _sendMessage,
          )
        : SizedBox(width: 48.sp); // 图标按钮默认大小48*48
  }

  // 工具按钮
  Widget _buildVisionToolButton(
    IconData icon,
    ImageSource source,
    String label,
  ) {
    return InkWell(
      onTap: () => _pickImage(source),
      child: Container(
        width: 48.sp,
        height: 48.sp,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8.sp),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey[600]),
            Text(label, style: TextStyle(fontSize: 12.sp)),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewArea() {
    return Container(
      padding: EdgeInsets.all(8.sp),
      child: Row(
        children: [
          if (_selectedImage != null)
            Stack(
              children: [
                Image.file(
                  _selectedImage!,
                  width: 100.sp,
                  height: 100.sp,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                ),
              ],
            ),
          if (_selectedVoice != null)
            Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(8.sp),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.sp),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VoiceWaveBubble(path: _selectedVoice!.path),
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedVoice = null),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _handleVoiceInput() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        widget.onSend(
          widget.controller.text,
          voice: File(path),
        );
      }
    } else {
      try {
        if (await _audioRecorder.hasPermission()) {
          final tempDir = await getTemporaryDirectory();
          final path =
              '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

          await _audioRecorder.start(
            const RecordConfig(
              encoder: AudioEncoder.aacLc,
              bitRate: 128000,
              sampleRate: 44100,
            ),
            path: path,
          );

          setState(() => _isRecording = true);
        }
      } catch (e) {
        debugPrint('录音失败: $e');
      }
    }
  }

  void _sendMessage() {
    unfocusHandle();

    if (widget.controller.text.isEmpty) {
      EasyLoading.showError('请输入消息内容');
      return;
    }

    widget.onSend(
      widget.controller.text,
      image: _selectedImage,
      voice: _selectedVoice,
    );

    widget.controller.clear();
    setState(() {
      _selectedImage = null;
      _selectedVoice = null;
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }
}
