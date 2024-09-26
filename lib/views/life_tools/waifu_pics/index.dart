import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../apis/waifu_pic/index.dart';
import '../../../common/components/searchable_dropdown.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/constants.dart';

class WaifuPicIndex extends StatefulWidget {
  const WaifuPicIndex({super.key});

  @override
  State<WaifuPicIndex> createState() => _WaifuPicIndexState();
}

class _WaifuPicIndexState extends State<WaifuPicIndex> {
  // waifu图源有两个，地址和参数稍微不一样
  List<String> waifuSources = ["pics", "im"];

  List<String> waifuImages = [];

  Map<String, List<String>> waifuTypeMap = {};

  String? selectedSource;
  String? selectedType;
  String? selectedCategory;
  int selectedNum = 1;

  // 提示文本
  String note = """
请注意，此模块面向少量的纯粹受众，如果图片产生不适，请勿继续使用即可，与应用开发者无关。

图片数据来源: [WAIFU.PICS](https://waifu.pics/docs)、[WAIFU.IM](https://docs.waifu.im/)

点击图片可缩放预览，长按图片可保存到本地。

点击【刷新】图标按钮可以更新随机图片列表。 

多图片会消耗大量流量，请注意网络流量额度。
""";

  @override
  void initState() {
    super.initState();

    // 默认都是第一个
    selectedSource = waifuSources.first;

    // 先确定了来源，再切换类型列表
    changeSourceTypes();

    // 默认选中第一个
    selectedType = waifuTypeMap.keys.first;
    selectedCategory = waifuTypeMap[selectedType]!.first;

    // 都选好了，默认随机来一张
    getRandomWaifuPics();
  }

  // 根据来源不同，显示不同的类型列表
  changeSourceTypes() {
    setState(() {
      if (selectedSource == "im") {
        waifuTypeMap = {
          "versatile": [
            // 这个可能是安全的
            "maid", "waifu", "marin-kitagawa", "mori-calliope", "raiden-shogun",
            "oppai", "selfies", "uniform", "kamisato-ayaka"
          ],
        };
      } else {
        waifuTypeMap = {
          "sfw": [
            // 一排五个
            "waifu", "neko", "shinobu", "megumin", "bully",
            "cuddle", "cry", "hug", "awoo", "kiss",
            "lick", "pat", "smug", "bonk", "yeet",
            "blush", "smile", "wave", "highfive", "handhold",
            "nom", "bite", "glomp", "slap", "kill",
            "kick", "happy", "wink", "poke", "dance",
            "cringe"
          ],
        };
      }
    });
  }

  getRandomWaifuPics() async {
    List<String> fact = [];
    if (selectedSource == "pics") {
      fact = await getWaifuPicImages(
        source: "pics",
        isMany: selectedNum > 1 ? true : false,
        type: selectedType ?? "sfw",
        category: selectedCategory ?? "waifu",
      );
    } else {
      fact = await getWaifuPicImages(
        source: "im",
        type: selectedType ?? "sfw",
        imIncludedTags: selectedCategory ?? "waifu",
        // 还是尽量不显示不安全的，如果非要显示，nsfw已经包含了versatile的标签了
        imIsNsfw: selectedType == "versatile" ? false : true,
        imLimit: selectedNum,
      );
    }

    if (!mounted) return;
    setState(() {
      waifuImages = fact;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WAIFU图库'),
        actions: [
          IconButton(
            onPressed: () {
              commonMDHintModalBottomSheet(
                context,
                "使用说明",
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
          _buildSelectArea(),
          SizedBox(height: 20.sp),

          // Expanded(
          //   child: AsymmetricView(imageUrls: waifuImages),
          // ),

          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: EdgeInsets.all(5.sp),
                  child: buildNetworkImageViewGrid(
                    context,
                    waifuImages,
                    crossAxisCount:
                        (waifuImages.isNotEmpty && waifuImages.length < 3)
                            ? waifuImages.length
                            : 3,
                    prefix: "waifu",
                    dlDir: DL_DIR,
                    fit: selectedNum > 1 ? BoxFit.cover : BoxFit.scaleDown,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.sp),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getRandomWaifuPics,
        tooltip: '随机刷新',
        shape: const CircleBorder(),
        child: const Icon(Icons.refresh), // 确保是圆形
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  _buildSelectArea() {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(flex: 1, child: Center(child: Text("来源"))),
            Expanded(flex: 1, child: Center(child: Text("类型"))),
            Expanded(flex: 2, child: Center(child: Text("分类"))),
            Expanded(flex: 1, child: Center(child: Text("数量"))),
          ],
        ),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: buildDropdownButton2<String>(
                value: selectedSource,
                items: waifuSources,
                hintLabel: "选择来源",
                onChanged: (value) {
                  setState(() {
                    selectedSource = value;
                    changeSourceTypes();
                    selectedType = waifuTypeMap.keys.first;
                    selectedCategory = null;
                  });
                },
                itemToString: (e) => e,
              ),
            ),
            Expanded(
              flex: 1,
              child: buildDropdownButton2<String>(
                value: selectedType,
                items: waifuTypeMap.keys.toList(),
                hintLabel: "选择类型",
                onChanged: (value) {
                  setState(() {
                    selectedType = value;
                    selectedCategory = null;
                  });
                },
                itemToString: (e) => e,
              ),
            ),
            Expanded(
              flex: 2,
              child: SearchableDropdown(
                value: selectedCategory,
                items: waifuTypeMap[selectedType]!,
                hintLable: "选择分类",
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
                itemToString: (e) => e,
              ),
            ),
            Expanded(
              flex: 1,
              child: buildDropdownButton2<int>(
                value: selectedNum,
                items: [1, 5, 10, 30],
                hintLabel: "选择数量",
                onChanged: (value) {
                  setState(() {
                    selectedNum = value ?? 1;
                  });
                },
                itemToString: (e) => e.toString(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
