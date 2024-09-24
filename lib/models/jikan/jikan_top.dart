import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'jikan_top.g.dart';

///
/// 非官方的 MyAnimeList(MAL) API 动漫排行榜接口返回的数据结构
/// 2024-09-19 暂时只关注这4个接口(MAL)y已经有很多第三方客户端了，我就只弄自己感兴趣的部分
/// 动画排行榜 https://api.jikan.moe/v4/top/anime
/// 漫画排行榜 https://api.jikan.moe/v4/top/manga
/// 角色排行榜 https://api.jikan.moe/v4/top/characters
/// 人物排行榜 https://api.jikan.moe/v4/top/people
///
/// 统一带上JK(Jikan)前缀

@JsonSerializable(explicitToJson: true)
class JikanTop {
  // 查询full的时候就没有分页信息
  @JsonKey(name: 'pagination')
  JKPagination? pagination;

  @JsonKey(name: 'data')
  List<JKTopData> data;

  JikanTop(
    this.data, {
    this.pagination,
  });

  // 从字符串转
  factory JikanTop.fromRawJson(String str) =>
      JikanTop.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JikanTop.fromJson(Map<String, dynamic> srcJson) =>
      _$JikanTopFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JikanTopToJson(this);
}

@JsonSerializable(explicitToJson: true)
class JKPagination {
  @JsonKey(name: 'last_visible_page')
  int lastVisiblePage;

  @JsonKey(name: 'has_next_page')
  bool hasNextPage;

  @JsonKey(name: 'current_page')
  int currentPage;

  @JsonKey(name: 'items')
  JKPaginationItem items;

  JKPagination(
    this.lastVisiblePage,
    this.hasNextPage,
    this.currentPage,
    this.items,
  );

  // 从字符串转
  factory JKPagination.fromRawJson(String str) =>
      JKPagination.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JKPagination.fromJson(Map<String, dynamic> srcJson) =>
      _$JKPaginationFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JKPaginationToJson(this);
}

@JsonSerializable(explicitToJson: true)
class JKPaginationItem {
  @JsonKey(name: 'count')
  int count;

  @JsonKey(name: 'total')
  int total;

  @JsonKey(name: 'per_page')
  int perPage;

  JKPaginationItem(
    this.count,
    this.total,
    this.perPage,
  );

  // 从字符串转
  factory JKPaginationItem.fromRawJson(String str) =>
      JKPaginationItem.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JKPaginationItem.fromJson(Map<String, dynamic> srcJson) =>
      _$JKPaginationItemFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JKPaginationItemToJson(this);
}

/// 这个jktopdata其实就是动漫、漫画、角色、人物中所有栏位的并集
/// 注意，是top接口的合集，如果是指定某个id然后full的查询，还有更多栏位
/// 指定动漫详情 https://api.jikan.moe/v4/anime/{id}/full （有额外栏位）
/// 指定角色详情 https://api.jikan.moe/v4/characters/{id}/full （有额外栏位）
/// 条件查询动漫 https://api.jikan.moe/v4/anime?q=xxx&type=xxx&……（结构和top一样）
/// 条件查询角色 https://api.jikan.moe/v4/characters?q=xxx&type=xxx&……（结构和top一样）
@JsonSerializable(explicitToJson: true)
class JKTopData {
  @JsonKey(name: 'mal_id')
  int malId;

  @JsonKey(name: 'url')
  String url;

  @JsonKey(name: 'images')
  JKImage images;

  @JsonKey(name: 'trailer')
  JKTrailer? trailer;

  @JsonKey(name: 'approved')
  bool? approved;

