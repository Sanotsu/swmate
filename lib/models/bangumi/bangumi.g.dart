// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bangumi.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BgmParam _$BgmParamFromJson(Map<String, dynamic> json) => BgmParam(
      keyword: json['keyword'] as String?,
      sort: json['sort'] as String? ?? "rank",
      filter: json['filter'] == null
          ? null
          : BGMFilter.fromJson(json['filter'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BgmParamToJson(BgmParam instance) => <String, dynamic>{
      'keyword': instance.keyword,
      'sort': instance.sort,
      'filter': instance.filter?.toJson(),
    };

BGMFilter _$BGMFilterFromJson(Map<String, dynamic> json) => BGMFilter(
      type: (json['type'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      tag: (json['tag'] as List<dynamic>?)?.map((e) => e as String).toList(),
      airDate: (json['air_date'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      rating:
          (json['rating'] as List<dynamic>?)?.map((e) => e as String).toList(),
      rank: (json['rank'] as List<dynamic>?)?.map((e) => e as String).toList(),
      nsfw: json['nsfw'] as bool? ?? false,
    );

Map<String, dynamic> _$BGMFilterToJson(BGMFilter instance) => <String, dynamic>{
      'type': instance.type,
      'tag': instance.tag,
      'air_date': instance.airDate,
      'rating': instance.rating,
      'rank': instance.rank,
      'nsfw': instance.nsfw,
    };

BGMSubjectResp _$BGMSubjectRespFromJson(Map<String, dynamic> json) =>
    BGMSubjectResp(
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => BGMSubject.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt(),
      limit: (json['limit'] as num?)?.toInt(),
      offset: (json['offset'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BGMSubjectRespToJson(BGMSubjectResp instance) =>
    <String, dynamic>{
      'data': instance.data?.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'limit': instance.limit,
      'offset': instance.offset,
    };

BGMSubject _$BGMSubjectFromJson(Map<String, dynamic> json) => BGMSubject(
      date: json['date'] as String?,
      image: json['image'] as String?,
      type: (json['type'] as num?)?.toInt(),
      summary: json['summary'] as String?,
      name: json['name'] as String?,
      nameCn: json['name_cn'] as String?,
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => BGMTag.fromJson(e as Map<String, dynamic>))
          .toList(),
      score: (json['score'] as num?)?.toDouble(),
      id: (json['id'] as num?)?.toInt(),
      rank: (json['rank'] as num?)?.toInt(),
      nsfw: json['nsfw'] as bool?,
    );

Map<String, dynamic> _$BGMSubjectToJson(BGMSubject instance) =>
    <String, dynamic>{
      'date': instance.date,
      'image': instance.image,
      'type': instance.type,
      'summary': instance.summary,
      'name': instance.name,
      'name_cn': instance.nameCn,
      'tags': instance.tags?.map((e) => e.toJson()).toList(),
      'score': instance.score,
      'id': instance.id,
      'rank': instance.rank,
      'nsfw': instance.nsfw,
    };

BGMTag _$BGMTagFromJson(Map<String, dynamic> json) => BGMTag(
      name: json['name'] as String?,
      count: (json['count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BGMTagToJson(BGMTag instance) => <String, dynamic>{
      'name': instance.name,
      'count': instance.count,
    };

BGMSubjectRelation _$BGMSubjectRelationFromJson(Map<String, dynamic> json) =>
    BGMSubjectRelation(
      images: json['images'] == null
          ? null
          : BGMImage.fromJson(json['images'] as Map<String, dynamic>),
      name: json['name'] as String?,
      relation: json['relation'] as String?,
      type: (json['type'] as num?)?.toInt(),
      id: (json['id'] as num?)?.toInt(),
      career:
          (json['career'] as List<dynamic>?)?.map((e) => e as String).toList(),
      eps: json['eps'] as String?,
      actors:
          (json['actors'] as List<dynamic>?)?.map((e) => e as String).toList(),
      nameCn:
          (json['name_cn'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$BGMSubjectRelationToJson(BGMSubjectRelation instance) =>
    <String, dynamic>{
      'images': instance.images?.toJson(),
      'name': instance.name,
      'relation': instance.relation,
      'type': instance.type,
      'id': instance.id,
      'career': instance.career,
      'eps': instance.eps,
      'actors': instance.actors,
      'name_cn': instance.nameCn,
    };

BGMCharacter _$BGMCharacterFromJson(Map<String, dynamic> json) => BGMCharacter(
      birthMon: (json['birth_mon'] as num?)?.toInt(),
      gender: json['gender'] as String?,
      birthDay: (json['birth_day'] as num?)?.toInt(),
      birthYear: (json['birth_year'] as num?)?.toInt(),
      bloodType: json['blood_type'] as String?,
      images: json['images'] == null
          ? null
          : BGMImage.fromJson(json['images'] as Map<String, dynamic>),
      summary: json['summary'] as String?,
      name: json['name'] as String?,
      infobox: (json['infobox'] as List<dynamic>?)
          ?.map((e) => BGMInfobox.fromJson(e as Map<String, dynamic>))
          .toList(),
      stat: json['stat'] == null
          ? null
          : BGMStat.fromJson(json['stat'] as Map<String, dynamic>),
      id: (json['id'] as num?)?.toInt(),
      locked: json['locked'] as bool?,
      type: (json['type'] as num?)?.toInt(),
      nsfw: json['nsfw'] as bool?,
    );

Map<String, dynamic> _$BGMCharacterToJson(BGMCharacter instance) =>
    <String, dynamic>{
      'birth_mon': instance.birthMon,
      'gender': instance.gender,
      'birth_day': instance.birthDay,
      'birth_year': instance.birthYear,
      'blood_type': instance.bloodType,
      'images': instance.images?.toJson(),
      'summary': instance.summary,
      'name': instance.name,
      'infobox': instance.infobox?.map((e) => e.toJson()).toList(),
      'stat': instance.stat?.toJson(),
      'id': instance.id,
      'locked': instance.locked,
      'type': instance.type,
      'nsfw': instance.nsfw,
    };

BGMImage _$BGMImageFromJson(Map<String, dynamic> json) => BGMImage(
      small: json['small'] as String?,
      grid: json['grid'] as String?,
      large: json['large'] as String?,
      medium: json['medium'] as String?,
    );

Map<String, dynamic> _$BGMImageToJson(BGMImage instance) => <String, dynamic>{
      'small': instance.small,
      'grid': instance.grid,
      'large': instance.large,
      'medium': instance.medium,
    };

BGMInfobox _$BGMInfoboxFromJson(Map<String, dynamic> json) => BGMInfobox(
      key: json['key'] as String?,
      value: json['value'],
    );

Map<String, dynamic> _$BGMInfoboxToJson(BGMInfobox instance) =>
    <String, dynamic>{
      'key': instance.key,
      'value': instance.value,
    };

BGMStat _$BGMStatFromJson(Map<String, dynamic> json) => BGMStat(
      comments: (json['comments'] as num?)?.toInt(),
      collects: (json['collects'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BGMStatToJson(BGMStat instance) => <String, dynamic>{
      'comments': instance.comments,
      'collects': instance.collects,
    };

BGMPerson _$BGMPersonFromJson(Map<String, dynamic> json) => BGMPerson(
      lastModified: json['last_modified'] as String?,
      bloodType: json['blood_type'] as String?,
      birthYear: (json['birth_year'] as num?)?.toInt(),
      birthDay: (json['birth_day'] as num?)?.toInt(),
      birthMon: (json['birth_mon'] as num?)?.toInt(),
      gender: json['gender'] as String?,
      images: json['images'] == null
          ? null
          : BGMImage.fromJson(json['images'] as Map<String, dynamic>),
      summary: json['summary'] as String?,
      name: json['name'] as String?,
      img: json['img'] as String?,
      infobox: (json['infobox'] as List<dynamic>?)
          ?.map((e) => BGMInfobox.fromJson(e as Map<String, dynamic>))
          .toList(),
      career:
          (json['career'] as List<dynamic>?)?.map((e) => e as String).toList(),
      stat: json['stat'] == null
          ? null
          : BGMStat.fromJson(json['stat'] as Map<String, dynamic>),
      id: (json['id'] as num?)?.toInt(),
      locked: json['locked'] as bool?,
      type: (json['type'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BGMPersonToJson(BGMPerson instance) => <String, dynamic>{
      'last_modified': instance.lastModified,
      'blood_type': instance.bloodType,
      'birth_year': instance.birthYear,
      'birth_day': instance.birthDay,
      'birth_mon': instance.birthMon,
      'gender': instance.gender,
      'images': instance.images?.toJson(),
      'summary': instance.summary,
      'name': instance.name,
      'img': instance.img,
      'infobox': instance.infobox?.map((e) => e.toJson()).toList(),
      'career': instance.career,
      'stat': instance.stat?.toJson(),
      'id': instance.id,
      'locked': instance.locked,
      'type': instance.type,
    };

BGMRelatedSubject _$BGMRelatedSubjectFromJson(Map<String, dynamic> json) =>
    BGMRelatedSubject(
      staff: json['staff'] as String?,
      name: json['name'] as String?,
      nameCn: json['name_cn'] as String?,
      image: json['image'] as String?,
      type: (json['type'] as num?)?.toInt(),
      id: (json['id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BGMRelatedSubjectToJson(BGMRelatedSubject instance) =>
    <String, dynamic>{
      'staff': instance.staff,
      'name': instance.name,
      'name_cn': instance.nameCn,
      'image': instance.image,
      'type': instance.type,
      'id': instance.id,
    };

BGMRelatedCharacterPerson _$BGMRelatedCharacterPersonFromJson(
        Map<String, dynamic> json) =>
    BGMRelatedCharacterPerson(
      images: json['images'] == null
          ? null
          : BGMImage.fromJson(json['images'] as Map<String, dynamic>),
      name: json['name'] as String?,
      subjectName: json['subject_name'] as String?,
      subjectNameCn: json['subject_name_cn'] as String?,
      subjectType: (json['subject_type'] as num?)?.toInt(),
      subjectId: (json['subject_id'] as num?)?.toInt(),
      staff: json['staff'] as String?,
      id: (json['id'] as num?)?.toInt(),
      type: (json['type'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BGMRelatedCharacterPersonToJson(
        BGMRelatedCharacterPerson instance) =>
    <String, dynamic>{
      'images': instance.images?.toJson(),
      'name': instance.name,
      'subject_name': instance.subjectName,
      'subject_name_cn': instance.subjectNameCn,
      'subject_type': instance.subjectType,
      'subject_id': instance.subjectId,
      'staff': instance.staff,
      'id': instance.id,
      'type': instance.type,
    };

BGMLargeSubjectResp _$BGMLargeSubjectRespFromJson(Map<String, dynamic> json) =>
    BGMLargeSubjectResp(
      results: (json['results'] as num?)?.toInt(),
      list: (json['list'] as List<dynamic>?)
          ?.map((e) => BGMLargeSubject.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BGMLargeSubjectRespToJson(
        BGMLargeSubjectResp instance) =>
    <String, dynamic>{
      'results': instance.results,
      'list': instance.list?.map((e) => e.toJson()).toList(),
    };

BGMLargeSubject _$BGMLargeSubjectFromJson(Map<String, dynamic> json) =>
    BGMLargeSubject(
      id: (json['id'] as num?)?.toInt(),
      url: json['url'] as String?,
      type: (json['type'] as num?)?.toInt(),
      name: json['name'] as String?,
      nameCn: json['name_cn'] as String?,
      summary: json['summary'] as String?,
      eps: (json['eps'] as num?)?.toInt(),
      epsCount: (json['eps_count'] as num?)?.toInt(),
      airDate: json['air_date'] as String?,
      airWeekday: (json['air_weekday'] as num?)?.toInt(),
      rating: json['rating'] == null
          ? null
          : BGMLargeRating.fromJson(json['rating'] as Map<String, dynamic>),
      images: json['images'] == null
          ? null
          : BGMLargeImage.fromJson(json['images'] as Map<String, dynamic>),
      collection: json['collection'] == null
          ? null
          : BGMLargeCollection.fromJson(
              json['collection'] as Map<String, dynamic>),
      rank: (json['rank'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BGMLargeSubjectToJson(BGMLargeSubject instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'type': instance.type,
      'name': instance.name,
      'name_cn': instance.nameCn,
      'summary': instance.summary,
      'eps': instance.eps,
      'eps_count': instance.epsCount,
      'air_date': instance.airDate,
      'air_weekday': instance.airWeekday,
      'rating': instance.rating?.toJson(),
      'images': instance.images?.toJson(),
      'collection': instance.collection?.toJson(),
      'rank': instance.rank,
    };

BGMLargeRating _$BGMLargeRatingFromJson(Map<String, dynamic> json) =>
    BGMLargeRating(
      total: (json['total'] as num?)?.toInt(),
      count: json['count'] == null
          ? null
          : BGMLargeCount.fromJson(json['count'] as Map<String, dynamic>),
      score: (json['score'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$BGMLargeRatingToJson(BGMLargeRating instance) =>
    <String, dynamic>{
      'total': instance.total,
      'count': instance.count?.toJson(),
      'score': instance.score,
    };

BGMLargeCount _$BGMLargeCountFromJson(Map<String, dynamic> json) =>
    BGMLargeCount(
      s1: (json['1'] as num?)?.toInt(),
      s2: (json['2'] as num?)?.toInt(),
      s3: (json['3'] as num?)?.toInt(),
      s4: (json['4'] as num?)?.toInt(),
      s5: (json['5'] as num?)?.toInt(),
      s6: (json['6'] as num?)?.toInt(),
      s7: (json['7'] as num?)?.toInt(),
      s8: (json['8'] as num?)?.toInt(),
      s9: (json['9'] as num?)?.toInt(),
      s10: (json['10'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BGMLargeCountToJson(BGMLargeCount instance) =>
    <String, dynamic>{
      '1': instance.s1,
      '2': instance.s2,
      '3': instance.s3,
      '4': instance.s4,
      '5': instance.s5,
      '6': instance.s6,
      '7': instance.s7,
      '8': instance.s8,
      '9': instance.s9,
      '10': instance.s10,
    };

BGMLargeImage _$BGMLargeImageFromJson(Map<String, dynamic> json) =>
    BGMLargeImage(
      large: json['large'] as String?,
      common: json['common'] as String?,
      medium: json['medium'] as String?,
      small: json['small'] as String?,
      grid: json['grid'] as String?,
    );

Map<String, dynamic> _$BGMLargeImageToJson(BGMLargeImage instance) =>
    <String, dynamic>{
      'large': instance.large,
      'common': instance.common,
      'medium': instance.medium,
      'small': instance.small,
      'grid': instance.grid,
    };

BGMLargeCollection _$BGMLargeCollectionFromJson(Map<String, dynamic> json) =>
    BGMLargeCollection(
      wish: (json['wish'] as num?)?.toInt(),
      collect: (json['collect'] as num?)?.toInt(),
      doing: (json['doing'] as num?)?.toInt(),
      onHold: (json['on_hold'] as num?)?.toInt(),
      dropped: (json['dropped'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BGMLargeCollectionToJson(BGMLargeCollection instance) =>
    <String, dynamic>{
      'wish': instance.wish,
      'collect': instance.collect,
      'doing': instance.doing,
      'on_hold': instance.onHold,
      'dropped': instance.dropped,
    };

BGMLargeCalendar _$BGMLargeCalendarFromJson(Map<String, dynamic> json) =>
    BGMLargeCalendar(
      weekday: json['weekday'] == null
          ? null
          : BGMLargeWeekday.fromJson(json['weekday'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => BGMLargeSubject.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BGMLargeCalendarToJson(BGMLargeCalendar instance) =>
    <String, dynamic>{
      'weekday': instance.weekday?.toJson(),
      'items': instance.items?.map((e) => e.toJson()).toList(),
    };

BGMLargeWeekday _$BGMLargeWeekdayFromJson(Map<String, dynamic> json) =>
    BGMLargeWeekday(
      en: json['en'] as String?,
      cn: json['cn'] as String?,
      ja: json['ja'] as String?,
      id: (json['id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BGMLargeWeekdayToJson(BGMLargeWeekday instance) =>
    <String, dynamic>{
      'en': instance.en,
      'cn': instance.cn,
      'ja': instance.ja,
      'id': instance.id,
    };