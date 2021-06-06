import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:polaris/shared/host.dart' as host;
import 'package:polaris/foreground/service.dart' as service;

class LoopbackHost extends ChangeNotifier implements host.Manager {
  final service.Manager serviceManager;

  host.State _state = host.State.unavailable;
  get state => _state;

  int? _port;
  get port => _port;

  LoopbackHost({required this.serviceManager}) {
    serviceManager.addListener(() async {
      await _updatePort();
    });
    _updatePort();
  }

  Future<void> _updatePort() async {
    _port = await serviceManager.getPort();
    _state = _port == null ? host.State.unavailable : host.State.available;
    notifyListeners();
  }

  String get url {
    assert(port != null);
    final String host = InternetAddress.loopbackIPv4.host;
    return 'http://$host:$port';
  }

  void onConnectionAttempt(String url) {}
  Future<void> onSuccessfulConnection() async {}
}
