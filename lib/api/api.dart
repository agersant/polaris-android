import 'package:polaris/api/dto.dart';

enum APIError {
  unspecifiedHost,
  networkError,
  requestFailed,
}

abstract class API {
  Future<APIVersion> getAPIVersion();
}
