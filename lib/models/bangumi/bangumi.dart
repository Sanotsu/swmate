import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'bangumi.g.dart';

///
/// bangumi 官方API
/// https://bangumi.github.io/api/
///
/// 主要几个类：
///   查询的参数
///   条目类(条目分为1 为 书籍、2 为 动画、3 为 音乐、4 为 游戏、6 为 三次元)
///   条目中关联的角色或人物或条目(3合1了)
///   角色类
///   人物类
///   角色中的条目和人物中的条目(2合1)
///   角色中的人物和人物中的角色(2合1)
///
/// 关键字查询的响应和上面的条目类还不一样
///

///
/// 这是 /v0/search/subjects 条目查询的参数
///
@JsonSerializable(explicitToJson: true)
class BgmParam {
  @JsonKey(name: 'keyword')
  String? keyword;

  @JsonKey(name: 'sort')
  String? sort;

  @JsonKey(name: 'filter')
  BGMFilter? filter;

  BgmParam({
    this.keyword,
    this.sort = "rank",
    this.filter,
  });

  // 从字符串转
  factory BgmParam.fromRawJson(String str) =>
      BgmParam.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory BgmParam.fromJson(Map<String, dynamic> srcJson) =>
      _$BgmParamFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BgmParamToJson(this);
}

/// 这是条目查询的过滤部分
@JsonSerializable(explicitToJson: true)
class BGMFilter {
  @JsonKey(name: 'type')
  List<int>? type;

  @JsonKey(name: 'tag')
  List<String>? tag;

  @JsonKey(name: 'air_date')
  List<String>? airDate;

  @JsonKey(name: 'rating')
  List<String>? rating;

  @JsonKey(name: 'rank')
  List<String>? rank;

  @JsonKey(name: 'nsfw')
  bool? nsfw;

  BGMFilter({
    this.type,
    this.tag,
    this.airDate,
    this.rating,
    this.rank,
    this.nsfw = false,
  });

  // 从字符串转
  factory BGMFilter.fromRawJson(String str) =>
      BGMFilter.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory BGMFilter.fromJson(Map<String, dynamic> srcJson) =>
      _$BGMFilterFromJson(srcJson);

  Map<String, dynamic> toFullJson() => _$BGMFilterToJson(this);

  // 自定义tojson方法，参数为null的就不加到json中
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (type != null) json['type'] = type;
    if (tag != null) json['tag'] = tag;
    if (airDate != null) json['air_date'] = airDate;
    if (rating != null) json['rating'] = rating;
    if (rank != null) json['rank'] = rank;
    if (nsfw != null) json['nsfw'] = nsfw;

    return json;
  }
}

/// https://api.bgm.tv/v0/search/subjects
/// 条件查询响应
@JsonSerializable(explicitToJson: true)
class BGMSubjectResp {
  @JsonKey(name: 'data')
  List<BGMSubject>? data;

  @JsonKey(name: 'total')
  int? total;

  @JsonKey(name: 'limit')
  int? limit;

  @JsonKey(name: 'offset')
  int? offset;

  BGMSubjectResp({
    this.data,
    this.total,
    this.limit,
    this.offset,
  });

  // 从字符串转
  factory BGMSubjectResp.fromRawJson(String str) =>
      BGMSubjectResp.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory BGMSubjectResp.fromJson(Map<String, dynamic> srcJson) =>
      _$BGMSubjectRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BGMSubjectRespToJson(this);
}

///
/// bgm 查询的条目的响应
///
@JsonSerializable(explicitToJson: true)
class BGMSubject {
  @JsonKey(name: 'date')
  String? date;

  @JsonKey(name: 'image')
  String? image;

  @JsonKey(name: 'type')
  int? type;

