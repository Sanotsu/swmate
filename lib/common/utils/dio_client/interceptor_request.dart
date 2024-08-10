// ignore_for_file: avoid_print

import 'package:dio/dio.dart';

class RequestInterceptor extends Interceptor {
  const RequestInterceptor();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    print('【onRequest】进入了dio的请求拦截器');

    // 可以在这里添加 authorization 自定义头等操作

    return handler.next(options);
  }
}
