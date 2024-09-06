import 'package:dio/dio.dart';

import 'cus_http_request.dart';

// 来源：https://www.cnblogs.com/luoshang/p/16987781.html

/// 调用底层的request，重新提供get，post等方便方法

class HttpUtils {
  static HttpRequest httpRequest = HttpRequest();

  /// get
  static Future get({
    required String path,
    Map<String, dynamic>? queryParameters,
    dynamic headers,
    CusRespType? responseType,
    bool showLoading = true,
    bool showErrorMessage = true,
  }) {
    return httpRequest.request(
      path: path,
      method: CusHttpMethod.get,
      queryParameters: queryParameters,
      responseType: responseType,
      headers: headers,
      showLoading: showLoading,
      showErrorMessage: showErrorMessage,
    );
  }

  /// post
  static Future post({
    required String path,
    required CusHttpMethod method,
    dynamic data,
    dynamic headers,
    CusRespType? responseType,
    CancelToken? cancelToken,
    bool showLoading = true,
    bool showErrorMessage = true,
  }) {
    return httpRequest.request(
      path: path,
      method: CusHttpMethod.post,
      data: data,
      responseType: responseType,
      headers: headers,
      cancelToken: cancelToken,
      showLoading: showLoading,
      showErrorMessage: showErrorMessage,
    );
  }
}

/*
使用方法: 
import 'cus_dio_client.dart';

HttpUtils.get(
　　path: '11111'
);

　HttpUtils.post(
　　path: '1111',
　　method: HttpMethod.post //可以更改其他的
);
*/