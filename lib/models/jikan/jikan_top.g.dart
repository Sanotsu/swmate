// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jikan_top.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JikanTop _$JikanTopFromJson(Map<String, dynamic> json) => JikanTop(
      (json['data'] as List<dynamic>)
          .map((e) => JKTopData.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: json['pagination'] == null
          ? null
          : JKPagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$JikanTopToJson(JikanTop instance) => <String, dynamic>{
      'pagination': instance.pagination?.toJson(),
      'data': instance.data.map((e) => e.toJson()).toList(),
    };

JKPagination _$JKPaginationFromJson(Map<String, dynamic> json) => JKPagination(
      (json['last_visible_page'] as num).toInt(),
      json['has_next_page'] as bool,
      (json['current_page'] as num).toInt(),
      JKPaginationItem.fromJson(json['items'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$JKPaginationToJson(JKPagination instance) =>
    <String, dynamic>{
      'last_visible_page': instance.lastVisiblePage,
      'has_next_page': instance.hasNextPage,
      'current_page': instance.currentPage,
      'items': instance.items.toJson(),
    };

JKPaginationItem _$JKPaginationItemFromJson(Map<String, dynamic> json) =>
    JKPaginationItem(
      (json['count'] as num).toInt(),
      (json['total'] as num).toInt(),
      (json['per_page'] as num).toInt(),
    );

Map<String, dynamic> _$JKPaginationItemToJson(JKPaginationItem instance) =>
    <String, dynamic>{
      'count': instance.count,
      'total': instance.total,
      'per_page': instance.perPage,
    };

JKTopData _$JKTopDataFromJson(Map<String, dynamic> json) => JKTopData(
      malId: (json['mal_id'] as num).toInt(),
      url: json['url'] as String,
      images: JKImage.fromJson(json['images'] as Map<String, dynamic>),
      trailer: json['trailer'] == null
          ? null
          : JKTrailer.fromJson(json['trailer'] as Map<String, dynamic>),
      approved: json['approved'] as bool?,
      titles: (json['titles'] as List<dynamic>?)
          ?.map((e) => JKTitle.fromJson(e as Map<String, dynamic>))
          .toList(),
      title: json['title'] as String?,
      titleEnglish: json['title_english'] as String?,
      titleJapanese: json['title_japanese'] as String?,
      titleSynonyms: (json['title_synonyms'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      type: json['type'] as String?,
      source: json['source'] as String?,
      episodes: (json['episodes'] as num?)?.toInt(),
      chapters: (json['chapters'] as num?)?.toInt(),
      volumes: (json['volumes'] as num?)?.toInt(),
      status: json['status'] as String?,
      airing: json['airing'] as bool?,
      aired: json['aired'] == null
          ? null
          : JKAired.fromJson(json['aired'] as Map<String, dynamic>),
      duration: json['duration'] as String?,
      rating: json['rating'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      scoredBy: (json['scored_by'] as num?)?.toInt(),
      rank: (json['rank'] as num?)?.toInt(),
      popularity: (json['popularity'] as num?)?.toInt(),
      members: (json['members'] as num?)?.toInt(),
      favorites: (json['favorites'] as num?)?.toInt(),
      synopsis: json['synopsis'] as String?,
      background: json['background'] as String?,
      season: json['season'] as String?,
      year: (json['year'] as num?)?.toInt(),
      broadcast: json['broadcast'] == null
          ? null
          : JKBroadcast.fromJson(json['broadcast'] as Map<String, dynamic>),
      producers: (json['producers'] as List<dynamic>?)
          ?.map((e) => JKCusItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      licensors: (json['licensors'] as List<dynamic>?)
          ?.map((e) => JKCusItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      studios: (json['studios'] as List<dynamic>?)
          ?.map((e) => JKCusItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      demographics: (json['demographics'] as List<dynamic>?)
          ?.map((e) => JKCusItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      relations: (json['relations'] as List<dynamic>?)
          ?.map((e) => JKRelation.fromJson(e as Map<String, dynamic>))
          .toList(),
      theme: json['theme'] == null
          ? null
          : JKTheme.fromJson(json['theme'] as Map<String, dynamic>),
      external: (json['external'] as List<dynamic>?)
          ?.map((e) => JKCusItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      streaming: (json['streaming'] as List<dynamic>?)
          ?.map((e) => JKCusItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      publishing: json['publishing'] as bool?,
      published: json['published'] == null
          ? null
          : JKPublished.fromJson(json['published'] as Map<String, dynamic>),
      scored: (json['scored'] as num?)?.toDouble(),
      authors: (json['authors'] as List<dynamic>?)
          ?.map((e) => JKCusItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      serializations: (json['serializations'] as List<dynamic>?)
          ?.map((e) => JKCusItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      genres: (json['genres'] as List<dynamic>?)
          ?.map((e) => JKCusItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      explicitGenres: json['explicit_genres'] as List<dynamic>?,
      themes: (json['themes'] as List<dynamic>?)
          ?.map((e) => JKCusItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      name: json['name'] as String?,
      nameKanji: json['name_kanji'] as String?,
      nicknames: (json['nicknames'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      about: json['about'] as String?,
      givenName: json['given_name'] as String?,
      familyName: json['family_name'] as String?,
      alternateNames: (json['alternate_names'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      birthday: json['birthday'] as String?,
    )
      ..anime = (json['anime'] as List<dynamic>?)
          ?.map((e) => JKOuterAnime.fromJson(e as Map<String, dynamic>))
          .toList()
      ..manga = (json['manga'] as List<dynamic>?)
          ?.map((e) => JKOuterAnime.fromJson(e as Map<String, dynamic>))
          .toList()
      ..voices = (json['voices'] as List<dynamic>?)
          ?.map((e) => JKOuterVoice.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$JKTopDataToJson(JKTopData instance) => <String, dynamic>{
      'mal_id': instance.malId,
      'url': instance.url,
      'images': instance.images.toJson(),
      'trailer': instance.trailer?.toJson(),
      'approved': instance.approved,
      'titles': instance.titles?.map((e) => e.toJson()).toList(),
      'title': instance.title,
      'title_english': instance.titleEnglish,
      'title_japanese': instance.titleJapanese,
      'title_synonyms': instance.titleSynonyms,
      'type': instance.type,
      'source': instance.source,
      'episodes': instance.episodes,
      'chapters': instance.chapters,
      'volumes': instance.volumes,
      'status': instance.status,
      'airing': instance.airing,
      'aired': instance.aired?.toJson(),
      'duration': instance.duration,
      'rating': instance.rating,
      'score': instance.score,
      'scored_by': instance.scoredBy,
      'rank': instance.rank,
      'popularity': instance.popularity,
      'members': instance.members,
      'favorites': instance.favorites,
      'synopsis': instance.synopsis,
      'background': instance.background,
      'season': instance.season,
      'year': instance.year,
      'broadcast': instance.broadcast?.toJson(),
      'producers': instance.producers?.map((e) => e.toJson()).toList(),
      'licensors': instance.licensors?.map((e) => e.toJson()).toList(),
      'studios': instance.studios?.map((e) => e.toJson()).toList(),
      'demographics': instance.demographics?.map((e) => e.toJson()).toList(),
      'relations': instance.relations?.map((e) => e.toJson()).toList(),
      'theme': instance.theme?.toJson(),
      'external': instance.external?.map((e) => e.toJson()).toList(),
      'streaming': instance.streaming?.map((e) => e.toJson()).toList(),
      'publishing': instance.publishing,
      'published': instance.published?.toJson(),
      'scored': instance.scored,
      'authors': instance.authors?.map((e) => e.toJson()).toList(),
      'serializations':
          instance.serializations?.map((e) => e.toJson()).toList(),
      'genres': instance.genres?.map((e) => e.toJson()).toList(),
      'explicit_genres': instance.explicitGenres,
      'themes': instance.themes?.map((e) => e.toJson()).toList(),
      'name': instance.name,
      'name_kanji': instance.nameKanji,
      'nicknames': instance.nicknames,
      'about': instance.about,
      'anime': instance.anime?.map((e) => e.toJson()).toList(),
      'manga': instance.manga?.map((e) => e.toJson()).toList(),
      'voices': instance.voices?.map((e) => e.toJson()).toList(),
      'given_name': instance.givenName,
      'family_name': instance.familyName,
      'alternate_names': instance.alternateNames,
      'birthday': instance.birthday,
    };

JKImage _$JKImageFromJson(Map<String, dynamic> json) => JKImage(
      jpg: json['jpg'] == null
          ? null
          : JKJpg.fromJson(json['jpg'] as Map<String, dynamic>),
      webp: json['webp'] == null
          ? null
          : JKWebp.fromJson(json['webp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$JKImageToJson(JKImage instance) => <String, dynamic>{
      'jpg': instance.jpg?.toJson(),
      'webp': instance.webp?.toJson(),
    };

JKJpg _$JKJpgFromJson(Map<String, dynamic> json) => JKJpg(
      imageUrl: json['image_url'] as String?,
      smallImageUrl: json['small_image_url'] as String?,
      largeImageUrl: json['large_image_url'] as String?,
    );

Map<String, dynamic> _$JKJpgToJson(JKJpg instance) => <String, dynamic>{
      'image_url': instance.imageUrl,
      'small_image_url': instance.smallImageUrl,
      'large_image_url': instance.largeImageUrl,
    };

JKWebp _$JKWebpFromJson(Map<String, dynamic> json) => JKWebp(
      imageUrl: json['image_url'] as String?,
      smallImageUrl: json['small_image_url'] as String?,
      largeImageUrl: json['large_image_url'] as String?,
    );

Map<String, dynamic> _$JKWebpToJson(JKWebp instance) => <String, dynamic>{
      'image_url': instance.imageUrl,
      'small_image_url': instance.smallImageUrl,
      'large_image_url': instance.largeImageUrl,
    };

JKTrailer _$JKTrailerFromJson(Map<String, dynamic> json) => JKTrailer(
      youtubeId: json['youtube_id'] as String?,
      url: json['url'] as String?,
      embedUrl: json['embed_url'] as String?,
      images: json['images'] == null
          ? null
          : JKTrailerImage.fromJson(json['images'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$JKTrailerToJson(JKTrailer instance) => <String, dynamic>{
      'youtube_id': instance.youtubeId,
      'url': instance.url,
      'embed_url': instance.embedUrl,
      'images': instance.images?.toJson(),
    };

JKTrailerImage _$JKTrailerImageFromJson(Map<String, dynamic> json) =>
    JKTrailerImage(
      imageUrl: json['image_url'] as String?,
      smallImageUrl: json['small_image_url'] as String?,
      mediumImageUrl: json['medium_image_url'] as String?,
      largeImageUrl: json['large_image_url'] as String?,
      maximumImageUrl: json['maximum_image_url'] as String?,
    );

Map<String, dynamic> _$JKTrailerImageToJson(JKTrailerImage instance) =>
    <String, dynamic>{
      'image_url': instance.imageUrl,
      'small_image_url': instance.smallImageUrl,
      'medium_image_url': instance.mediumImageUrl,
      'large_image_url': instance.largeImageUrl,
      'maximum_image_url': instance.maximumImageUrl,
    };

JKTitle _$JKTitleFromJson(Map<String, dynamic> json) => JKTitle(
      type: json['type'] as String?,
      title: json['title'] as String?,
    );

Map<String, dynamic> _$JKTitleToJson(JKTitle instance) => <String, dynamic>{
      'type': instance.type,
      'title': instance.title,
    };

JKAired _$JKAiredFromJson(Map<String, dynamic> json) => JKAired(
      from: json['from'] as String?,
      to: json['to'] as String?,
      prop: json['prop'] == null
          ? null
          : JKProp.fromJson(json['prop'] as Map<String, dynamic>),
      string: json['string'] as String?,
    );

Map<String, dynamic> _$JKAiredToJson(JKAired instance) => <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
      'prop': instance.prop?.toJson(),
      'string': instance.string,
    };

JKProp _$JKPropFromJson(Map<String, dynamic> json) => JKProp(
      from: json['from'] == null
          ? null
          : JKDate.fromJson(json['from'] as Map<String, dynamic>),
      to: json['to'] == null
          ? null
          : JKDate.fromJson(json['to'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$JKPropToJson(JKProp instance) => <String, dynamic>{
      'from': instance.from?.toJson(),
      'to': instance.to?.toJson(),
    };

JKDate _$JKDateFromJson(Map<String, dynamic> json) => JKDate(
      (json['day'] as num?)?.toInt(),
      (json['month'] as num?)?.toInt(),
      (json['year'] as num?)?.toInt(),
    );

Map<String, dynamic> _$JKDateToJson(JKDate instance) => <String, dynamic>{
      'day': instance.day,
      'month': instance.month,
      'year': instance.year,
    };

JKBroadcast _$JKBroadcastFromJson(Map<String, dynamic> json) => JKBroadcast(
      day: json['day'] as String?,
      time: json['time'] as String?,
      timezone: json['timezone'] as String?,
      string: json['string'] as String?,
    );

Map<String, dynamic> _$JKBroadcastToJson(JKBroadcast instance) =>
    <String, dynamic>{
      'day': instance.day,
      'time': instance.time,
      'timezone': instance.timezone,
      'string': instance.string,
    };

JKCusItem _$JKCusItemFromJson(Map<String, dynamic> json) => JKCusItem(
      malId: (json['mal_id'] as num?)?.toInt(),
      type: json['type'] as String?,
      name: json['name'] as String?,
      url: json['url'] as String?,
    );

Map<String, dynamic> _$JKCusItemToJson(JKCusItem instance) => <String, dynamic>{
      'mal_id': instance.malId,
      'type': instance.type,
      'name': instance.name,
      'url': instance.url,
    };

JKPublished _$JKPublishedFromJson(Map<String, dynamic> json) => JKPublished(
      from: json['from'] as String?,
      to: json['to'] as String?,
      prop: json['prop'] == null
          ? null
          : JKProp.fromJson(json['prop'] as Map<String, dynamic>),
      string: json['string'] as String?,
    );

Map<String, dynamic> _$JKPublishedToJson(JKPublished instance) =>
    <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
      'prop': instance.prop?.toJson(),
      'string': instance.string,
    };

JKRelation _$JKRelationFromJson(Map<String, dynamic> json) => JKRelation(
      json['relation'] as String,
      (json['entry'] as List<dynamic>)
          .map((e) => JKCusItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$JKRelationToJson(JKRelation instance) =>
    <String, dynamic>{
      'relation': instance.relation,
      'entry': instance.entry.map((e) => e.toJson()).toList(),
    };

JKTheme _$JKThemeFromJson(Map<String, dynamic> json) => JKTheme(
      openings: (json['openings'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      endings:
          (json['endings'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$JKThemeToJson(JKTheme instance) => <String, dynamic>{
      'openings': instance.openings,
      'endings': instance.endings,
    };

JKOuterAnime _$JKOuterAnimeFromJson(Map<String, dynamic> json) => JKOuterAnime(
      role: json['role'] as String?,
      position: json['position'] as String?,
      anime: json['anime'] == null
          ? null
          : JKInnerItem.fromJson(json['anime'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$JKOuterAnimeToJson(JKOuterAnime instance) =>
    <String, dynamic>{
      'role': instance.role,
      'position': instance.position,
      'anime': instance.anime?.toJson(),
    };

JKOuterVoice _$JKOuterVoiceFromJson(Map<String, dynamic> json) => JKOuterVoice(
      language: json['language'] as String?,
      person: json['person'] == null
          ? null
          : JKInnerItem.fromJson(json['person'] as Map<String, dynamic>),
      role: json['role'] as String?,
      anime: json['anime'] == null
          ? null
          : JKInnerItem.fromJson(json['anime'] as Map<String, dynamic>),
      character: json['character'] == null
          ? null
          : JKInnerItem.fromJson(json['character'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$JKOuterVoiceToJson(JKOuterVoice instance) =>
    <String, dynamic>{
      'language': instance.language,
      'person': instance.person?.toJson(),
      'role': instance.role,
      'anime': instance.anime?.toJson(),
      'character': instance.character?.toJson(),
    };

JKInnerItem _$JKInnerItemFromJson(Map<String, dynamic> json) => JKInnerItem(
      malId: (json['mal_id'] as num?)?.toInt(),
      url: json['url'] as String?,
      images: json['images'] == null
          ? null
          : JKImage.fromJson(json['images'] as Map<String, dynamic>),
      title: json['title'] as String?,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$JKInnerItemToJson(JKInnerItem instance) =>
    <String, dynamic>{
      'mal_id': instance.malId,
      'url': instance.url,
      'images': instance.images?.toJson(),
      'title': instance.title,
      'name': instance.name,
    };
