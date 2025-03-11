import 'package:flutter/material.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isEditing;
  final bool isStreaming;
  final VoidCallback? onStop;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.isEditing = false,
    this.isStreaming = false,
    this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              enabled: !isStreaming,
              decoration: InputDecoration(
                hintText: isEditing ? '编辑消息...' : '输入消息...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(isStreaming ? Icons.stop : (isEditing ? Icons.check : Icons.send)),
            onPressed: isStreaming ? onStop : onSend,
          ),
        ],
      ),
    );
  }
} 