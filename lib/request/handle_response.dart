import 'package:dio/dio.dart';
import 'package:nvm_desktop/request/http_exception.dart';
import 'package:nvm_desktop/request/http_response.dart';

MyDioResponse handleResponse(Response? response) {
  // 返回值异常
  if (response == null) {
    return MyDioResponse.failure(MyDioException("未知错误"));
  }

  // token失效
  if (_isTokenTimeout(response.statusCode)) {
    return MyDioResponse.failure(MyDioException("没有权限"));
  }
  // 接口调用成功
  if (_isRequestSuccess(response.statusCode)) {
    return MyDioResponse.success(response.data);
  } else {
    // 接口调用失败
    return MyDioResponse.failure(MyDioException("未知错误"));
  }
}

MyDioResponse handleException(Exception exc) {
  var parseException = _parseException(exc);
  return MyDioResponse.failure(parseException);
}

/// 鉴权失败
bool _isTokenTimeout(int? code) {
  return code == 401;
}

/// 请求成功
bool _isRequestSuccess(int? statusCode) {
  return (statusCode != null && statusCode >= 200 && statusCode < 300);
}

MyDioException _parseException(Exception exc) {
  if (exc is DioException) {
    final int? statusCode = exc.response?.statusCode;
    return switch (exc.type) {
      DioExceptionType.connectionTimeout => MyDioException("连接超时", statusCode),
      DioExceptionType.sendTimeout => MyDioException("发送超时", statusCode),
      DioExceptionType.receiveTimeout => MyDioException("响应超时", statusCode),
      DioExceptionType.badCertificate => MyDioException("证书错误", statusCode),
      DioExceptionType.badResponse => MyDioException("服务器错误", statusCode),
      DioExceptionType.cancel => MyDioException("请求已取消", statusCode),
      DioExceptionType.connectionError => MyDioException("网络异常", statusCode),
      DioExceptionType.unknown => MyDioException("未知错误", statusCode),
    };
  } else {
    return MyDioException("未知错误");
  }
}
