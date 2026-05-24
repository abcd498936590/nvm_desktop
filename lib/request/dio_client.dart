import 'dart:io';

import 'package:dio/dio.dart';
import 'package:nvm_desktop/request/handle_response.dart';
import 'package:nvm_desktop/request/http_client_adapter.dart';
import 'package:nvm_desktop/request/http_response.dart';
import 'package:nvm_desktop/request/interceptor/cache.dart';
import 'interceptor/global.dart';

class HttpUtil {
  static final HttpUtil _instance = HttpUtil._internal();
  factory HttpUtil() => _instance;

  static late final Dio dio;
  static late final CacheConfig cacheConfig;

  List<CancelToken?> pendingRequest = [];

  void cancelRequests() {
    pendingRequest.map((token) => token!.cancel('dio cancel'));
  }

  CancelToken createDioCancelToken(CancelToken? cancelToken) {
    CancelToken token = cancelToken ?? CancelToken();
    pendingRequest.add(token);
    return token;
  }

  HttpUtil._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: '',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        responseType: ResponseType.json,
      ),
    );
    // 设置缓存配置
    cacheConfig = CacheConfig(
      containsMethods: const ['get', 'post'],
      cacheEnable: true,
    );
    // 自定义http adapter
    dio.httpClientAdapter = UnsafeHttpClientAdapter();
    // 删掉默认的userAgent = Dart/3.x (dart:io)
    dio.options.headers.remove(HttpHeaders.userAgentHeader);
    // 中间件
    dio.interceptors.add(AppInterceptor());
    dio.interceptors.add(NetCacheInterceptor());
  }

  // App 启动时必须调用
  Future<void> init({
    String? baseUrl,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 15),
    Map<String, String>? headers,
    List<Interceptor>? interceptors,
  }) async {
    dio.options = dio.options.copyWith(
      baseUrl: baseUrl ?? "",
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: headers ?? const {},
    );

    if (interceptors != null && interceptors.isNotEmpty) {
      dio.interceptors.addAll(interceptors);
    }
  }

  Future<MyDioResponse> get<T>(
    String path, {
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
    bool refresh = false,
    String? cacheKey,
    bool cacheDisk = false,
    bool noCache = false,
  }) async {
    Options requestOptions = options ?? Options();
    CancelToken dioCancelToken = createDioCancelToken(cancelToken);
    requestOptions = requestOptions.copyWith(
      extra: {
        "refresh": refresh,
        "cacheKey": cacheKey,
        "cacheDisk": cacheDisk,
        "noCache": noCache,
      },
    );
    try {
      var response = await dio.get<T>(
        path,
        queryParameters: query,
        options: requestOptions,
        cancelToken: dioCancelToken,
      );
      // if (kDebugMode) {
      //   print("---------------");
      //   print(response);
      //   print("---------------");
      // }
      pendingRequest.remove(dioCancelToken);
      return handleResponse(response);
    } on Exception catch (e) {
      // if (kDebugMode) {
      //   print("+++++++++++++++");
      //   print(e);
      //   print("+++++++++++++++");
      // }
      return handleException(e);
    }
  }

  Future<MyDioResponse> post<T>(
    String path, {
    dynamic data,
    Options? options,
    CancelToken? cancelToken,
    bool refresh = false,
    String? cacheKey,
    bool cacheDisk = false,
    bool noCache = false,
  }) async {
    Options requestOptions = options ?? Options();
    CancelToken dioCancelToken = createDioCancelToken(cancelToken);
    requestOptions = requestOptions.copyWith(
      extra: {
        "refresh": refresh,
        "cacheKey": cacheKey,
        "cacheDisk": cacheDisk,
        "noCache": noCache,
      },
    );
    try {
      var response = await dio.post<T>(
        path,
        data: data,
        options: requestOptions,
        cancelToken: dioCancelToken,
      );
      pendingRequest.remove(dioCancelToken);
      return handleResponse(response);
    } on Exception catch (e) {
      return handleException(e);
    }
  }

  Future<MyDioResponse> download(
    String path,
    savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    data,
    Options? options,
  }) async {
    CancelToken dioCancelToken = createDioCancelToken(cancelToken);
    try {
      var response = await dio.download(
        path,
        savePath,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
        deleteOnError: deleteOnError,
        lengthHeader: lengthHeader,
        data: data,
        options: data,
        cancelToken: dioCancelToken,
      );
      pendingRequest.remove(dioCancelToken);
      return handleResponse(response);
    } on Exception catch (e) {
      return handleException(e);
    }
  }
}
