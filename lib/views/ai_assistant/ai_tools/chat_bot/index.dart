// ignore_for_file: avoid_print,

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../../../apis/chat_completion/common_cc_apis.dart';
import '../../../../apis/voice_recognition/xunfei_apis.dart';
import '../../../../common/constants.dart';
import '../../../../common/llm_spec/cc_spec.dart';
import '../../../../common/utils/db_tools/db_helper.dart';
import '../../../../models/chat_competion/com_cc_resp.dart';
import '../../../../models/chat_competion/com_cc_state.dart';
import '../../_chat_screen_parts/chat_appbar_area.dart';
import '../../_chat_screen_parts/chat_default_question_area.dart';
import '../../_chat_screen_parts/chat_history_drawer.dart';
import '../../_chat_screen_parts/chat_list_area.dart';
import '../../_chat_screen_parts/chat_plat_and_llm_area.dart';
import '../../_chat_screen_parts/chat_title_area.dart';
import '../../_chat_screen_parts/chat_user_send_area_with_voice.dart';
import '../../_componets/sounds_message_button/utils/sounds_recorder_controller.dart';

/// 2024-07-16
/// 这个应该会复用，后续抽出chatbatindex出来
/// 2024-07-23
/// 页面中各个布局的部件已经抽出来了，放在lib/views/ai_assistant/_chat_screen_parts
///   目前已经重构的页面：
///     lib/views/ai_assistant/ai_tools/chat_bot/index.dart
///     lib/views/ai_assistant/ai_tools/aggregate_search/index.dart
///
///
class ChatBat extends StatefulWidget {
  const ChatBat({super.key});

  @override
  State createState() => _ChatBatState();
}

class _ChatBatState extends State<ChatBat> {
  final DBHelper _dbHelper = DBHelper();

  // 人机对话消息滚动列表
  final ScrollController _scrollController = ScrollController();

  // 用户输入的文本控制器
  final TextEditingController _userInputController = TextEditingController();
  // 用户输入的内容（当不是AI在思考、且输入框有非空文字时才可以点击发送按钮）
  String userInput = "";

  /// 级联选择效果：云平台-模型名
  ApiPlatform selectedPlatform = ApiPlatform.siliconCloud;

  CCMSpec selectedModelSpec = CCM_SPEC_LIST
      .where((spec) => spec.platform == ApiPlatform.siliconCloud)
      .toList()
      .first;

  // AI是否在思考中(如果是，则不允许再次发送)
  bool isBotThinking = false;

  /// 2024-06-11 默认使用流式请求，更快;但是同样的问题，流式使用的token会比非流式更多
  /// 2024-06-15 限时限量的可能都是收费的，本来就慢，所以默认就流式，不用切换
  /// 2024-06-20 流式使用的token太多了，还是默认更省的
  bool isStream = true;

  // 默认进入对话页面应该就是啥都没有，然后根据这空来显示预设对话
  List<ChatMessage> messages = [];

  // 2024-06-01 当前的对话记录(用于存入数据库或者从数据库中查询某个历史对话)
  ChatSession? chatSession;

  // 最近对话需要的记录历史对话的变量
  List<ChatSession> chatHistory = [];

  // 等待AI响应时的占位的消息，在构建真实对话的list时要删除
  var placeholderMessage = ChatMessage(
    messageId: "placeholderMessage",
    dateTime: DateTime.now(),
    role: "assistant",
    content: "努力思考中，请耐心等待  ",
    isPlaceholder: true,
  );

  // 进入对话页面简单预设的一些问题
  List<String> defaultQuestions = chatQuestionSamples;

  // 当前正在响应的api返回流(放在全局为了可以手动取消)
  StreamWithCancel<ComCCResp>? respStream;

  @override
  void initState() {
    super.initState();

    initCusConfig();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _userInputController.dispose();
    super.dispose();
  }

  // 进入自行配置的对话页面，看看用户配置有没有生效
  initCusConfig() {
    // 2024-07-14 每次进来都随机选一个
    List<ApiPlatform> values = ApiPlatform.values.toList();
    selectedPlatform = values[Random().nextInt(values.length)];

    setState(() {
      // 2024-07-14 同样的，选中的平台后也随机选择一个模型
      List<CCMSpec> models = CCM_SPEC_LIST
          .where((spec) => spec.platform == selectedPlatform)
          .toList();

      selectedModelSpec = models[Random().nextInt(models.length)];
    });
  }

