import 'dart:math';

import 'chat_branch_message.dart';

class BranchManager {
  /// 获取指定分支路径的消息
  List<ChatBranchMessage> getMessagesByBranchPath(
    List<ChatBranchMessage> allMessages,
    String branchPath,
  ) {
    if (allMessages.isEmpty) return [];
    
    // 将分支路径拆分为各级索引
    final pathIndices = branchPath.split('/');
    if (pathIndices.isEmpty) return [];
    
    // 按创建时间排序所有消息
    final sortedMessages = List<ChatBranchMessage>.from(allMessages)
      ..sort((a, b) => a.createTime.compareTo(b.createTime));
    
    // 找到当前路径下最大索引的子分支
    Map<String, int> maxChildIndices = {};
    for (var message in sortedMessages) {
      final messagePath = message.branchPath.split('/');
      if (messagePath.length == pathIndices.length + 1 && 
          messagePath.sublist(0, pathIndices.length).join('/') == pathIndices.join('/')) {
        final parentPath = messagePath.sublist(0, messagePath.length - 1).join('/');
        final currentIndex = int.parse(messagePath.last);
        maxChildIndices[parentPath] = max(maxChildIndices[parentPath] ?? 0, currentIndex);
      }
    }
    
    // 筛选当前分支路径上的消息
    return sortedMessages.where((message) {
      final messagePath = message.branchPath.split('/');
      
      // 如果消息路径比目标路径短，检查是否是目标路径的前缀
      if (messagePath.length <= pathIndices.length) {
        for (var i = 0; i < messagePath.length; i++) {
          if (messagePath[i] != pathIndices[i]) return false;
        }
        return true;
      }
      
      // 如果消息路径比目标路径长，检查是否是最大索引的子分支
      if (messagePath.length > pathIndices.length) {
        // 检查前缀是否匹配
        for (var i = 0; i < pathIndices.length; i++) {
          if (messagePath[i] != pathIndices[i]) return false;
        }
        
        // 获取父路径
        final parentPath = messagePath.sublist(0, pathIndices.length).join('/');
        final maxIndex = maxChildIndices[parentPath] ?? 0;
        
        // 只显示最大索引的子分支
        if (messagePath.length == pathIndices.length + 1) {
          return messagePath[pathIndices.length] == maxIndex.toString();
        } else {
          // 对于更深层的消息，检查其路径上的每一级是否都是最大索引
          for (var i = pathIndices.length; i < messagePath.length; i++) {
            final currentParentPath = messagePath.sublist(0, i).join('/');
            final currentMaxIndex = maxChildIndices[currentParentPath] ?? 0;
            if (messagePath[i] != currentMaxIndex.toString()) return false;
          }
          return true;
        }
      }
      
      return true;
    }).toList();
  }

  /// 获取同级分支的所有消息
  List<ChatBranchMessage> getSiblingBranches(
    List<ChatBranchMessage> allMessages,
    ChatBranchMessage message,
  ) {
    if (allMessages.isEmpty) return [];
    
    // 处理根消息
    if (message.parent.target == null) {
      return allMessages
        .where((m) => m.depth == 0)
        .toList()
        ..sort((a, b) => a.branchIndex.compareTo(b.branchIndex));
    }
    
    // 处理子消息
    final parentMessage = message.parent.target!;
    final siblings = allMessages
      .where((m) => 
        m.parent.target?.id == parentMessage.id && 
        m.depth == message.depth &&
        m.branchPath.startsWith(parentMessage.branchPath) // 确保是同一分支路径下的消息
      )
      .toList();

    // 按分支路径排序，确保新增的分支正确插入
    siblings.sort((a, b) {
      final aPath = a.branchPath.split('/');
      final bPath = b.branchPath.split('/');
      final aIndex = int.parse(aPath.last);
      final bIndex = int.parse(bPath.last);
      return aIndex.compareTo(bIndex);
    });

    return siblings;
  }

  /// 获取消息的分支索引
  int getBranchIndex(List<ChatBranchMessage> messages, ChatBranchMessage message) {
    final siblings = getSiblingBranches(messages, message);
    final availableSiblings = siblings.where((m) => messages.contains(m)).toList()
      ..sort((a, b) => a.branchIndex.compareTo(b.branchIndex));
    
    return availableSiblings.indexWhere((m) => m.id == message.id);
  }

  /// 获取消息的总分支数
  int getBranchCount(List<ChatBranchMessage> messages, ChatBranchMessage message) {
    final siblings = getSiblingBranches(messages, message);
    return siblings.where((m) => messages.contains(m)).length;
  }

  /// 获取下一个可用的分支索引
  int getNextAvailableBranchIndex(List<ChatBranchMessage> messages, ChatBranchMessage message, int targetIndex) {
    final siblings = getSiblingBranches(messages, message);
    // 只获取存在于当前消息列表中的分支，并按实际的 branchIndex 排序
    final availableSiblings = siblings
      .where((m) => messages.contains(m))
      .toList()
      ..sort((a, b) => a.branchIndex.compareTo(b.branchIndex));
    
    if (availableSiblings.isEmpty) return -1;
    
    // 获取当前消息的实际 branchIndex
    final currentBranchIndex = message.branchIndex;
    
    // 向后切换
    if (targetIndex > getBranchIndex(messages, message)) {
      // 找到第一个比当前 branchIndex 大的分支
      final nextMessage = availableSiblings
          .firstWhere(
            (m) => m.branchIndex > currentBranchIndex,
            orElse: () => availableSiblings.first, // 如果没有更大的，回到第一个
          );
      return nextMessage.branchIndex;
    }
    
    // 向前切换
    // 找到最后一个比当前 branchIndex 小的分支
    final previousMessages = availableSiblings
        .where((m) => m.branchIndex < currentBranchIndex)
        .toList();
    
    if (previousMessages.isEmpty) {
      // 如果没有更小的，跳到最后一个
      return availableSiblings.last.branchIndex;
    }
    
    return previousMessages.last.branchIndex;
  }

  /// 创建新分支路径
  String createNewBranchPath(ChatBranchMessage parentMessage) {
    int nextBranchIndex = parentMessage.children.length;
    return '${parentMessage.branchPath}/$nextBranchIndex';
  }
} 