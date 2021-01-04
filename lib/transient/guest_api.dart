import 'package:polaris/shared/dto.dart';

abstract class GuestAPI {
  Future<APIVersion> getAPIVersion();
  Future<Authorization> login(String username, String password);
  Future<void> testConnection();
}