  @JsonKey(name: 'summary')
  String? summary;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'name_cn')
  String? nameCn;

  @JsonKey(name: 'tags')
  List<BGMTag>? tags;

  @JsonKey(name: 'score')
  double? score;

  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'rank')
  int? rank;

  @JsonKey(name: 'nsfw')
  bool? nsfw;

  BGMSubject({
    this.date,
    this.image,
    this.type,
    this.summary,
    this.name,
    this.nameCn,
    this.tags,
    this.score,
    this.id,
    this.rank,
    this.nsfw,
  });

  // 从字符串转
  factory BGMSubject.fromRawJson(String str) =>
      BGMSubject.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory BGMSubject.fromJson(Map<String, dynamic> srcJson) =>
      _$BGMSubjectFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BGMSubjectToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BGMTag {
  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'count')
  int? count;

  BGMTag({
    this.name,
    this.count,
  });

  // 从字符串转
  factory BGMTag.fromRawJson(String str) => BGMTag.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory BGMTag.fromJson(Map<String, dynamic> srcJson) =>
      _$BGMTagFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BGMTagToJson(this);
}

///
/// 条目中的人物或角色或条目(3合1)
///
@JsonSerializable(explicitToJson: true)
class BGMSubjectRelation {
  // 这几个条目中的人物或角色中投有
  @JsonKey(name: 'images')
  BGMImage? images;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'relation')
  String? relation;

  @JsonKey(name: 'type')
  int? type;

  @JsonKey(name: 'id')
  int? id;

  // 这几个条目中的人物单独
  @JsonKey(name: 'career')
  List<String>? career;

  @JsonKey(name: 'eps')
  String? eps;

  // 这几个条目中的角色单独
  @JsonKey(name: 'actors')
  List<String>? actors;

  // 这几个条目中的条目单独
  @JsonKey(name: 'name_cn')
  List<String>? nameCn;

  BGMSubjectRelation({
    this.images,
    this.name,
    this.relation,
    this.type,
    this.id,
    this.career,
    this.eps,
    this.actors,
    this.nameCn,
  });

  // 从字符串转
  factory BGMSubjectRelation.fromRawJson(String str) =>
      BGMSubjectRelation.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory BGMSubjectRelation.fromJson(Map<String, dynamic> srcJson) =>
      _$BGMSubjectRelationFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BGMSubjectRelationToJson(this);
}

///
/// bgm 查询的角色条目
///
@JsonSerializable(explicitToJson: true)
class BGMCharacter {
  @JsonKey(name: 'birth_mon')
  int? birthMon;

  @JsonKey(name: 'gender')
  String? gender;

  @JsonKey(name: 'birth_day')
  int? birthDay;

  @JsonKey(name: 'birth_year')
  int? birthYear;

  @JsonKey(name: 'blood_type')
  String? bloodType;

  @JsonKey(name: 'images')
  BGMImage? images;

