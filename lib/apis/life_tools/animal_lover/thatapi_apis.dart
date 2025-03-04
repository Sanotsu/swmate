import '../../../common/utils/dio_client/cus_http_client.dart';
import '../../../models/life_tools/animal_lover/the_dog_cat_api_breed.dart';
import '../../../models/life_tools/animal_lover/the_dog_cat_api_image.dart';

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
/// 获取品种信息
///
Future<List<Breed>> getThatApiBreeds({
  String type = 'cat', // 查询猫或者狗
}) async {
  try {
    var url = "https://api.the${type}api.com/v1/breeds";

    List respData = await HttpUtils.get(path: url);

    // 响应是json格式的列表 List<dynamic>
    return respData.map((e) => Breed.fromJson(e)).toList();
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}

///
/// 获取图片信息
///
Future<List<TheDogCatApiImage>> getThatApiImages({
  String? type = 'dog', // 猫还是狗 cat dog
  bool isRandom = false, // 是否随机
  int? number, // 随机数量
  // 品种，多个用逗号连接(thecarapi栏位是String，thedogapi栏位是int)
  dynamic breedIds,
}) async {
// 如果传了number，则是随机某几个
// 如果只传breed，则是查询单个主品种信息
// 如果传了breed和subBreed，则是查询单个子品种信息

  try {
    var url = "https://api.the${type}api.com/v1/images/search";

    if (isRandom) {
      if (number != null) {
        url += "?limit=${number <= 10 ? 1 : 10}";
      } else {
        url = url;
      }
    } else if (breedIds != null) {
      url += "?breed_ids=$breedIds";
    }

    List<dynamic> respData = await HttpUtils.get(path: url);

    // 响应是json格式的列表 List<dynamic>
    return respData.map((e) => TheDogCatApiImage.fromJson(e)).toList();
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}
