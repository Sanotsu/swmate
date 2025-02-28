import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'the_dog_cat_api_breed.g.dart';

///
/// https://portal.thatapicompany.com/
/// thecatapi/thedogapi 请求用get即可，所有端点的返回，都放在这里来
///
///
/// 获取图片信息的时候，会带上品种信息，暂时没有亚种
///
/// 整理后的猫狗通用响应栏位只留下：
/*
{
  "id": "0XYvRd7oD",
  "url": "https://cdn2.thecatapi.com/images/0XYvRd7oD.jpg",
  "breeds": [
    {
      "id": "abys",
      "name": "Abyssinian",
      "breed_group": "Hound",
      "temperament": "Active, Energetic, Independent, Intelligent, Gentle",
      "origin": "Egypt",
      "description": "The Abyssinian is easy to care for, and a joy to have in your home. They’re affectionate cats and love both people and other animals.",
      "life_span": "14 - 15",
      "alt_names": "",
      "wikipedia_url": "https://en.wikipedia.org/wiki/Abyssinian_(cat)",
      "reference_image_id": "0XYvRd7oD"
    }
  ]
}
*/
///
/// https://developers.thecatapi.com/view-account/ylX4blBYT9FaoVd6OhvR?report=bOoHBz-8t
///
// 2024-09-14目前有用到实际上存入数据库的，只有品种即可
@JsonSerializable(explicitToJson: true)
class TheDogCatApiResp {
  @JsonKey(name: 'id')
  String id;

  @JsonKey(name: 'url')
  String url;

  @JsonKey(name: 'breeds')
  List<Breed> breeds;

  TheDogCatApiResp(
    this.id,
    this.url,
    this.breeds,
  );

  factory TheDogCatApiResp.fromJson(Map<String, dynamic> srcJson) =>
      _$TheDogCatApiRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TheDogCatApiRespToJson(this);

  // 从字符串转
  factory TheDogCatApiResp.fromRawJson(String str) =>
      TheDogCatApiResp.fromJson(json.decode(str));

  // 转为字符串
  String toRawJson() => json.encode(toJson());

  // 手动编写的 toMap 方法
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'breeds': breeds.map((breed) => breed.toMap()).toList(),
    };
  }

  // 手动编写的 fromMap 方法
  factory TheDogCatApiResp.fromMap(Map<String, dynamic> map) {
    return TheDogCatApiResp(
      map['id'] as String,
      map['url'] as String,
      (map['breeds'] as List<dynamic>)
          .map((breed) => Breed.fromMap(breed as Map<String, dynamic>))
          .toList(),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class Breed {
  // 可能是字符串也可能 是int
  @JsonKey(name: 'id')
  dynamic id;

  // 亚种名称
  @JsonKey(name: 'name')
  String? name;

  // 有这个栏位，这个栏位就是品种，name就是亚种
  @JsonKey(name: 'breed_group')
  String? breedGroup;

  // 性格
  @JsonKey(name: 'temperament')
  String? temperament;

  // 原产地
  @JsonKey(name: 'origin')
  String? origin;

  // 简介
  @JsonKey(name: 'description')
  String? description;

  // 生命周期
  @JsonKey(name: 'life_span')
  String? lifeSpan;

  // 别名
  @JsonKey(name: 'alt_names')
  String? altNames;

  // 维基百科地址
  @JsonKey(name: 'wikipedia_url')
  String? wikipediaUrl;

  // 分类的参考图片
  @JsonKey(name: 'reference_image_id')
  String? referenceImageId;

  // 这个是自己加的，为了匹配数据库栏位
  @JsonKey(name: 'data_source')
  String? dataSource;

  Breed({
    this.id,
    this.name,
    this.breedGroup,
    this.temperament,
    this.origin,
    this.description,
    this.lifeSpan,
    this.altNames,
    this.wikipediaUrl,
    this.referenceImageId,
    this.dataSource,
  });

  factory Breed.fromJson(Map<String, dynamic> srcJson) =>
      _$BreedFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BreedToJson(this);

  // 从字符串转
  factory Breed.fromRawJson(String str) => Breed.fromJson(json.decode(str));

  // 转为字符串
  String toRawJson() => json.encode(toJson());

  // 手动编写的 toMap 方法(存取数据库时使用，所以栏位有点不一样)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subBreed': name,
      'breed': breedGroup,
      'temperament': temperament,
      'origin': origin,
      'description': description,
      'lifeSpan': lifeSpan,
      'altNames': altNames,
      'wikipediaUrl': wikipediaUrl,
      'referenceImageUrl': referenceImageId,
      'dataSource': dataSource,
    };
  }

  // 手动编写的 fromMap 方法
  factory Breed.fromMap(Map<String, dynamic> map) {
    return Breed(
      id: map['id'],
      name: map['breed'] as String?,
      breedGroup: map['subBreed'] as String?,
      temperament: map['temperament'] as String?,
      origin: map['origin'] as String?,
      description: map['description'] as String?,
      lifeSpan: map['lifeSpan'] as String?,
      altNames: map['altNames'] as String?,
      wikipediaUrl: map['wikipediaUrl'] as String?,
      referenceImageId: map['referenceImageUrl'] as String?,
      dataSource: map['dataSource'] as String?,
    );
  }
}
