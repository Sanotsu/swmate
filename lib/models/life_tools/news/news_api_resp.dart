import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'news_api_resp.g.dart';

///
/// newsapi 返回的数据，国内不可访问
/// https://newsapi.org/docs
///
@JsonSerializable(explicitToJson: true)
class NewsApiResp {
  @JsonKey(name: 'status')
  String status;

  @JsonKey(name: 'totalResults')
  int? totalResults;

  @JsonKey(name: 'articles')
  List<NewsApiArticle>? articles;

  @JsonKey(name: 'code')
  String? code;

  @JsonKey(name: 'message')
  String? message;

  NewsApiResp({
    required this.status,
    this.totalResults,
    this.articles,
    this.code,
    this.message,
  });

  factory NewsApiResp.fromRawJson(String str) =>
      NewsApiResp.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory NewsApiResp.fromJson(Map<String, dynamic> srcJson) =>
      _$NewsApiRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$NewsApiRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class NewsApiArticle {
  @JsonKey(name: 'source')
  NewsApiSource? source;

  @JsonKey(name: 'author')
  String? author;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'description')
  String? description;

  @JsonKey(name: 'url')
  String? url;

  @JsonKey(name: 'urlToImage')
  String? urlToImage;

  @JsonKey(name: 'publishedAt')
  String? publishedAt;

  @JsonKey(name: 'content')
  String? content;

  NewsApiArticle({
    this.source,
    this.author,
    this.title,
    this.description,
    this.url,
    this.urlToImage,
    this.publishedAt,
    this.content,
  });

  factory NewsApiArticle.fromRawJson(String str) =>
      NewsApiArticle.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory NewsApiArticle.fromJson(Map<String, dynamic> srcJson) =>
      _$NewsApiArticleFromJson(srcJson);

  Map<String, dynamic> toJson() => _$NewsApiArticleToJson(this);
}

@JsonSerializable(explicitToJson: true)
class NewsApiSource {
  @JsonKey(name: 'id')
  String? id;

  @JsonKey(name: 'name')
  String? name;

  NewsApiSource({
    this.id,
    this.name,
  });

  factory NewsApiSource.fromRawJson(String str) =>
      NewsApiSource.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory NewsApiSource.fromJson(Map<String, dynamic> srcJson) =>
      _$NewsApiSourceFromJson(srcJson);

  Map<String, dynamic> toJson() => _$NewsApiSourceToJson(this);
}
