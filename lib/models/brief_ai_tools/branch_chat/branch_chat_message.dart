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
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.modelLabel,
  });
}
