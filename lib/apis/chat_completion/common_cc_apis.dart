import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:proste_logger/proste_logger.dart';

import '../../common/utils/db_tools/db_ai_tool_helper.dart';
import '../../models/chat_competion/com_cc_req.dart';
import '../../models/chat_competion/com_cc_resp.dart';
import '../../common/llm_spec/cus_llm_spec.dart';
import '../../common/utils/dio_client/cus_http_client.dart';
import '../../common/utils/dio_client/cus_http_request.dart';
import '../../common/utils/dio_client/interceptor_error.dart';
import '../../services/cus_get_storage.dart';
import '../gen_access_token/tencent_signature_v3.dart';
import '../gen_access_token/zhipu_signature.dart';
import '../get_app_key_helper.dart';
import '../platform_keys.dart';
import 'chat_helper.dart';

final l = ProsteLogger();
final DBAIToolHelper _dbHelper = DBAIToolHelper();

enum PlatUrl {
  tencentCCUrl,
  aliyunCompatibleCCUrl,
  baiduCCUrl,
  baiduTTIUrl,
  baiduCCAuthUrl,
  siliconFlowCCUrl,
  lingyiwanwuCCUrl,
  xfyunCCUrl,
  zhipuCCUrl,
}

const Map<PlatUrl, String> platUrls = {
  PlatUrl.tencentCCUrl: "https://hunyuan.tencentcloudapi.com/",
  PlatUrl.aliyunCompatibleCCUrl:
      "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
  PlatUrl.baiduCCUrl:
      "https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat/",
  PlatUrl.baiduTTIUrl:
      "https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/image2text/",
  PlatUrl.baiduCCAuthUrl: "https://aip.baidubce.com/oauth/2.0/token",
  PlatUrl.siliconFlowCCUrl: "https://api.siliconflow.cn/v1/chat/completions",
  PlatUrl.lingyiwanwuCCUrl: "https://api.lingyiwanwu.com/v1/chat/completions",
  PlatUrl.xfyunCCUrl: "https://spark-api-open.xf-yun.com/v1/chat/completions",
  PlatUrl.zhipuCCUrl: "https://open.bigmodel.cn/api/paas/v4/chat/completions",
};

/// https://cloud.infini-ai.com/maas/{model}/{chiptype}
/// nvidia 属于一个chiptype 参数，默认是nvidia
///   允许的值有: nvidia、amd、chip1、chip2、chip3、chip4、chip5
///   但chip3、chip4、chip5 流式响应模式下有不兼容，所以暂时默认nvidia
String infiniCCUrl(String model) =>
    "https://cloud.infini-ai.com/maas/$model/nvidia/chat/completions";

///
///===========可以取消流的写法
///
class StreamWithCancel<T> {
  final Stream<T> stream;
  final Future<void> Function() cancel;

  StreamWithCancel(this.stream, this.cancel);

  static StreamWithCancel<T> empty<T>() {
    return StreamWithCancel<T>(const Stream.empty(), () async {});
  }
}

var lineRegex = RegExp(r'^([^:]*)(?::)?(?: )?(.*)?$');

