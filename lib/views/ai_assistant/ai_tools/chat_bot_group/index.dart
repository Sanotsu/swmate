// ignore_for_file: avoid_print,

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as path;
import 'package:toggle_switch/toggle_switch.dart';
import 'package:uuid/uuid.dart';

import '../../../../apis/chat_completion/common_cc_apis.dart';
import '../../../../apis/voice_recognition/xunfei_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/constants.dart';
import '../../../../common/llm_spec/cus_llm_model.dart';
import '../../../../common/llm_spec/cus_llm_spec.dart';
import '../../../../common/utils/db_tools/db_helper.dart';
import '../../../../models/chat_competion/com_cc_resp.dart';
import '../../../../models/chat_competion/com_cc_state.dart';
import '../../_chat_screen_parts/chat_default_question_area.dart';
import '../../_chat_screen_parts/chat_history_drawer.dart';
import '../../_chat_screen_parts/chat_list_area.dart';
import '../../_chat_screen_parts/chat_user_send_area_with_voice.dart';
import '../../_componets/sounds_message_button/utils/sounds_recorder_controller.dart';
import '../../_helper/handle_cc_response.dart';
import '../../_componets/multi_select_dialog.dart';
import '../../_helper/tools.dart';

/// 2024-07-23
/// 这个初衷是：
///   1 用户选中几个大模型
///   2 用户问一个问题，然后被选中的大模型依次回答问题
///   3 用户继续询问，各个模型根据自己的上下文继续问答问题
///   4 用户可以【保存】对话，下次进入时，可以恢复对话（这个和之前的设计差别挺大，暂时不做）
///
class ChatBotGroup extends StatefulWidget {
  const ChatBotGroup({super.key});

  @override
  State createState() => _ChatBotGroupState();
}

class _ChatBotGroupState extends State<ChatBotGroup> {
  final DBHelper _dbHelper = DBHelper();

  // 人机对话消息滚动列表
  final ScrollController _scrollController = ScrollController();

  // 用户输入的文本控制器
  final TextEditingController _userInputController = TextEditingController();
  // 用户输入的内容（当不是AI在思考、且输入框有非空文字时才可以点击发送按钮）
  String userInput = "";

  // AI是否在思考中(如果是，则不允许再次发送)
  bool isBotThinking = false;

  bool isStream = true;

  ///============

  // 2024-07-23 对话现在需要考虑更多
  // 用户输入、AI响应、不同平台的消息要单独分开、等待错误重试等占位
  // map的key为模型名，value为该模型的消息列表
  Map<String, List<ChatMessage>> msgMap = {};

  // 2024-07-24 用于在一个列表中显示的消息对话
  List<ChatMessage> messages = [];

  // 当前的群聊对话记录(用于存入数据库或者从数据库中查询某个历史对话)
  GroupChatHistory? chatHistory;
  // 最近的群聊对话记录列表
  List<GroupChatHistory> chatHistoryList = [];

  // 进入对话页面简单预设的一些问题
  List<String> defaultQuestions = chatQuestionSamples;

  ///==============
  // 2024-07-23 这里纯粹是为了方便，把enLable存平台的名称，用于区分需要调用的接口函数
  late List<CusLabel> _allItems;

  List<CusLabel> _selectedItems = [];

  // map的key为模型名，value为该模型SSE请求流
  // (理论上每个选中的模型，同一时间只有一个流。流式响应的时候可以一下子停止所有)
  Map<String, StreamWithCancel<ComCCResp>> respStreamMap = {};

  // 如果选中的对比模型是2个，且启用对战模式，才上下两个列表分别显示各自模型的对话
  // 否则就是一个用户输入，下面多个AI回复
  bool isBattleMode = false;

  @override
  void initState() {
    initCusLabelList();

    super.initState();
  }

