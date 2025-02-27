import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'sina_roll_news_resp.g.dart';

///
/// 2024-11-08
/// 新浪滚动新闻中心
///
/// 网页：https://news.sina.com.cn/roll/#pageid=153&lid=2509&k=&num=50&page=1
/// 接口：https://feed.mix.sina.com.cn/api/roll/get?pageid=153&lid=2509&num=50&page=1
/// 响应的内容很多，就简单取几个，最外层默认的result也不要了
///
/// 前缀 SinaRN
///

@JsonSerializable(explicitToJson: true)
class SinaRollNewsResp {
  // 响应状态
  @JsonKey(name: 'status')
  SinaRNStatus? status;
  // 响应结果的时间字符串
  @JsonKey(name: 'timestamp')
  String? timestamp;
  // 响应结果的时间戳
  @JsonKey(name: 'rtime')
  int? rtime;
  // 新闻总量
  @JsonKey(name: 'total')
  int? total;
  // 新闻分类编号
  @JsonKey(name: 'lid')
  int? lid;
  // 新闻信息列表
  @JsonKey(name: 'data')
  List<SinaRollNews>? data;

  SinaRollNewsResp({
    this.status,
    this.timestamp,
    this.total,
    this.lid,
    this.rtime,
    this.data,
  });

  factory SinaRollNewsResp.fromRawJson(String str) =>
      SinaRollNewsResp.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory SinaRollNewsResp.fromJson(Map<String, dynamic> srcJson) =>
      _$SinaRollNewsRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$SinaRollNewsRespToJson(this);
}

@JsonSerializable()
class SinaRNStatus {
  @JsonKey(name: 'code')
  int? code;

  @JsonKey(name: 'msg')
  String? msg;

  SinaRNStatus({
    this.code,
    this.msg,
  });

  factory SinaRNStatus.fromRawJson(String str) =>
      SinaRNStatus.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory SinaRNStatus.fromJson(Map<String, dynamic> srcJson) =>
      _$SinaRNStatusFromJson(srcJson);

  Map<String, dynamic> toJson() => _$SinaRNStatusToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SinaRollNews {
  // 新闻标题
  @JsonKey(name: 'title')
  String? title;
  // 简介，很短，比标题多不了几个字
  @JsonKey(name: 'intro')
  String? intro;
  // 新闻的关键字
  @JsonKey(name: 'keywords')
  String? keywords;
  // 关联的分类(应该是这些分类中都可以看到这个新闻)
  @JsonKey(name: 'lids')
  String? lids;
  // 新闻来源媒体
  @JsonKey(name: 'media_name')
  String? mediaName;
  // 好像没什么用，大部分都是0
  @JsonKey(name: 'author')
  String? author;

  // 新闻的网页地址
  @JsonKey(name: 'url')
  String? url;
  // 一般是手机访问的地址
  @JsonKey(name: 'wapurl')
  String? wapurl;

  // 创建时间
  @JsonKey(name: 'ctime')
  String? ctime;
  // 更新时间
  @JsonKey(name: 'mtime')
  String? mtime;

  // 这个应该是标题的缩略图，但是如果没有是一个空数组[]，如果有是一个对象
  @JsonKey(name: 'img')
  dynamic img;
  //  应该是新闻正文的图片
  @JsonKey(name: 'images')
  List<SinaRNImage>? images;

  SinaRollNews({
    this.title,
    this.intro,
    this.keywords,
    this.lids,
    this.author,
    this.url,
    this.wapurl,
    this.mediaName,
    this.ctime,
    this.mtime,
    this.img,
    this.images,
  });

  factory SinaRollNews.fromRawJson(String str) =>
      SinaRollNews.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory SinaRollNews.fromJson(Map<String, dynamic> srcJson) =>
      _$SinaRollNewsFromJson(srcJson);

  Map<String, dynamic> toJson() => _$SinaRollNewsToJson(this);
}

// 图片只保留地址和宽高
@JsonSerializable()
class SinaRNImage {
  @JsonKey(name: 'u')
  String? u;

  // 宽高有的分类是字符串的数字，有的又是int
  @JsonKey(name: 'w')
  dynamic w;

  @JsonKey(name: 'h')
  dynamic h;

  SinaRNImage({
    this.u,
    this.w,
    this.h,
  });

  factory SinaRNImage.fromRawJson(String str) =>
      SinaRNImage.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory SinaRNImage.fromJson(Map<String, dynamic> srcJson) =>
      _$SinaRNImageFromJson(srcJson);

  Map<String, dynamic> toJson() => _$SinaRNImageToJson(this);
}
