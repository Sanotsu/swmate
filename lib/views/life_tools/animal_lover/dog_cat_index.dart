import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../apis/animal_lover/random_fact_apis.dart';
import '../../../apis/animal_lover/thatapi_apis.dart';
import '../../../apis/chat_completion/common_cc_apis.dart';
import '../../../apis/animal_lover/dogceo_apis.dart';
import '../../../common/components/searchable_dropdown.dart';
import '../../../common/components/simple_marquee_or_text.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/constants.dart';
import '../../../common/llm_spec/cus_llm_model.dart';
import '../../../common/llm_spec/cus_llm_spec.dart';
import '../../../common/utils/tools.dart';
import '../../../models/chat_competion/com_cc_resp.dart';
import '../../../models/chat_competion/com_cc_state.dart';
import '../../ai_assistant/_chat_screen_parts/chat_list_area.dart';
import '../../ai_assistant/_componets/cus_platform_and_llm_row.dart';
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
  // 可供挑选的模型列表
  final List<CusLLMSpec> llmSpecList;

  const DogCatLover({
    super.key,
    required this.llmSpecList,
  });

  @override
  State<DogCatLover> createState() => _DogCatLoverState();
}

class _DogCatLoverState extends State<DogCatLover> {
  // 是否点击了指定品种(如果是，可以选择品种和亚品种，以及图片的数量)
  bool isCusFilter = false;

  var cusRand = Random();

  ///
  /// 用于指定品种时的相关栏位
  ///
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
  CusLabel? selectedAnimalType;

  // 用于构建下拉框的动物品种列表
  List<CusLabel> animalBreedList = [];
  // 选中的品种和图片数量
  CusLabel? selectedBreed;
  // 加载图片时加载多少张
  int selectedNumber = 1;
  // 网络API获取的猫狗图片列表
  List<String> animalImages = [];
  // 上传猫狗图片时选择的图片文件
  File? selectedImage;
  // 是否在加载品种数据中
  bool isLoading = false;

  ///
  /// 用于图片识别时选用视觉大模型
  ///
  // 所有图像识别的模型
  late List<CusLLMSpec> llmSpecList;
  // 级联选择效果：云平台-模型名
  late ApiPlatform selectedPlatform;
  // 被选中的模型信息
  late CusLLMSpec selectedModelSpec;

  // 指定品种或获取品种信息使用的大模型，
  // 2024-09-18 目标默认为智谱的免费API，后续再考量是否使用其他的
  ApiPlatform selectedCCPlatform = ApiPlatform.zhipu;
  String selectedCCModel = "glm-4-flash";

  ///
  /// 调用大模型时使用的变量
  ///
  // 调用大模型查询品种信息
  bool isBotThinking = false;
  bool isStream = true;
  List<ChatMessage> messages = [];

  var systemPrompt = ChatMessage(
    messageId: const Uuid().v4(),
    role: CusRole.system.name,
    content: getSimpleAnimalPrompt(),
    dateTime: DateTime.now(),
  );

  StreamWithCancel<ComCCResp> respStream = StreamWithCancel.empty();

  // 人机对话消息滚动列表
  final ScrollController _scrollController = ScrollController();

  // 提示文本
  String note = """
【AI识别品种】功能是使用视觉大模型对图片中猫或狗进行识别，成功率和正确率与大模型能力相关，结果仅供参考。

【AI识别品种】出现“请求语法错误”，可能是由于大模型API请求频率限制，稍后再试即可。

指定品种后的【品种说明】是使用文本大模型对该指定品种的猫或狗进行讲解说明，虽然更加准确，但结果仍仅供参考。

可点击上传图标按钮，对本地图片中的猫或狗进行识别，支持文件上传和拍照。

点击图片可缩放预览，长按图片可保存到本地。

点击左侧 fact_check 图标可更新一条关于猫狗的小知识。

图片数据来源:  
[dog.ceo](https://dog.ceo/dog-api/documentation/)  
[thedogapi.com](https://thedogapi.com/)  
[thecatapi.com](https://thecatapi.com/)

猫狗小知识来源:  
[wh-iterabb-it/meowfacts](https://meowfacts.herokuapp.com/?lang=zho)  
[catfact.ninja](https://catfact.ninja/fact)  
[dogapi.dog](https://dogapi.dog/api/v2/facts)  
""";

  String factStr = "";