  initCusLabelList() async {
    var specs = await fetchCusLLMSpecList(LLModelType.cc);

    setState(() {
      _allItems = specs
          .map((e) => CusLabel(cnLabel: e.name, enLabel: e.model, value: e))
          .toList();

      _selectedItems = [
        // _allItems[1],
        _allItems[5],
        _allItems[6],
        // _allItems[11],
      ];
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _userInputController.dispose();
    super.dispose();
  }

  // 在用户输入或者AI响应后，需要把对话列表滚动到最下面
  // 调用时放在状态改变函数中
  chatListScrollToBottom() {
    // 每收到一点新的响应文本，就都滚动到ListView的底部
    // 注意：ai响应的消息卡片下方还有一行功能按钮，这里滚动了那个还没显示的话是看不到的
    // 所以滚动到最大还加一点高度（大于实际功能按钮高度也没问题）
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 80,
      curve: Curves.easeOut,
      // 注意：sse的间隔比较短，这个滚动也要快一点
      duration: const Duration(milliseconds: 50),
    );
  }

  //获取指定分类的历史对话
  Future<List<GroupChatHistory>> getHistoryChats() async {
    return await _dbHelper.queryGroupChatList();
  }

  /// 获取指定对话列表
  _getChatInfo(String chatId) async {
    // 默认查询到所有的历史对话(这里有uuid了，应该就只有1条存在才对)
    var list = await _dbHelper.queryGroupChatList(uuid: chatId);

    if (list.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        chatHistory = list.first;
        chatHistory?.messages = list.first.messages;
        chatHistory?.modelMsgMap = list.first.modelMsgMap;

        // 查到了db中的历史记录，则需要替换成当前的
        messages = chatHistory!.messages;
        msgMap = chatHistory!.modelMsgMap;

        // 获取群聊历史记录中选中的模型，构建选中编号

        // _selectedItems = msgMap.keys
        //     .toList()
        //     .map((label) =>
        //         _allItems.indexWhere((item) => item.cnLabel == label))
        //     .where((index) => index != -1)
        //     .toList();

        _selectedItems = msgMap.keys
            .toList()
            .map((label) => _allItems.firstWhere(
                (item) => item.enLabel == label,
                orElse: () => _allItems.first))
            .toSet() // 因为上面orElse可能多个都不匹配就有多个first的值
            .toList();
      });
    }
  }

  /// 保存对话到数据库
  _saveToDb() async {
    print("保存到数据库前---${chatHistory?.toRawJson()}");
    // 如果插入时只有一条，那就是用户首次输入，截取部分内容和生成对话记录的uuid
    // 2024-08-23 如果对话中只有1个user或者1个user和1个system(即两条信息)，则表明是新建对话
    if (messages.isNotEmpty &&
            (messages.length == 1 &&
                messages.where((e) => e.role == "user").length == 1) ||
        (messages.length == 2 &&
            messages.where((e) => e.role == "user").length == 1 &&
            messages.where((e) => e.role == "system").length == 1)) {
      // 如果没有对话记录(即上层没有传入，且当前时用户第一次输入文字还没有创建对话记录)，则新建对话记录
      chatHistory ??= GroupChatHistory(
        uuid: const Uuid().v4(),
        title: messages.first.content.length > 30
            ? messages.first.content.substring(0, 30)
            : messages.first.content,
        gmtCreate: DateTime.now(),
        gmtModified: DateTime.now(),
        messages: messages,
        modelMsgMap: msgMap,
      );

      await _dbHelper.insertGroupChatList([chatHistory!]);

      // 如果已经有多个对话了，理论上该对话已经存入db了，只需要修改该对话的实际对话内容即可
    } else if (messages.length > 1) {
      chatHistory!.messages = messages;
      chatHistory!.modelMsgMap = msgMap;
      // 2024-08-30,如果用户有修改之前的对话记录，则需要更新对话记录的时间
      chatHistory!.gmtModified = DateTime.now();

      await _dbHelper.updateGroupChatHistory(chatHistory!);
    }

    // 其他没有对话记录、没有消息列表的情况，就不做任何处理了
  }

  // 先多选了几个模型，发送后，每个模型都要调用
  _userSendMessage(
    String text, {
    String? contentVoicePath,
  }) {
    // 用户发送了消息，只需要加入一次
    var temp = ChatMessage(
      messageId: const Uuid().v4(),
      role: "user",
      content: text,
      // 没有录音文件就存空字符串，避免内部转化为“null”字符串
      contentVoicePath: contentVoicePath ?? "",
      dateTime: DateTime.now(),
    );

    // 对话列表只添加一条
    setState(() {
      messages.add(temp);
      _userInputController.clear();
    });

    // 在每次添加了对话之后，都把整个对话列表存入对话历史中去
    _saveToDb();

    // 注意，因为下面每个模型响应中都已经调用滚动了，所以用户输入后不用调用滚动
    // 调用了反而会出错 ：
    //    ScrollController not attached to any scroll views.
    //    'package:flutter/src/widgets/scroll_controller.dart':
    //    Failed assertion: line 157 pos 12: '_positions.isNotEmpty'
    // chatListScrollToBottom();

    // 每个模型用于构建消息参数的，各自添加
    for (var e in _selectedItems) {
      var model = (e.value as CusLLMSpec).model;

      // 添加到对话列表中（只有这里有新增修改）
      if (msgMap.containsKey(model)) {
        // 如果键存在，向列表中添加值
        msgMap[model]?.add(temp);
      } else {
        // 如果键不存在，创建新的列表并将值添加进去
        msgMap[model] = [temp];
      }

      separatelyHandleMessage(model, e);
    }
  }

  // 单纯AI响应后的消息，要添加到整体对话列表和各个模型各自的对话列表中
  separatelyHandleMessage(
    String model, // 当前调用的模型名
    CusLabel e, // 当前模型的规格信息
  ) async {
    // 获取响应流
    StreamWithCancel<ComCCResp> tempStream = await getCCResponseSWC(
      // 每个模型都用各自的消息列表，理论上都应该存在的
      messages: msgMap[model]!,
      selectedPlatform: (e.value as CusLLMSpec).platform,
      selectedModel: model,
      isStream: isStream,
    );

    if (!mounted) return;
    setState(() {
      // 理论上，每个模型同时只有一个推送流，所以这里直接替换了，用于用户终止操作
      respStreamMap[model] = tempStream;
    });

    // 在得到响应后，就直接把响应的消息加入对话列表
    // 又因为是流式的,初始时文本设为空，SSE有推送时，会更新相关栏位
    // 又因为SSE推送完之后要清空，所有可为null
    // csMsg => currentStreamingMessage
    ChatMessage? csMsg = buildEmptyAssistantChatMessage(modelLabel: model);

    setState(() {
      // 添加到整体对话列表
      messages.add(csMsg!);
      // 添加到对话列表中
      if (msgMap.containsKey(model)) {
        // 如果键存在，向列表中添加值
        msgMap[model]?.add(csMsg!);
      } else {
        // 如果键不存在，创建新的列表并将值添加进去
        msgMap[model] = [csMsg!];
      }
    });

    // 处理流式响应
    handleCCResponseSWC(
      swc: tempStream,
      onData: (crb) {
        commonOnDataHandler(
          crb: crb,
          csMsg: csMsg!,
          // 流式响应结束了，就保存数据到db，并重置流式变量和aip响应标志
          onStreamDone: () {
            if (!mounted) return;
            setState(() {
              _saveToDb();
              csMsg = null;
              isBotThinking = false;
            });
          },
          // 处理流的过程中都是响应中
          // (如果不设置这个，就没办法促使SSE每有一个推送都及时更新页面了)
          setIsResponsing: () {
            setState(() {
              isBotThinking = true;
            });
          },
          // 如果是对战模式，上下两个滚动，所以这里使用会报错
          scrollToBottom: !isBattleMode ? chatListScrollToBottom : null,
        );
      },
      onDone: () {
        print("文本对话 监听的【onDone】触发了");
        // 如果是流式响应，最后一条会带有[DNOE]关键字，所以在上面处理最后响应结束的操作
        // 如果不是流式，响应流就只有1条数据，那么就只有在这里才能得到流结束了，所以需要在这里完成后的操作
        // 但是如果是流式，还在这里处理结束操作的话会出问题(实测在数据还在推送的时候，这个ondone就触发了)
        if (!isStream) {
          if (!mounted) return;
          // 流式响应结束了，就保存数据到db，并重置流式变量和aip响应标志
          setState(() {
            _saveToDb();
            csMsg = null;
            isBotThinking = false;
          });
        }
      },
      onError: (error) {
        commonExceptionDialog(context, "异常提示", error.toString());
      },
    );

    print("separatelyHandleMessage---$model");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能群聊'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: messages.isNotEmpty
                ? () {
                    setState(() {
                      chatHistory = null;
                      messages.clear();
                      msgMap.clear();
                    });
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.checklist_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return CusMultiSelectBottomSheet(
                    items: _allItems,
                    selectedItems: _selectedItems,
                    title: "模型多选",
                  );
                },
              ).then((selectedItems) {
                // 多选框点击了确认就要重新开始(点击取消则不会)
                if (selectedItems != null) {
                  setState(() {
                    _selectedItems = selectedItems;
                    // 重新选择了模型列表，则重新开始对话
                    messages.clear();
                    msgMap.clear();
                  });
                }
              });
            },
          ),
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.history),
                onPressed: () async {
                  var list = await getHistoryChats();
                  if (!context.mounted) return;
                  setState(() {
                    chatHistoryList = list;
                  });
                  unfocusHandle();

                  print("xxxxxxxxxxxx");
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        // 允许子控件（如TextField）接收点击事件
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // 点击空白处可以移除焦点，关闭键盘
          unfocusHandle();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 选中的平台模型
            SizedBox(
              height: 50.sp,
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.only(left: 10.sp, right: 10.sp),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(width: 10.sp),
                      Wrap(
                        direction: Axis.horizontal,
                        spacing: 5,
                        alignment: WrapAlignment.spaceAround,
                        children: List.generate(
                          _selectedItems.length,
                          (index) => buildSmallButtonTag(
                            _selectedItems[index].cnLabel,
                            bgColor: Colors.lightGreen[100],
                            labelTextSize: 12.sp,
                          ),
                        ).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(width: 20.sp),
                Expanded(
                  child: Text(
                    "可横向滚动查看选中模型",
                    style: TextStyle(fontSize: 13.sp),
                  ),
                ),
                // 只有选中的模型仅2个时才支持对战模式
                if (_selectedItems.length == 2)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.sp),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          isBattleMode = !isBattleMode;
                        });
                      },
                      icon: Icon(
                        Icons.compare,
                        // 如果已经是对战模式，则为蓝色；如果不是对战模式，用默认颜色，表示可以开启对战模式
                        color: isBattleMode ? Colors.blue : null,
                      ),
                    ),
                  ),
                ToggleSwitch(
                  minHeight: 30.sp,
                  minWidth: 48.sp,
                  fontSize: 13.sp,
                  cornerRadius: 5.sp,
                  initialLabelIndex: isStream == true ? 0 : 1,
                  totalSwitches: 2,
                  labels: const ['分段', '直出'],
                  onToggle: (index) =>
                      setState(() => isStream = index == 0 ? true : false),
                ),
                SizedBox(width: 5.sp),
              ],
            ),

            Divider(height: 1.sp),

            /// 如果对话是空，显示预设的问题
            if (msgMap.values.isEmpty)
              // 预设的问题标题
              Padding(
                padding: EdgeInsets.all(10.sp),
                child: Text(" 你可以试着问我：", style: TextStyle(fontSize: 18.sp)),
              ),

            // 预设的问题列表
            if (msgMap.values.isEmpty)
              ChatDefaultQuestionArea(
                defaultQuestions: defaultQuestions,
                onQuestionTap: _userSendMessage,
              ),

            /// 对话的标题区域(因为暂时没有保存，所以就显示用户第一次输入的前20个字符就好了)
            if (msgMap.values.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(1.sp),
                child: Row(
                  children: [
                    const Icon(Icons.title),
                    SizedBox(width: 10.sp),
                    Expanded(
                      child: Text(
                        msgMap.values.first.first.content,
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            /// 显示对话消息主体
            /// (所有对话内容放到一个列表中)
            if (msgMap.values.isNotEmpty && !isBattleMode)
              ChatListArea(
                messages: messages,
                scrollController: _scrollController,
                isBotThinking: isBotThinking,
                isShowModelLable: true,
                isAvatarTop: true,
              ),

            /// 显示对话消息主体
            /// （不同的模型放在不同的列表中，当只有2个进行对比时，各自滚动比较好看）
            /// (模型多了，切得太小了就不好看了)
            if (msgMap.values.isNotEmpty && isBattleMode)
              ...List.generate(msgMap.values.length, (index) {
                return Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(width: 5.sp), // 头像宽度
                          Text(
                            msgMap.keys.toList()[index],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                              color: Colors.green,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ],
                      ),
                      ChatListArea(
                        messages: msgMap.values.toList()[index],
                        scrollController: _scrollController,
                        isBotThinking: isBotThinking,
                        isShowModelLable: false,
                        isAvatarTop: true,
                      ),
                    ],
                  ),
                );
              }),

            /// 显示输入框和发送按钮
            const Divider(),

            /// 用户发送区域
            ChatUserVoiceSendArea(
              controller: _userInputController,
              hintText: '可以向我提任何问题哦',
              isBotThinking: isBotThinking,
              isSendClickable: userInput.isNotEmpty,
              onInpuChanged: (text) {
                setState(() {
                  userInput = text.trim();
                });
              },
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
                  String tempPath = path.join(
                    path.dirname(content),
                    path.basenameWithoutExtension(content),
                  );

                  var transcription = await sendAudioToServer("$tempPath.pcm");
                  _userSendMessage(
                    transcription,
                    contentVoicePath: "$tempPath.m4a",
                  );
                }
              },
              // 2024-08-08 手动点击了终止
              // 因为多选模型，就有多个响应流，就存入全局，一一停止
              onStop: () async {
                for (var s in respStreamMap.values) {
                  await s.cancel();
                }

                if (!mounted) return;
                setState(() {
                  _saveToDb();

                  _userInputController.clear();
                  // 滚动到ListView的底部
                  // 如果是对战模式，上下两个滚动，所以这里使用会报错
                  if (!isBattleMode) {
                    chatListScrollToBottom();
                  }
                  isBotThinking = false;
                });
              },
            ),
          ],
        ),
      ),

      /// 构建在对话历史中的对话标题列表
      endDrawer: ChatHistoryDrawer(
        chatHistory: chatHistoryList,
        onTap: (GroupChatHistory e) {
          Navigator.of(context).pop();
          // 点击了指定历史对话，则替换当前对话
          setState(() {
            _getChatInfo(e.uuid);
          });
        },
        onUpdate: (GroupChatHistory e) async {
          // 修改对话的标题
          await _dbHelper.updateGroupChatHistory(e);
          // 修改成功后重新查询更新
          var list = await getHistoryChats();
          if (!mounted) return;
          setState(() {
            chatHistoryList = list;
          });
        },
        onDelete: (GroupChatHistory e) async {
          // 先删除
          await _dbHelper.deleteGroupChatById(e.uuid);
          // 然后重新查询并更新
          var list = await getHistoryChats();
          if (!mounted) return;
          setState(() {
            chatHistoryList = list;
          });
          // 如果删除的历史对话是当前对话，跳到新开对话页面
          if (chatHistory?.uuid == e.uuid) {
            setState(() {
              chatHistory = null;
              messages.clear();
              msgMap.clear();
            });
          }
        },
      ),
    );
  }
}
