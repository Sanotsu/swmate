import 'package:flutter/material.dart';
import '../../../../models/brief_ai_tools/chat_branch/chat_branch_message.dart';

class BranchMessageItem extends StatelessWidget {
  final ChatBranchMessage message;
  final Function(ChatBranchMessage)? onEdit;
  final Function(ChatBranchMessage)? onRegenerate;
  final Function(ChatBranchMessage, int)? onSwitchBranch;
  final bool hasMultipleBranches;
  final int currentBranchIndex;
  final int totalBranches;
  final Function(ChatBranchMessage, LongPressStartDetails)? onLongPress;
  final bool isRegenerating;
  final List<ChatBranchMessage> messages;

  const BranchMessageItem({
    super.key,
    required this.message,
    this.onEdit,
    this.onRegenerate,
    this.onSwitchBranch,
    required this.hasMultipleBranches,
    required this.currentBranchIndex,
    required this.totalBranches,
    this.onLongPress,
    this.isRegenerating = false,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    // 获取实际可用的分支数量和索引
    final availableSiblings = _getAvailableSiblings();
    final showBranchControls = availableSiblings.length > 1;

    // 获取可用分支中最大的分支索引
    // totalBranches是所有分支的数量，maxBranchIndex是可用分支中最大的分支索引
    // 加入原本有分支1、2、3(当然存储时是0、1、2,显示时都+1)，现在删除了分支2，
    // 那么totalBranches=2，maxBranchIndex=3
    // 在切换时分支显示的时候，需要显示“分支1/3”、“分支3/3”，
    // 但作为是否可以切换判断的时候，需要判断 totalBranches =2
    final maxBranchIndex = availableSiblings
        .map((e) => e.branchIndex)
        .reduce((a, b) => a > b ? a : b);

    print("""可用分支: ${availableSiblings.length}，
        当前分支: $currentBranchIndex，
        总分支: $totalBranches，
        最大分支: $maxBranchIndex""");

    return GestureDetector(
      onLongPressStart: onLongPress != null
          ? (details) => onLongPress!(message, details)
          : null,
      child: Column(
        crossAxisAlignment: message.role == 'user'
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.all(8.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color:
                  message.role == 'user' ? Colors.blue[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isRegenerating)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  Text(message.content),
                if (message.role == 'assistant' &&
                    message.reasoningContent != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      message.reasoningContent!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (message.role == 'assistant')
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isRegenerating && onRegenerate != null)
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 16),
                          onPressed: () => onRegenerate!(message),
                          tooltip: '重新生成',
                        ),
                      if (message.thinkingDuration != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '思考时间: ${message.thinkingDuration}ms',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        ),
                      if (message.totalTokens != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                          child: Text(
                            'Tokens: ${message.totalTokens}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          if (showBranchControls)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_left),
                    onPressed: currentBranchIndex > 0 && onSwitchBranch != null
                        ? () => onSwitchBranch!(message, currentBranchIndex - 1)
                        : null,
                  ),
                  Text(
                    '当前分支${message.branchIndex + 1} / 最大分支${maxBranchIndex + 1}(分支总数 $totalBranches)',
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_right),
                    onPressed: currentBranchIndex < totalBranches - 1 &&
                            onSwitchBranch != null
                        ? () => onSwitchBranch!(message, currentBranchIndex + 1)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<ChatBranchMessage> _getAvailableSiblings() {
    if (!hasMultipleBranches) return [message];

    // 获取同级分支并按实际索引排序
    final siblings = messages
        .where((m) =>
            m.parent.target?.id == message.parent.target?.id &&
            m.depth == message.depth)
        .toList()
      ..sort((a, b) => a.branchIndex.compareTo(b.branchIndex));

    return siblings;
  }
}
