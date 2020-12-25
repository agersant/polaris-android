import 'package:polaris/platform/dto.dart';

enum APIError {
  unspecifiedHost,
  networkError,
  requestFailed,
}

abstract class API {
  Future<APIVersion> getAPIVersion();
}
