import 'package:json_annotation/json_annotation.dart';

part 'dog_ceo_resp.g.dart';

///
/// dog ceo 请求用get即可，所有端点的返回，都放在这里来
///
/// https://github.com/ElliottLandsborough/dog-ceo-api
///
@JsonSerializable(explicitToJson: true)
class DogCeoResp {
  // 可能是List<String>，比如查询主品种信息、自定数量的随机图片
  // 可能是List<dynamic>，比如查询所有品种带子品种信息，就是个二维数据
  // 可能是String，比如随机单个图片
  @JsonKey(name: 'message')
  dynamic message;

  @JsonKey(name: 'status')
  String status;

  DogCeoResp(
    this.message,
    this.status,
  );

  factory DogCeoResp.fromJson(Map<String, dynamic> srcJson) =>
      _$DogCeoRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DogCeoRespToJson(this);
}
