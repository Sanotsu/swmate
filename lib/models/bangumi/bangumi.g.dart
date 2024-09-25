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
      platform: json['platform'] as String?,
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
      infobox: (json['infobox'] as List<dynamic>?)
          ?.map((e) => BGMInfobox.fromJson(e as Map<String, dynamic>))
          .toList(),
      rating: json['rating'] == null
          ? null
          : BGMLargeRating.fromJson(json['rating'] as Map<String, dynamic>),
      totalEpisodes: (json['total_episodes'] as num?)?.toInt(),
      eps: (json['eps'] as num?)?.toInt(),
      volumes: (json['volumes'] as num?)?.toInt(),
      series: json['series'] as bool?,
      locked: json['locked'] as bool?,
      collection: json['collection'] == null
          ? null
          : BGMLargeCollection.fromJson(
              json['collection'] as Map<String, dynamic>),
      url: json['url'] as String?,
      epsCount: (json['eps_count'] as num?)?.toInt(),
      airDate: json['air_date'] as String?,
      airWeekday: (json['air_weekday'] as num?)?.toInt(),
      images: json['images'] == null
          ? null
          : BGMImage.fromJson(json['images'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BGMSubjectToJson(BGMSubject instance) =>
    <String, dynamic>{
      'date': instance.date,
      'platform': instance.platform,
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
      'infobox': instance.infobox?.map((e) => e.toJson()).toList(),
      'collection': instance.collection?.toJson(),
      'images': instance.images?.toJson(),
      'rating': instance.rating?.toJson(),
      'total_episodes': instance.totalEpisodes,
      'eps': instance.eps,
      'eps_count': instance.epsCount,
      'air_date': instance.airDate,
      'air_weekday': instance.airWeekday,
      'volumes': instance.volumes,
      'series': instance.series,
      'locked': instance.locked,
      'url': instance.url,
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
      actors: (json['actors'] as List<dynamic>?)
          ?.map((e) => BGMActor.fromJson(e as Map<String, dynamic>))
          .toList(),
      nameCn: json['name_cn'] as String?,
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
      'actors': instance.actors?.map((e) => e.toJson()).toList(),
      'name_cn': instance.nameCn,
    };

BGMActor _$BGMActorFromJson(Map<String, dynamic> json) => BGMActor(
      images: json['images'] == null
          ? null
          : BGMImage.fromJson(json['images'] as Map<String, dynamic>),
      name: json['name'] as String?,
      shortSummary: json['short_summary'] as String?,
      career:
          (json['career'] as List<dynamic>?)?.map((e) => e as String).toList(),
      id: (json['id'] as num?)?.toInt(),
      type: (json['type'] as num?)?.toInt(),
      locked: json['locked'] as bool?,
    );

Map<String, dynamic> _$BGMActorToJson(BGMActor instance) => <String, dynamic>{
      'images': instance.images?.toJson(),
      'name': instance.name,
      'short_summary': instance.shortSummary,
      'career': instance.career,
      'id': instance.id,
      'type': instance.type,
      'locked': instance.locked,
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
          ?.map((e) => BGMSubject.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BGMLargeSubjectRespToJson(
        BGMLargeSubjectResp instance) =>
    <String, dynamic>{
      'results': instance.results,
      'list': instance.list?.map((e) => e.toJson()).toList(),
    };

BGMLargeRating _$BGMLargeRatingFromJson(Map<String, dynamic> json) =>
    BGMLargeRating(
      rank: (json['rank'] as num?)?.toInt(),
      total: (json['total'] as num?)?.toInt(),
      count: (json['count'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ),
      score: (json['score'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$BGMLargeRatingToJson(BGMLargeRating instance) =>
    <String, dynamic>{
      'rank': instance.rank,
      'total': instance.total,
      'count': instance.count,
      'score': instance.score,
    };

BGMImage _$BGMImageFromJson(Map<String, dynamic> json) => BGMImage(
      large: json['large'] as String?,
      common: json['common'] as String?,
      medium: json['medium'] as String?,
      small: json['small'] as String?,
      grid: json['grid'] as String?,
    );

Map<String, dynamic> _$BGMImageToJson(BGMImage instance) => <String, dynamic>{
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
          ?.map((e) => BGMSubject.fromJson(e as Map<String, dynamic>))
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

BGMEpisodeResp _$BGMEpisodeRespFromJson(Map<String, dynamic> json) =>
    BGMEpisodeResp(
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => BGMEpisode.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt(),
      limit: (json['limit'] as num?)?.toInt(),
      offset: (json['offset'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BGMEpisodeRespToJson(BGMEpisodeResp instance) =>
    <String, dynamic>{
      'data': instance.data?.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'limit': instance.limit,
      'offset': instance.offset,
    };

BGMEpisode _$BGMEpisodeFromJson(Map<String, dynamic> json) => BGMEpisode(
      airdate: json['airdate'] as String?,
      name: json['name'] as String?,
      nameCn: json['name_cn'] as String?,
      duration: json['duration'] as String?,
      desc: json['desc'] as String?,
      ep: (json['ep'] as num?)?.toInt(),
      sort: (json['sort'] as num?)?.toInt(),
      id: (json['id'] as num?)?.toInt(),
      subjectId: (json['subject_id'] as num?)?.toInt(),
      comment: (json['comment'] as num?)?.toInt(),
      type: (json['type'] as num?)?.toInt(),
      disc: (json['disc'] as num?)?.toInt(),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BGMEpisodeToJson(BGMEpisode instance) =>
    <String, dynamic>{
      'airdate': instance.airdate,
      'name': instance.name,
      'name_cn': instance.nameCn,
      'duration': instance.duration,
      'desc': instance.desc,
      'ep': instance.ep,
      'sort': instance.sort,
      'id': instance.id,
      'subject_id': instance.subjectId,
      'comment': instance.comment,
      'type': instance.type,
      'disc': instance.disc,
      'duration_seconds': instance.durationSeconds,
    };
