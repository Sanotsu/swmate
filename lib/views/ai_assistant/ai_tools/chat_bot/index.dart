// ignore_for_file: avoid_print,

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../../../apis/chat_completion/common_cc_apis.dart';
import '../../../../apis/voice_recognition/xunfei_apis.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/constants.dart';
import '../../../../common/llm_spec/cus_llm_spec.dart';
import '../../../../common/llm_spec/cus_llm_model.dart';
import '../../../../common/utils/db_tools/db_helper.dart';
import '../../../../models/chat_competion/com_cc_resp.dart';
import '../../../../models/chat_competion/com_cc_state.dart';
import '../../_chat_screen_parts/chat_appbar_area.dart';
import '../../_chat_screen_parts/chat_default_question_area.dart';
import '../../_chat_screen_parts/chat_history_drawer.dart';
import '../../_chat_screen_parts/chat_list_area.dart';
import '../../_chat_screen_parts/chat_title_area.dart';
import '../../_chat_screen_parts/chat_user_send_area_with_voice.dart';
import '../../_componets/cus_system_prompt_modal.dart';
import '../../_componets/sounds_message_button/utils/sounds_recorder_controller.dart';
import '../../_helper/handle_cc_response.dart';
import '../../_componets/cus_platform_and_llm_row.dart';
import '../../_helper/tools.dart';