  @JsonKey(name: 'summary')
  String? summary;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'infobox')
  List<BGMInfobox>? infobox;

  @JsonKey(name: 'stat')
  BGMStat? stat;

  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'locked')
  bool? locked;

  @JsonKey(name: 'type')
  int? type;

  @JsonKey(name: 'nsfw')
  bool? nsfw;

  BGMCharacter({
    this.birthMon,
    this.gender,
    this.birthDay,
    this.birthYear,
    this.bloodType,
    this.images,
    this.summary,
    this.name,
    this.infobox,
    this.stat,
    this.id,
    this.locked,
    this.type,
    this.nsfw,
  });

  // 从字符串转
  factory BGMCharacter.fromRawJson(String str) =>
      BGMCharacter.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory BGMCharacter.fromJson(Map<String, dynamic> srcJson) =>
      _$BGMCharacterFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BGMCharacterToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BGMImage {
  @JsonKey(name: 'small')
  String? small;

  @JsonKey(name: 'grid')
  String? grid;

  @JsonKey(name: 'large')
  String? large;

  @JsonKey(name: 'medium')
  String? medium;

  BGMImage({
    this.small,
    this.grid,
    this.large,
    this.medium,
  });

  // 从字符串转
  factory BGMImage.fromRawJson(String str) =>
      BGMImage.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory BGMImage.fromJson(Map<String, dynamic> srcJson) =>
      _$BGMImageFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BGMImageToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BGMInfobox {
  @JsonKey(name: 'key')
  String? key;

  // 这个名称信息，可以是直接的名称String格式：  "value": "枢木朱雀"
  // 还可能是其他别名的Lisy<Map<String,String>>： "value":[{"k": "第二中文名","v": "白色骑士"},……]
  @JsonKey(name: 'value')
  dynamic value;

  BGMInfobox({
    this.key,
    this.value,
  });

  // 从字符串转
  factory BGMInfobox.fromRawJson(String str) =>
      BGMInfobox.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory BGMInfobox.fromJson(Map<String, dynamic> srcJson) =>
      _$BGMInfoboxFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BGMInfoboxToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BGMStat {
  // 评论数
  @JsonKey(name: 'comments')
  int? comments;

  // 添加到合集的数量
  @JsonKey(name: 'collects')
  int? collects;

  BGMStat({
    this.comments,
    this.collects,
  });

  // 从字符串转
  factory BGMStat.fromRawJson(String str) => BGMStat.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory BGMStat.fromJson(Map<String, dynamic> srcJson) =>
      _$BGMStatFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BGMStatToJson(this);
}

///
/// bgm中的人物
/// 人物和角色有一些相同的栏位，但也有很多不同的栏位
///
@JsonSerializable(explicitToJson: true)
class BGMPerson {
  @JsonKey(name: 'last_modified')
  String? lastModified;

  @JsonKey(name: 'blood_type')
  String? bloodType;

  @JsonKey(name: 'birth_year')
  int? birthYear;

  @JsonKey(name: 'birth_day')
  int? birthDay;

  @JsonKey(name: 'birth_mon')
  int? birthMon;

  @JsonKey(name: 'gender')
  String? gender;

  @JsonKey(name: 'images')
  BGMImage? images;

  @JsonKey(name: 'summary')
  String? summary;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'img')
  String? img;

  @JsonKey(name: 'infobox')
  List<BGMInfobox>? infobox;

  @JsonKey(name: 'career')
  List<String>? career;

  @JsonKey(name: 'stat')
  BGMStat? stat;

  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'locked')
  bool? locked;

  @JsonKey(name: 'type')
  int? type;

  BGMPerson({
    this.lastModified,
    this.bloodType,
    this.birthYear,
    this.birthDay,
    this.birthMon,
    this.gender,
    this.images,
    this.summary,
    this.name,
    this.img,
    this.infobox,
    this.career,
    this.stat,
    this.id,
    this.locked,
    this.type,
  });

  // 从字符串转
  factory BGMPerson.fromRawJson(String str) =>
      BGMPerson.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory BGMPerson.fromJson(Map<String, dynamic> srcJson) =>
      _$BGMPersonFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BGMPersonToJson(this);
}

///
/// 角色关联的项目
/// 人物关联的项目
/// (两者一样)
///
@JsonSerializable(explicitToJson: true)
class BGMRelatedSubject {
  @JsonKey(name: 'staff')
  String? staff;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'name_cn')
  String? nameCn;

  @JsonKey(name: 'image')
  String? image;

  @JsonKey(name: 'type')
  int? type;

  @JsonKey(name: 'id')
  int? id;

  BGMRelatedSubject({
    this.staff,
    this.name,
    this.nameCn,
    this.image,
    this.type,
    this.id,
  });

  // 从字符串转
  factory BGMRelatedSubject.fromRawJson(String str) =>
      BGMRelatedSubject.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory BGMRelatedSubject.fromJson(Map<String, dynamic> srcJson) =>
      _$BGMRelatedSubjectFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BGMRelatedSubjectToJson(this);
}