/// 获取流式和非流式的对话响应数据
Future<StreamWithCancel<ComCCResp>> getSseCcResponse(
  String url,
  Map<String, dynamic> headers,
  Map<String, dynamic> data, {
  bool stream = false,
}) async {
  try {
    var respData = await HttpUtils.post(
      path: url,
      method: CusHttpMethod.post,
      responseType: stream ? CusRespType.stream : CusRespType.json,
      headers: headers,
      data: data,
    );

    if (stream) {
      // 处理流式响应
      if (respData is ResponseBody) {
        final streamController = StreamController<ComCCResp>();

        StreamTransformer<Uint8List, List<int>> unit8Transformer =
            StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            sink.add(List<int>.from(data));
          },
        );

        final subscription = respData.stream
            // 创建一个自定义的 StreamTransformer 来处理 Uint8List 到 String 的转换。
            .transform(unit8Transformer)
            .transform(const Utf8Decoder())
            // 将输入的 Stream<String> 按照行（即换行符 \n 或 \r\n）进行分割，并将每一行作为一个单独的事件发送到输出流中。
            .transform(const LineSplitter())
            .transform(const SseTransformer())
            // 处理每一行数据
            .listen((event) async {
          // print(
          //   "【Event】 ${event.id}, ${event.event}, ${event.retry}, ${event.data}",
          // );

          // 如果流式响应其实在报错，则要单独
          // 腾讯的响应，报错的时候不是正常流格式，是一个含Response栏位的json字符串,
          // 得取出来才和其他结构类似
          if ((event.data).contains('"Response":{"Error"')) {
            if (!streamController.isClosed) {
              streamController.add(
                ComCCResp.fromJson(jsonDecode(event.data)["Response"]),
              );
              streamController.close();
            }
          } else {
            // 正常的分段数据
            // 如果包含DONE，是正常获取AI接口的结束
            if ((event.data).contains('[DONE]')) {
              if (!streamController.isClosed) {
                streamController.add(ComCCResp(cusText: '[DONE]'));
                streamController.close();
              }
            } else {
              final jsonData = json.decode(event.data);
              final commonRespBody = ComCCResp.fromJson(jsonData);
              if (!streamController.isClosed) {
                streamController.add(commonRespBody);
              }
            }
          }
        }, onDone: () {
          // 流处理完手动补一个结束子串
          if (!streamController.isClosed) {
            streamController.add(ComCCResp(cusText: '[DONE]-onDone'));
            streamController.close();
          }
        }, onError: (error) {
          if (!streamController.isClosed) {
            streamController.addError(error);
            streamController.close();
          }
        });

        Future<void> cancel() async {
          // ？？？占位用的，先发送最后一个手动终止的信息，再实际取消(手动的更没有token信息了)
          if (!streamController.isClosed) {
            streamController.add(ComCCResp(cusText: '[手动终止]'));
          }
          await subscription.cancel();
          if (!streamController.isClosed) {
            streamController.close();
          }
        }

        return StreamWithCancel(streamController.stream, cancel);
      } else {
        throw CusHttpException(cusCode: 500, cusMsg: '不符合预期的数据流响应类型');
      }
    } else {
      if (respData.runtimeType == String) {
        respData = json.decode(respData);
      }

      // 2024-08-17 腾讯的响应，在最外面还多一个Response栏位,得取出来才和其他结构类似
      if (respData["Response"] != null) {
        respData = respData["Response"];
      }

      return StreamWithCancel(
        Stream.value(ComCCResp.fromJson(respData)),
        () async {},
      );
    }
  } on CusHttpException catch (e) {
    // 报错时也要流式返回，并手动添加一条结束标志
    final streamController = StreamController<ComCCResp>();
    streamController.add(
      ComCCResp(
        cusText: """HTTP请求响应异常:\n\n错误代码: ${e.cusCode}
            \n\n错误信息: ${e.cusMsg}
            \n\n错误原文: ${e.errMessage}
            \n\n原始信息: ${e.errRespString}
            \n\n""",
      ),
    );
    streamController.add(ComCCResp(cusText: '[DONE]-后台响应错误'));
    streamController.close();

    return StreamWithCancel(streamController.stream, () async {});
  } catch (e) {
    rethrow;
  }
}

