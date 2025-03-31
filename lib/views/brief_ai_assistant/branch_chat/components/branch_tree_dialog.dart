import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../common/constants/constants.dart';
import '../../../../models/brief_ai_tools/branch_chat/branch_chat_message.dart';

class BranchTreeDialog extends StatefulWidget {
  final List<BranchChatMessage> messages;
  final String currentPath;
  final Function(String) onPathSelected;

  const BranchTreeDialog({
    super.key,
    required this.messages,
    required this.currentPath,
    required this.onPathSelected,
  });

  @override
  State<BranchTreeDialog> createState() => _BranchTreeDialogState();
}

class _BranchTreeDialogState extends State<BranchTreeDialog> {
  late String selectedPath;

  @override
  void initState() {
    super.initState();
    selectedPath = widget.currentPath;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('对话分支树'),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('确定'),
              onPressed: () {
                widget.onPathSelected(selectedPath);
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(48.sp),
            child: Container(
              padding: EdgeInsets.all(8.sp),
              child: Row(
                children: [
                  _buildLegendItem(Colors.blue, '用户消息'),
                  SizedBox(width: 16.sp),
                  _buildLegendItem(Colors.green, 'AI响应'),
                  SizedBox(width: 16.sp),
                  _buildLegendItem(Colors.blue.withValues(alpha: 0.1), '当前选中'),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: ExpansionTile(
                initiallyExpanded: true,
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.account_tree, size: 16.sp),
                    SizedBox(width: 8.sp),
                    Text(
                      '当前分支路径',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8.sp),
                    Text(
                      '(${selectedPath.split('/').length ~/ 2} 轮对话)',
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.sp),
                    child: _buildCurrentPathInfo(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 16.sp, top: 8.sp, bottom: 8.sp),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.account_tree, size: 16.sp),
                  SizedBox(width: 8.sp),
                  Text(
                    '对话分支消息',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(8.sp),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width - 16.sp,
                    ),
                    child: _buildBranchTree(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildBranchTree(BuildContext context) {
    final sortedMessages = List<BranchChatMessage>.from(widget.messages)
      ..sort((a, b) => a.createTime.compareTo(b.createTime));

    return _buildTreeNode(
      context,
      sortedMessages.where((m) => m.parent.target == null).toList(),
      sortedMessages,
      0,
    );
  }

  Widget _buildTreeNode(
    BuildContext context,
    List<BranchChatMessage> nodes,
    List<BranchChatMessage> allMessages,
    int depth,
  ) {
    final availableNodes = nodes
        .where((node) => allMessages.contains(node))
        .toList()
      ..sort((a, b) => a.branchIndex.compareTo(b.branchIndex));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: availableNodes.map((node) {
        final isCurrentPath = node.branchPath == selectedPath ||
            selectedPath.startsWith('${node.branchPath}/');

        final children = allMessages
            .where((m) =>
                m.parent.target?.id == node.id && allMessages.contains(m))
            .toList()
          ..sort((a, b) => a.branchIndex.compareTo(b.branchIndex));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                if (depth > 0)
                  Positioned(
                    left: (depth - 1) * 24.sp + 12.sp,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2.sp,
                      color: Colors.grey.shade200,
                    ),
                  ),
                InkWell(
                  onTap: () => setState(() => selectedPath = node.branchPath),
                  child: Container(
                    margin: EdgeInsets.only(left: depth * 24.sp),
                    padding: EdgeInsets.all(8.sp),
                    constraints: BoxConstraints(
                      maxWidth: 300.sp,
                      minWidth: 300.sp,
                    ),
                    decoration: BoxDecoration(
                      color: node.branchPath == selectedPath
                          ? (node.role == CusRole.user.name
                              ? Colors.blue.withValues(alpha: 0.1)
                              : Colors.green.withValues(alpha: 0.1))
                          : null,
                      border: Border.all(
                        color: node.role == CusRole.user.name
                            ? Colors.blue
                            : Colors.green,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8.sp),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              node.role == CusRole.user.name
                                  ? Icons.person
                                  : Icons.smart_toy,
                              size: 16.sp,
                              color: node.role == CusRole.user.name
                                  ? Colors.blue
                                  : Colors.green,
                            ),
                            SizedBox(width: 8.sp),
                            Text(
                              node.role == CusRole.user.name ? '用户' : 'AI',
                              style: TextStyle(
                                color: node.role == CusRole.user.name
                                    ? Colors.blue
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.sp,
                                vertical: 2.sp,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4.sp),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.layers,
                                    size: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 4.sp),
                                  Text(
                                    '${depth + 1}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 4.sp,
                                    ),
                                    width: 1.sp,
                                    height: 10.sp,
                                    color: Colors.grey[300],
                                  ),
                                  Icon(
                                    Icons.account_tree,
                                    size: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 4.sp),
                                  Text(
                                    '${node.branchIndex + 1}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrentPath) ...[
                              SizedBox(width: 8.sp),
                              Icon(
                                Icons.check_circle,
                                color: Colors.blue,
                                size: 16.sp,
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 8.sp),
                        Text(
                          node.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (node.reasoningContent != null) ...[
                          SizedBox(height: 4.sp),
                          Text(
                            node.reasoningContent!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (children.isNotEmpty) ...[
              SizedBox(height: 8.sp),
              _buildTreeNode(context, children, allMessages, depth + 1),
            ],
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCurrentPathInfo(BuildContext context) {
    final pathParts = selectedPath.split('/');
    final messages = widget.messages;

    return Wrap(
      spacing: 8.sp,
      runSpacing: 8.sp,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: pathParts.asMap().entries.expand((entry) {
        final i = entry.key;
        final part = entry.value;

        // 获取当前路径对应的消息
        final currentPath = pathParts.sublist(0, i + 1).join('/');
        final message = messages.firstWhere(
          (m) => m.branchPath == currentPath,
          orElse: () => messages.first,
        );

        return [
          if (i > 0)
            Icon(Icons.arrow_forward_ios, size: 12.sp, color: Colors.grey),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 0.sp),
            decoration: BoxDecoration(
              color: message.role == CusRole.user.name
                  ? Colors.blue.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.sp),
              border: Border.all(
                color: message.role == CusRole.user.name
                    ? Colors.blue.withValues(alpha: 0.3)
                    : Colors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '${int.parse(part) + 1}',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: message.role == CusRole.user.name
                    ? Colors.blue
                    : Colors.green,
              ),
            ),
          ),
        ];
      }).toList(),
    );
  }
}