  @JsonKey(name: 'titles')
  List<JKTitle>? titles;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'title_english')
  String? titleEnglish;

  @JsonKey(name: 'title_japanese')
  String? titleJapanese;

  @JsonKey(name: 'title_synonyms')
  List<String>? titleSynonyms;

  @JsonKey(name: 'type')
  String? type;

  @JsonKey(name: 'source')
  String? source;

  @JsonKey(name: 'episodes')
  int? episodes;

  // 章数
  @JsonKey(name: 'chapters')
  int? chapters;

  // 单行本
  @JsonKey(name: 'volumes')
  int? volumes;

  @JsonKey(name: 'status')
  String? status;

  @JsonKey(name: 'airing')
  bool? airing;

  @JsonKey(name: 'aired')
  JKAired? aired;

  @JsonKey(name: 'duration')
  String? duration;

  @JsonKey(name: 'rating')
  String? rating;

  @JsonKey(name: 'score')
  double? score;

  @JsonKey(name: 'scored_by')
  int? scoredBy;

  @JsonKey(name: 'rank')
  int? rank;

  @JsonKey(name: 'popularity')
  int? popularity;

  @JsonKey(name: 'members')
  int? members;

  @JsonKey(name: 'favorites')
  int? favorites;

  @JsonKey(name: 'synopsis')
  String? synopsis;

  @JsonKey(name: 'background')
  String? background;

  @JsonKey(name: 'season')
  String? season;

  @JsonKey(name: 'year')
  int? year;

  @JsonKey(name: 'broadcast')
  JKBroadcast? broadcast;

  @JsonKey(name: 'producers')
  List<JKCusItem>? producers;

  @JsonKey(name: 'licensors')
  List<JKCusItem>? licensors;

  @JsonKey(name: 'studios')
  List<JKCusItem>? studios;

  @JsonKey(name: 'demographics')
  List<JKCusItem>? demographics;

  /// 下面几个是指定编号用full查询时的栏位
  /// 查询动漫时 relations、theme、external、streaming
  /// 查询漫画时 relations、external
  @JsonKey(name: 'relations')
  List<JKRelation>? relations;

  @JsonKey(name: 'theme')
  JKTheme? theme;

  @JsonKey(name: 'external')
  List<JKCusItem>? external;

  @JsonKey(name: 'streaming')
  List<JKCusItem>? streaming;

  @JsonKey(name: 'publishing')
  bool? publishing;

  @JsonKey(name: 'published')
  JKPublished? published;

  @JsonKey(name: 'scored')
  double? scored;

  @JsonKey(name: 'authors')
  List<JKCusItem>? authors;

  @JsonKey(name: 'serializations')
  List<JKCusItem>? serializations;

  @JsonKey(name: 'genres')
  List<JKCusItem>? genres;

  @JsonKey(name: 'explicit_genres')
  List<dynamic>? explicitGenres;

  @JsonKey(name: 'themes')
  List<JKCusItem>? themes;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'name_kanji')
  String? nameKanji;

  @JsonKey(name: 'nicknames')
  List<String>? nicknames;

  @JsonKey(name: 'about')
  String? about;

  /// 以下下几个是指定角色full的额外栏位
  /// anime、manga、voices
  @JsonKey(name: 'anime')
  List<JKOuterAnime>? anime;

  // manga 和 anime 结构一样，栏位名称不一样而已
  @JsonKey(name: 'manga')
  List<JKOuterAnime>? manga;

  @JsonKey(name: 'voices')
  List<JKOuterVoice>? voices;

  @JsonKey(name: 'given_name')
  String? givenName;

  @JsonKey(name: 'family_name')
  String? familyName;

  @JsonKey(name: 'alternate_names')
  List<String>? alternateNames;

  @JsonKey(name: 'birthday')
  String? birthday;

  JKTopData({
    required this.malId,
    required this.url,
    required this.images,
    this.trailer,
    this.approved,
    this.titles,
    this.title,
    this.titleEnglish,
    this.titleJapanese,
    this.titleSynonyms,
    this.type,
    this.source,
    this.episodes,
    this.chapters,
    this.volumes,
    this.status,
    this.airing,
    this.aired,
    this.duration,
    this.rating,
    this.score,
    this.scoredBy,
    this.rank,
    this.popularity,
    this.members,
    this.favorites,
    this.synopsis,
    this.background,
    this.season,
    this.year,
    this.broadcast,
    this.producers,
    this.licensors,
    this.studios,
    this.demographics,
    this.relations,
    this.theme,
    this.external,
    this.streaming,
    this.publishing,
    this.published,
    this.scored,
    this.authors,
    this.serializations,
    this.genres,
    this.explicitGenres,
    this.themes,
    this.name,
    this.nameKanji,
    this.nicknames,
    this.about,
    this.givenName,
    this.familyName,
    this.alternateNames,
    this.birthday,
  });

  // 从字符串转
  factory JKTopData.fromRawJson(String str) =>
      JKTopData.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JKTopData.fromJson(Map<String, dynamic> srcJson) =>
      _$JKTopDataFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JKTopDataToJson(this);
}