///
/// 角色关联的人物
/// 人物关联的角色
/// (两者一样)
///
@JsonSerializable(explicitToJson: true)
class BGMRelatedCharacterPerson {
  @JsonKey(name: 'images')
  BGMImage? images;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'subject_name')
  String? subjectName;

  @JsonKey(name: 'subject_name_cn')
  String? subjectNameCn;

  @JsonKey(name: 'subject_type')
  int? subjectType;

  @JsonKey(name: 'subject_id')
  int? subjectId;

  @JsonKey(name: 'staff')
  String? staff;

  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'type')
  int? type;

  BGMRelatedCharacterPerson({
    this.images,
    this.name,
    this.subjectName,
    this.subjectNameCn,
    this.subjectType,
    this.subjectId,
    this.staff,
    this.id,
    this.type,
  });

  // 从字符串转
  factory BGMRelatedCharacterPerson.fromRawJson(String str) =>
      BGMRelatedCharacterPerson.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory BGMRelatedCharacterPerson.fromJson(Map<String, dynamic> srcJson) =>
      _$BGMRelatedCharacterPersonFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BGMRelatedCharacterPersonToJson(this);
}

///
/// /search/subject/{keywords}
///
///  这个和每日放送/calendar没有/v0前缀，其他的有，所以响应结构不一样
///
/// 条件查询的条目(和上面post查询的响应不一样)
/// 就连images的响应结构也不一样,大概内容都有了，除了管理的角色和人物等
/// 栏位的数量和查询条件的responseGroup有关：
///   large最全，
///   medium没有 rating，
///   small没有rating、collection、summary的值、eps、eps_count
///
@JsonSerializable(explicitToJson: true)
class BGMLargeSubjectResp {
  @JsonKey(name: 'results')
  int? results;

  @JsonKey(name: 'list')
  List<BGMLargeSubject>? list;

  BGMLargeSubjectResp({
    this.results,
    this.list,
  });

  // 从字符串转
  factory BGMLargeSubjectResp.fromRawJson(String str) =>
      BGMLargeSubjectResp.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory BGMLargeSubjectResp.fromJson(Map<String, dynamic> srcJson) =>
      _$BGMLargeSubjectRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BGMLargeSubjectRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BGMLargeSubject {
  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'url')
  String? url;

  @JsonKey(name: 'type')
  int? type;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'name_cn')
  String? nameCn;

  @JsonKey(name: 'summary')
  String? summary;

  @JsonKey(name: 'eps')
  int? eps;

  @JsonKey(name: 'eps_count')
  int? epsCount;

  @JsonKey(name: 'air_date')
  String? airDate;

  @JsonKey(name: 'air_weekday')
  int? airWeekday;

  @JsonKey(name: 'rating')
  BGMLargeRating? rating;

  @JsonKey(name: 'images')
  BGMLargeImage? images;

  @JsonKey(name: 'collection')
  BGMLargeCollection? collection;

  // 条件查询中没有此栏位，但每日放送中有
  @JsonKey(name: 'rank')
  int? rank;

  BGMLargeSubject({
    this.id,
    this.url,
    this.type,
    this.name,
    this.nameCn,
    this.summary,
    this.eps,
    this.epsCount,
    this.airDate,
    this.airWeekday,
    this.rating,
    this.images,
    this.collection,
    this.rank,
  });

  // 从字符串转
  factory BGMLargeSubject.fromRawJson(String str) =>
      BGMLargeSubject.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory BGMLargeSubject.fromJson(Map<String, dynamic> srcJson) =>
      _$BGMLargeSubjectFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BGMLargeSubjectToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BGMLargeRating {
  @JsonKey(name: 'total')
  int? total;

  @JsonKey(name: 'count')
  BGMLargeCount? count;

  @JsonKey(name: 'score')
  double? score;

  BGMLargeRating({
    this.total,
    this.count,
    this.score,
  });

  // 从字符串转
  factory BGMLargeRating.fromRawJson(String str) =>
      BGMLargeRating.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory BGMLargeRating.fromJson(Map<String, dynamic> srcJson) =>
      _$BGMLargeRatingFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BGMLargeRatingToJson(this);
}

