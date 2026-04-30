//缓存配置
import 'package:dio/dio.dart';
import 'package:nvm_desktop/request/dio_client.dart';
import 'package:nvm_desktop/utils/shared_preferences.dart';

class CacheConfig {
  final Duration diskCacheMaxAge;
  final Duration ramCacheMaxAge;
  final int ramCacheMaxCount;
  final bool cacheEnable;
  final List<String> containsMethods;
  const CacheConfig({
    this.diskCacheMaxAge = const Duration(days: 30),
    this.ramCacheMaxAge = const Duration(minutes: 1),
    this.ramCacheMaxCount = 1000,
    this.cacheEnable = false,
    this.containsMethods = const ["get"],
  });
}

class CacheObject {
  Response response;
  int timeStamp;
  CacheObject(this.response)
    : timeStamp = DateTime.now().millisecondsSinceEpoch;

  @override
  bool operator ==(other) {
    return response.hashCode == other.hashCode;
  }

  @override
  int get hashCode => response.realUri.hashCode;
}

class NetCacheInterceptor extends Interceptor {
  // 为确保迭代器顺序和对象插入时间一致顺序一致，我们使用LinkedHashMap
  var cache = <String, CacheObject>{};

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 不开启缓存
    if (!HttpUtil.cacheConfig.cacheEnable) {
      return handler.next(options);
    }
    // refresh标记是否是刷新缓存
    bool refresh = options.extra["refresh"] == true;
    // 是否磁盘缓存
    bool cacheDisk = options.extra["cacheDisk"] == true;
    // 如果刷新，先删除相关缓存
    if (refresh) {
      // 删除uri相同的内存缓存
      delete(options.uri.toString());
      // 删除磁盘缓存
      if (cacheDisk) {
        await SpUtil().remove(options.uri.toString());
      }
      return handler.next(options);
    }

    String curMethod = options.method.toLowerCase();
    bool isContainsMethod = HttpUtil.cacheConfig.containsMethods.contains(
      curMethod,
    );
    bool cacheEnable = HttpUtil.cacheConfig.cacheEnable;

    // 开启缓存 && 请求方式符合要求
    if (isContainsMethod && cacheEnable) {
      String key = options.extra["cacheKey"] ?? options.uri.toString();
      // 策略 1 内存缓存优先，2 然后才是磁盘缓存
      // 1 内存缓存
      var ob = cache[key];
      final int ramCacheMaxAge =
          HttpUtil.cacheConfig.ramCacheMaxAge.inMilliseconds;
      final int nowTimer = DateTime.now().millisecondsSinceEpoch;
      if (ob != null) {
        // 若缓存未过期，则返回缓存内容
        if ((nowTimer - ob.timeStamp) < ramCacheMaxAge) {
          return handler.resolve(ob.response);
        } else {
          //若已过期则删除缓存，继续向服务器请求
          cache.remove(key);
        }
      }
      // final int diskCacheMaxAge =
      //     HttpUtil.cacheConfig.diskCacheMaxAge.inMilliseconds;
      // // 2 磁盘缓存
      // if (cacheDisk) {
      //   var diskData = SpUtil().getJSON(key);
      //   if (diskData != null && diskData is Map) {
      //     int saveTime = diskData["saveTime"] ?? 0;
      //     if ((nowTimer - saveTime) < diskCacheMaxAge) {
      //       return handler.resolve(
      //         Response(
      //           data: diskData["data"],
      //           requestOptions: options,
      //           statusCode: 200,
      //         ),
      //       );
      //     }
      //   }
      // }
    }
    return handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    // 如果启用缓存，将返回结果保存到缓存
    bool cacheEnable = HttpUtil.cacheConfig.cacheEnable;
    if (cacheEnable) {
      await _saveCache(response);
    }
    return handler.next(response);
  }

  Future<void> _saveCache(Response response) async {
    RequestOptions options = response.requestOptions;
    String curMethod = options.method.toLowerCase();
    // 检查需要缓存的请求类型
    bool isContainsMethod = HttpUtil.cacheConfig.containsMethods.contains(
      curMethod,
    );
    // 请求中使用缓存 && 包含当前类型
    if (isContainsMethod) {
      String key = options.extra["cacheKey"] ?? options.uri.toString();
      // 保存到磁盘：包裹一层时间戳
      if (options.extra["cacheDisk"] == true) {
        await SpUtil().setJSON(key, {
          "data": response.data,
          "saveTime": DateTime.now().millisecondsSinceEpoch,
        });
      }
      // 内存缓存
      // 如果缓存数量超过最大数量限制，则先移除最早的一条记录
      if (cache.length >= HttpUtil.cacheConfig.ramCacheMaxCount) {
        cache.remove(cache.keys.first);
      }
      cache[key] = CacheObject(response);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 关键点：当网络请求失败（断网、超时等）时，尝试读取缓存兜底
    if (HttpUtil.cacheConfig.cacheEnable &&
        err.requestOptions.extra["noCache"] != true) {
      String key =
          err.requestOptions.extra["cacheKey"] ??
          err.requestOptions.uri.toString();
      // 1. 内存兜底
      var ob = cache[key];
      if (ob != null) return handler.resolve(ob.response);

      // 2. 磁盘兜底（即使过期了也返回，保证 App 启动有东西看）
      if (err.requestOptions.extra["cacheDisk"] == true) {
        var diskData = SpUtil().getJSON(key);
        if (diskData != null && diskData is Map) {
          return handler.resolve(
            Response(
              data: diskData["data"],
              requestOptions: err.requestOptions,
              statusCode: 200,
              extra: {...err.requestOptions.extra, "isOfflineData": true},
            ),
          );
        }
      }
    }
    return handler.next(err);
  }

  void delete(String key) {
    cache.remove(key);
  }
}
