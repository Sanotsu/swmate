// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../apis/voice_recognition/xunfei_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/llm_spec/cus_llm_model.dart';
import '../../../../common/llm_spec/cus_llm_spec.dart';
import '../../../../common/utils/tools.dart';
import '../../../ai_assistant/_componets/sounds_message_button/button_widget/sounds_message_button.dart';
import '../../../ai_assistant/_componets/sounds_message_button/utils/sounds_recorder_controller.dart';
import '../../../ai_assistant/_componets/voice_chat_bubble.dart';

class ChatInput extends StatefulWidget {
  final CusLLMSpec? model;
  final Function(String text, {File? image, File? voice}) onSend;
  final VoidCallback? onCancel;
  final bool isStreaming;

  const ChatInput({
    super.key,
    required this.model,
    required this.onSend,
    this.onCancel,
    this.isStreaming = false,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isRecording = false;
  final _audioRecorder = AudioRecorder();
  File? _selectedImage;
  File? _selectedVoice;
  bool _isVoiceMode = false;
  bool _showTools = true;

  Future<bool> _checkPermissions() async {
    if (!(await requestMicrophonePermission())) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('未授权语音录制权限，无法语音输入'),
        ),
      );
      return false;
    }
    if (!(await requestStoragePermission())) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('未授权访问设备外部存储，无法进行语音识别'),
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final hasVisionAbility = widget.model?.modelType == LLModelType.vision;
    final hasVoiceAbility = widget.model?.modelType == LLModelType.voice;
    final hasTools =
        (hasVisionAbility || hasVoiceAbility) && !widget.isStreaming;

    return Column(
      children: [
        if (_selectedImage != null || _selectedVoice != null)
          _buildPreviewArea(),
        Container(
          padding: EdgeInsets.all(8.sp),
          child: Column(
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('等待响应完成或终止后再输入'),
                          ),
                        );
                      }
                    : (type, content) async {
                        if (content.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('请输入消息内容')),
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
              controller: _controller,
              enabled: !widget.isStreaming,
              decoration: InputDecoration(
                hintText: '给智能助手发送消息',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.sp),
                ),
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
        width: 96.sp,
        height: 96.sp,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8.sp),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            IconButton(
              icon: Icon(icon, color: Colors.grey[600]),
              onPressed: () => _pickImage(source),
            ),
            Text(label),
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
          _controller.text,
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
        print('录音失败: $e');
      }
    }
  }

  void _sendMessage() {
    unfocusHandle();

    if (_controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入消息内容')),
      );
      return;
    }

    widget.onSend(
      _controller.text,
      image: _selectedImage,
      voice: _selectedVoice,
    );

    _controller.clear();
    setState(() {
      _selectedImage = null;
      _selectedVoice = null;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }
}