  //获取指定分类的历史对话
  Future<List<ChatSession>> getHistoryChats() async {
    return await _dbHelper.queryChatList(cateType: "aigc");
  }

  /// 获取指定对话列表
  _getChatInfo(String chatId) async {
    // 默认查询到所有的历史对话(这里有uuid了，应该就只有1条存在才对)
    var list = await _dbHelper.queryChatList(uuid: chatId, cateType: "aigc");

    if (list.isNotEmpty && list.isNotEmpty) {
      // 2024-07-23 注意！！！这里要处理该条历史记录中的消息列表，具体看_sendMessage中的说明
      List<ChatMessage> resultList =
          filterAlternatingRoles(list.first.messages);

      // 注意，如果遍历结束，但只剩下一条role为user的消息列表，则补一个占位消息
      if (resultList.length == 1 && resultList.first.role == "user") {
        resultList.add(ChatMessage(
          messageId: "retry",
          dateTime: DateTime.now(),
          role: "assistant",
          content: "问题回答已遗失，请重新提问",
          isPlaceholder: false,
        ));
      }

      if (!mounted) return;
      setState(() {
        chatSession = list.first;
        chatSession?.messages = resultList;

        // 如果有存是哪个模型，也默认选中该模型
        // ？？？2024-06-11 虽然同一个对话现在可以切换平台和模型了，但这里只是保留第一次对话取的值
        // 后面对话过程中切换平台和模型，只会在该次对话过程中有效
        var tempSpecs = CCM_SPEC_LIST
            // 数据库存的模型名就是自定义的模型名
            .where((e) => e.name == list.first.llmName)
            .toList();

        // 被选中的平台也就是记录中存放的平台
        var tempCps = ApiPlatform.values
            .where((e) => e.name.contains(list.first.cloudPlatformName ?? ""))
            .toList();

        // 避免麻烦，两个都不为空才显示；否则还是预设的
        if (tempSpecs.isNotEmpty && tempCps.isNotEmpty) {
          selectedModelSpec = tempSpecs.first;
          selectedPlatform = tempCps.first;
        }

        // 查到了db中的历史记录，则需要替换成当前的(父页面没选择历史对话进来就是空，则都不会有这个函数)
        messages = chatSession!.messages;
      });
    }
  }