@JsonSerializable(explicitToJson: true)
class JKImage {
  @JsonKey(name: 'jpg')
  JKJpg? jpg;

  @JsonKey(name: 'webp')
  JKWebp? webp;

  JKImage({this.jpg, this.webp});

  // 从字符串转
  factory JKImage.fromRawJson(String str) => JKImage.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JKImage.fromJson(Map<String, dynamic> srcJson) =>
      _$JKImageFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JKImageToJson(this);
}

@JsonSerializable(explicitToJson: true)
class JKJpg {
  @JsonKey(name: 'image_url')
  String? imageUrl;

  @JsonKey(name: 'small_image_url')
  String? smallImageUrl;

  @JsonKey(name: 'large_image_url')
  String? largeImageUrl;

  JKJpg({
    this.imageUrl,
    this.smallImageUrl,
    this.largeImageUrl,
  });

  // 从字符串转
  factory JKJpg.fromRawJson(String str) => JKJpg.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JKJpg.fromJson(Map<String, dynamic> srcJson) =>
      _$JKJpgFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JKJpgToJson(this);
}

@JsonSerializable(explicitToJson: true)
class JKWebp {
  @JsonKey(name: 'image_url')
  String? imageUrl;

  @JsonKey(name: 'small_image_url')
  String? smallImageUrl;

  @JsonKey(name: 'large_image_url')
  String? largeImageUrl;

  JKWebp({
    this.imageUrl,
    this.smallImageUrl,
    this.largeImageUrl,
  });

  // 从字符串转
  factory JKWebp.fromRawJson(String str) => JKWebp.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JKWebp.fromJson(Map<String, dynamic> srcJson) =>
      _$JKWebpFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JKWebpToJson(this);
}

@JsonSerializable(explicitToJson: true)
class JKTrailer {
  @JsonKey(name: 'youtube_id')
  String? youtubeId;

  @JsonKey(name: 'url')
  String? url;

  @JsonKey(name: 'embed_url')
  String? embedUrl;

  @JsonKey(name: 'images')
  JKTrailerImage? images;

  JKTrailer({
    this.youtubeId,
    this.url,
    this.embedUrl,
    this.images,
  });

  // 从字符串转
  factory JKTrailer.fromRawJson(String str) =>
      JKTrailer.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JKTrailer.fromJson(Map<String, dynamic> srcJson) =>
      _$JKTrailerFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JKTrailerToJson(this);
}

@JsonSerializable(explicitToJson: true)
class JKTrailerImage {
  @JsonKey(name: 'image_url')
  String? imageUrl;

  @JsonKey(name: 'small_image_url')
  String? smallImageUrl;

  @JsonKey(name: 'medium_image_url')
  String? mediumImageUrl;

  @JsonKey(name: 'large_image_url')
  String? largeImageUrl;

  @JsonKey(name: 'maximum_image_url')
  String? maximumImageUrl;

  JKTrailerImage({
    this.imageUrl,
    this.smallImageUrl,
    this.mediumImageUrl,
    this.largeImageUrl,
    this.maximumImageUrl,
  });