  @override
  void initState() {
    super.initState();

    initPlatAndModel();

    getRandomFact();

    selectedAnimalType = animalTypes.first;
    selectedSource = dataSourceList.first;

    getRandomImage();
    getAnimalBreed();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    respStream.cancel();
    super.dispose();
  }

  // 初始化图像识别的平台和模型
  initPlatAndModel() {
    // 每次进来都随机选一个平台
    List<ApiPlatform> plats =
        widget.llmSpecList.map((e) => e.platform).toSet().toList();
    setState(() {
      selectedPlatform = plats[cusRand.nextInt(plats.length)];
    });

    // 同样的，选中的平台后也随机选择一个模型
    List<CusLLMSpec> models = widget.llmSpecList
        .where((spec) => spec.platform == selectedPlatform)
        .toList();

    setState(() {
      selectedModelSpec = models[cusRand.nextInt(models.length)];
    });
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

          animalBreedList = result
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
      var list = await getThatApiBreeds(type: selectedAnimalType?.value);
      if (list.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          animalBreedList = list
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
    // 如果是随机一张图片，则需要先重置当前用户上传图片文件为空，避免AI解析时未正确使用图片数据
    setState(() {
      selectedImage = null;
    });

    // 随机生成一个数，判断是奇数还是偶数
    // 如果是偶数就使用dog.ceo获取狗狗图片；如果是奇数,就从thecatapi/thedogapi中获取猫狗图片
    // 后续来源更多时，可以直接随机来源列表的索引
    bool isEven = cusRand.nextInt(101) % 2 == 0;

    if (isEven) {
      // 从dog.ceo中获取随机图片
      var temp = await getDogCeoImages(isRandom: true, number: 1);

      setState(() {
        animalImages.clear();
        animalImages.addAll(
            (temp.message as List<dynamic>).map((e) => e.toString()).toList());
      });
    } else {
      // 从thecatapi中获取随机图片
      // 随机的时候就猫狗 都有可能
      final randomType = animalTypes[cusRand.nextInt(animalTypes.length)];

      var temp = await getThatApiImages(
        type: randomType.value,
        isRandom: true,
        number: 1,
      );

      setState(() {
        animalImages.clear();
        animalImages.addAll(temp.map((e) => e.url).toList());
      });
    }

    // 因为重新随机了猫狗图片，所以之前的识别品种对话可以清空
    setState(() {
      messages.clear();
    });
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
        animalImages.clear();
        animalImages.addAll(
          (temp.message as List<dynamic>).map((e) => e.toString()).toList(),
        );
      });
    } else {
      var temp = await getThatApiImages(
        type: selectedAnimalType?.value,
        breedIds: selectedBreed?.value,
        number: selectedNumber,
      );

      setState(() {
        animalImages.clear();
        animalImages.addAll(temp.map((e) => e.url).toList());
      });
    }
  }

  // 随机获取一条猫狗小知识
  getRandomFact() async {
    var fact = await getAnimalFact();

    setState(() {
      factStr = fact;
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
      });

      // 2024-09-18 如果是使用百度的Fuyu8B，则无法像下面的通用
      if (selectedModelSpec.cusLlm == CusLLM.baidu_Fuyu_8B) {
        // 如果是图像理解、但没有传入图片，模拟模型返回异常信息
        if (animalImages.isEmpty) {
          EasyLoading.showError("图像理解模式下，必须选择图片");
          setState(() {
            isBotThinking = false;
          });
          return;
        }

        messages.add(ChatMessage(
          messageId: const Uuid().v4(),
          role: CusRole.user.name,
          content: """Identify the breed and subspecies of dogs or cats 
in the picture, and then provide a detailed introduction.""",
          dateTime: DateTime.now(),
        ));

        tempStream = await baiduCCRespWithCancel(
          [],
          prompt:
              messages.where((e) => e.role == CusRole.user.name).last.content,
          image: await getBase64FromNetworkImage(animalImages.first),
          model: selectedModelSpec.model,
          stream: isStream,
        );
      } else {
        messages.add(ChatMessage(
          messageId: const Uuid().v4(),
          role: CusRole.user.name,
          content: "请识别出图片中的猫或狗的具体品种，并对识别到的物种提供详细的介绍。",
          dateTime: DateTime.now(),
        ));

        /// 2024-09-14 实测分析
        /// 通义千问VL-Max版本识别率最佳，但偶尔返回400错误，多点几次就行,
        /// VL-PLus效果也一般，和零一万物差不多，但输出也没有按照系统提示词的格式来
        ///
        /// 零一万物的Vision不一定能识别对，多问几次可能对的也改成错的了，但输出格式没问题
        ///
        /// 智谱AI的 glm-4v-plus 不一定识别的对，glm-4v 听不懂同样的识别指令，只是说“没有修改图片的能力”
        ///   两者对指定的输出格式也基本没有遵守，而且识别正确率是最差的
        tempStream = await getCCResponseSWC(
          messages: messages,
          // 图像识别的时候选中的模型
          selectedPlatform: selectedPlatform,
          selectedModel: selectedModelSpec.model,
          isStream: isStream,
          selectedImage: selectedImage,
          // 如果是选择了本地图片，则不使用url而是使用选中的文件
          selectedImageUrl: selectedImage != null ? null : animalImages.first,
          useType: CC_SWC_TYPE.image,
          onNotImageHint: (error) {
            commonExceptionDialog(context, "异常提示", error);
          },
          onImageError: (error) {
            commonExceptionDialog(context, "异常提示", error);
          },
        );
      }
    } else {
      setState(() {
        isBotThinking = true;

        var cc = (selectedBreed != null
            ? selectedAnimalType?.cnLabel == "猫"
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
        // 图像识别不同的模型识别效果不一样，但文字介绍由于指定了明确的分类，所以不需要过多模型
        selectedPlatform: selectedCCPlatform,
        selectedModel: selectedCCModel,
        isStream: isStream,
      );
    }

    if (!mounted) return;
    setState(() {
      respStream = tempStream;
    });

    ChatMessage? csMsg = buildEmptyAssistantChatMessage();
    setState(() {
      csMsg?.modelLabel = isImage ? selectedModelSpec.model : selectedCCModel;
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

  /// 选择图片来源
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    debugPrint("选中的图片---------$pickedFile");

    if (pickedFile != null) {
      setState(() {
        messages.clear();
        selectedImage = File(pickedFile.path);

        animalImages.clear();
        animalImages.add(selectedImage!.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('猫狗之家'),
        actions: [
          IconButton(
            onPressed: getRandomFact,
            icon: const Icon(Icons.fact_check_outlined),
          ),
          IconButton(
            onPressed: () {
              commonMDHintModalBottomSheet(
                context,
                "模型使用说明",
                note,
                msgFontSize: 15.sp,
              );
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          // 滚动显示一行有趣的猫狗小知识
          SimpleMarqueeOrText(
            data: factStr,
            velocity: 30,
            style: TextStyle(fontSize: 13.sp),
          ),

          /// 如果没有指定品种，则是随机拉取一张图片或者用户上传图片
          if (!isCusFilter)
            // 构建可切换云平台和模型的行,用于选择图像识别的模型
            ...buildModelButtonArea(),

          /// 如果指定了品种，可以自行筛选品种，获取图片和品质信息
          buildSelectPanel(),

          /// 图片放一行，AI介绍也放一行，两者占比高度一致
          if (animalImages.isNotEmpty)
            Expanded(
              child: buildImageCarouselSlider(
                animalImages,
                type: 1, // 点击某个图片，只对该图片进行预览而不是所有图片可以滚动
                aspectRatio: 1,
                dlDir: DL_DIR,
              ),
            ),

          // dogceo的图片路径可以看到品种，thatapi不行，所以这里如果是dogceo的展示品种(取4应该就对的)
          if (animalImages.isNotEmpty &&
              !animalImages.first.contains("dog.ceo"))
            Center(child: Text(animalImages.first)),
          if (animalImages.isNotEmpty && animalImages.first.contains("dog.ceo"))
            Text(animalImages.first.split("/")[4]),

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
              : Container()
          // Expanded(child: Container()),
        ],
      ),
    );
  }

  /// 构建模型选中下拉框，和上传图片、随机图片、AI识别品种按钮区域
  List<Widget> buildModelButtonArea() {
    return [
      CusPlatformAndLlmRow(
        initialPlatform: selectedPlatform,
        initialModelSpec: selectedModelSpec,
        llmSpecList: widget.llmSpecList,
        targetModelType: LLModelType.vision,
        showToggleSwitch: true,
        isStream: isStream,
        onToggle: (index) {
          setState(() {
            isStream = index == 0 ? true : false;
          });
        },
        onPlatformOrModelChanged: (ApiPlatform? cp, CusLLMSpec? llmSpec) {
          setState(() {
            selectedPlatform = cp!;
            selectedModelSpec = llmSpec!;
          });
        },
      ),
      // 构建上传图片按钮、随机获取图片按钮、AI品种识别按钮行
      Row(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("选择图片来源", style: TextStyle(fontSize: 18.sp)),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _pickImage(ImageSource.camera);
                          },
                          child: Text("拍照", style: TextStyle(fontSize: 16.sp)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _pickImage(ImageSource.gallery);
                          },
                          child: Text("相册", style: TextStyle(fontSize: 16.sp)),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Icons.file_upload),
            ),
          ),
          ElevatedButton(
            style: buildFunctionButtonStyle(),
            // style: ElevatedButton.styleFrom(
            //   minimumSize: Size(80.sp, 32.sp),
            //   padding: EdgeInsets.symmetric(horizontal: 10.sp),
            //   shape: RoundedRectangleBorder(
            //     borderRadius: BorderRadius.circular(15.sp),
            //   ),
            // ),
            onPressed: getRandomImage,
            child: const Text('随机一张猫狗图片'),
          ),
          SizedBox(width: 10.sp),
          ElevatedButton(
            style: buildFunctionButtonStyle(),
            onPressed: !isBotThinking
                ? () async {
                    await getProcessedResult(isImage: true);
                  }
                : null,
            child: const Text('AI识别品种'),
          ),
          SizedBox(width: 5.sp),
        ],
      )
    ];
  }

  /// 指定品种选择折叠栏
  Widget buildSelectPanel() {
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
              animalImages.clear();
            } else {
              // 如果是收起来了更多选项，则重新随机一张图片
              getRandomImage();
            }

            messages.clear();
            selectedBreed = null;
            selectedNumber = 1;
          });
        },
        children: [
          Padding(
            padding: EdgeInsets.all(5.sp),
            child: _buildSelectArea(),
          ),
        ],
      ),
    );
  }

  _buildSelectArea() {
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
            // 除了切换数量，其他切换来源、猫狗分类、品种，都要清空大模型的品种说明数据
            Expanded(
              flex: 2,
              child: buildDropdownButton2<String>(
                value: selectedSource,
                items: dataSourceList,
                hintLabel: "选择来源",
                onChanged: (value) {
                  setState(() {
                    // 选择了来源之后，要重置品种(不用重置类型，因为选中dogceo用不到类型，选中thatapi需要一个默认类型)
                    selectedSource = value;
                    selectedBreed = null;
                    selectedNumber = 1;
                    messages.clear();

                    getAnimalBreed();

                    // 如果数据源不是thatapi，那选中的类型只能是狗
                    if (selectedSource != "thatapi") {
                      setState(() {
                        selectedAnimalType = animalTypes.last;
                      });
                    }
                  });
                },
                itemToString: (e) => e,
              ),
            ),
            if (selectedSource == "thatapi")
              Expanded(
                child: buildDropdownButton2<CusLabel?>(
                  value: selectedAnimalType,
                  items: animalTypes,
                  hintLabel: "选择类型",
                  onChanged: (value) {
                    setState(() {
                      selectedAnimalType = value;
                      selectedBreed = null; // 重置品种选择
                      selectedNumber = 1;
                      messages.clear();

                      getAnimalBreed();
                    });
                  },
                  itemToString: (e) => (e as CusLabel).cnLabel,
                ),
              ),
            Expanded(
              flex: 4,
              child: (!isLoading)
                  ? SearchableDropdown(
                      value: selectedBreed,
                      items: animalBreedList,
                      hintLable: "选择品种",
                      onChanged: (value) {
                        setState(() {
                          selectedBreed = value;
                          selectedNumber = 1;
                          messages.clear();
                        });
                      },
                      itemToString: (e) => (e as CusLabel).cnLabel,
                    )

                  // buildDropdownButton2<CusLabel?>(
                  //     value: selectedBreed,
                  //     items: animalBreedList,
                  //     hintLable: "选择品种",
                  //     onChanged: (value) {
                  //       setState(() {
                  //         selectedBreed = value;
                  //         selectedNumber = 1;
                  //       });
                  //     },
                  //     itemToString: (e) => (e as CusLabel).cnLabel,
                  //   )
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
            const Expanded(child: SizedBox()),
            ElevatedButton(
              style: buildFunctionButtonStyle(),
              onPressed: (selectedBreed != null)
                  ? () async {
                      getBreedDogImages();
                    }
                  : null,
              child: const Text('查看图片'),
            ),
            SizedBox(width: 10.sp),
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