///
///-----------------------------------------------------------------------------
/// 百度的请求方法
///
/// 使用 AK，SK 生成鉴权签名（Access Token）
/// token 有效期是30天
Future<String> getAccessToken() async {
  // 这个获取的token的结果是一个_Map<String, dynamic>，不用转json直接取就得到Access Token了

  try {
    var respData = await HttpUtils.post(
      path: platUrls[PlatUrl.baiduCCAuthUrl]!,
      method: CusHttpMethod.post,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      data: {
        "grant_type": "client_credentials",
        "client_id": getStoredUserKey(SKN.baiduApiKey.name, BAIDU_API_KEY),
        "client_secret":
            getStoredUserKey(SKN.baiduSecretKey.name, BAIDU_SECRET_KEY),
      },
    );

    // 计算今天往后的 14 天(官方过期是30甜)
    DateTime expiredDate = DateTime.now().add(const Duration(days: 14));

    // 保存token信息到缓存
    await MyGetStorage().setBaiduTokenInfo({
      "accessToken": respData['access_token'].toString(),
      "expiredDate": expiredDate.toIso8601String(),
    });

    // 响应是json格式
    return respData['access_token'];
  } catch (e) {
    rethrow;
  }
}

/// 百度云的请求方法
Future<StreamWithCancel<ComCCResp>> baiduCCRespWithCancel(
  List<CCMessage> messages, {
  String? model,
  bool stream = false,
  String? system,
  // 百度如果传这两个参数，就是调用Fuyu8
  String? prompt,
  String? image,
}) async {
  var specs = await _dbHelper.queryCusLLMSpecList(platform: ApiPlatform.baidu);

  model = model ??
      specs.firstWhere((e) => e.cusLlm == CusLLM.baidu_Ernie_Tiny_8K).model;

  // 获取token信息
  var tokenInfo = MyGetStorage().getBaiduTokenInfo();

  String token = "";
  if (tokenInfo["accessToken"] != null &&
      tokenInfo["expiredDate"] != null &&
      DateTime.now().isBefore(DateTime.parse(tokenInfo["expiredDate"]!))) {
    token = tokenInfo["accessToken"]!;
  } else {
    try {
      token = await getAccessToken();
    } catch (e) {
      // 请求token报错就直接返回了
      return StreamWithCancel(
        Stream.value(ComCCResp(
          errorCode: (e as CusHttpException).cusCode,
          errorMsg: (e).errRespString,
        )),
        () async {},
      );
    }
  }

  ComCCReq body;
  if (prompt != null && image != null) {
    body = ComCCReq.baiduFuyu8B(prompt: prompt, image: image, stream: stream);
  } else {
    body = ComCCReq.baidu(messages: messages, stream: stream, system: system);
  }

  var headers = {"Content-Type": "application/json"};

  return getSseCcResponse(
    (prompt != null && image != null)
        ? "${platUrls[PlatUrl.baiduTTIUrl]!}$model?access_token=$token"
        : "${platUrls[PlatUrl.baiduCCUrl]!}$model?access_token=$token",
    headers,
    body.toJson(),
    stream: stream,
  );
}

/// siliconFlow 的请求方法
Future<StreamWithCancel<ComCCResp>> siliconFlowCCRespWithCancel(
  List<CCMessage> messages, {
  String? model,
  bool stream = false,
}) async {
  var specs =
      await _dbHelper.queryCusLLMSpecList(platform: ApiPlatform.siliconCloud);

  model = model ??
      specs
          .firstWhere((e) => e.cusLlm == CusLLM.siliconCloud_Qwen2_7B_Instruct)
          .model;

  var body = ComCCReq(model: model, messages: messages, stream: stream);

  var headers = {
    "Content-Type": "application/json",
    "Authorization":
        "Bearer ${getStoredUserKey(SKN.siliconFlowAK.name, SILICON_CLOUD_AK)}",
  };
  return getSseCcResponse(
    platUrls[PlatUrl.siliconFlowCCUrl]!,
    headers,
    body.toJson(),
    stream: stream,
  );
}

