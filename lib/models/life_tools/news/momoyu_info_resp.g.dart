// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'momoyu_info_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MomoyuInfoResp<T> _$MomoyuInfoRespFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    MomoyuInfoResp<T>(
      status: (json['status'] as num?)?.toInt(),
      message: json['message'] as String?,
      data: _$nullableGenericFromJson(json['data'], fromJsonT),
    );

Map<String, dynamic> _$MomoyuInfoRespToJson<T>(
  MomoyuInfoResp<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'data': _$nullableGenericToJson(instance.data, toJsonT),
    };

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) =>
    input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) =>
    input == null ? null : toJson(input);

ListWithT<T> _$ListWithTFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    ListWithT<T>(
      (json['list'] as List<dynamic>?)?.map(fromJsonT).toList(),
    );

Map<String, dynamic> _$ListWithTToJson<T>(
  ListWithT<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'list': instance.list?.map(toJsonT).toList(),
    };

MMYCateData _$MMYCateDataFromJson(Map<String, dynamic> json) => MMYCateData(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => MMYData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MMYCateDataToJson(MMYCateData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'data': instance.data?.map((e) => e.toJson()).toList(),
    };

MMYData _$MMYDataFromJson(Map<String, dynamic> json) => MMYData(
      id: (json['id'] as num?)?.toInt(),
      sort: (json['sort'] as num?)?.toInt(),
      name: json['name'] as String?,
      sourceKey: json['source_key'] as String?,
      iconColor: json['icon_color'] as String?,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => MMYDataItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createTime: json['create_time'] as String?,
    );

Map<String, dynamic> _$MMYDataToJson(MMYData instance) => <String, dynamic>{
      'id': instance.id,
      'sort': instance.sort,
      'name': instance.name,
      'source_key': instance.sourceKey,
      'icon_color': instance.iconColor,
      'data': instance.data?.map((e) => e.toJson()).toList(),
      'create_time': instance.createTime,
    };

MMYIdData _$MMYIdDataFromJson(Map<String, dynamic> json) => MMYIdData(
      time: json['time'] as String?,
      list: (json['list'] as List<dynamic>?)
          ?.map((e) => MMYDataItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MMYIdDataToJson(MMYIdData instance) => <String, dynamic>{
      'time': instance.time,
      'list': instance.list?.map((e) => e.toJson()).toList(),
    };

MMYDataItem _$MMYDataItemFromJson(Map<String, dynamic> json) => MMYDataItem(
      id: (json['id'] as num?)?.toInt(),
      title: json['title'] as String?,
      extra: json['extra'] as String?,
      link: json['link'] as String?,
    );

Map<String, dynamic> _$MMYDataItemToJson(MMYDataItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'extra': instance.extra,
      'link': instance.link,
    };
