import 'package:nvm_desktop/request/http_exception.dart';

class MyDioResponse {
  bool ok;
  dynamic data;
  MyDioException? exc;

  MyDioResponse.success([this.data]) : ok = true;

  MyDioResponse.failure(this.exc) : ok = false;
}
