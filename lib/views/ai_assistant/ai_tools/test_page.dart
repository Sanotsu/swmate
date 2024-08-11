// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import '../../../apis/chat_completion/common_cc_apis.dart';
import '../../../apis/chat_completion/common_cc_sse_apis.dart';
import '../../../common/llm_spec/cc_spec.dart';
import '../../../models/chat_competion/com_cc_resp.dart';
import '../../../models/chat_competion/com_cc_state.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  // 当前正在响应的api返回流(放在全局为了可以手动取消)
  StreamWithCancel<ComCCResp>? respStream;

  bool isBotThinking = false;

  List<ChatMessage> messages = [];

  var aaa = "";

  _getCCResponse() async {
    var list = [CCMessage(role: "user", content: "巴里奥运金牌榜")];
    var model = CCM_SPEC_LIST.firstWhere((e) => e.ccm == CCM.YiLargeRag).model;
    var temp = await lingyiSseCCResp(list, model: model, stream: true);

    if (!mounted) return;
    setState(() {
      respStream = null;
      respStream = temp;
    });

    ChatMessage? csMsg;
    final StringBuffer messageBuffer = StringBuffer();
    csMsg = ChatMessage(
      messageId: const Uuid().v4(),
      role: "assistant",
      content: messageBuffer.toString(),
      contentVoicePath: "",
      dateTime: DateTime.now(),
    );

    setState(() {
      messages.add(csMsg!);
    });

    respStream?.stream.listen(
      (crb) {
        // 得到回复后要删除表示加载中的占位消息
        if (!mounted) return;

        if (crb.cusText == '[DONE]') {
          if (!mounted) return;
          setState(() {
            csMsg = null;
            isBotThinking = false;
          });
        } else {
          // 正常流式的响应，都逐步追加到对话消息体中
          setState(() {
            isBotThinking = true;

            messageBuffer.write(crb.cusText);

            print(crb.usage?.promptTokens);
            csMsg!.content = messageBuffer.toString();

            // token的使用就是每条返回的就是当前使用的结果，所以最后一条就是最终结果，实时更新到最后一条
            csMsg!.promptTokens = (crb.usage?.promptTokens ?? 0);
            csMsg!.completionTokens = (crb.usage?.completionTokens ?? 0);
            csMsg!.totalTokens = (crb.usage?.totalTokens ?? 0);

            // 模型为rag时，当最后一条时，才会带上引用
            if (crb.choices != null &&
                crb.choices?.first != null &&
                crb.choices?.first.delta != null &&
                crb.choices!.first.delta?.quote != null) {
              csMsg!.quotes = crb.choices!.first.delta!.quote!;
            }
          });
        }
      },
      onDone: () {
        print("http sse 监听的【onDone】触发了");
      },
      onError: (error) {
        print("http sse 监听的【error】触发了0000$error");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('AI 测试页面'),
        actions: [
          IconButton(
            onPressed: () {
              _getCCResponse();
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {
              final crb = ComCCResp.fromJson(testjson);

              setState(() {
                if (crb.choices != null &&
                    crb.choices?.first != null &&
                    crb.choices?.first.delta != null &&
                    crb.choices!.first.delta?.quote != null) {
                  aaa = crb.choices!.first.delta!.quote!.first.title!;
                }
              });
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(aaa),
          SizedBox(
            height: 300.sp,
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                var msg = messages[index];

                return Padding(
                  padding: EdgeInsets.all(5.sp),
                  child: Column(
                    children: [
                      // 构建每个对话消息
                      Text(msg.role),

                      Text(msg.content),

                      if (msg.quotes != null)
                        ...List.generate(
                          msg.quotes!.length,
                          (index) => GestureDetector(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 5.sp),
                              child: Text(
                                '${index + 1}. ${msg.quotes?[index].title}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Theme.of(context).primaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                respStream?.cancel();
              });
            },
            icon: const Icon(Icons.stop),
          )
        ],
      ),
    );
  }
}

var testdelta = {
  "delta": {
    "quote": [
      {
        "num": 1,
        "url":
            "https://www.usatoday.com/story/sports/olympics/2024/08/11/olympic-medals-today-medal-count-paris-games-sunday/74753991007/",
        "title":
            "USA Today: What is the medal count at 2024 Paris Games on Sunday?"
      },
      {
        "num": 2,
        "url":
            "https://www.usatoday.com/story/sports/olympics/2024/07/27/olympic-gold-medals-count/74449123007/",
        "title":
            "Gold medal count at Paris Olympics 2024: Which country has most gold?"
      },
    ]
  }
};

var testjson = {
  "id": "cmpl-71876l63",
  "object": "chat.completion.chunk",
  "created": 1723376217,
  "model": "yi-large-rag",
  "choices": [
    {
      "delta": {
        "quote": [
          {
            "num": 1,
            "url":
                "https://www.usatoday.com/story/sports/olympics/2024/08/11/olympic-medals-today-medal-count-paris-games-sunday/74753991007/",
            "title":
                "USA Today: What is the medal count at 2024 Paris Games on Sunday?"
          },
          {
            "num": 2,
            "url":
                "https://www.usatoday.com/story/sports/olympics/2024/07/27/olympic-gold-medals-count/74449123007/",
            "title":
                "Gold medal count at Paris Olympics 2024: Which country has most gold?"
          },
          {
            "num": 3,
            "url": "https://www.thepaper.cn/newsDetail_forward_28322278",
            "title": "2024巴黎奥运会金牌榜（8月5日）_澎湃号·媒体_澎湃新闻 ..."
          },
          {
            "num": 4,
            "url": "https://apnews.com/olympics-medal-tracker",
            "title": "Paris Olympics 2024 medal tracker by country | AP News"
          },
          {
            "num": 5,
            "url":
                "https://www.espn.com/olympics/summer/2024/medals/_/view/overall",
            "title": "Summer Olympics Medal Count - ESPN"
          },
          {
            "num": 6,
            "url":
                "https://www.usatoday.com/story/sports/olympics/2024/08/10/paris-olympics-live-results/74191196007/",
            "title": "USA Today: USA men's basketball, USWNT win gold in Paris"
          },
          {
            "num": 7,
            "url": "https://sports.163.com/special/olympic2024_rank_mod/",
            "title": "2024巴黎奥运会_奖牌榜_网易体育"
          },
          {
            "num": 8,
            "url": "https://www.eurosport.com/olympics/medals/",
            "title": "Eurosport: Medals | Paris 2024 Olympics"
          },
          {
            "num": 9,
            "url": "https://results.nbcolympics.com/medals",
            "title": "Paris Olympics Results and Live Scores | NBC Olympics"
          },
          {
            "num": 10,
            "url":
                "http://sports.news.cn/20240811/db755cfb68ff46f6b178f1de48f42ad7/c.html",
            "title": "新华网: 8月10日巴黎奥运会金牌榜"
          },
          {
            "num": 11,
            "url": "https://m.yicai.com/news/102226835.html",
            "title": "第一财经: 41金！8月10日巴黎奥运会金牌赛程来了"
          },
          {
            "num": 12,
            "url":
                "https://finance.sina.com.cn/jjxw/2024-08-10/doc-incieazh1386490.shtml",
            "title": "新浪网: 奥运会金牌榜，美国队霸榜为何不再轻而易举？"
          },
          {
            "num": 13,
            "url": "https://www.sohu.com/a/799559301_121894852",
            "title": "2024年巴黎奥运会金牌榜美国队24金登顶，中国香港77万美金夺冠"
          },
          {
            "num": 14,
            "url": "https://sports.cctv.com/Paris2024/medal_list/index.shtml",
            "title": "奖牌榜_2024巴黎奥运会_体育_央视网(cctv.com)"
          },
          {
            "num": 15,
            "url":
                "https://www.365scores.com/zh/olympics/league/olympics-7710/medals",
            "title": "2024 年巴黎奥运会：实时奖牌榜 - 365Scores"
          },
          {
            "num": 16,
            "url": "https://news.bjd.com.cn/2024/08/11/10863815.shtml",
            "title": "巴黎奥运会今日战报｜6枚金牌5大突破！乒乓女团斩获夏奥 ..."
          },
          {
            "num": 17,
            "url":
                "https://sports.cctv.com/Paris2024/gold_medals/index.shtml?date=0809",
            "title": "此刻是金_2024巴黎奥运会_体育_央视网(cctv.com)"
          },
          {
            "num": 18,
            "url":
                "https://baike.baidu.com/item/2024%E5%B9%B4%E5%B7%B4%E9%BB%8E%E5%A5%A5%E8%BF%90%E4%BC%9A/17619118",
            "title": "2024年巴黎奥运会（第33届夏季奥林匹克运动会）_百度百科"
          },
          {
            "num": 19,
            "url": "https://new.qq.com/rain/a/20240729A00SOT00",
            "title": "2024巴黎奥运会金牌榜（7月28日） - 腾讯网"
          },
          {
            "num": 20,
            "url":
                "http://sports.news.cn/20240809/04a4051a5c554257b1e3976b0d5cbca9/c.html",
            "title": "新华网: 8月8日巴黎奥运会金牌榜"
          },
          {
            "num": 21,
            "url":
                "https://www.365scores.com/zh-tw/olympics/league/olympics-7710/medals",
            "title": "2024 巴黎奧運：即時獎牌榜 - 365Scores"
          },
          {
            "num": 22,
            "url":
                "https://www.usatoday.com/story/sports/olympics/2024/08/10/olympic-medals-today-what-is-medal-count-at-paris-games-on-aug-10/74737504007/",
            "title":
                "Olympic medal count today: What is the medal count at 2024 Paris Games ..."
          },
          {
            "num": 23,
            "url":
                "https://www.usatoday.com/story/sports/olympics/2024/08/11/paris-olympics-live-results/74191216007/",
            "title":
                "Paris Olympics live results: Today's schedule, updates, medal count"
          },
          {
            "num": 24,
            "url":
                "https://zijing.com.cn/article/2024-08/11/content_1272149527868346368.html",
            "title": "紫荆网: 再夺两金，中国暂列金牌榜第一！"
          },
          {
            "num": 25,
            "url":
                "https://apnews.com/article/olympics-2024-roundup-basketball-soccer-track-ecdee39aa3b025ce07d9f6a600470feb",
            "title":
                "AP News: Paris Olympics Day 15: US wins gold in men's basketball ..."
          },
          {
            "num": 26,
            "url":
                "https://apnews.com/article/olympics-2024-boxing-lin-khelif-28d3e1a46ed8fe5c1aa6cd612e2561ca",
            "title":
                "Taiwan boxer Lin Yu-ting breaks down after winning Olympic gold | AP News"
          },
          {
            "num": 27,
            "url": "https://news.bjd.com.cn/2024/08/11/90044477.shtml",
            "title": "北京日报: 都视频| 2024巴黎奥运会8月10日金牌榜变化动态图"
          },
          {
            "num": 28,
            "url":
                "https://apnews.com/article/olympics-2024-medal-winners-today-b9522fd1223ae6599569ffe1ee48cc62",
            "title": "AP News: A complete list of Paris Olympics medal winners"
          },
          {
            "num": 29,
            "url": "https://www.chinanews.com.cn/ty/2024/08-10/10267041.shtml",
            "title": "中国新闻网: （巴黎奥运）闭幕日看点：李雯雯有望卫冕金牌榜之争尘埃落定"
          }
        ]
      },
      "index": 0
    }
  ],
  "lastOne": false
};
