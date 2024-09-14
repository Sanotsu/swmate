import 'package:json_annotation/json_annotation.dart';

part 'the_dog_cat_api_image.g.dart';

@JsonSerializable()
class TheDogCatApiImage {
  @JsonKey(name: 'id')
  String id;

  @JsonKey(name: 'url')
  String url;

  @JsonKey(name: 'width')
  int width;

  @JsonKey(name: 'height')
  int height;

  TheDogCatApiImage(
    this.id,
    this.url,
    this.width,
    this.height,
  );

  factory TheDogCatApiImage.fromJson(Map<String, dynamic> srcJson) =>
      _$TheDogCatApiImageFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TheDogCatApiImageToJson(this);
}
