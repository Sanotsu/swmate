// 收集

import 'dart:convert';
import 'dart:math';

import '../../../common/utils/dio_client/cus_http_client.dart';

/// 获取犬科事实(dog facts)的地址：https://dogapi.dog/api/v2/facts
/// 随机cat facts ：https://meowfacts.herokuapp.com/?lang=zho
/// 随机1个事实（总共332个事实）：https://catfact.ninja/fact
///
/// 随机一张狗图：https://random.dog/woof.json
/// 随机一张猫图：https://cataas.com/cat

enum FactSource {
  dogapi,
  // meowfacts,
  catfact,
}

const Map<FactSource, String> apiUrls = {
  FactSource.dogapi: "https://dogapi.dog/api/v2/facts",
  // 2024-10-07 国内不能访问
  // FactSource.meowfacts: "https://meowfacts.herokuapp.com/?lang=zho",
  FactSource.catfact: "https://catfact.ninja/fact",
};

Future<String> getAnimalFact() async {
  var apikey = FactSource.values[Random().nextInt(FactSource.values.length)];

  try {
    var url = apiUrls[apikey]!;

    var respData = await HttpUtils.get(
      path: url,
      headers: {"Content-Type": "application/json"},
    );

    /// 2024-06-06 注意，这里报错的时候，响应的是String，而正常获取回复响应是_Map<String, dynamic>
    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    // 不同的API响应的结果不一样，但最终都是返回一个字符串
    if (apikey == FactSource.dogapi) {
      // 结构类似 {"data":[{"id":"a264e88f-ef76-48b5-ab35-9a1c2e71cab9","type":"fact",
      // "attributes":{"body":"Fifty-eight percent of people put pets in family and holiday portraits."}}]}
      return ((respData["data"] as List<dynamic>).first["attributes"]
          as Map<String, dynamic>)["body"];
    }
    //  else if (apikey == FactSource.meowfacts) {
    //   // 结构类似 {"data":["貓咪極速奔跑可達時速 50 公里。"]}
    //   return (respData["data"] as List<dynamic>).first;
    // }
    else if (apikey == FactSource.catfact) {
      // 结构类似 {"fact":"Cats take between 20-40 breaths per minute.","length":43}
      return respData["fact"];
    }

    return "<暂未获取数据>";
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}
