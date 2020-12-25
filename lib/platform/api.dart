import 'package:polaris/platform/dto.dart';

enum APIError {
  unspecifiedHost,
  networkError,
  unauthorized,
  requestFailed,
}

abstract class API {
  Future<APIVersion> getAPIVersion();
  Future<Authorization> login(String username, String password);
  Future browse(String path);
}