  // 从字符串转
  factory JKTrailerImage.fromRawJson(String str) =>
      JKTrailerImage.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JKTrailerImage.fromJson(Map<String, dynamic> srcJson) =>
      _$JKTrailerImageFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JKTrailerImageToJson(this);
}

@JsonSerializable(explicitToJson: true)
class JKTitle {
  @JsonKey(name: 'type')
  String? type;

  @JsonKey(name: 'title')
  String? title;

  JKTitle({
    this.type,
    this.title,
  });

  // 从字符串转
  factory JKTitle.fromRawJson(String str) => JKTitle.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JKTitle.fromJson(Map<String, dynamic> srcJson) =>
      _$JKTitleFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JKTitleToJson(this);
}

@JsonSerializable(explicitToJson: true)
class JKAired {
  @JsonKey(name: 'from')
  String? from;

  @JsonKey(name: 'to')
  String? to;

  @JsonKey(name: 'prop')
  JKProp? prop;

  @JsonKey(name: 'string')
  String? string;

  JKAired({
    this.from,
    this.to,
    this.prop,
    this.string,
  });

  // 从字符串转
  factory JKAired.fromRawJson(String str) => JKAired.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JKAired.fromJson(Map<String, dynamic> srcJson) =>
      _$JKAiredFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JKAiredToJson(this);
}

@JsonSerializable(explicitToJson: true)
class JKProp {
  @JsonKey(name: 'from')
  JKDate? from;

  @JsonKey(name: 'to')
  JKDate? to;

  JKProp({
    this.from,
    this.to,
  });

  // 从字符串转
  factory JKProp.fromRawJson(String str) => JKProp.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JKProp.fromJson(Map<String, dynamic> srcJson) =>
      _$JKPropFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JKPropToJson(this);
}

@JsonSerializable(explicitToJson: true)
class JKDate {
  @JsonKey(name: 'day')
  int? day;

  @JsonKey(name: 'month')
  int? month;

  @JsonKey(name: 'year')
  int? year;

  JKDate(
    this.day,
    this.month,
    this.year,
  );

  // 从字符串转
  factory JKDate.fromRawJson(String str) => JKDate.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JKDate.fromJson(Map<String, dynamic> srcJson) =>
      _$JKDateFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JKDateToJson(this);
}

@JsonSerializable(explicitToJson: true)
class JKBroadcast {
  @JsonKey(name: 'day')
  String? day;

  @JsonKey(name: 'time')
  String? time;

  @JsonKey(name: 'timezone')
  String? timezone;

  @JsonKey(name: 'string')
  String? string;

  JKBroadcast({
    this.day,
    this.time,
    this.timezone,
    this.string,
  });

  // 从字符串转
  factory JKBroadcast.fromRawJson(String str) =>
      JKBroadcast.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JKBroadcast.fromJson(Map<String, dynamic> srcJson) =>
      _$JKBroadcastFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JKBroadcastToJson(this);
}

@JsonSerializable(explicitToJson: true)
class JKCusItem {
  @JsonKey(name: 'mal_id')
  int? malId;

  @JsonKey(name: 'type')
  String? type;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'url')
  String? url;

  JKCusItem({
    this.malId,
    this.type,
    this.name,
    this.url,
  });

  // 从字符串转
  factory JKCusItem.fromRawJson(String str) =>
      JKCusItem.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JKCusItem.fromJson(Map<String, dynamic> srcJson) =>
      _$JKCusItemFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JKCusItemToJson(this);
}

@JsonSerializable(explicitToJson: true)
class JKPublished {
  @JsonKey(name: 'from')
  String? from;
  @JsonKey(name: 'to')
  String? to;

  @JsonKey(name: 'prop')
  JKProp? prop;

  @JsonKey(name: 'string')
  String? string;

  JKPublished({
    this.from,
    this.to,
    this.prop,
    this.string,
  });

