import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:polaris/service/entrypoint.dart' as service;
import 'package:polaris/transient/authentication.dart' as authentication;
import 'package:polaris/transient/connection.dart' as connection;
import 'package:polaris/shared/host.dart' as host;
import 'package:polaris/shared/token.dart' as token;
import 'package:polaris/ui/strings.dart';

class ServiceLauncher {
  final connection.Manager connectionManager;
  final authentication.Manager authenticationManager;
  final host.Manager hostManager;
  final token.Manager tokenManager;

  ServiceLauncher({
    @required this.connectionManager,
    @required this.authenticationManager,
    @required this.hostManager,
    @required this.tokenManager,
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
      AudioService.start(
          backgroundTaskEntrypoint: service.entrypoint,
          androidNotificationChannelName: appName,
          androidNotificationColor: Colors.blue[400].value, // TODO evaluate where this goes and how it looks
          androidNotificationIcon: 'mipmap/ic_launcher',
          androidEnableQueue: true,
          params: {
            service.polarisHostParam: hostManager.url,
            service.polarisAuthTokenParam: tokenManager.token,
          });
    } else {
      AudioService.stop();
    }
  }
}
