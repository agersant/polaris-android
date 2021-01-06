import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:polaris/service/entrypoint.dart' as service;
import 'package:polaris/transient/authentication.dart' as authentication;
import 'package:polaris/transient/connection.dart' as connection;
import 'package:polaris/shared/host.dart' as host;
import 'package:polaris/shared/token.dart' as token;
import 'package:polaris/ui/strings.dart';

class Manager extends ChangeNotifier {
  final connection.Manager connectionManager;
  final authentication.Manager authenticationManager;
  final host.Manager hostManager;
  final token.Manager tokenManager;
  final Launcher launcher;
  bool isServiceRunning = false;

  Manager({
    @required this.connectionManager,
    @required this.authenticationManager,
    @required this.hostManager,
    @required this.tokenManager,
    @required this.launcher,
  })  : assert(connectionManager != null),
        assert(authenticationManager != null),
        assert(hostManager != null),
        assert(tokenManager != null),
        assert(launcher != null) {
    connectionManager.addListener(_updateService);
    authenticationManager.addListener(_updateService);
    _updateService();
  }

  Future<void> _updateService() async {
    // TODO this will try to kill service when UI reboots but service is still alive!
    final bool canRunService = connectionManager.state == connection.State.connected &&
        authenticationManager.state == authentication.State.authenticated;
    if (canRunService) {
      await launcher.start();
      isServiceRunning = true;
      notifyListeners();
    } else {
      isServiceRunning = false;
      notifyListeners();
      await launcher.stop();
    }
  }

  Future<int> getPort() async {
    return await launcher.getServicePort();
  }
}

abstract class Launcher {
  Future<void> start();
  Future<void> stop();
  Future<int> getServicePort();
}

class AudioServiceLauncher implements Launcher {
  bool _started = false;

  @override
  Future<void> start() async {
    await AudioService.start(
      backgroundTaskEntrypoint: service.entrypoint,
      androidNotificationChannelName: appName,
      androidNotificationColor: Colors.blue[400].value, // TODO evaluate where this goes and how it looks
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidEnableQueue: true,
    );
    _started = true;
  }

  @override
  Future<void> stop() async {
    _started = false;
    await AudioService.stop();
  }

  @override
  Future<int> getServicePort() async {
    return _started ? await AudioService.customAction(service.customActionGetPort) : null;
  }
}