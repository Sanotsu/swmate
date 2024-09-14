import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import '../../../apis/chat_completion/common_cc_apis.dart';
import '../../../apis/dog_lover/index.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/constants.dart';
import '../../../common/llm_spec/cus_llm_spec.dart';
import '../../../models/base_model/dog_lover/dog_ceo_resp.dart';
import '../../../models/chat_competion/com_cc_resp.dart';
import '../../../models/chat_competion/com_cc_state.dart';
import '../../ai_assistant/_chat_screen_parts/chat_list_area.dart';
import '../../ai_assistant/_helper/handle_cc_response.dart';
import 'animal_system_prompt.dart';

class DogLover extends StatefulWidget {
  const DogLover({super.key});

  @override
  State<DogLover> createState() => _DogLoverState();
}

class _DogLoverState extends State<DogLover> {
  // 狗狗图片列表
  List<String> dogImages = [];

  // 查询狗狗分类
  late Future<DogCeoResp> _futureDogCeoResp;
  Map<String, List<dynamic>> breeds = {};

  // 是否点击了分类查看(如果是，可以选择品种和亚品种，以及图片的数量)
  bool isCusFilter = false;

  // 选中的品种和图片数量
  String? selectedBreed;
  String? selectedSubBreed;
  int selectedNumber = 1;

  // 调用大模型查询品种信息
  bool isBotThinking = false;
  bool isStream = true;
  List<ChatMessage> messages = [];

  var systemPrompt = ChatMessage(
    messageId: const Uuid().v4(),
    role: CusRole.system.name,
    content: getAnimalPrompt(),
    dateTime: DateTime.now(),
  );

  StreamWithCancel<ComCCResp> respStream = StreamWithCancel.empty();

  // 人机对话消息滚动列表
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _futureDogCeoResp = getDogSpecResp();
    getRandomDogImage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 获取一张随机图片
  getRandomDogImage() async {
    var temp = await getDogImageResp(isRandom: true, number: 1);

    print(temp.message);

    setState(() {
      dogImages.clear();
      dogImages.addAll(
          (temp.message as List<dynamic>).map((e) => e.toString()).toList());
    });
  }

  // 查询指定品种或者亚种的狗图片
  // isAll 就查询指定品种、亚种的所有图片
  // 指定了num，则随机指定数量的品种亚种图片
  getBreedDogImages({bool isAll = false, int? num}) async {
    var temp = isAll
        ? await getDogImageResp(
            breed: selectedBreed,
            subBreed: selectedSubBreed,
          )
        : await getDogImageResp(
            breed: selectedBreed,
            subBreed: selectedSubBreed,
            isRandom: true,
            number: num ?? selectedNumber,
          );

    setState(() {
      dogImages.clear();
      dogImages.addAll(
        (temp.message as List<dynamic>).map((e) => e.toString()).toList(),
      );
    });
  }

