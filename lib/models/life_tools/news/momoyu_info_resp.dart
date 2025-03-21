import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'momoyu_info_resp.g.dart';

///
/// 摸摸鱼（https://momoyu.cc/）主页响应
/// https://momoyu.cc/api/hot/list?type=0
/// 看起来type的0和1有些许不同，1是把所有数据来源再分类了一次
///
/// 指定编号的响应稍微不同
/// https://momoyu.cc/api/hot/item?id=1
///
///
/// 前缀带上MMY（momoyu）
///

@JsonSerializable(genericArgumentFactories: true, explicitToJson: true)
class MomoyuInfoResp<T> {
  @JsonKey(name: 'status')
  int? status;

  @JsonKey(name: 'message')
  String? message;

  // 不同的参数，可能是MMYCateData列表、MMYData列表、MMYIdData实例(这个不是数组了)
  @JsonKey(name: 'data')
  T? data;

  MomoyuInfoResp({
    this.status,
    this.message,
    this.data,
  });

  // 从原始 JSON 字符串反序列化
  factory MomoyuInfoResp.fromRawJson(
      String str, T Function(Object? json) fromJsonT) {
    final jsonMap = json.decode(str);
    return MomoyuInfoResp.fromJson(jsonMap, fromJsonT);
  }

  // 序列化为原始 JSON 字符串
  String toRawJson(Object? Function(T value) toJsonT) {
    return json.encode(toJson(toJsonT));
  }

  factory MomoyuInfoResp.fromJson(
          Map<String, dynamic> json, T Function(Object? json) fromJsonT) =>
      _$MomoyuInfoRespFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$MomoyuInfoRespToJson(this, toJsonT);
}

///
/// data 可能是一个 list< MMYCateData > 或者 list< MMYData >
/// 结果列表也用泛型
///
@JsonSerializable(genericArgumentFactories: true, explicitToJson: true)
class ListWithT<T> {
  List<T>? list;

  ListWithT(this.list);

  factory ListWithT.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$ListWithTFromJson<T>(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T) toJsonT) =>
      _$ListWithTToJson(this, toJsonT);
}

// list?type=1时有分类
@JsonSerializable(explicitToJson: true)
class MMYCateData {
  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'data')
  List<MMYData>? data;

  MMYCateData({
    this.id,
    this.name,
    this.data,
  });

  factory MMYCateData.fromRawJson(String str) =>
      MMYCateData.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory MMYCateData.fromJson(Map<String, dynamic> srcJson) =>
      _$MMYCateDataFromJson(srcJson);

  Map<String, dynamic> toJson() => _$MMYCateDataToJson(this);
}

// list?type=0时直接数据列表
@JsonSerializable(explicitToJson: true)
class MMYData {
  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'sort')
  int? sort;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'source_key')
  String? sourceKey;

  @JsonKey(name: 'icon_color')
  String? iconColor;

  @JsonKey(name: 'data')
  List<MMYDataItem>? data;

  @JsonKey(name: 'create_time')
  String? createTime;

  MMYData({
    this.id,
    this.sort,
    this.name,
    this.sourceKey,
    this.iconColor,
    this.data,
    this.createTime,
  });

  factory MMYData.fromRawJson(String str) => MMYData.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory MMYData.fromJson(Map<String, dynamic> srcJson) =>
      _$MMYDataFromJson(srcJson);

  Map<String, dynamic> toJson() => _$MMYDataToJson(this);
}

// item?id=1 指定分类时直接项次列表和上次更新时间
@JsonSerializable(explicitToJson: true)
class MMYIdData {
  @JsonKey(name: 'time')
  String? time;

  @JsonKey(name: 'list')
  List<MMYDataItem>? list;

  MMYIdData({
    this.time,
    this.list,
  });

  factory MMYIdData.fromRawJson(String str) =>
      MMYIdData.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory MMYIdData.fromJson(Map<String, dynamic> srcJson) =>
      _$MMYIdDataFromJson(srcJson);

  Map<String, dynamic> toJson() => _$MMYIdDataToJson(this);
}

@JsonSerializable(explicitToJson: true)
class MMYDataItem {
  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'extra')
  String? extra;

  @JsonKey(name: 'link')
  String? link;

  MMYDataItem({
    this.id,
    this.title,
    this.extra,
    this.link,
  });

  factory MMYDataItem.fromRawJson(String str) =>
      MMYDataItem.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory MMYDataItem.fromJson(Map<String, dynamic> srcJson) =>
      _$MMYDataItemFromJson(srcJson);

  Map<String, dynamic> toJson() => _$MMYDataItemToJson(this);
}
