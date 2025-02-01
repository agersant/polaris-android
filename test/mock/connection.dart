import 'package:polaris/core/connection.dart';

class ConnectionManager implements ManagerInterface {
  final String? host;

  ConnectionManager(this.host);

  @override
  String? get url => host;

  @override
  int? get apiVersion => 8;
}
