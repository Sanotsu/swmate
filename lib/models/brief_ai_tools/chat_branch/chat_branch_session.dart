import 'package:objectbox/objectbox.dart';
import 'chat_branch_message.dart';

@Entity()
class ChatBranchSession {
  @Id(assignable: true)
  int id;
  
  String title;
  DateTime createTime;
  DateTime updateTime;
  
  @Backlink('session')
  final messages = ToMany<ChatBranchMessage>();
  
  ChatBranchSession({
    this.id = 0,
    required this.title,
    required this.createTime,
    required this.updateTime,
  });
} 