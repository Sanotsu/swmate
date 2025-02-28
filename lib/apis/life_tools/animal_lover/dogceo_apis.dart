import 'dart:convert';

import '../../../common/utils/dio_client/cus_http_client.dart';
import '../../../models/life_tools/dog_lover/dog_ceo_resp.dart';

///
/// dog.ceo 中的一些可用端点
/// 文档：https://dog.ceo/dog-api/documentation/
///

// 基础端点
const String dogCeoBase = "https://dog.ceo/api";

///
/// 查询狗品种信息
///
String _genDogCeoBreedUrl({
  bool isAll = true, // 是否是主品种带子品种
  bool isMasterBreed = true, // 是否是主品种
  String? breed, // 品种名称（仅在查询子品种时使用,查询子品种需要品种信息）
  bool isRandom = false, // 是否随机
  int? number, // 随机数量
}) {
  // 指定了品种或子品种，端点是breed，没有指定则是breeds
  String baseUrl = isAll
      ? "$dogCeoBase/breeds/list/all"
      : isMasterBreed
          ? "$dogCeoBase/breed/list"
          : "$dogCeoBase/breed/${breed ?? ''}";

  if (isRandom) {
    if (number != null) {
      return "$baseUrl/random/$number";
    }
    return "$baseUrl/random";
  }

  return baseUrl;
}

///
/// 获取指定品种详细信息(可查询指定子品种信息)
/// 实测无数据
///
String dogCeoGetBreedInfo(String breed, {String? subBreed}) {
  if (subBreed != null) {
    return "$dogCeoBase/$breed/$subBreed";
  }
  return "$dogCeoBase/$breed";
}

///
/// 通用的构造获取图片URL的函数
///
String _genDogCeoImageUrl({
  bool isRandom = false, // 是否随机
  int? number, // 随机数量
  String? breed, // 主品种名称
  String? subBreed, // 子品种名称
}) {
  String baseUrl;

  // 指定了品种或子品种，端点是breed，没有指定则是breeds
  if (breed != null && subBreed != null) {
    // 获取指定主品种下子品种的图片
    baseUrl = "$dogCeoBase/breed/$breed/$subBreed/images";
  } else if (breed != null) {
    // 获取指定主品种的图片
    baseUrl = "$dogCeoBase/breed/$breed/images";
  } else {
    // 获取随机图片
    baseUrl = "$dogCeoBase/breeds/image";
  }

  // 如果是随机
  if (isRandom) {
    if (number != null) {
      // 有指定数量，则获取指定随机数量的图片
      return "$baseUrl/random/$number";
    }
    // 仅仅单张
    return "$baseUrl/random";
  }

  return baseUrl;
}

