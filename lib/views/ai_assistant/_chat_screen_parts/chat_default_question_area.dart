import 'package:flutter/material.dart';

///
/// 对话页面预设对话区域
///
class ChatDefaultQuestionArea extends StatelessWidget {
  final List<String> defaultQuestions;
  final Function(String) onQuestionTap;

  const ChatDefaultQuestionArea({
    super.key,
    required this.defaultQuestions,
    required this.onQuestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: ListView.builder(
        itemCount: defaultQuestions.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            child: ListTile(
              title: Text(
                defaultQuestions[index],
                style: const TextStyle(color: Colors.blue),
              ),
              trailing: const Icon(Icons.touch_app, color: Colors.blue),
              onTap: () {
                onQuestionTap(defaultQuestions[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
