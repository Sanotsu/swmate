import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkStatusService {
  // 创建一个单例实例
  static final _instance = NetworkStatusService._internal();

  factory NetworkStatusService() => _instance;

  NetworkStatusService._internal();

  // 创建一个 StreamController 来管理网络状态的变化
  final _networkStatusController =
      StreamController<List<ConnectivityResult>>.broadcast();

  // 获取网络状态的 Stream
  Stream<List<ConnectivityResult>> get networkStatusStream =>
      _networkStatusController.stream;

  // 初始化网络状态监听
  void initialize() {
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      _networkStatusController.add(result);
    });
  }

  // 判断当前网络是否是 Wi-Fi 状态
  Future<bool> isWifi() async {
    List<ConnectivityResult> result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.wifi);
  }

  Future<bool> isMobile() async {
    List<ConnectivityResult> result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.mobile);
  }

  Future<bool> isNetwork() async {
    List<ConnectivityResult> result = await Connectivity().checkConnectivity();
    return (result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi));
  }

  // 关闭 StreamController
  void dispose() {
    _networkStatusController.close();
  }
}