/// 零一万物的请求方法
Future<StreamWithCancel<ComCCResp>> lingyiwanwuCCRespWithCancel(
  List<CCMessage> messages, {
  String? model,
  bool stream = false,
}) async {
  var specs =
      await _dbHelper.queryCusLLMSpecList(platform: ApiPlatform.lingyiwanwu);

  model = model ??
      specs.firstWhere((e) => e.cusLlm == CusLLM.lingyiwanwu_YiSpark).model;

  var body = ComCCReq(model: model, messages: messages, stream: stream);

  var header = {
    "Content-Type": "application/json",
    "Authorization":
        "Bearer ${getStoredUserKey(SKN.lingyiwanwuAK.name, LINGYI_AK)}",
  };

  return getSseCcResponse(
    platUrls[PlatUrl.lingyiwanwuCCUrl]!,
    header,
    body.toJson(),
    stream: stream,
  );
}

/// 讯飞云的请求方法
Future<StreamWithCancel<ComCCResp>> xfyunCCRespWithCancel(
  List<CCMessage> messages, {
  String? model,
  bool stream = false,
}) async {
  var specs = await _dbHelper.queryCusLLMSpecList(platform: ApiPlatform.xfyun);

  model = model ??
      specs.firstWhere((e) => e.cusLlm == CusLLM.xfyun_Spark_Lite).model;

  var body = ComCCReq.xfyun(model: model, messages: messages, stream: stream);

  var ak = "";

  if (model ==
      specs.firstWhere((e) => e.cusLlm == CusLLM.xfyun_Spark_Lite).model) {
    ak = getStoredUserKey(
      SKN.xfyunSparkLiteApiPassword.name,
      XUNFEI_SPARK_LITE_API_PASSWORD,
    );
  } else if (model ==
      specs.firstWhere((e) => e.cusLlm == CusLLM.xfyun_Spark_Pro).model) {
    ak = getStoredUserKey(
      SKN.xfyunSparkProApiPassword.name,
      XUNFEI_SPARK_PRO_API_PASSWORD,
    );
  }
  var header = {
    "Content-Type": "application/json",
    "Authorization": "Bearer $ak",
  };

  return getSseCcResponse(
    platUrls[PlatUrl.xfyunCCUrl]!,
    header,
    body.toJson(),
    stream: stream,
  );
}

/// 腾讯云的请求方法
Future<StreamWithCancel<ComCCResp>> tencentCCRespWithCancel(
  List<CCMessage> messages, {
  String? model,
  bool stream = false,
}) async {
  var specs =
      await _dbHelper.queryCusLLMSpecList(platform: ApiPlatform.tencent);

  model = model ??
      specs.firstWhere((e) => e.cusLlm == CusLLM.tencent_Hunyuan_Lite).model;

  Map<String, dynamic> tempBody = {
    "Model": model,
    "Stream": stream,
    "Messages": messages
        .map((e) => {
              "Role": e.role,
              "Content": e.content.toString(),
            })
        .toList(),
  };

  var header = genHunyuanLiteSignatureHeaders(
    jsonEncode(tempBody),
    getStoredUserKey(SKN.tencentSecretId.name, TENCENT_SECRET_ID),
    getStoredUserKey(SKN.tencentSecretKey.name, TENCENT_SECRET_KEY),
  );

  return getSseCcResponse(
    platUrls[PlatUrl.tencentCCUrl]!,
    header,
    tempBody,
    stream: stream,
  );
}