///
/// 获取品种信息
///
Future<DogCeoResp> getDogCeoBreeds({
  bool isAll = true, // 是否是主品种带子品种
  bool isMasterBreed = true, // 是否是主品种
  String? breed, // 品种名称（仅在查询子品种时使用,查询子品种需要品种信息）
  bool isRandom = false, // 是否随机
  int? number, // 随机数量
}) async {
// 如果传了number，则是随机某几个
// 如果只传breed，则是查询单个主品种信息
// 如果传了breed和subBreed，则是查询单个子品种信息

  try {
    var url = _genDogCeoBreedUrl(
      isAll: isAll,
      isMasterBreed: isMasterBreed,
      breed: breed,
      isRandom: isRandom,
      number: number,
    );

    var respData = await HttpUtils.get(
      path: url,
      headers: {"Content-Type": "application/json"},
    );

    /// 2024-06-06 注意，这里报错的时候，响应的是String，而正常获取回复响应是_Map<String, dynamic>
    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    // 响应是json格式
    return DogCeoResp.fromJson(respData);
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}

///
/// 获取图片信息
///
Future<DogCeoResp> getDogCeoImages({
  bool isRandom = false, // 是否随机
  int? number, // 随机数量
  String? breed, // 主品种名称
  String? subBreed, // 子品种名称
}) async {
// 如果传了number，则是随机某几个
// 如果只传breed，则是查询单个主品种信息
// 如果传了breed和subBreed，则是查询单个子品种信息

  try {
    var url = _genDogCeoImageUrl(
      isRandom: isRandom,
      number: number,
      breed: breed,
      subBreed: subBreed,
    );

    var respData = await HttpUtils.get(path: url);

    /// 2024-06-06 注意，这里报错的时候，响应的是String，而正常获取回复响应是_Map<String, dynamic>
    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    // 响应是json格式
    return DogCeoResp.fromJson(respData);
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}


///
///
/// 另一个dog api的仓库： https://github.com/kinduff/dogapi.dog
/// 虽然也有品种和分类，但是没有图片，所以品种分类这块就不使用他的API了
/// 
/// 获取犬科事实(dog facts)的地址：https://dogapi.dog/api/v2/facts
/// 
/// =====
/// 
/// 猫狗都有，需要ak，可以用来获取品种和图片(说是有60k+ Images. Breeds. Facts.)，其他使用大模型来获取
/// https://portal.thatapicompany.com/
/// 
/// 随机图片不需要AK，但指定品种的话，需要AK(如果是狗的话，把thecatapi改为thedogapi即可)
/// 随机1张图片：https://api.thecatapi.com/v1/images/search
/// 随机10张图片：https://api.thecatapi.com/v1/images/search?limit=10
/// 指定品种：https://api.thecatapi.com/v1/images/search?limit=10&breed_ids=beng&api_key=REPLACE_ME
/// 随机指定品种的一张图(没有ak只有1张)：https://api.thecatapi.com/v1/images/search?breed_ids=beng
/// 获取所有品种：https://api.thecatapi.com/v1/breeds
/// 
/// 获取指定图片：https://api.thecatapi.com/v1/images/{reference_image_id}
///   在上面获取所有品种时，每个品种都有一个reference_image_id，替换上面编号可以得到指定图片的详情
/// 
/// 
/// =====
/// 
/// 随机一张狗图：https://random.dog/woof.json
///
/// =====
/// 
/// 随机cat facts：https://github.com/wh-iterabb-it/meowfacts
/// 
/// 一个：https://meowfacts.herokuapp.com/
/// 指定数量：https://meowfacts.herokuapp.com/?count=3
/// 语言支持：https://meowfacts.herokuapp.com/?lang=zho
/// 参数合并：https://meowfacts.herokuapp.com/?count=3&lang=zho
/// 
/// =====
/// 随机鸭子图：https://random-d.uk/api
/// 
/// 随机鸭子图片地址：https://random-d.uk/api/v2/random 或者 https://random-d.uk/api/v2/quack
/// 随机鸭子图片文件：https://random-d.uk/api/v2/randomimg
/// 获取所有图片：https://random-d.uk/api/v2/list (一共57+290张)
///   图片地址类似"https://random-d.uk/api/20.gif"，在上面获取所有图片时，只需要替换`20.gif`这个就可以了
///
/// =====
/// 随机猫图： https://cataas.com/
/// 
/// 随机一张猫图：https://cataas.com/cat
/// 随机一张gif的猫图：https://cataas.com/cat/gif
/// 随机的猫图上显示指定的文字内容(替换text)：https://cataas.com/cat/says/{text}
/// 
/// 随机一张指定tag的猫图：https://cataas.com/cat/orange,cute
/// 随机一张指定tag的猫图显示指定文字：https://cataas.com/cat/cute/says/{text}
/// 
/// 指定type返回的一张猫图：https://cataas.com/cat?type={square}
/// 指定filter返回的一张猫图：https://cataas.com/cat?filter={mono}
///
/// 返回所有tag：https://cataas.com//api/tags (实测这些tag不一样有用)
///
///