  // 从字符串转
  factory JKPublished.fromRawJson(String str) =>
      JKPublished.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JKPublished.fromJson(Map<String, dynamic> srcJson) =>
      _$JKPublishedFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JKPublishedToJson(this);
}

// 动漫关联内容
@JsonSerializable(explicitToJson: true)
class JKRelation {
  @JsonKey(name: 'relation')
  String relation;

  @JsonKey(name: 'entry')
  List<JKCusItem> entry;

  JKRelation(
    this.relation,
    this.entry,
  );

  // 从字符串转
  factory JKRelation.fromRawJson(String str) =>
      JKRelation.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JKRelation.fromJson(Map<String, dynamic> srcJson) =>
      _$JKRelationFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JKRelationToJson(this);
}

/// 主题曲和片尾曲
@JsonSerializable(explicitToJson: true)
class JKTheme {
  @JsonKey(name: 'openings')
  List<String>? openings;

  @JsonKey(name: 'endings')
  List<String>? endings;

  JKTheme({
    this.openings,
    this.endings,
  });

  // 从字符串转
  factory JKTheme.fromRawJson(String str) => JKTheme.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JKTheme.fromJson(Map<String, dynamic> srcJson) =>
      _$JKThemeFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JKThemeToJson(this);
}

/// 这两个在查询 characters/{id}/full 或 people/{id}/full 的时候，
/// 额外栏位 anime 有用到， anime 里面还有 anime
/// 额外栏位 manga 里面还有 manga，但结构和 anime 一样的
@JsonSerializable(explicitToJson: true)
class JKOuterAnime {
  // 角色时是role，人物时是position
  @JsonKey(name: 'role')
  String? role;

  @JsonKey(name: 'position')
  String? position;

  @JsonKey(name: 'anime')
  JKInnerItem? anime;

  JKOuterAnime({
    this.role,
    this.position,
    this.anime,
  });

  // 从字符串转
  factory JKOuterAnime.fromRawJson(String str) =>
      JKOuterAnime.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JKOuterAnime.fromJson(Map<String, dynamic> srcJson) =>
      _$JKOuterAnimeFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JKOuterAnimeToJson(this);
}

/// 这在查询 characters/{id}/full 和 people/{id}/full 的时候额外 voices 栏位
/// 前者 language、person
/// 后者 role、anime、character
@JsonSerializable(explicitToJson: true)
class JKOuterVoice {
  @JsonKey(name: 'language')
  String? language;

  @JsonKey(name: 'person')
  JKInnerItem? person;

  @JsonKey(name: 'role')
  String? role;

  @JsonKey(name: 'anime')
  JKInnerItem? anime;

  @JsonKey(name: 'character')
  JKInnerItem? character;

  JKOuterVoice({
    this.language,
    this.person,
    this.role,
    this.anime,
    this.character,
  });

  // 从字符串转
  factory JKOuterVoice.fromRawJson(String str) =>
      JKOuterVoice.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JKOuterVoice.fromJson(Map<String, dynamic> srcJson) =>
      _$JKOuterVoiceFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JKOuterVoiceToJson(this);
}

@JsonSerializable(explicitToJson: true)
class JKInnerItem {
  @JsonKey(name: 'mal_id')
  int? malId;

  @JsonKey(name: 'url')
  String? url;

  @JsonKey(name: 'images')
  JKImage? images;

  @JsonKey(name: 'title')
  String? title;

  // characters/{id}/full 额外栏位的anime manga 内部有上面个
  // 但voices栏位内部的person是title 变 name
  @JsonKey(name: 'name')
  String? name;

  JKInnerItem({
    this.malId,
    this.url,
    this.images,
    this.title,
    this.name,
  });

  // 从字符串转
  factory JKInnerItem.fromRawJson(String str) =>
      JKInnerItem.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory JKInnerItem.fromJson(Map<String, dynamic> srcJson) =>
      _$JKInnerItemFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JKInnerItemToJson(this);
}