/// 2024-07-16
/// 这个应该会复用，后续抽出chatbatindex出来
/// 2024-07-23
/// 页面中各个布局的部件已经抽出来了，放在lib/views/ai_assistant/_chat_screen_parts
///   目前已经重构的页面：
///     lib/views/ai_assistant/ai_tools/chat_bot/index.dart
///     lib/views/ai_assistant/ai_tools/aggregate_search/index.dart
///
/// 2024-08-11 把http请求等待响应的加载圈放在拦截器里面，这里的对话列表中就不再需要占位的消息了
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

  // 所有支持文生图的模型列表(用于下拉的平台和该平台拥有的模型列表也从这里来)
  late List<CusLLMSpec> llmSpecList;

  /// 级联选择效果：云平台-模型名
  ApiPlatform selectedPlatform = ApiPlatform.siliconCloud;

  // 被选中的模型信息
  late CusLLMSpec selectedModelSpec;

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

  // 进入对话页面简单预设的一些问题
  List<String> defaultQuestions = chatQuestionSamples;

  // 当前正在响应的api返回流(放在全局为了可以手动取消)
  StreamWithCancel<ComCCResp> respStream = StreamWithCancel.empty();

  // 2024-08-23 用户如果选择了预设角色，就得显示出来
  CusSysRoleSpec? selectedRole;

  // 可供选择的系统角色列表
  late List<CusSysRoleSpec> ccSysRoleList;

  // 是否初始化完成(选择的对话和支持的对话列表，没从数据库获取到就不要加载页面)
  bool isInited = false;

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

  // 进入自行配置的对话页面，看看用户配置有没有生效
  initCusConfig() async {
    // 获取对话的模型列表(具体逻辑看函数内部)
    var tempList = await fetchCusLLMSpecList(LLModelType.cc);
    setState(() {
      llmSpecList = tempList;
    });

    // 2024-07-14 每次进来都随机选一个
    List<ApiPlatform> values =
        llmSpecList.map((e) => e.platform).toSet().toList();
    // 不能放在下面一起，因为选中的平台要先生效，才能构建该平台下的模型
    setState(() {
      selectedPlatform = values[Random().nextInt(values.length)];
    });

    // 2024-07-14 同样的，选中的平台后也随机选择一个模型
    List<CusLLMSpec> models =
        llmSpecList.where((spec) => spec.platform == selectedPlatform).toList();
    setState(() {
      selectedModelSpec = models[Random().nextInt(models.length)];
    });

    // 2024-08-26 同样的，还要查询到db中所有预设的系统角色
    var cusSysRoleSpecs = await _dbHelper.queryCusSysRoleSpecList(
      sysRoleType: LLModelType.cc,
    );

    setState(() {
      ccSysRoleList = cusSysRoleSpecs.toList();
    });

    // 最后才设置为初始化完成
    setState(() {
      isInited = true;
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

    if (list.isNotEmpty) {
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
        ));
      }

      var specs = await _dbHelper.queryCusLLMSpecList();
      if (!mounted) return;
      setState(() {
        chatSession = list.first;
        chatSession?.messages = resultList;

        // 如果有存是哪个模型，也默认选中该模型
        // ？？？2024-06-11 虽然同一个对话现在可以切换平台和模型了，但这里只是保留第一次对话取的值
        // 后面对话过程中切换平台和模型，只会在该次对话过程中有效
        var tempSpecs = specs
            // 数据库存的模型名就是自定义的模型名
            .where((e) => e.name == list.first.llmName)
            .toList();

        // 避免麻烦，两个都不为空才显示；否则还是预设的
        if (tempSpecs.isNotEmpty) {
          selectedModelSpec = tempSpecs.first;
          selectedPlatform = tempSpecs.first.platform;
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
  }) {
    setState(() {
      // 用户发送消息的逻辑，这里只是简单地将消息添加到列表中
      messages.add(
        ChatMessage(
          messageId: const Uuid().v4(),
          role: "user",
          content: text,
          // 没有录音文件就存空字符串，避免内部转化为“null”字符串
          contentVoicePath: contentVoicePath ?? "",
          dateTime: DateTime.now(),
        ),
      );

      // 在每次添加了对话之后，都把整个对话列表存入对话历史中去
      _saveToDb();

      _userInputController.clear();
      chatListScrollToBottom();

      _getCCResponse();
    });
  }

  // 根据不同的平台、选中的不同模型，调用对应的接口，得到回复
  // 虽然返回的响应通用了，但不同的平台和模型实际取值还是没有抽出来的
  _getCCResponse() async {
    // 在调用前，不会设置响应状态
    if (isBotThinking) return;
    setState(() {
      isBotThinking = true;
    });

    // 获取响应流
    StreamWithCancel<ComCCResp> tempStream = await getCCResponseSWC(
      messages: messages,
      selectedPlatform: selectedPlatform,
      selectedModel: selectedModelSpec.model,
      isStream: isStream,
    );

    if (!mounted) return;
    setState(() {
      respStream = tempStream;
    });

    // 在得到响应后，就直接把响应的消息加入对话列表
    // 又因为是流式的,初始时文本设为空，SSE有推送时，会更新相关栏位
    // csMsg => currentStreamingMessage
    ChatMessage? csMsg = buildEmptyAssistantChatMessage();

    setState(() {
      messages.add(csMsg!);
    });

    // 处理流式响应
    handleCCResponseSWC(
      swc: respStream,
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
          scrollToBottom: chatListScrollToBottom,
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
  }

  /// 保存对话到数据库
  _saveToDb() async {
    // 如果插入时只有一条，那就是用户首次输入，截取部分内容和生成对话记录的uuid
    // 2024-08-23 如果对话中只有1个user或者1个user和1个system(即两条信息)，则表明是新建对话
    if (messages.isNotEmpty &&
            (messages.length == 1 &&
                messages.where((e) => e.role == "user").length == 1) ||
        (messages.length == 2 &&
            messages.where((e) => e.role == "user").length == 1 &&
            messages.where((e) => e.role == "system").length == 1)) {
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

  /// 最后一条大模型回复如果不满意，可以重新生成(中间的不行，因为后续的问题是关联上下文的)
  /// 2024-06-20 限量的要计算token数量，所以不让重新生成(？？？但实际也没做累加的token的逻辑)
  regenerateLatestQuestion() {
    setState(() {
      // 将最后一条消息删除，重新发送
      messages.removeLast();
      _getCCResponse();
    });
  }

// 重新开启对话要清空一些内容
  restartChat() {
    setState(() {
      chatSession = null;
      messages.clear();
      selectedRole = null;
    });
  }

  // 显示系统角色弹窗
  showSystemRoleMadel() {
    showCusSysRoleList(
      context,
      ccSysRoleList,
      isInited,
      onRoleSelected,
    );
  }

  // 如果选择了系统角色，则清除当前对话,添加system prompt
  void onRoleSelected(CusSysRoleSpec role) {
    setState(() {
      restartChat();

      selectedRole = role;
      messages.add(
        ChatMessage(
          messageId: const Uuid().v4(),
          role: "system",
          content: role.systemPrompt,
          contentVoicePath: "",
          dateTime: DateTime.now(),
        ),
      );
    });

    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('Selected: ${role.label}')),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBarArea(
        title: '智能对话',
        onCusSysRolePressed: showSystemRoleMadel,
        onNewChatPressed: () => restartChat(),
        onHistoryPressed: (BuildContext context) async {
          var list = await getHistoryChats();
          if (!context.mounted) return;
          setState(() {
            chatHistory = list;
          });
          unfocusHandle();
          Scaffold.of(context).openEndDrawer();
        },
      ),
      body: GestureDetector(
        // 允许子控件（如TextField）接收点击事件
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // 点击空白处可以移除焦点，关闭键盘
          unfocusHandle();
        },
        child: !isInited
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 构建可切换云平台和模型的行
                  Container(
                    color: Colors.grey[300],
                    child: Padding(
                      padding: EdgeInsets.only(left: 10.sp),
                      child: CusPlatformAndLlmRow(
                        initialPlatform: selectedPlatform,
                        initialModelSpec: selectedModelSpec,
                        llmSpecList: llmSpecList,
                        targetModelType: LLModelType.cc,
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
                        onPlatformOrModelChanged:
                            (ApiPlatform? cp, CusLLMSpec? llmSpec) {
                          setState(() {
                            selectedPlatform = cp!;
                            selectedModelSpec = llmSpec!;
                            // 模型可供输出的图片尺寸列表也要更新
                            // 2024-06-15 切换模型应该新建对话，因为上下文丢失了。
                            // 建立新对话就是把已有的对话清空就好(因为保存什么的在发送消息时就处理了)
                            // 2024-08-23 切换了模型也要清空预设角色
                            restartChat();
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
                      child:
                          Text(" 你可以试着问我：", style: TextStyle(fontSize: 18.sp)),
                    ),
                  // 预设的问题列表
                  if (messages.isEmpty)
                    ChatDefaultQuestionArea(
                      defaultQuestions: defaultQuestions,
                      onQuestionTap: _userSendMessage,
                    ),

                  /// 如果有选择了预设角色，则显示改角色
                  if (selectedRole != null)
                    Container(
                      height: 32.sp,
                      color: Colors.grey[100],
                      child: Center(
                        child: Text(
                          "选择的预设角色: ${selectedRole!.label}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
                  if (chatSession != null)
                    Divider(height: 3.sp, thickness: 1.sp),

                  /// 显示对话消息主体
                  ChatListArea(
                    messages: messages,
                    // 如果不想显示system信息，这里可以移除掉(但不能修改原消息列表)
                    // messages: messages.where((e) => e.role != "system").toList(),
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
                    isSendClickable: userInput.isNotEmpty,
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
                        String tempPath = path.join(
                          path.dirname(content),
                          path.basenameWithoutExtension(content),
                        );

                        var transcription =
                            await sendAudioToServer("$tempPath.pcm");
                        // 注意：语言转换文本必须pcm格式，但是需要点击播放的语音则需要原本的m4a格式
                        // 都在同一个目录下同一路径不同扩展名
                        _userSendMessage(
                          transcription,
                          contentVoicePath: "$tempPath.m4a",
                        );
                      }
                    },
                    // 2024-08-08 手动点击了终止
                    onStop: () async {
                      await respStream.cancel();
                      if (!mounted) return;
                      setState(() {
                        _saveToDb();
                        _userInputController.clear();
                        // 滚动到ListView的底部
                        chatListScrollToBottom();

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
          // 点击了指定历史对话，则替换当前对话
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
            restartChat();
          }
        },
      ),
    );
  }
}
