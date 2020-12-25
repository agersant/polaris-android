import 'package:polaris/platform/dto.dart';

enum APIError {
  unspecifiedHost,
  networkError,
  unauthorized,
  requestFailed,
}

abstract class API {
  Future<APIVersion> getAPIVersion();
}
