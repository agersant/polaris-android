import 'dart:io';

import 'package:polaris/shared/host.dart' as host;

class LoopbackHost implements host.Manager {
  int _port;

  LoopbackHost(this._port);

  String get url {
    final String host = InternetAddress.loopbackIPv4.host;
    return 'http://$host:$_port';
  }

  void onConnectionAttempt(String url) {}
  Future<void> onSuccessfulConnection() async {}
}
