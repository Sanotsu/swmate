import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextSelectionDialog extends StatelessWidget {
  final String text;

  const TextSelectionDialog({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('选择文本'),
          actions: [
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已复制到剪贴板')),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
} 