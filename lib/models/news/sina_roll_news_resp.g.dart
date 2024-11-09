// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sina_roll_news_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SinaRollNewsResp _$SinaRollNewsRespFromJson(Map<String, dynamic> json) =>
    SinaRollNewsResp(
      status: json['status'] == null
          ? null
          : SinaRNStatus.fromJson(json['status'] as Map<String, dynamic>),
      timestamp: json['timestamp'] as String?,
      total: (json['total'] as num?)?.toInt(),
      lid: (json['lid'] as num?)?.toInt(),
      rtime: (json['rtime'] as num?)?.toInt(),
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => SinaRollNews.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SinaRollNewsRespToJson(SinaRollNewsResp instance) =>
    <String, dynamic>{
      'status': instance.status?.toJson(),
      'timestamp': instance.timestamp,
      'rtime': instance.rtime,
      'total': instance.total,
      'lid': instance.lid,
      'data': instance.data?.map((e) => e.toJson()).toList(),
    };

SinaRNStatus _$SinaRNStatusFromJson(Map<String, dynamic> json) => SinaRNStatus(
      code: (json['code'] as num?)?.toInt(),
      msg: json['msg'] as String?,
    );

Map<String, dynamic> _$SinaRNStatusToJson(SinaRNStatus instance) =>
    <String, dynamic>{
      'code': instance.code,
      'msg': instance.msg,
    };

SinaRollNews _$SinaRollNewsFromJson(Map<String, dynamic> json) => SinaRollNews(
      title: json['title'] as String?,
      intro: json['intro'] as String?,
      keywords: json['keywords'] as String?,
      lids: json['lids'] as String?,
      author: json['author'] as String?,
      url: json['url'] as String?,
      wapurl: json['wapurl'] as String?,
      mediaName: json['media_name'] as String?,
      ctime: json['ctime'] as String?,
      mtime: json['mtime'] as String?,
      img: json['img'],
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => SinaRNImage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SinaRollNewsToJson(SinaRollNews instance) =>
    <String, dynamic>{
      'title': instance.title,
      'intro': instance.intro,
      'keywords': instance.keywords,
      'lids': instance.lids,
      'media_name': instance.mediaName,
      'author': instance.author,
      'url': instance.url,
      'wapurl': instance.wapurl,
      'ctime': instance.ctime,
      'mtime': instance.mtime,
      'img': instance.img,
      'images': instance.images?.map((e) => e.toJson()).toList(),
    };

SinaRNImage _$SinaRNImageFromJson(Map<String, dynamic> json) => SinaRNImage(
      u: json['u'] as String?,
      w: json['w'],
      h: json['h'],
    );

Map<String, dynamic> _$SinaRNImageToJson(SinaRNImage instance) =>
    <String, dynamic>{
      'u': instance.u,
      'w': instance.w,
      'h': instance.h,
    };