// 评分各个分数的占比
@JsonSerializable(explicitToJson: true)
class BGMLargeCount {
  @JsonKey(name: '1')
  int? s1;

  @JsonKey(name: '2')
  int? s2;

  @JsonKey(name: '3')
  int? s3;

  @JsonKey(name: '4')
  int? s4;

  @JsonKey(name: '5')
  int? s5;

  @JsonKey(name: '6')
  int? s6;

  @JsonKey(name: '7')
  int? s7;

  @JsonKey(name: '8')
  int? s8;

  @JsonKey(name: '9')
  int? s9;

  @JsonKey(name: '10')
  int? s10;

  BGMLargeCount({
    this.s1,
    this.s2,
    this.s3,
    this.s4,
    this.s5,
    this.s6,
    this.s7,
    this.s8,
    this.s9,
    this.s10,
  });

  // 从字符串转
  factory BGMLargeCount.fromRawJson(String str) =>
      BGMLargeCount.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory BGMLargeCount.fromJson(Map<String, dynamic> srcJson) =>
      _$BGMLargeCountFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BGMLargeCountToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BGMLargeImage {
  @JsonKey(name: 'large')
  String? large;

  @JsonKey(name: 'common')
  String? common;

  @JsonKey(name: 'medium')
  String? medium;

  @JsonKey(name: 'small')
  String? small;

  @JsonKey(name: 'grid')
  String? grid;

  BGMLargeImage({
    this.large,
    this.common,
    this.medium,
    this.small,
    this.grid,
  });

  // 从字符串转
  factory BGMLargeImage.fromRawJson(String str) =>
      BGMLargeImage.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory BGMLargeImage.fromJson(Map<String, dynamic> srcJson) =>
      _$BGMLargeImageFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BGMLargeImageToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BGMLargeCollection {
  @JsonKey(name: 'wish')
  int? wish;

  @JsonKey(name: 'collect')
  int? collect;

  @JsonKey(name: 'doing')
  int? doing;

  @JsonKey(name: 'on_hold')
  int? onHold;

  @JsonKey(name: 'dropped')
  int? dropped;

  BGMLargeCollection({
    this.wish,
    this.collect,
    this.doing,
    this.onHold,
    this.dropped,
  });

  // 从字符串转
  factory BGMLargeCollection.fromRawJson(String str) =>
      BGMLargeCollection.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory BGMLargeCollection.fromJson(Map<String, dynamic> srcJson) =>
      _$BGMLargeCollectionFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BGMLargeCollectionToJson(this);
}

///
/// 每日放送，当天有哪些更新的
/// 内容就是条件查询的条目，比该接口多个rank
///
@JsonSerializable(explicitToJson: true)
class BGMLargeCalendar {
  @JsonKey(name: 'weekday')
  BGMLargeWeekday? weekday;

  @JsonKey(name: 'items')
  List<BGMLargeSubject>? items;

  BGMLargeCalendar({
    this.weekday,
    this.items,
  });

  // 从字符串转
  factory BGMLargeCalendar.fromRawJson(String str) =>
      BGMLargeCalendar.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory BGMLargeCalendar.fromJson(Map<String, dynamic> srcJson) =>
      _$BGMLargeCalendarFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BGMLargeCalendarToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BGMLargeWeekday {
  @JsonKey(name: 'en')
  String? en;

  @JsonKey(name: 'cn')
  String? cn;

  @JsonKey(name: 'ja')
  String? ja;

  @JsonKey(name: 'id')
  int? id;

  BGMLargeWeekday({
    this.en,
    this.cn,
    this.ja,
    this.id,
  });

  // 从字符串转
  factory BGMLargeWeekday.fromRawJson(String str) =>
      BGMLargeWeekday.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory BGMLargeWeekday.fromJson(Map<String, dynamic> srcJson) =>
      _$BGMLargeWeekdayFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BGMLargeWeekdayToJson(this);
}
