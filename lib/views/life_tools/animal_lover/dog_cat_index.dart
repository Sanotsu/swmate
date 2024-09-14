import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import '../../../apis/animal_lover/thatapi_apis.dart';
import '../../../apis/chat_completion/common_cc_apis.dart';
import '../../../apis/animal_lover/dogceo_apis.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/constants.dart';
import '../../../common/llm_spec/cus_llm_spec.dart';
import '../../../common/utils/db_tools/db_helper.dart';
import '../../../models/chat_competion/com_cc_resp.dart';
import '../../../models/chat_competion/com_cc_state.dart';
import '../../ai_assistant/_chat_screen_parts/chat_list_area.dart';
import '../../ai_assistant/_helper/handle_cc_response.dart';
import 'animal_system_prompt.dart';

///
/// 2024-09-14 注意，这个页面是针对
/// https://portal.thatapicompany.com/
/// https://dog.ceo/dog-api/documentation/
/// 提供的API。
///
/// 用于获取其中cat和dog的分类和图片
///
class DogCatLover extends StatefulWidget {
  const DogCatLover({super.key});

  @override
  State<DogCatLover> createState() => _DogCatLoverState();
}

class _DogCatLoverState extends State<DogCatLover> {
  // 狗狗图片列表
  List<String> dogImages = [];

  // 是否点击了分类查看(如果是，可以选择品种和亚品种，以及图片的数量)
  bool isCusFilter = false;

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

  final DBHelper dbHelper = DBHelper();

  // 目前猫猫狗狗的来源： dogceo 和 thatapi
  List<String> dataSourceList = ["dogceo", "thatapi"];

  // 选中的来源(构建品种，如果是thatapi，还要结合猫或狗的选项)
  String? selectedSource;

  // 如果是thatapi，还可以选择猫或者狗
  List<CusLabel> animalTypes = [
    CusLabel(cnLabel: "猫", value: "cat"),
    CusLabel(cnLabel: "狗", value: "dog"),
  ];

  // 这是thatapi中选中猫或者狗(用于查询品种，如果是dogceo就只有狗品种)
  CusLabel? selectedType;

  List<CusLabel> animalList = [];

  // 选中的品种和图片数量
  CusLabel? selectedBreed;

  int selectedNumber = 1;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    selectedType = animalTypes.first;
    selectedSource = dataSourceList.first;

