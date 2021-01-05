import 'dart:io';

import 'package:polaris/shared/host.dart' as host;

class LoopbackHost implements host.Manager {
  int port = 8000;

  LoopbackHost();

  String get url {
    final String host = InternetAddress.loopbackIPv4.host;
    return 'http://$host:$port';
  }

  void onConnectionAttempt(String url) {}
  Future<void> onSuccessfulConnection() async {}
}
