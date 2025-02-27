// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'readhub_hot_topic_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReadhubHotTopicResp _$ReadhubHotTopicRespFromJson(Map<String, dynamic> json) =>
    ReadhubHotTopicResp(
      totalItems: (json['totalItems'] as num?)?.toInt(),
      startIndex: (json['startIndex'] as num?)?.toInt(),
      pageIndex: (json['pageIndex'] as num?)?.toInt(),
      itemsPerPage: (json['itemsPerPage'] as num?)?.toInt(),
      currentItemCount: (json['currentItemCount'] as num?)?.toInt(),
      totalPages: (json['totalPages'] as num?)?.toInt(),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => ReadhubHotTopicItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ReadhubHotTopicRespToJson(
        ReadhubHotTopicResp instance) =>
    <String, dynamic>{
      'totalItems': instance.totalItems,
      'startIndex': instance.startIndex,
      'pageIndex': instance.pageIndex,
      'itemsPerPage': instance.itemsPerPage,
      'currentItemCount': instance.currentItemCount,
      'totalPages': instance.totalPages,
      'items': instance.items?.map((e) => e.toJson()).toList(),
    };

ReadhubHotTopicItem _$ReadhubHotTopicItemFromJson(Map<String, dynamic> json) =>
    ReadhubHotTopicItem(
      uid: json['uid'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      createdAt: json['createdAt'] as String,
      publishDate: json['publishDate'] as String,
      siteCount: (json['siteCount'] as num).toInt(),
      siteNameDisplay: json['siteNameDisplay'] as String,
      newsAggList: (json['newsAggList'] as List<dynamic>?)
          ?.map((e) => ReadhubNewsAggList.fromJson(e as Map<String, dynamic>))
          .toList(),
      timeline: json['timeline'] == null
          ? null
          : ReadhubTimeline.fromJson(json['timeline'] as Map<String, dynamic>),
      entityList: json['entityList'] as List<dynamic>?,
      tagList: json['tagList'] as List<dynamic>?,
      itemId: json['itemId'] as String,
      useful: json['useful'] == null
          ? null
          : ReadhubUseful.fromJson(json['useful'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ReadhubHotTopicItemToJson(
        ReadhubHotTopicItem instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'title': instance.title,
      'summary': instance.summary,
      'createdAt': instance.createdAt,
      'publishDate': instance.publishDate,
      'siteCount': instance.siteCount,
      'siteNameDisplay': instance.siteNameDisplay,
      'newsAggList': instance.newsAggList?.map((e) => e.toJson()).toList(),
      'timeline': instance.timeline?.toJson(),
      'entityList': instance.entityList,
      'tagList': instance.tagList,
      'itemId': instance.itemId,
      'useful': instance.useful?.toJson(),
    };

ReadhubNewsAggList _$ReadhubNewsAggListFromJson(Map<String, dynamic> json) =>
    ReadhubNewsAggList(
      json['uid'] as String,
      json['url'] as String,
      json['title'] as String,
      json['siteNameDisplay'] as String,
    );

Map<String, dynamic> _$ReadhubNewsAggListToJson(ReadhubNewsAggList instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'url': instance.url,
      'title': instance.title,
      'siteNameDisplay': instance.siteNameDisplay,
    };

ReadhubTimeline _$ReadhubTimelineFromJson(Map<String, dynamic> json) =>
    ReadhubTimeline(
      (json['topics'] as List<dynamic>)
          .map((e) => ReadhubTimelineTopic.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['commonEntityList'] as List<dynamic>,
    );

Map<String, dynamic> _$ReadhubTimelineToJson(ReadhubTimeline instance) =>
    <String, dynamic>{
      'topics': instance.topics.map((e) => e.toJson()).toList(),
      'commonEntityList': instance.commonEntityList,
    };

ReadhubTimelineTopic _$ReadhubTimelineTopicFromJson(
        Map<String, dynamic> json) =>
    ReadhubTimelineTopic(
      json['uid'] as String,
      json['title'] as String,
      json['createdAt'] as String,
      json['publishDate'] as String,
    );

Map<String, dynamic> _$ReadhubTimelineTopicToJson(
        ReadhubTimelineTopic instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'title': instance.title,
      'createdAt': instance.createdAt,
      'publishDate': instance.publishDate,
    };

ReadhubUseful _$ReadhubUsefulFromJson(Map<String, dynamic> json) =>
    ReadhubUseful(
      (json['count'] as num).toInt(),
      json['topicId'] as String,
    );

Map<String, dynamic> _$ReadhubUsefulToJson(ReadhubUseful instance) =>
    <String, dynamic>{
      'count': instance.count,
      'topicId': instance.topicId,
    };
