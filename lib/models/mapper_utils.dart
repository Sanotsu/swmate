/*
1、
{
  "prompt_tokens": 3,
  "completion_tokens": 14,
  "total_tokens": 17
}
2、
{
  "PromptTokens": 3,
  "CompletionTokens": 14,
  "TotalTokens": 17
}
3、
{
  "promptTokens": 3,
  "completionTokens": 14,
  "totalTokens": 17
}
 */
/// 2024-08-17
/// 专门为响应体匹配多种结构设计的函数
/// 比如如上面有3不同的响应体，一般的API返回的都是第一种，蛇式命名，但像“腾讯”这种异类，请求和响应都是第二种帕斯卡命名的json
/// 为了统一处理，就在【处理响应时】，在json_annotation 的 @JsonKey(readValue: readValue)，中，统一处理响应的json栏位
/// 请求体就暂时不必， 就混元Lite的请求在转换时需要帕斯卡，目前只打算几个必要参数，就不多做处理了
dynamic readJsonValue(Map json, String key) {
  // 尝试从多个可能的键中读取值
  var possibleKeys = generatePossibleKeys(key);

  for (var possibleKey in possibleKeys) {
    if (json.containsKey(possibleKey)) {
      return json[possibleKey];
    }
  }
  return null;
}

List<String> generatePossibleKeys(String key) {
  // 生成蛇形命名、帕斯卡命名和驼峰命名的可能键
  return [
    // 蛇形命名
    key
        .replaceAllMapped(
          RegExp(r'(?<=[a-z])[A-Z]'),
          (match) => '_${match.group(0)}',
        )
        .toLowerCase(),
    // 帕斯卡命名
    key[0].toUpperCase() + key.substring(1),
    // 驼峰命名
    key,
  ];
}

// 报错信息可是多种多样
dynamic readErrorMsgValue(Map json, String key) {
  // 尝试从多个可能的键中读取值
  // 例如时error_msg,会匹配error_msg、ErrorMsg、errorMsg
  var possibleKeys = generatePossibleKeys(key);

  for (var possibleKey in possibleKeys) {
    if (json.containsKey(possibleKey)) {
      return json[possibleKey];
    }
  }

  // 单独报错消息，除了error_msg，还可以其他形状 ，比如讯飞的message、无问芯穹的msg
  // 2024-11-04 注意，讯飞的报错使用了message栏位，但是成功该栏位也有值"Success"，需要特殊处理
  return json["message"] ?? json['Message'] ?? json["msg"] ?? json["Msg"];
}

// 2025-03-24 不同平台联网搜索参考内容不一样，所以需要单独处理
dynamic readReferenceValue(Map json, String key) {
  // 尝试从多个可能的键中读取值
  // 例如时error_msg,会匹配error_msg、ErrorMsg、errorMsg
  var possibleKeys = generatePossibleKeys(key);

  for (var possibleKey in possibleKeys) {
    if (json.containsKey(possibleKey)) {
      return json[possibleKey];
    }
  }

  // 2025-03-24 火山引擎的联网搜索参考内容是references
  // 2025-03-25 智谱的联网搜索参考内容是 web_search
  return json["references"] ?? json["web_search"];
}
