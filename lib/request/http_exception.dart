class MyDioException implements Exception {
  final String? _message;

  String get message => _message ?? runtimeType.toString();

  final int? _code;

  int get code => _code ?? -1;

  MyDioException(this._message, [this._code]);

  @override
  String toString() {
    return "code:$code--message=$message";
  }
}
