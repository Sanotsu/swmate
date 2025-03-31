import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:objectbox/objectbox.dart';
import 'branch_chat_session.dart';

@Entity()
class BranchChatMessage {
  @Id(assignable: true)
  int id;

  String messageId;
  String role;
  String content;
  DateTime createTime;

  // 可选字段
  String? reasoningContent;
  int? thinkingDuration;
  String? contentVoicePath;
  String? imagesUrl;
  String? videosUrl;

  // 2025-03-24 联网搜索参考内容
  // 使用字符串存储序列化后的JSON
  String? referencesJson;

  // 非持久化字段，用于运行时
  @Transient()
  List<Map<String, dynamic>>? _references;

  int? promptTokens;
  int? completionTokens;
  int? totalTokens;
  String? modelLabel;

  // 树形结构关系
  @Backlink('parent')
  final children = ToMany<BranchChatMessage>();

  final parent = ToOne<BranchChatMessage>();
  final session = ToOne<BranchChatSession>();

  // 分支相关
  int branchIndex; // 当前分支在同级分支中的索引
  int depth; // 分支深度，根节点为0
  String branchPath; // 存储从根到当前节点的分支路径，如 "0/1/0"

  // Getter和Setter用于处理references字段
  List<Map<String, dynamic>>? get references {
    if (_references == null && referencesJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(referencesJson!);
        _references = decoded.cast<Map<String, dynamic>>();
      } catch (e) {
        if (kDebugMode) {
          print('解析references失败: $e');
        }
        _references = null;
      }
    }
    return _references;
  }

  set references(List<Map<String, dynamic>>? value) {
    _references = value;
    if (value != null) {
      try {
        referencesJson = jsonEncode(value);
      } catch (e) {
        if (kDebugMode) {
          print('序列化references失败: $e');
        }
        referencesJson = null;
      }
    } else {
      referencesJson = null;
    }
  }

  BranchChatMessage({
    this.id = 0,
    required this.messageId,
    required this.role,
    required this.content,
    required this.createTime,
    this.branchIndex = 0,
    this.depth = 0,
    this.branchPath = "0",
    this.reasoningContent,
    this.thinkingDuration,
    this.contentVoicePath,
    this.imagesUrl,
    this.videosUrl,
    List<Map<String, dynamic>>? references,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.modelLabel,
  }) {
    this.references = references; // 使用setter来设置references和referencesJson
  }
}
