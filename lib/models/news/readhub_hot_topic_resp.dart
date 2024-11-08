import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'readhub_hot_topic_resp.g.dart';

///
/// readhub 热门话题的响应
/// 2024-11-05 从网页上看，好像已经是SSR了，这些以前可以用的API都不太行了，
/// 这个热点话题的API不知道还能用多久
/// https://api.readhub.cn/topic/list?page=1&size=5
///
/// 这个API正常请求是最外面有个data，这里就忽略了，http请求时response取data属性就好
///
@JsonSerializable(explicitToJson: true)
class ReadhubHotTopicResp {
  @JsonKey(name: 'totalItems')
  int? totalItems;

  @JsonKey(name: 'startIndex')
  int? startIndex;

  @JsonKey(name: 'pageIndex')
  int? pageIndex;

  @JsonKey(name: 'itemsPerPage')
  int? itemsPerPage;

  @JsonKey(name: 'currentItemCount')
  int? currentItemCount;

  @JsonKey(name: 'totalPages')
  int? totalPages;

  @JsonKey(name: 'items')
  List<ReadhubHotTopicItem>? items;

  ReadhubHotTopicResp({
    this.totalItems,
    this.startIndex,
    this.pageIndex,
    this.itemsPerPage,
    this.currentItemCount,
    this.totalPages,
    this.items,
  });

  factory ReadhubHotTopicResp.fromRawJson(String str) =>
      ReadhubHotTopicResp.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ReadhubHotTopicResp.fromJson(Map<String, dynamic> srcJson) =>
      _$ReadhubHotTopicRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$ReadhubHotTopicRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ReadhubHotTopicItem {
  @JsonKey(name: 'uid')
  String uid;

  @JsonKey(name: 'title')
  String title;

  @JsonKey(name: 'summary')
  String summary;

  @JsonKey(name: 'createdAt')
  String createdAt;

  @JsonKey(name: 'publishDate')
  String publishDate;

  @JsonKey(name: 'siteCount')
  int siteCount;

  @JsonKey(name: 'siteNameDisplay')
  String siteNameDisplay;

  @JsonKey(name: 'newsAggList')
  List<ReadhubNewsAggList>? newsAggList;

  @JsonKey(name: 'timeline')
  ReadhubTimeline? timeline;

  @JsonKey(name: 'entityList')
  List<dynamic>? entityList;

  @JsonKey(name: 'tagList')
  List<dynamic>? tagList;

  @JsonKey(name: 'itemId')
  String itemId;

  @JsonKey(name: 'useful')
  ReadhubUseful? useful;

  ReadhubHotTopicItem({
    required this.uid,
    required this.title,
    required this.summary,
    required this.createdAt,
    required this.publishDate,
    required this.siteCount,
    required this.siteNameDisplay,
    this.newsAggList,
    this.timeline,
    this.entityList,
    this.tagList,
    required this.itemId,
    this.useful,
  });

  factory ReadhubHotTopicItem.fromRawJson(String str) =>
      ReadhubHotTopicItem.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ReadhubHotTopicItem.fromJson(Map<String, dynamic> srcJson) =>
      _$ReadhubHotTopicItemFromJson(srcJson);

  Map<String, dynamic> toJson() => _$ReadhubHotTopicItemToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ReadhubNewsAggList {
  @JsonKey(name: 'uid')
  String uid;

  @JsonKey(name: 'url')
  String url;

  @JsonKey(name: 'title')
  String title;

  @JsonKey(name: 'siteNameDisplay')
  String siteNameDisplay;

  ReadhubNewsAggList(
    this.uid,
    this.url,
    this.title,
    this.siteNameDisplay,
  );

  factory ReadhubNewsAggList.fromRawJson(String str) =>
      ReadhubNewsAggList.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ReadhubNewsAggList.fromJson(Map<String, dynamic> srcJson) =>
      _$ReadhubNewsAggListFromJson(srcJson);

  Map<String, dynamic> toJson() => _$ReadhubNewsAggListToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ReadhubTimeline {
  @JsonKey(name: 'topics')
  List<ReadhubTimelineTopic> topics;

  @JsonKey(name: 'commonEntityList')
  List<dynamic> commonEntityList;

  ReadhubTimeline(
    this.topics,
    this.commonEntityList,
  );

  factory ReadhubTimeline.fromRawJson(String str) =>
      ReadhubTimeline.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ReadhubTimeline.fromJson(Map<String, dynamic> srcJson) =>
      _$ReadhubTimelineFromJson(srcJson);

  Map<String, dynamic> toJson() => _$ReadhubTimelineToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ReadhubTimelineTopic {
  @JsonKey(name: 'uid')
  String uid;

  @JsonKey(name: 'title')
  String title;

  @JsonKey(name: 'createdAt')
  String createdAt;

  @JsonKey(name: 'publishDate')
  String publishDate;

  ReadhubTimelineTopic(
    this.uid,
    this.title,
    this.createdAt,
    this.publishDate,
  );

  factory ReadhubTimelineTopic.fromRawJson(String str) =>
      ReadhubTimelineTopic.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ReadhubTimelineTopic.fromJson(Map<String, dynamic> srcJson) =>
      _$ReadhubTimelineTopicFromJson(srcJson);

  Map<String, dynamic> toJson() => _$ReadhubTimelineTopicToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ReadhubUseful {
  @JsonKey(name: 'count')
  int count;

  @JsonKey(name: 'topicId')
  String topicId;

  ReadhubUseful(
    this.count,
    this.topicId,
  );

  factory ReadhubUseful.fromRawJson(String str) =>
      ReadhubUseful.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ReadhubUseful.fromJson(Map<String, dynamic> srcJson) =>
      _$ReadhubUsefulFromJson(srcJson);

  Map<String, dynamic> toJson() => _$ReadhubUsefulToJson(this);
}