/// 智谱AI的请求方法
Future<StreamWithCancel<ComCCResp>> zhipuCCRespWithCancel(
  List<CCMessage> messages, {
  String? model,
  bool stream = false,
}) async {
  var specs = await _dbHelper.queryCusLLMSpecList(platform: ApiPlatform.zhipu);

  model = model ??
      specs.firstWhere((e) => e.cusLlm == CusLLM.zhipu_GLM4_Flash).model;

  var body = ComCCReq.glm(
    model: model,
    messages: messages,
    stream: stream,
    tools: [
      CCTool(
        "web_search",
        webSearch: CCWebSearch(enable: true, searchResult: true),
      )
    ],
  );

  var token = zhipuGenerateToken(
    getStoredUserKey(SKN.zhipuAK.name, ZHIPU_AK),
  );

  var header = {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  return getSseCcResponse(
    platUrls[PlatUrl.zhipuCCUrl]!,
    header,
    body.toJson(),
    stream: stream,
  );
}

/// 阿里云的请求方法
Future<StreamWithCancel<ComCCResp>> aliyunCCRespWithCancel(
  List<CCMessage> messages, {
  String? model,
  bool stream = false,
}) async {
  var specs = await _dbHelper.queryCusLLMSpecList(platform: ApiPlatform.aliyun);

  model = model ??
      specs.firstWhere((e) => e.cusLlm == CusLLM.aliyun_Qwen_VL_Max_0809).model;

  var body = ComCCReq.aliyun(
    model: model,
    messages: messages,
    stream: stream,
    // 非流式时传此参数会报错
    streamOptions: stream ? StreamOption(includeUsage: true) : null,
  );

  var header = {
    "Content-Type": "application/json",
    "Authorization":
        "Bearer ${getStoredUserKey(SKN.aliyunApiKey.name, ALIYUN_API_KEY)}",
  };

  return getSseCcResponse(
    platUrls[PlatUrl.aliyunCompatibleCCUrl]!,
    header,
    body.toJson(),
    stream: stream,
  );
}

/// 无问芯穹的请求方法
Future<StreamWithCancel<ComCCResp>> infiniCCRespWithCancel(
  List<CCMessage> messages, {
  String? model,
  bool stream = false,
}) async {
  var specs = await _dbHelper.queryCusLLMSpecList(platform: ApiPlatform.infini);

  model = model ??
      specs
          .firstWhere((e) => e.cusLlm == CusLLM.infini_Qwen2_72B_Instruct)
          .model;

  // 请求路径有model，参数也得有
  var body = ComCCReq(model: model, messages: messages, stream: stream);

  var header = {
    "Content-Type": "application/json",
    "Authorization":
        "Bearer ${getStoredUserKey(SKN.infiniAK.name, INFINI_GEN_STUDIO_AK)}",
  };

  return getSseCcResponse(
    infiniCCUrl(model),
    header,
    body.toJson(),
    stream: stream,
  );
}

///
/// 2024-09-28
/// 单独的，不需要流式的时候，可以更简单的处理，不必强行混合在流式响应中
///
/// 百度的、腾讯的、讯飞的验证麻烦一点，其他的操作类似，只需AK即可
///
Future<ComCCResp> baiduCCResp(
  List<CCMessage> messages,
  String model, {
  String? system,
  // 百度如果传这两个参数，就是调用Fuyu8
  String? prompt,
  String? image,
}) async {
  // 获取token信息
  var tokenInfo = MyGetStorage().getBaiduTokenInfo();

  String token = "";
  if (tokenInfo["accessToken"] != null &&
      tokenInfo["expiredDate"] != null &&
      DateTime.now().isBefore(DateTime.parse(tokenInfo["expiredDate"]!))) {
    token = tokenInfo["accessToken"]!;
  } else {
    try {
      token = await getAccessToken();
    } catch (e) {
      // 请求token报错就直接返回了
      return ComCCResp(
        errorCode: (e as CusHttpException).cusCode,
        errorMsg: (e).errRespString,
      );
    }
  }

  ComCCReq body;
  if (prompt != null && image != null) {
    body = ComCCReq.baiduFuyu8B(prompt: prompt, image: image);
  } else {
    body = ComCCReq.baidu(messages: messages, system: system);
  }

  var headers = {"Content-Type": "application/json"};

  return getCCResp(
    (prompt != null && image != null)
        ? "${platUrls[PlatUrl.baiduTTIUrl]!}$model?access_token=$token"
        : "${platUrls[PlatUrl.baiduCCUrl]!}$model?access_token=$token",
    body.toJson(),
    headers: headers,
  );
}

Future<ComCCResp> tencentCCResp(
  List<CCMessage> messages,
  String model,
) async {
  Map<String, dynamic> tempBody = {
    "Model": model,
    "Messages": messages
        .map((e) => {
              "Role": e.role,
              "Content": e.content.toString(),
            })
        .toList(),
  };

  var header = genHunyuanLiteSignatureHeaders(
    jsonEncode(tempBody),
    getStoredUserKey(SKN.tencentSecretId.name, TENCENT_SECRET_ID),
    getStoredUserKey(SKN.tencentSecretKey.name, TENCENT_SECRET_KEY),
  );

  return getCCResp(
    platUrls[PlatUrl.tencentCCUrl]!,
    tempBody,
    headers: header,
  );
}

Future<ComCCResp> xfyunCCResp(
  List<CCMessage> messages,
  String model,
) async {
  var specs = await _dbHelper.queryCusLLMSpecList(platform: ApiPlatform.xfyun);

  var body = ComCCReq.xfyun(model: model, messages: messages);

  var ak = "";

  if (model ==
      specs.firstWhere((e) => e.cusLlm == CusLLM.xfyun_Spark_Lite).model) {
    ak = getStoredUserKey(
      SKN.xfyunSparkLiteApiPassword.name,
      XUNFEI_SPARK_LITE_API_PASSWORD,
    );
  } else if (model ==
      specs.firstWhere((e) => e.cusLlm == CusLLM.xfyun_Spark_Pro).model) {
    ak = getStoredUserKey(
      SKN.xfyunSparkProApiPassword.name,
      XUNFEI_SPARK_PRO_API_PASSWORD,
    );
  }

  return getCCResp(
    platUrls[PlatUrl.xfyunCCUrl]!,
    body.toJson(),
    ak: ak,
  );
}

// 这个仅仅用于非流式请求时的各个使用ak的平台的对话api地址，不包含校验地址
Map<ApiPlatform, String> platAPIUrlMap = {
  ApiPlatform.baidu: platUrls[PlatUrl.baiduCCUrl]!,
  ApiPlatform.tencent: platUrls[PlatUrl.tencentCCUrl]!,
  ApiPlatform.xfyun: platUrls[PlatUrl.xfyunCCUrl]!,
  // 无问芯穹地址比较特殊，包含模型，所以不在这里
  ApiPlatform.aliyun: platUrls[PlatUrl.aliyunCompatibleCCUrl]!,
  ApiPlatform.siliconCloud: platUrls[PlatUrl.siliconFlowCCUrl]!,
  ApiPlatform.lingyiwanwu: platUrls[PlatUrl.lingyiwanwuCCUrl]!,
  ApiPlatform.zhipu: platUrls[PlatUrl.zhipuCCUrl]!,
};

// 这个仅仅用于非流式请求时的各个使用ak的平台的ak(智谱还有二次加密)
Map<ApiPlatform, String> platAKMap = {
  ApiPlatform.aliyun: getStoredUserKey(SKN.aliyunApiKey.name, ALIYUN_API_KEY),
  ApiPlatform.siliconCloud:
      getStoredUserKey(SKN.siliconFlowAK.name, SILICON_CLOUD_AK),
  ApiPlatform.lingyiwanwu: getStoredUserKey(SKN.lingyiwanwuAK.name, LINGYI_AK),
  ApiPlatform.infini: getStoredUserKey(SKN.infiniAK.name, INFINI_GEN_STUDIO_AK),
  // 智谱这个是占位的，需要key来做是否存在的判断
  ApiPlatform.zhipu: "",
};

///
/// 这几个使用AK的，再简化一点
///
Future<ComCCResp> useAkCCResp(
  List<CCMessage> messages,
  ApiPlatform plat,
  String model, {
  bool? webSearch = true,
}) async {
  if (!platAKMap.keys.contains(plat)) {
    return ComCCResp(errorCode: 9999, cusText: "不支持该平台的统一AK调用");
  }

  var ak = plat == ApiPlatform.zhipu
      ? zhipuGenerateToken(getStoredUserKey(SKN.zhipuAK.name, ZHIPU_AK))
      : platAKMap[plat]!;

  var body = plat == ApiPlatform.zhipu
      ? ComCCReq.glm(
          model: model,
          messages: messages,
          // 翻译的时候联网反而可能会出事，所以加一个可以控制联网的参数
          tools: webSearch == true
              ? [
                  CCTool(
                    "web_search",
                    webSearch: CCWebSearch(enable: true, searchResult: true),
                  )
                ]
              : null,
        )
      : ComCCReq(model: model, messages: messages);

  return getCCResp(
    platAPIUrlMap[plat]!,
    body.toJson(),
    ak: ak,
  );
}

Future<ComCCResp> zhipuCCResp(
  List<CCMessage> messages,
  String model,
) async {
  var body = ComCCReq.glm(
    model: model,
    messages: messages,
    tools: [
      CCTool(
        "web_search",
        webSearch: CCWebSearch(enable: true, searchResult: true),
      )
    ],
  );

  return getCCResp(
    platAPIUrlMap[ApiPlatform.zhipu]!,
    body.toJson(),
    ak: zhipuGenerateToken(getStoredUserKey(SKN.zhipuAK.name, ZHIPU_AK)),
  );
}

Future<ComCCResp> siliconFlowCCResp(
  List<CCMessage> messages,
  String model,
) async {
  return getCCResp(
    platUrls[PlatUrl.siliconFlowCCUrl]!,
    ComCCReq(model: model, messages: messages).toJson(),
    ak: getStoredUserKey(SKN.siliconFlowAK.name, SILICON_CLOUD_AK),
  );
}

Future<ComCCResp> lingyiwanwuCCResp(
  List<CCMessage> messages,
  String model,
) async {
  return getCCResp(
    platUrls[PlatUrl.lingyiwanwuCCUrl]!,
    ComCCReq(model: model, messages: messages).toJson(),
    ak: getStoredUserKey(SKN.lingyiwanwuAK.name, LINGYI_AK),
  );
}

Future<ComCCResp> aliyunCCResp(
  List<CCMessage> messages,
  String model,
) async {
  return getCCResp(
    platUrls[PlatUrl.aliyunCompatibleCCUrl]!,
    ComCCReq.aliyun(model: model, messages: messages).toJson(),
    ak: getStoredUserKey(SKN.aliyunApiKey.name, ALIYUN_API_KEY),
  );
}

Future<ComCCResp> infiniCCResp(
  List<CCMessage> messages,
  String model,
) async {
  return getCCResp(
    infiniCCUrl(model),
    ComCCReq(model: model, messages: messages).toJson(),
    ak: getStoredUserKey(SKN.infiniAK.name, INFINI_GEN_STUDIO_AK),
  );
}

Future<ComCCResp> getCCResp(
  String url,
  Map<String, dynamic> data, {
  // 如果传入标头，就直接使用；如果是传入ak，就要构建标头；
  // 二者至少一项，header优先级更高，暂不验证都不存在
  Map<String, dynamic>? headers,
  String? ak,
}) async {
  var cusHeaders = headers ??
      {"Content-Type": "application/json", "Authorization": "Bearer $ak"};

  try {
    var respData = await HttpUtils.post(
      path: url,
      method: CusHttpMethod.post,
      responseType: CusRespType.json,
      headers: cusHeaders,
      data: data,
    );

    if (respData.runtimeType == String) respData = json.decode(respData);

    // 2024-08-17 腾讯的响应，在最外面还多一个Response栏位,得取出来才和其他结构类似
    if (respData["Response"] != null) {
      respData = respData["Response"];
    }

    return ComCCResp.fromJson(respData);
  } on CusHttpException catch (e) {
    return ComCCResp(
      cusText: """HTTP请求响应异常:
\n\n错误代码: ${e.cusCode}
\n\n错误信息: ${e.cusMsg}
\n\n\n\n原始信息: ${e.errRespString}""",
    );
  } catch (e) {
    rethrow;
  }
}
