// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// 简单的错误拦截示例
class ErrorInterceptor extends Interceptor {
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    print('【onError】进入了dio的错误拦截器');

    print("err is :$err");

    print(
      """-----------------------
err 详情 
  message: ${err.message} 
  type: ${err.type} 
  error: ${err.error} 
  response: ${err.response}
  -----------------------""",
    );

    /// 根据DioError创建HttpException
    CusHttpException httpException = CusHttpException.create(err);

    /// dio默认的错误实例，如果是没有网络，只能得到一个未知错误，无法精准的得知是否是无网络的情况
    /// 这里对于断网的情况，给一个特殊的code和msg，其他可以识别处理的错误也可以订好
    if (err.type == DioExceptionType.unknown) {
      var connectivityResult = await (Connectivity().checkConnectivity());

      print("connectivityResult这里以前是返回一个，现在是列表里？？？$connectivityResult");

      if (connectivityResult.first == ConnectivityResult.none) {
        httpException = CusHttpException(code: -100, msg: '【无网络】');
      }
    }

    /// 2024-03-11 旧版本的写法是这样，但会报错，所以下面是新建了一个error
    // 将自定义的HttpException
    // err.error = httpException;
    // // 调用父类，回到dio框架
    // super.onError(err, handler);

    /// 创建一个新的DioException实例，并设置自定义的HttpException
    DioException newErr = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: httpException,
    );

    print("往上抛的newErr：$newErr");
    super.onError(newErr, handler);

    // 2024-03-11 新版本要这样写了吗？？？
    // handler.next(newErr);
  }
}

//
class CusHttpException implements Exception {
  final int code;
  final String msg;
  final String responseString;

  CusHttpException({
    this.code = -1,
    this.msg = '【未知错误】',
    this.responseString = '【未知响应】',
  });

  @override
  String toString() {
    return 'Http Error [$code]: $msg';
  }

  factory CusHttpException.create(DioException error) {
    /// dio异常
    switch (error.type) {
      case DioExceptionType.cancel:
        {
          return CusHttpException(code: -1, msg: 'request cancel');
        }
      case DioExceptionType.connectionTimeout:
        {
          return CusHttpException(code: -1, msg: 'connect timeout');
        }
      case DioExceptionType.sendTimeout:
        {
          return CusHttpException(code: -1, msg: 'send timeout');
        }
      case DioExceptionType.receiveTimeout:
        {
          return CusHttpException(code: -1, msg: 'receive timeout');
        }
      case DioExceptionType.badResponse:
        {
          try {
            int statusCode = error.response?.statusCode ?? 0;
            // String errMsg = error.response.statusMessage;
            // return ErrorEntity(code: errCode, message: errMsg);
            switch (statusCode) {
              case 400:
                {
                  return CusHttpException(
                    code: statusCode,
                    msg: '输入格式错误。Request syntax error',
                    responseString: error.response.toString(),
                  );
                }
              case 401:
                {
                  return CusHttpException(
                    code: statusCode,
                    msg: '权限异常。Without permission',
                    responseString: error.response.toString(),
                  );
                }
              case 403:
                {
                  return CusHttpException(
                    code: statusCode,
                    msg: '后台拒绝执行。Server rejects execution',
                    responseString: error.response.toString(),
                  );
                }
              case 404:
                {
                  return CusHttpException(
                    code: statusCode,
                    msg: '无效的 Endpoint URL 或模型名。Unable to connect to server',
                    responseString: error.response.toString(),
                  );
                }
              case 405:
                {
                  return CusHttpException(
                    code: statusCode,
                    msg: 'The request method is disabled',
                    responseString: error.response.toString(),
                  );
                }
              case 500:
                {
                  return CusHttpException(
                    code: statusCode,
                    msg: '服务端内部错误，请稍后重试。Server internal error',
                    responseString: error.response.toString(),
                  );
                }
              case 502:
                {
                  return CusHttpException(
                    code: statusCode,
                    msg: '无效的请求。Invalid request',
                    responseString: error.response.toString(),
                  );
                }
              case 503:
                {
                  return CusHttpException(
                    code: statusCode,
                    msg: 'The server is down.',
                    responseString: error.response.toString(),
                  );
                }
              case 505:
                {
                  return CusHttpException(
                    code: statusCode,
                    msg: 'HTTP requests are not supported',
                    responseString: error.response.toString(),
                  );
                }
              case 529:
                {
                  return CusHttpException(
                    code: statusCode,
                    msg: '系统繁忙，请重试，请 1 分钟后重试。System busy',
                    responseString: error.response.toString(),
                  );
                }
              default:
                {
                  return CusHttpException(
                    code: statusCode,
                    msg: error.response?.statusMessage ?? 'unknow error',
                    responseString: error.response.toString(),
                  );
                }
            }
          } on Exception catch (_) {
            return CusHttpException(
              code: -1,
              msg: 'unknow error',
              responseString: error.response.toString(),
            );
          }
        }
      default:
        {
          return CusHttpException(
            code: -1,
            msg: error.message ?? 'unknow error',
            responseString: error.response.toString(),
          );
        }
    }
  }
}