    getRandomImage();
    getAnimalBreed();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 获取猫猫狗狗的品种信息
  getAnimalBreed() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    if (selectedSource == "dogceo") {
      var resp = await getDogCeoBreeds();

      // dogceo是有分品种和亚种的，结果是个对象，要拍平为数组
      var nestedMap = Map<String, List<dynamic>>.from(resp.message);

      if (nestedMap.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          final List<String> result = [];

          nestedMap.forEach((key, value) {
            if (value.isEmpty) {
              result.add(key);
            } else {
              for (final subKey in value) {
                // 有亚种的，直接品种 + 亚种 放一条，品种就不单列了
                result.add('$key $subKey');
              }
            }
          });

          animalList = result
              .map((e) => CusLabel(
                    cnLabel: e,
                    // 显示的时候品种亚种之间用空格，但查询图片时url需要用/区分品种和亚种
                    value: e.replaceAll(RegExp(r' '), '/'),
                  ))
              .toSet()
              .toList();
        });
      }
    } else {
      // 每次进来都调用API查询的方式
      var list = await getThatApiBreeds(type: selectedType?.value);
      if (list.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          animalList = list
              .map((e) => CusLabel(
                    // 显示用名称(实际是英文)
                    cnLabel: e.name ?? e.breedGroup ?? "",
                    // 分类查询用编号
                    value: e.id,
                    // 这个暂时用不到
                    enLabel: e.dataSource,
                  ))
              .toSet()
              .toList();
        });
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  // 获取一张随机猫狗图片
  getRandomImage() async {
    // 随机生成一个数，判断是奇数还是偶数
    // 如果是偶数就使用dog.ceo获取狗狗图片；如果是奇数,就从thecatapi/thedogapi中获取猫狗图片
    // 后续来源更多时，可以直接随机来源列表的索引
    bool isEven = Random().nextInt(101) % 2 == 0;

    if (isEven) {
      // 从dog.ceo中获取随机图片
      var temp = await getDogCeoImages(isRandom: true, number: 1);

      setState(() {
        dogImages.clear();
        dogImages.addAll(
            (temp.message as List<dynamic>).map((e) => e.toString()).toList());
      });
    } else {
      // 从thecatapi中获取随机图片
      // 随机的时候就猫狗 都有可能
      final randomType = animalTypes[Random().nextInt(animalTypes.length)];

      var temp = await getThatApiImages(
        type: randomType.value,
        isRandom: true,
        number: 1,
      );

      setState(() {
        dogImages.clear();
        dogImages.addAll(temp.map((e) => e.url).toList());
      });
    }
  }

  // 获取指定品种或的猫狗图片
  // dogceo可以50张以内任意数量，thatapi免费用户只有1张
  getBreedDogImages() async {
    if (selectedSource == "dogceo") {
      var temp = await getDogCeoImages(
        breed: selectedBreed?.value,
        isRandom: true,
        number: selectedNumber,
      );

      setState(() {
        dogImages.clear();
        dogImages.addAll(
          (temp.message as List<dynamic>).map((e) => e.toString()).toList(),
        );
      });
    } else {
      var temp = await getThatApiImages(
        type: selectedType?.value,
        breedIds: selectedBreed?.value,
        number: selectedNumber,
      );

      setState(() {
        dogImages.clear();
        dogImages.addAll(temp.map((e) => e.url).toList());
      });
    }
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

        var cc = (selectedBreed != null
            ? selectedType?.cnLabel == "猫"
                ? "猫科品种：${selectedBreed?.cnLabel} "
                : "犬科品种：${selectedBreed?.cnLabel} "
            : '');

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
      appBar: AppBar(title: const Text('猫狗之家')),
      body: Column(
        children: [
          if (!isCusFilter)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: getRandomImage,
                    child: const Text('随机一张猫狗图片'),
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

          /// 图片放一行
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
              selectedNumber = 1;
            } else {
              // 如果是收起来了更多选项，则重新随机一张图片
              getRandomImage();
              messages.clear();
              selectedBreed = null;
              selectedNumber = 1;
            }
          });
        },
        children: [
          Padding(
            padding: EdgeInsets.all(5.sp),
            child: buildSelectArea(),
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
            const Expanded(flex: 2, child: Text("来源")),
            if (selectedSource == "thatapi") const Expanded(child: Text("类型")),
            const Expanded(flex: 4, child: Text("品种")),
          ],
        ),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: buildDropdownButton2<String>(
                value: selectedSource,
                items: dataSourceList,
                hintLable: "选择来源",
                onChanged: (value) {
                  setState(() {
                    // 选择了来源之后，要重置品种(不用重置类型，因为选中dogceo用不到类型，选中thatapi需要一个默认类型)
                    selectedSource = value;
                    selectedBreed = null;
                    selectedNumber = 1;
                    getAnimalBreed();
                  });
                },
                itemToString: (e) => e,
              ),
            ),
            if (selectedSource == "thatapi")
              Expanded(
                child: buildDropdownButton2<CusLabel?>(
                  value: selectedType,
                  items: animalTypes,
                  hintLable: "选择类型",
                  onChanged: (value) {
                    setState(() {
                      selectedType = value;
                      selectedBreed = null; // 重置品种选择
                      selectedNumber = 1;
                      getAnimalBreed();
                    });
                  },
                  itemToString: (e) => (e as CusLabel).cnLabel,
                ),
              ),
            Expanded(
              flex: 4,
              child: (!isLoading)
                  ? buildDropdownButton2<CusLabel?>(
                      value: selectedBreed,
                      items: animalList,
                      hintLable: "选择品种",
                      onChanged: (value) {
                        setState(() {
                          selectedBreed = value;
                          selectedNumber = 1;
                        });
                      },
                      itemToString: (e) => (e as CusLabel).cnLabel,
                    )
                  : Center(
                      child: SizedBox(
                        width: 16.sp,
                        height: 16.sp,
                        child: CircularProgressIndicator(strokeWidth: 2.sp),
                      ),
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
                items: selectedSource == "dogceo" ? [1, 5, 10] : [1],
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
              onPressed: (selectedBreed != null)
                  ? () async {
                      getBreedDogImages();
                    }
                  : null,
              child: const Text('查看图片'),
            ),
            const Expanded(child: SizedBox()),
            ElevatedButton(
              style: buildFunctionButtonStyle(),
              onPressed: (selectedBreed != null || selectedBreed != null) &&
                      !isBotThinking
                  ? () async {
                      await getProcessedResult();

                      //  因为可能切换了品种再查询品种说明，所以图片可能是之前的，
                      // 所以一定在点击“品种说明”时切换图片
                      getBreedDogImages();
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
