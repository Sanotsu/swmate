import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../apis/_default_system_role_list/inner_system_prompt.dart';
import '../../../apis/free_dictionary/free_dictionary_apis.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/utils/tools.dart';
import '../../../models/free_dictionary/free_dictionary_resp.dart';
import '../anime_top/_components.dart';

class FreeDictionary extends StatefulWidget {
  const FreeDictionary({super.key});

  @override
  State<FreeDictionary> createState() => _FreeDictionaryState();
}

class _FreeDictionaryState extends State<FreeDictionary> {
  // 单词输入
  TextEditingController searchController = TextEditingController();
  String query = '';

  // 单词查询结果
  FreeDictionaryItem? result;

  // AI翻译的结果
  String? translatedText;

  // 播放发音
  final AudioPlayer audioPlayer = AudioPlayer();

  String note = """
数据来源：[freeDictionaryAPI](https://github.com/meetDeveloper/freeDictionaryAPI).
- 说其API的数据源是 [Wiktionary](https://www.wiktionary.org/)，但类似every、hell、look、for、is等基础词汇都无法正确识别。
- 如果API查询无果，可以借助“AI翻译”辅助查询英英释义(使用AI大模型API实现，仅供参考)。
- 直接"Query"更快更准确，"AI翻译"更慢结果仅供参考。
- AI翻译比如“ok”可能无法正确理解，多试几遍或输入“翻译 ok”试试。

由原API结构对应：
- ANT/SYN表示同一词性的反义词、近义词。
- ant/syn/e.g.表示同一释义的反义词、近义词、使用示例。
""";

  @override
  void dispose() {
    searchController.dispose();
    audioPlayer.dispose();

    super.dispose();
  }

  //  单词查询
  _handleSearch() async {
    setState(() {
      query = searchController.text;
      // 调用词典API时，置空AI释义结果
      translatedText = null;
    });

    unfocusHandle();

    try {
      var rst = await getFreeDictionaryItem(query);

      if (!mounted) return;
      setState(() {
        result = rst;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // AI词典工具
  Future<void> _translateText() async {
    String translation = await getAITranslation(
      query,
      systemPrompt: aiEn2EnDictionaryTool(),
    );
    if (!mounted) return;
    setState(() {
      // 调用AI翻译时，置空词典API结果
      result = null;
      translatedText = translation;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FreeDictionary'),
        actions: [
          IconButton(
            onPressed: () {
              commonMDHintModalBottomSheet(
                context,
                "说明",
                note,
                msgFontSize: 15.sp,
              );
            },
            icon: const Icon(Icons.info_outline),
          ),
          TextButton(
            onPressed: query.isNotEmpty
                ? () {
                    _translateText();
                  }
                : null,
            child: const Text('AI 翻译'),
          ),
        ],
      ),
      body: GestureDetector(
        // 允许子控件（如TextField）接收点击事件
        behavior: HitTestBehavior.translucent,
        // 点击空白处可以移除焦点，关闭键盘
        onTap: unfocusHandle,
        child: Column(
          children: [
            // 单词
            KeywordInputArea(
              searchController: searchController,
              height: 52.sp,
              hintText: "Enter word here",
              buttonHintText: "Query",
              textOnChanged: (val) => setState(() => query = val),
              onSearchPressed: query.isNotEmpty ? _handleSearch : null,
            ),

            Text(
              result?.word ?? query,
              style: TextStyle(fontSize: 20.sp),
              textAlign: TextAlign.start,
            ),

            if (result?.phonetics != null && result!.phonetics!.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: buildPhonetic(result!.phonetics!),
              ),
            Divider(height: 5.sp),

            if (result?.message != null)
              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(10.sp),
                  // 如果有AI翻译的结果，这个API调用404的就不显示了
                  child: (translatedText != null)
                      ? Container()
                      : Column(
                          children: [
                            if (result?.title != null)
                              Text(
                                result?.title ?? "",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (result?.message != null)
                              Text(result?.message ?? ""),
                            if (result?.resolution != null)
                              Text(result?.resolution ?? ""),
                          ],
                        ),
                ),
              ),
            if (result?.meanings != null)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(10.sp, 0, 10.sp, 10.sp),
                  child: ListView.builder(
                    itemCount: result?.meanings?.length ?? 0,
                    itemBuilder: (context, index) {
                      final meaning = result?.meanings?[index];

                      if (meaning == null) return Container();
                      return buildMeaning(meaning);
                    },
                  ),
                ),
              ),

            if (translatedText != null)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(10.sp, 0, 10.sp, 10.sp),
                  child: SingleChildScrollView(
                    child: MarkdownBody(
                      data: translatedText!,
                      selectable: true,
                      // 设置Markdown文本全局样式
                      styleSheet: MarkdownStyleSheet(
                        // 普通段落文本颜色(假定用户输入就是普通段落文本)
                        p: TextStyle(fontSize: 15.sp, color: Colors.black),
                        // ... 其他级别的标题样式
                        // 可以继续添加更多Markdown元素的样式
                      ),
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  Future<void> _playAudio(url) async {
    await audioPlayer.play(UrlSource(url));
  }

  List<Widget> buildPhonetic(List<FDPhonetic> phonetics) {
    return phonetics.map((p) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(p.text ?? ""),
          if (p.audio != null && p.audio!.isNotEmpty)
            IconButton(
              onPressed: () {
                _playAudio(p.audio!);
              },
              icon: const Icon(Icons.volume_up),
            ),
          SizedBox(width: 20.sp),
        ],
      );
    }).toList();
  }

  // 一个单词有多种词性；不同词性有不同意思
  buildMeaning(FDMeaning meaning) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 词性
        Text(
          meaning.partOfSpeech ?? "",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),

        /// 词性的同义词
        if (meaning.synonyms != null && meaning.synonyms!.isNotEmpty)
          Text(
            'SYN: ${meaning.synonyms!.join("、")}',
            style: const TextStyle(color: Colors.lightBlue),
          ),

        /// 词性的反义词
        if (meaning.antonyms != null && meaning.antonyms!.isNotEmpty)
          Text(
            'ANT: ${meaning.antonyms!.join("、")}',
            style: const TextStyle(color: Colors.lightBlue),
          ),

        /// 释义
        ...meaning.definitions!.asMap().entries.map((entry) {
          final definitionIndex = entry.key + 1;
          final definition = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 5.sp),
              Text("$definitionIndex. ${definition.definition}"),
              SizedBox(height: 5.sp),
              // 释义的同义词
              if (definition.synonyms != null &&
                  definition.synonyms!.isNotEmpty)
                Text(
                  'syn: ${definition.synonyms!.join("、")}',
                  style: const TextStyle(color: Colors.lightBlue),
                ),
              // 释义的反义词
              if (definition.antonyms != null &&
                  definition.antonyms!.isNotEmpty)
                Text(
                  'ant: ${definition.antonyms!.join("、")}',
                  style: const TextStyle(color: Colors.lightBlue),
                ),
              // 释义的示例
              if (definition.example != null)
                Text(
                  'e.g. ${definition.example}',
                  style: const TextStyle(color: Colors.grey),
                ),
            ],
          );
        }),
      ],
    );
  }
}
