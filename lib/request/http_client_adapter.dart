import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';

class UnsafeHttpClientAdapter implements HttpClientAdapter {
  late final HttpClient _client;

  UnsafeHttpClientAdapter() {
    _client = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }

  @override
  void close({bool force = false}) {
    _client.close(force: force);
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final uri = options.uri;
    final request = await _client.openUrl(options.method, uri);

    options.headers.forEach((key, value) {
      request.headers.set(key, value);
    });

    if (requestStream != null) {
      await requestStream.pipe(request);
    }

    final response = await request.close();

    final headers = <String, List<String>>{};
    response.headers.forEach((key, values) {
      headers[key] = values;
    });

    final stream = response.transform(
      StreamTransformer<List<int>, Uint8List>.fromHandlers(
        handleData: (data, sink) {
          sink.add(Uint8List.fromList(data));
        },
      ),
    );

    return ResponseBody(
      stream,
      response.statusCode,
      headers: headers,
      statusMessage: response.reasonPhrase,
    );
  }
}