  // 获取大模型返回的品种分析(识图或者直接品种分析)
  Future<void> getProcessedResult({isImage = false}) async {
    if (isBotThinking) return;
    if (!mounted) return;

    // 当前选中的平台和模型(固定智谱的GLM-Flash)
    StreamWithCancel<ComCCResp> tempStream;

    // 如果是图像识别的
    if (isImage) {
      setState(() {
        isBotThinking = true;

        messages.clear();
        messages.add(systemPrompt);
        messages.add(ChatMessage(
          messageId: const Uuid().v4(),
          role: CusRole.user.name,
          content: "识别出图片中犬类的品种和亚种，显示该品种和亚种的中文名称和英文名称，再进行详细介绍。",
          dateTime: DateTime.now(),
        ));
      });
      tempStream = await getCCResponseSWC(
        messages: messages,
        // 图像识别的时候，就是零一万物的调用
        selectedPlatform: ApiPlatform.lingyiwanwu,
        selectedModel: "yi-vision",
        isStream: isStream,

        useType: CC_SWC_TYPE.image,
        selectedImageUrl: dogImages.first,
        onNotImageHint: (error) {
          commonExceptionDialog(context, "异常提示", error);
        },
        onImageError: (error) {
          commonExceptionDialog(context, "异常提示", error);
        },
      );
    } else {
      setState(() {
        isBotThinking = true;

        var cc = (selectedBreed != null ? "犬科品种：$selectedBreed " : '') +
            (selectedSubBreed != null ? "，犬科亚种：$selectedSubBreed " : '');

        messages.clear();
        messages.add(systemPrompt);
        messages.add(ChatMessage(
          messageId: const Uuid().v4(),
          role: CusRole.user.name,
          content: cc,
          dateTime: DateTime.now(),
        ));
      });
      // 否则就是正常询问的
      tempStream = await getCCResponseSWC(
        messages: messages,
        selectedPlatform: ApiPlatform.zhipu,
        selectedModel: "glm-4-flash",

        // selectedPlatform: ApiPlatform.siliconCloud,
        // selectedModel: "Qwen/Qwen2-7B-Instruct",
        // selectedModel:  "THUDM/chatglm3-6b",
        // selectedModel: "THUDM/glm-4-9b-chat",
        // selectedModel: "meta-llama/Meta-Llama-3.1-8B-Instruct",

        // selectedPlatform: ApiPlatform.baidu,
        // selectedModel: "ernie_speed",
        isStream: isStream,
      );
    }

    if (!mounted) return;
    setState(() {
      respStream = tempStream;
    });

    ChatMessage? csMsg = buildEmptyAssistantChatMessage();
    setState(() {
      csMsg?.modelLabel = isImage ? "yi-vision" : "glm-4-flash";
      messages.add(csMsg!);
    });

    handleCCResponseSWC(
      swc: respStream,
      onData: (crb) {
        if (!mounted) return;
        commonOnDataHandler(
          crb: crb,
          csMsg: csMsg!,
          onStreamDone: () {
            if (!mounted) return;
            setState(() {
              csMsg = null;
              isBotThinking = false;
            });
          },
          setIsResponsing: () {
            setState(() {
              isBotThinking = true;
            });
          },
        );
      },
      onDone: () {
        if (!isStream) {
          if (!mounted) return;
          setState(() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('爱狗之家')),
      body: Column(
        children: [
          if (!isCusFilter)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: getRandomDogImage,
                    child: const Text('随机一张狗狗图片'),
                  ),
                ),
                ElevatedButton(
                  style: buildFunctionButtonStyle(),
                  onPressed: () async {
                    await getProcessedResult(isImage: true);
                  },
                  child: const Text('品种分析'),
                ),
              ],
            ),

          _buildSelectPanel(),

          /// 图片放一行，最多只有4张
          if (dogImages.isNotEmpty)
            Expanded(
              child: buildImageCarouselSlider(
                dogImages,
                type: 1, // 点击某个图片，只对该图片进行预览而不是所有图片可以滚动
                aspectRatio: 1,
                dlDir: DL_DIR,
              ),
            ),

          /// 显示对话消息主体(因为绑定了滚动控制器，所以一开始就要在)
          (messages
                  .where((e) => e.role == CusRole.assistant.name)
                  .toList()
                  .isNotEmpty)
              ? ChatListArea(
                  // messages: messages,
                  // 如果不想显示system信息，这里可以移除掉(但不能修改原消息列表)
                  messages: messages
                      .where((e) => e.role == CusRole.assistant.name)
                      .toList(),
                  scrollController: _scrollController,
                  isBotThinking: isBotThinking,
                  isAvatarTop: true,
                  isShowModelLable: true,
                )
              : Expanded(child: Container()),

          // Expanded(
          //   child: SingleChildScrollView(
          //     child: Column(
          //       children: [
          //         Padding(
          //           padding: EdgeInsets.symmetric(horizontal: 2.sp),
          //           child: buildNetworkImageViewGrid(
          //             context,
          //             dogImages,
          //             crossAxisCount:
          //                 (dogImages.isNotEmpty && dogImages.length < 4)
          //                     ? dogImages.length
          //                     : 4,
          //             // 模型名有空格或斜线，等后续更新spec，用name来
          //             prefix: "",
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildSelectPanel() {
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: ExpansionTile(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [Text('指定品种')],
        ),
        initiallyExpanded: isCusFilter,
        onExpansionChanged: (bool expanded) {
          setState(() {
            isCusFilter = expanded;
            // 如果是展开了更多选项，则之前可能随机的一张图片就清空
            if (isCusFilter) {
              dogImages.clear();
              messages.clear();
              selectedBreed = null;
              selectedSubBreed = null;
              selectedNumber = 1;
            } else {
              // 如果是收起来了更多选项，则重新随机一张图片
              getRandomDogImage();
              messages.clear();
              selectedBreed = null;
              selectedSubBreed = null;
              selectedNumber = 1;
            }
          });
        },
        children: [
          FutureBuilder<DogCeoResp>(
            future: _futureDogCeoResp,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('[获取品种列表出错]: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('无可用数据'));
              } else {
                DogCeoResp resp = snapshot.data!;
                if (resp.message is Map<String, dynamic>) {
                  breeds = Map<String, List<dynamic>>.from(resp.message);
                }

                return Padding(
                  padding: EdgeInsets.all(5.sp),
                  child: buildSelectArea(),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  buildSelectArea() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Text("品种")),
            if (selectedBreed != null && breeds[selectedBreed!]!.isNotEmpty)
              const Expanded(child: Text("亚种")),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: buildDropdownButton2<String?>(
                value: selectedBreed,
                items: breeds.keys.toList(),
                hintLable: "选择品种",
                onChanged: (value) {
                  setState(() {
                    selectedBreed = value;
                    selectedSubBreed = null; // 重置子品种选择
                  });
                },
                itemToString: (e) => e,
              ),
            ),
            if (selectedBreed != null && breeds[selectedBreed!]!.isNotEmpty)
              Expanded(
                child: buildDropdownButton2<dynamic>(
                  value: selectedSubBreed,
                  items: breeds[selectedBreed!]!.toList(),
                  hintLable: "选择亚种",
                  onChanged: (value) {
                    setState(() {
                      selectedSubBreed = value;
                    });
                  },
                  itemToString: (e) => e.toString(),
                ),
              ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("图片数量"),
            SizedBox(
              width: 60.sp,
              child: buildDropdownButton2<dynamic>(
                value: selectedNumber,
                items: [1, 5, 10, 20, 50],
                onChanged: (value) {
                  setState(() {
                    selectedNumber = value;
                  });
                },
                itemToString: (e) => e.toString(),
              ),
            ),
            SizedBox(width: 20.sp),
            TextButton(
              onPressed: (selectedBreed != null || selectedBreed != null)
                  ? () async {
                      getBreedDogImages();
                    }
                  : null,
              child: const Text('获取图片'),
            ),
            // /// 显示全部图片可能过多，考虑是否需要
            // ElevatedButton(
            //   onPressed: () async {
            //     getBreedDogImages(isAll: true);
            //   },
            //   child: const Text('全部图片'),
            // ),
            const Expanded(child: SizedBox()),
            ElevatedButton(
              style: buildFunctionButtonStyle(),
              onPressed: (selectedBreed != null || selectedBreed != null) &&
                      !isBotThinking
                  ? () async {
                      await getProcessedResult();

                      //  因为可能切换了品种再查询品种说明，所以图片可能是之前的，
                      // 所以一定在点击“品种说明”时切换图片
                      getBreedDogImages(num: selectedNumber);
                    }
                  : null,
              child: const Text('品种说明'),
            ),
          ],
        ),
      ],
    );
  }
}
