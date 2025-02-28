// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_api_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NewsApiResp _$NewsApiRespFromJson(Map<String, dynamic> json) => NewsApiResp(
      status: json['status'] as String,
      totalResults: (json['totalResults'] as num?)?.toInt(),
      articles: (json['articles'] as List<dynamic>?)
          ?.map((e) => NewsApiArticle.fromJson(e as Map<String, dynamic>))
          .toList(),
      code: json['code'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$NewsApiRespToJson(NewsApiResp instance) =>
    <String, dynamic>{
      'status': instance.status,
      'totalResults': instance.totalResults,
      'articles': instance.articles?.map((e) => e.toJson()).toList(),
      'code': instance.code,
      'message': instance.message,
    };

NewsApiArticle _$NewsApiArticleFromJson(Map<String, dynamic> json) =>
    NewsApiArticle(
      source: json['source'] == null
          ? null
          : NewsApiSource.fromJson(json['source'] as Map<String, dynamic>),
      author: json['author'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      url: json['url'] as String?,
      urlToImage: json['urlToImage'] as String?,
      publishedAt: json['publishedAt'] as String?,
      content: json['content'] as String?,
    );

Map<String, dynamic> _$NewsApiArticleToJson(NewsApiArticle instance) =>
    <String, dynamic>{
      'source': instance.source?.toJson(),
      'author': instance.author,
      'title': instance.title,
      'description': instance.description,
      'url': instance.url,
      'urlToImage': instance.urlToImage,
      'publishedAt': instance.publishedAt,
      'content': instance.content,
    };

NewsApiSource _$NewsApiSourceFromJson(Map<String, dynamic> json) =>
    NewsApiSource(
      id: json['id'] as String?,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$NewsApiSourceToJson(NewsApiSource instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };
