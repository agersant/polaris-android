import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:polaris/background/entrypoint.dart' as service;
import 'package:polaris/foreground/authentication.dart' as authentication;
import 'package:polaris/foreground/connection.dart' as connection;
import 'package:polaris/shared/host.dart' as host;
import 'package:polaris/shared/token.dart' as token;
import 'package:polaris/foreground/ui/strings.dart';

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
    final bool isConnected = connectionManager.state == connection.State.connected &&
        authenticationManager.state == authentication.State.authenticated;
    final bool isDisconnected = connectionManager.state == connection.State.disconnected ||
        authenticationManager.state == authentication.State.unauthenticated;
    final bool isReconnecting = connectionManager.state == connection.State.reconnecting ||
        authenticationManager.state == authentication.State.reauthenticating;
    if (isConnected) {
      await launcher.start();
      isServiceRunning = true;
      notifyListeners();
    } else if (isDisconnected && !isReconnecting) {
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
