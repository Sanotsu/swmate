import 'package:json_annotation/json_annotation.dart';

part 'xunfei_voice_dictation.g.dart';

///
/// 讯飞-语音识别-语音听写的返回结果
/// https://www.xfyun.cn/doc/asr/voicedictation/API.html
///
@JsonSerializable(explicitToJson: true)
class XunfeiVoiceDictation {
  // 本次会话的id，只在握手成功后第一帧请求时返回
  String? sid;
  // 返回码，0表示成功，其它表示异常，详情请参考错误码
  int? code;
  // 错误描述
  String? message;
  // 听写结果信息(XVD前缀：XunfeiVoiceDictation，讯飞语音听写)
  XVDData? data;

  XunfeiVoiceDictation(
    this.sid,
    this.code,
    this.message,
    this.data,
  );

  factory XunfeiVoiceDictation.fromJson(Map<String, dynamic> srcJson) =>
      _$XunfeiVoiceDictationFromJson(srcJson);

  Map<String, dynamic> toJson() => _$XunfeiVoiceDictationToJson(this);
}

@JsonSerializable(explicitToJson: true)
class XVDData {
  // 识别结果是否结束标识：0：识别的第一块结果，1：识别中间结果，2：识别最后一块结果
  int? status;
  // 听写识别结果
  //  在XVDData里面的result
  XVDDataResult? result;

  XVDData(
    this.status,
    this.result,
  );

  factory XVDData.fromJson(Map<String, dynamic> srcJson) =>
      _$XVDDataFromJson(srcJson);

  Map<String, dynamic> toJson() => _$XVDDataToJson(this);
}

@JsonSerializable(explicitToJson: true)
class XVDDataResult {
  // 返回结果的序号
  int? sn;
  // 是否是最后一片结果
  bool? ls;
  // 保留字段，无需关心
  int? bg;
  // 保留字段，无需关心
  int? ed;
  // 听写结果
  List<XVDDataResultWs>? ws;

  XVDDataResult(
    this.ls,
    this.bg,
    this.ed,
    this.ws,
    this.sn,
  );

  factory XVDDataResult.fromJson(Map<String, dynamic> srcJson) =>
      _$XVDDataResultFromJson(srcJson);

  Map<String, dynamic> toJson() => _$XVDDataResultToJson(this);
}

@JsonSerializable(explicitToJson: true)
class XVDDataResultWs {
  // 起始的端点帧偏移值，单位：帧（1帧=10ms）
  //  注：以下两种情况下bg=0，无参考意义：1)返回结果为标点符号或者为空；2)本次返回结果过长。
  int? bg;

  // 中文分词
  List<XVDDataResultWsCw>? cw;

  XVDDataResultWs(
    this.bg,
    this.cw,
  );

  factory XVDDataResultWs.fromJson(Map<String, dynamic> srcJson) =>
      _$XVDDataResultWsFromJson(srcJson);

  Map<String, dynamic> toJson() => _$XVDDataResultWsToJson(this);
}

@JsonSerializable()
class XVDDataResultWsCw extends Object {
  // 字词
  String? w;
  // sc/wb/wc/we/wp 均为保留字段，无需关心。如果解析sc字段，建议float与int数据类型都做兼容
  int? sc;

  XVDDataResultWsCw(
    this.sc,
    this.w,
  );

  factory XVDDataResultWsCw.fromJson(Map<String, dynamic> srcJson) =>
      _$XVDDataResultWsCwFromJson(srcJson);

  Map<String, dynamic> toJson() => _$XVDDataResultWsCwToJson(this);
}