  // 这个发送消息实际是将对话文本添加到对话列表中
  // 但是在用户发送消息之后，需要等到AI响应，成功响应之后将响应加入对话中
  ///
  /// 2024-08-08 从目前使用来看，只有API响应时传入的role才不是user
  // 而使用流式响应时，显示的文本时追加的，此时再调用这个函数就会出现一次响应被当作多个对话条目去了
  // 所以这个改为只为用户发送，API响应直接在响应函数中处理
  _userSendMessage(
    String text, {
    // 2024-08-07 可能text是语音转的文字，保留语音文件路径
    String? contentVoicePath,
    CCUsage? usage,
  }) {
    // 发送消息的逻辑，这里只是简单地将消息添加到列表中
    var temp = ChatMessage(
      messageId: const Uuid().v4(),
      role: "user",
      content: text,
      // 没有录音文件就存空字符串，避免内部转化为“null”字符串
      contentVoicePath: contentVoicePath ?? "",
      dateTime: DateTime.now(),
      promptTokens: usage?.promptTokens,
      completionTokens: usage?.completionTokens,
      totalTokens: usage?.totalTokens,
    );

    if (!mounted) return;
    setState(() {
      isBotThinking = true;

      messages.add(temp);

      // 在每次添加了对话之后，都把整个对话列表存入对话历史中去
      _saveToDb();

      _userInputController.clear();
      // 滚动到ListView的底部
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 300),
      );

      // 如果是用户发送了消息，则开始等到AI响应(如果不是用户提问，则不会去调用接口)
      // 如果是用户输入时，在列表中添加一个占位的消息，以便思考时的装圈和已加载的消息可以放到同一个list进行滑动
      // 一定注意要记得AI响应后要删除此占位的消息
      placeholderMessage.dateTime = DateTime.now();
      messages.add(placeholderMessage);

      _getCCResponse();
    });
  }

  // 保存对话到数据库
  _saveToDb() async {
    // 如果插入时只有一条，那就是用户首次输入，截取部分内容和生成对话记录的uuid

    if (messages.isNotEmpty && messages.length == 1) {
      // 如果没有对话记录(即上层没有传入，且当前时用户第一次输入文字还没有创建对话记录)，则新建对话记录
      chatSession ??= ChatSession(
        uuid: const Uuid().v4(),
        title: messages.first.content.length > 30
            ? messages.first.content.substring(0, 30)
            : messages.first.content,
        gmtCreate: DateTime.now(),
        messages: messages,
        // 2026-06-20 这里记录的自定义模型枚举的值，因为后续查询结果过滤有需要用来判断
        llmName: selectedModelSpec.name,
        cloudPlatformName: selectedPlatform.name,
        // 2026-06-06 对话历史默认带上类别
        chatType: "aigc",
      );

      await _dbHelper.insertChatList([chatSession!]);

      // 如果已经有多个对话了，理论上该对话已经存入db了，只需要修改该对话的实际对话内容即可
    } else if (messages.length > 1) {
      chatSession!.messages = messages;

      await _dbHelper.updateChatSession(chatSession!);
    }

    // 其他没有对话记录、没有消息列表的情况，就不做任何处理了
  }

  // 根据不同的平台、选中的不同模型，调用对应的接口，得到回复
  // 虽然返回的响应通用了，但不同的平台和模型实际取值还是没有抽出来的
  _getCCResponse() async {
    // 将已有的消息处理成Ernie支出的消息列表格式(构建查询条件时要删除占位的消息)
    List<CCMessage> msgs = messages
        .where((e) => e.isPlaceholder != true)
        .map((e) => CCMessage(
              content: e.content,
              role: e.role,
            ))
        .toList();

    // 2024-06-06 ??? 这里一定要确保存在模型名称，因为要作为http请求参数
    var model = selectedModelSpec.model;

    // 后续可手动终止响应时的写法
    StreamWithCancel<ComCCResp> temp;
    if (selectedPlatform == ApiPlatform.lingyiwanwu) {
      temp = await lingyiwanwuCCRespWithCancel(msgs,
          model: model, stream: isStream);
    } else {
      temp = await siliconFlowCCRespWithCancel(msgs,
          model: model, stream: isStream);
    }

    if (!mounted) return;
    setState(() {
      respStream = temp;
    });

    // 在请求前创建当前响应的消息和文本内容，当前请求完之后，就重置为空
    // csMsg => currentStreamingMessage
    ChatMessage? csMsg;
    final StringBuffer messageBuffer = StringBuffer();
    // 上面赋值了，这里应该可以监听到新的流了
    respStream?.stream.listen(
      (crb) {
        // 得到回复后要删除表示加载中的占位消息
        if (!mounted) return;
        setState(() {
          messages.removeWhere((e) => e.isPlaceholder == true);
        });

        // 当前响应流处理完了，就不是AI响应中了
        if (crb.cusText == '[DONE]') {
          if (!mounted) return;
          setState(() {
            _saveToDb();
            _userInputController.clear();
            // 滚动到ListView的底部
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              curve: Curves.easeOut,
              duration: const Duration(milliseconds: 300),
            );

            csMsg = null;
            isBotThinking = false;
          });
        } else {
          setState(() {
            isBotThinking = true;

            messageBuffer.write(crb.cusText);

            // 只有第一次响应时才创建消息体，后续接收的响应流数据只更新当前的
            if (csMsg == null) {
              csMsg = ChatMessage(
                messageId: const Uuid().v4(),
                role: "assistant",
                content: messageBuffer.toString(),
                quotes: crb.choices?.first.quote,
                contentVoicePath: "",
                dateTime: DateTime.now(),
                promptTokens: crb.usage?.promptTokens ?? 0,
                completionTokens: crb.usage?.completionTokens ?? 0,
                totalTokens: crb.usage?.totalTokens ?? 0,
              );

              messages.add(csMsg!);
            } else {
              print(crb.usage?.promptTokens);
              csMsg!.content = messageBuffer.toString();
              // token的使用就是每条返回的就是当前使用的结果，所以最后一条就是最终结果，实时更新到最后一条
              csMsg!.promptTokens = (crb.usage?.promptTokens ?? 0);
              csMsg!.completionTokens = (crb.usage?.completionTokens ?? 0);
              csMsg!.totalTokens = (crb.usage?.totalTokens ?? 0);

              // 模型为rag时，当最后一条时，才会带上引用
              if (crb.lastOne == true) {
                csMsg!.quotes = crb.choices?.first.quote;
              }
            }
          });
        }
      },
      // 非流式的时候，只有一条数据，永远不会触发上面监听时的DONE的情况
      onDone: () {
        if (!mounted) return;
        setState(() {
          _saveToDb();
          _userInputController.clear();
          // 滚动到ListView的底部
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            curve: Curves.easeOut,
            duration: const Duration(milliseconds: 300),
          );

          csMsg = null;
          isBotThinking = false;
        });
      },
    );
  }

  /// 构建用于下拉的平台列表(根据上层传入的值)
  List<DropdownMenuItem<ApiPlatform?>> buildCloudPlatforms() {
    return ApiPlatform.values.map((e) {
      return DropdownMenuItem<ApiPlatform?>(
        value: e,
        alignment: AlignmentDirectional.center,
        child: Text(
          CP_NAME_MAP[e]!,
          style: const TextStyle(color: Colors.blue),
        ),
      );
    }).toList();
  }

  /// 当切换了云平台时，要同步切换选中的大模型
  onCloudPlatformChanged(ApiPlatform? value) {
    // 如果平台被切换，则更新当前的平台为选中的平台，且重置模型为符合该平台的模型的第一个
    if (value != selectedPlatform) {
      // 更新被选中的平台为当前选中平台
      selectedPlatform = value ?? ApiPlatform.siliconCloud;

      setState(() {
        // 切换平台后，修改选中的模型为该平台第一个

        selectedModelSpec = CCM_SPEC_LIST
            .where((spec) => spec.platform == selectedPlatform)
            .toList()
            .first;

        // 2024-06-15 切换平台或者模型应该清空当前对话，因为上下文丢失了。
        // 建立新对话就是把已有的对话清空就好(因为保存什么的在发送消息时就处理了)
        chatSession = null;
        messages.clear();
      });
    }
  }

  List<DropdownMenuItem<CCMSpec>> buildPlatformLLMs() {
    // 用于下拉的模型首先是需要以平台前缀命名的
    return CCM_SPEC_LIST
        .where((spec) => spec.platform == selectedPlatform)
        .map((e) => DropdownMenuItem<CCMSpec>(
              value: e,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                e.name,
                style: const TextStyle(color: Colors.blue),
              ),
            ))
        .toList();
  }

  /// 最后一条大模型回复如果不满意，可以重新生成(中间的不行，因为后续的问题是关联上下文的)
  /// 2024-06-20 限量的要计算token数量，所以不让重新生成(？？？但实际也没做累加的token的逻辑)
  regenerateLatestQuestion() {
    setState(() {
      // 将最后一条消息删除，并添加占位消息，重新发送
      messages.removeLast();
      placeholderMessage.dateTime = DateTime.now();
      messages.add(placeholderMessage);

      _getCCResponse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBarArea(
        title: '你问我答',
        onNewChatPressed: () {
          setState(() {
            chatSession = null;
            messages.clear();
          });
        },
        onHistoryPressed: (BuildContext context) async {
          var list = await getHistoryChats();
          if (!mounted) return;
          setState(() {
            chatHistory = list;
          });
          if (!context.mounted) return;
          Scaffold.of(context).openEndDrawer();
        },
      ),
      body: GestureDetector(
        // 允许子控件（如TextField）接收点击事件
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // 点击空白处可以移除焦点，关闭键盘
          FocusScope.of(context).unfocus();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 构建可切换云平台和模型的行
            Container(
              color: Colors.grey[300],
              child: Padding(
                padding: EdgeInsets.only(left: 10.sp),
                child: PlatAndLlmRow(
                  selectedPlatform: selectedPlatform,
                  onPlatformChanged: onCloudPlatformChanged,
                  selectedModelSpec: selectedModelSpec,
                  onModelSpecChanged: (val) {
                    setState(() {
                      selectedModelSpec = val!;
                      // 2024-06-15 切换模型应该新建对话，因为上下文丢失了。
                      // 建立新对话就是把已有的对话清空就好(因为保存什么的在发送消息时就处理了)
                      chatSession = null;
                      messages.clear();
                    });
                  },
                  buildPlatformList: buildCloudPlatforms,
                  buildModelSpecList: buildPlatformLLMs,
                  showToggleSwitch: true,
                  isStream: isStream,
                  onToggle: (index) {
                    setState(() {
                      isStream = index == 0 ? true : false;
                      // 切换流式/同步响应也新开对话
                      // chatSession = null;
                      // messages.clear();
                    });
                  },
                ),
              ),
            ),

            /// 如果对话是空，显示预设的问题
            // 预设的问题标题
            if (messages.isEmpty)
              Padding(
                padding: EdgeInsets.all(10.sp),
                child: Text(" 你可以试着问我：", style: TextStyle(fontSize: 18.sp)),
              ),
            // 预设的问题列表
            if (messages.isEmpty)
              ChatDefaultQuestionArea(
                defaultQuestions: defaultQuestions,
                onQuestionTap: _userSendMessage,
              ),

            /// 对话的标题区域
            /// 在顶部显示对话标题(避免在appbar显示，内容太挤)
            if (chatSession != null)
              ChatTitleArea(
                chatSession: chatSession,
                onUpdate: (ChatSession e) async {
                  // 修改对话的标题
                  await _dbHelper.updateChatSession(e);

                  // 修改后更新标题
                  if (!mounted) return;
                  setState(() {
                    chatSession = e;
                  });
                },
              ),

            /// 标题和对话正文的分割线
            if (chatSession != null) Divider(height: 3.sp, thickness: 1.sp),

            /// 显示对话消息主体
            ChatListArea(
              messages: messages,
              scrollController: _scrollController,
              isBotThinking: isBotThinking,
              regenerateLatestQuestion: regenerateLatestQuestion,
            ),

            /// 显示输入框和发送按钮
            const Divider(),

            /// 用户发送区域
            ChatUserVoiceSendArea(
              controller: _userInputController,
              hintText: '可以向我提任何问题哦',
              isBotThinking: isBotThinking,
              userInput: userInput,
              onInpuChanged: (text) {
                setState(() {
                  userInput = text.trim();
                });
              },
              // onSendPressed 和 onSendSounds 理论上不会都触发的
              onSendPressed: () {
                _userSendMessage(userInput);
                setState(() {
                  userInput = "";
                });
              },
              // 点击了语音发送，可能是文件，也可能是语音转的文字
              onSendSounds: (type, content) async {
                print("语音发送的玩意儿 $type $content");

                if (type == SendContentType.text) {
                  _userSendMessage(content);
                } else if (type == SendContentType.voice) {
                  //

                  /// 同一份语言有两个部分，一个是原始录制的m4a的格式，一个是转码厚的pcm格式
                  /// 前者用于语音识别，后者用于播放
                  String fullPathWithoutExtension = path.join(
                    path.dirname(content),
                    path.basenameWithoutExtension(content),
                  );

                  var transcription =
                      await sendAudioToServer("$fullPathWithoutExtension.pcm");
                  // 注意：语言转换文本必须pcm格式，但是需要点击播放的语音则需要原本的m4a格式
                  // 都在同一个目录下同一路径不同扩展名
                  _userSendMessage(
                    transcription,
                    contentVoicePath: "$fullPathWithoutExtension.m4a",
                  );
                }
              },
              // 2024-08-08 手动点击了终止
              onStop: () async {
                await respStream?.cancel();
                if (!mounted) return;
                setState(() {
                  _saveToDb();
                  _userInputController.clear();
                  // 滚动到ListView的底部
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    curve: Curves.easeOut,
                    duration: const Duration(milliseconds: 300),
                  );

                  isBotThinking = false;
                });
              },
            ),
          ],
        ),
      ),

      /// 构建在对话历史中的对话标题列表
      endDrawer: ChatHistoryDrawer(
        chatHistory: chatHistory,
        onTap: (ChatSession e) {
          Navigator.of(context).pop();
          // 点击了知道历史对话，则替换当前对话
          setState(() {
            _getChatInfo(e.uuid);
          });
        },
        onUpdate: (ChatSession e) async {
          // 修改对话的标题
          await _dbHelper.updateChatSession(e);
          // 修改成功后重新查询更新
          var list = await getHistoryChats();
          if (!mounted) return;
          setState(() {
            chatHistory = list;
          });
        },
        onDelete: (ChatSession e) async {
          // 先删除
          await _dbHelper.deleteChatById(e.uuid);
          // 然后重新查询并更新
          var list = await getHistoryChats();
          if (!mounted) return;
          setState(() {
            chatHistory = list;
          });
          // 如果删除的历史对话是当前对话，跳到新开对话页面
          if (chatSession?.uuid == e.uuid) {
            setState(() {
              chatSession = null;
              messages.clear();
            });
          }
        },
      ),
    );
  }
}
