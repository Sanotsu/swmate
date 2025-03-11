import 'dart:convert';
import 'package:objectbox/objectbox.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../common/llm_spec/constant_llm_enum.dart';
import 'chat_branch_message.dart';

@Entity()
class ChatBranchSession {
  @Id()
  int id;

  String title;
  DateTime createTime;
  DateTime updateTime;

  // 修改字段名，使其成为普通属性而不是私有属性
  String? llmSpecJson;
  String? modelTypeStr;

  @Transient() // 标记为非持久化字段
  CusBriefLLMSpec? _llmSpec;

  @Transient() // 标记为非持久化字段
  LLModelType? _modelType;

  // Getter 和 Setter
  CusBriefLLMSpec get llmSpec {
    if (_llmSpec == null && llmSpecJson != null) {
      try {
        _llmSpec = CusBriefLLMSpec.fromJson(jsonDecode(llmSpecJson!));
      } catch (e) {
        print('Error decoding llmSpec: $e');
        print('llmSpecJson: $llmSpecJson');
        rethrow;
      }
    }
    return _llmSpec!;
  }

  set llmSpec(CusBriefLLMSpec value) {
    _llmSpec = value;
    llmSpecJson = jsonEncode(value.toJson());
  }

  LLModelType get modelType {
    if (_modelType == null && modelTypeStr != null) {
      _modelType = LLModelType.values.firstWhere(
        (e) => e.toString() == modelTypeStr,
      );
    }
    return _modelType!;
  }

  set modelType(LLModelType value) {
    _modelType = value;
    modelTypeStr = value.toString();
  }

  @Backlink('session')
  final messages = ToMany<ChatBranchMessage>();

  // 添加默认构造函数
  ChatBranchSession({
    this.id = 0,
    required this.title,
    required this.createTime,
    required this.updateTime,
    this.llmSpecJson,
    this.modelTypeStr,
  });

  // 添加命名构造函数用于创建新会话
  factory ChatBranchSession.create({
    required String title,
    required CusBriefLLMSpec llmSpec,
    required LLModelType modelType,
  }) {
    final session = ChatBranchSession(
      title: title,
      createTime: DateTime.now(),
      updateTime: DateTime.now(),
    );
    session.llmSpec = llmSpec;
    session.modelType = modelType;
    return session;
  }
}
