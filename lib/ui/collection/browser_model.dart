import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/utils.dart';

class BrowserModel extends ChangeNotifier {
  final connection.Manager connectionManager;
  List<String> _browserStack = const [''];
  List<String> get browserStack => _browserStack;
  bool _isBrowserActive = false;
  bool get isBrowserActive => _isBrowserActive;
  ChangeNotifier onJump = ChangeNotifier();

  BrowserModel({required this.connectionManager}) {
    connectionManager.addListener(() {
      if (connectionManager.state == connection.State.disconnected) {
        clearBrowserLocations();
      }
    });
  }

  void setBrowserActive(bool active) {
    _isBrowserActive = active;
    notifyListeners();
  }

  void clearBrowserLocations() {
    _browserStack = const [''];
    notifyListeners();
  }

  void pushBrowserLocation(String path) {
    final newLocations = List<String>.from(_browserStack);
    newLocations.add(path);
    _browserStack = newLocations;
    notifyListeners();
  }

  void popBrowserLocations(int numLocationsToPop) {
    _browserStack = _browserStack.take(max(1, _browserStack.length - numLocationsToPop)).toList();
    notifyListeners();
  }

  bool popBrowserLocation() {
    if (_browserStack.length <= 1) {
      return false;
    }
    popBrowserLocations(1);
    return true;
  }

  void jumpTo(String path) {
    _browserStack = [_browserStack.first];
    final components = splitPath(path);
    final paths = List.generate(components.length, (i) => components.take(i + 1).join('/'));
    _browserStack.addAll(paths);
    onJump.notifyListeners();
    notifyListeners();
  }
}
