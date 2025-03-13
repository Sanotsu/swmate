import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../common/constants/constants.dart';
import '../../../../models/brief_ai_tools/chat_branch/chat_branch_message.dart';

class BranchMessageActions extends StatelessWidget {
  // 当前消息
  final ChatBranchMessage message;
  // 所有消息
  final List<ChatBranchMessage> messages;
  // 重新生成回调
  final VoidCallback onRegenerate;
  // 是否正在重新生成
  final bool isRegenerating;
  // 是否有多条分支
  final bool hasMultipleBranches;
  // 当前分支索引
  final int currentBranchIndex;
  // 总分支数量
  final int totalBranches;
  // 切换分支回调
  final Function(ChatBranchMessage, int)? onSwitchBranch;

  const BranchMessageActions({
    super.key,
    required this.message,
    required this.messages,
    required this.onRegenerate,
    this.isRegenerating = false,
    required this.hasMultipleBranches,
    required this.currentBranchIndex,
    required this.totalBranches,
    this.onSwitchBranch,
  });

  // 获取实际可用的分支数量和索引
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

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == CusRole.user.name ||
        message.role == CusRole.system.name;

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

    return Container(
      padding: EdgeInsets.all(4.sp),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // 复制按钮
          IconButton(
            icon: Icon(Icons.copy, size: 20.sp),
            visualDensity: VisualDensity.compact,
            tooltip: '复制内容',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message.content));
              EasyLoading.showSuccess('已复制到剪贴板');
            },
          ),

          // 如果不是用户消息，且不是正在重新生成，则显示重新生成按钮
          if (!isUser && !isRegenerating)
            IconButton(
              icon: Icon(Icons.refresh, size: 20.sp),
              onPressed: onRegenerate,
              tooltip: '重新生成',
            ),

          // 如果不是用户消息，但是在重新生成中，则显示加载
          if (!isUser && isRegenerating)
            SizedBox(
              width: 16.sp,
              height: 16.sp,
              child: CircularProgressIndicator(strokeWidth: 2.sp),
            ),

          // 分支切换按钮
          if (showBranchControls && onSwitchBranch != null) ...[
            SizedBox(width: 16.sp),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.sp),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 36.sp,
                    height: 36.sp,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios, size: 20.sp),
                      padding: EdgeInsets.zero, // 移除边距
                      onPressed: currentBranchIndex > 0 &&
                              onSwitchBranch != null
                          ? () =>
                              onSwitchBranch!(message, currentBranchIndex - 1)
                          : null,
                    ),
                  ),
                  Text(
                    '${message.branchIndex + 1} / ${maxBranchIndex + 1} ($totalBranches)',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
                  ),
                  SizedBox(
                    width: 36.sp,
                    height: 36.sp,
                    child: IconButton(
                      icon: Icon(Icons.arrow_forward_ios, size: 20.sp),
                      padding: EdgeInsets.zero, // 移除边距
                      onPressed: currentBranchIndex < totalBranches - 1 &&
                              onSwitchBranch != null
                          ? () =>
                              onSwitchBranch!(message, currentBranchIndex + 1)
                          : null,
                    ),
                  ),
                ],
              ),
            )
          ],
        ],
      ),
    );
  }
}
