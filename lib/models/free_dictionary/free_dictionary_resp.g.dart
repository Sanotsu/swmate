// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'free_dictionary_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FreeDictionaryItem _$FreeDictionaryItemFromJson(Map<String, dynamic> json) =>
    FreeDictionaryItem(
      word: json['word'] as String?,
      phonetics: (json['phonetics'] as List<dynamic>?)
          ?.map((e) => FDPhonetic.fromJson(e as Map<String, dynamic>))
          .toList(),
      meanings: (json['meanings'] as List<dynamic>?)
          ?.map((e) => FDMeaning.fromJson(e as Map<String, dynamic>))
          .toList(),
      license: json['license'] == null
          ? null
          : FDLicense.fromJson(json['license'] as Map<String, dynamic>),
      sourceUrls: (json['sourceUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      title: json['title'] as String?,
      message: json['message'] as String?,
      resolution: json['resolution'] as String?,
    );

Map<String, dynamic> _$FreeDictionaryItemToJson(FreeDictionaryItem instance) =>
    <String, dynamic>{
      'word': instance.word,
      'phonetics': instance.phonetics?.map((e) => e.toJson()).toList(),
      'meanings': instance.meanings?.map((e) => e.toJson()).toList(),
      'license': instance.license?.toJson(),
      'sourceUrls': instance.sourceUrls,
      'title': instance.title,
      'message': instance.message,
      'resolution': instance.resolution,
    };

FDPhonetic _$FDPhoneticFromJson(Map<String, dynamic> json) => FDPhonetic(
      text: json['text'] as String?,
      audio: json['audio'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      license: json['license'] == null
          ? null
          : FDLicense.fromJson(json['license'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FDPhoneticToJson(FDPhonetic instance) =>
    <String, dynamic>{
      'text': instance.text,
      'audio': instance.audio,
      'sourceUrl': instance.sourceUrl,
      'license': instance.license?.toJson(),
    };

FDLicense _$FDLicenseFromJson(Map<String, dynamic> json) => FDLicense(
      name: json['name'] as String?,
      url: json['url'] as String?,
    );

Map<String, dynamic> _$FDLicenseToJson(FDLicense instance) => <String, dynamic>{
      'name': instance.name,
      'url': instance.url,
    };

FDMeaning _$FDMeaningFromJson(Map<String, dynamic> json) => FDMeaning(
      json['partOfSpeech'] as String?,
      (json['definitions'] as List<dynamic>?)
          ?.map((e) => FDDefinition.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['synonyms'] as List<dynamic>?)?.map((e) => e as String).toList(),
      json['antonyms'] as List<dynamic>?,
    );

Map<String, dynamic> _$FDMeaningToJson(FDMeaning instance) => <String, dynamic>{
      'partOfSpeech': instance.partOfSpeech,
      'definitions': instance.definitions?.map((e) => e.toJson()).toList(),
      'synonyms': instance.synonyms,
      'antonyms': instance.antonyms,
    };

FDDefinition _$FDDefinitionFromJson(Map<String, dynamic> json) => FDDefinition(
      definition: json['definition'] as String?,
      synonyms: json['synonyms'] as List<dynamic>?,
      antonyms: json['antonyms'] as List<dynamic>?,
      example: json['example'] as String?,
    );

Map<String, dynamic> _$FDDefinitionToJson(FDDefinition instance) =>
    <String, dynamic>{
      'definition': instance.definition,
      'synonyms': instance.synonyms,
      'antonyms': instance.antonyms,
      'example': instance.example,
    };
