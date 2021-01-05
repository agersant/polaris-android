import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:polaris/service/entrypoint.dart' as service;
import 'package:polaris/shared/loopback_host.dart';
import 'package:polaris/transient/authentication.dart' as authentication;
import 'package:polaris/transient/connection.dart' as connection;
import 'package:polaris/shared/host.dart' as host;
import 'package:polaris/shared/token.dart' as token;
import 'package:polaris/ui/strings.dart';

class ServiceLauncher extends ChangeNotifier {
  final connection.Manager connectionManager;
  final authentication.Manager authenticationManager;
  final host.Manager hostManager;
  final token.Manager tokenManager;
  final LoopbackHost loopbackHost;
  bool isServiceRunning = false;

  ServiceLauncher({
    @required this.connectionManager,
    @required this.authenticationManager,
    @required this.hostManager,
    @required this.tokenManager,
    @required this.loopbackHost,
  })  : assert(connectionManager != null),
        assert(authenticationManager != null),
        assert(hostManager != null),
        assert(tokenManager != null) {
    connectionManager.addListener(_updateService);
    authenticationManager.addListener(_updateService);
    _updateService();
  }

  Future<void> _updateService() async {
    // TODO this will try to kill service when UI reboots but service is still alive!
    final bool canRunService = connectionManager.state == connection.State.connected &&
        authenticationManager.state == authentication.State.authenticated;
    if (canRunService) {
      await AudioService.start(
        backgroundTaskEntrypoint: service.entrypoint,
        androidNotificationChannelName: appName,
        androidNotificationColor: Colors.blue[400].value, // TODO evaluate where this goes and how it looks
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidEnableQueue: true,
      );
      // TODO this is a little jank? Not sure it can be much better
      loopbackHost.port = await AudioService.customAction(service.customActionGetPort);
      assert(loopbackHost.port != null);
      isServiceRunning = true;
      notifyListeners();
    } else {
      isServiceRunning = false;
      notifyListeners();
      await AudioService.stop();
    }
  }
}
