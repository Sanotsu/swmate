import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'free_dictionary_resp.g.dart';

///
/// 来源： https://github.com/meetDeveloper/freeDictionaryAPI
/// 以维基词典为源的英英词典API响应
/// 前缀为FD
///

List<FreeDictionaryItem> getFreeDictionaryRespList(List<dynamic> list) {
  List<FreeDictionaryItem> result = [];
  for (var item in list) {
    result.add(FreeDictionaryItem.fromJson(item));
  }
  return result;
}

///
/// 这次响应是个单元素数组，即该查询的单词
/// 但报错查不到结果时，是一个对象
///
@JsonSerializable(explicitToJson: true)
class FreeDictionaryItem {
  // 正常能查到结果响应是这几个(虽然是放在一个数组中，但查询显示时取第一个元素构建的)
  @JsonKey(name: 'word')
  String? word;

  @JsonKey(name: 'phonetics')
  List<FDPhonetic>? phonetics;

  @JsonKey(name: 'meanings')
  List<FDMeaning>? meanings;

  @JsonKey(name: 'license')
  FDLicense? license;

  @JsonKey(name: 'sourceUrls')
  List<String>? sourceUrls;

  // 如果查不到可能就是这几个栏位带上错误信息
  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'message')
  String? message;

  @JsonKey(name: 'resolution')
  String? resolution;

  FreeDictionaryItem({
    this.word,
    this.phonetics,
    this.meanings,
    this.license,
    this.sourceUrls,
    this.title,
    this.message,
    this.resolution,
  });

  // 从字符串转
  factory FreeDictionaryItem.fromRawJson(String str) =>
      FreeDictionaryItem.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory FreeDictionaryItem.fromJson(Map<String, dynamic> srcJson) =>
      _$FreeDictionaryItemFromJson(srcJson);

  Map<String, dynamic> toJson() => _$FreeDictionaryItemToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FDPhonetic {
  @JsonKey(name: 'text')
  String? text;

  @JsonKey(name: 'audio')
  String? audio;

  @JsonKey(name: 'sourceUrl')
  String? sourceUrl;

  @JsonKey(name: 'license')
  FDLicense? license;

  FDPhonetic({
    this.text,
    this.audio,
    this.sourceUrl,
    this.license,
  });

  factory FDPhonetic.fromRawJson(String str) =>
      FDPhonetic.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory FDPhonetic.fromJson(Map<String, dynamic> srcJson) =>
      _$FDPhoneticFromJson(srcJson);

  Map<String, dynamic> toJson() => _$FDPhoneticToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FDLicense {
  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'url')
  String? url;

  FDLicense({
    this.name,
    this.url,
  });

  factory FDLicense.fromRawJson(String str) =>
      FDLicense.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory FDLicense.fromJson(Map<String, dynamic> srcJson) =>
      _$FDLicenseFromJson(srcJson);

  Map<String, dynamic> toJson() => _$FDLicenseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FDMeaning {
  @JsonKey(name: 'partOfSpeech')
  String? partOfSpeech;

  @JsonKey(name: 'definitions')
  List<FDDefinition>? definitions;

  @JsonKey(name: 'synonyms')
  List<String>? synonyms;

  @JsonKey(name: 'antonyms')
  List<dynamic>? antonyms;

  FDMeaning(
    this.partOfSpeech,
    this.definitions,
    this.synonyms,
    this.antonyms,
  );

  factory FDMeaning.fromRawJson(String str) =>
      FDMeaning.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory FDMeaning.fromJson(Map<String, dynamic> srcJson) =>
      _$FDMeaningFromJson(srcJson);

  Map<String, dynamic> toJson() => _$FDMeaningToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FDDefinition {
  @JsonKey(name: 'definition')
  String? definition;

  @JsonKey(name: 'synonyms')
  List<dynamic>? synonyms;

  @JsonKey(name: 'antonyms')
  List<dynamic>? antonyms;

  @JsonKey(name: 'example')
  String? example;

  FDDefinition({
    this.definition,
    this.synonyms,
    this.antonyms,
    this.example,
  });

  factory FDDefinition.fromRawJson(String str) =>
      FDDefinition.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory FDDefinition.fromJson(Map<String, dynamic> srcJson) =>
      _$FDDefinitionFromJson(srcJson);

  Map<String, dynamic> toJson() => _$FDDefinitionToJson(this);
}
