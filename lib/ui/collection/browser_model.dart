import 'package:flutter/foundation.dart';
import 'package:polaris/core/dto.dart' as dto;
import 'package:polaris/core/connection.dart' as connection;

class BrowserModel extends ChangeNotifier {
  final connection.Manager connectionManager;
  List<String> _browserStack = const [''];
  List<String> get browserStack => _browserStack;
  bool isBrowserActive = false;

  BrowserModel({required this.connectionManager}) {
    connectionManager.addListener(() {
      if (connectionManager.state == connection.State.disconnected) {
        clearBrowserLocations();
      }
    });
  }

  void clearBrowserLocations() {
    _browserStack = const [''];
    notifyListeners();
  }

  void pushBrowserLocation(dto.Directory directory) {
    final newLocations = List<String>.from(_browserStack);
    newLocations.add(directory.path);
    _browserStack = newLocations;
    notifyListeners();
  }

  void popBrowserLocations(int numLocationsToPop) {
    _browserStack = _browserStack.take(_browserStack.length - numLocationsToPop).toList();
    notifyListeners();
  }

  bool popBrowserLocation() {
    if (_browserStack.length <= 1) {
      return false;
    }
    popBrowserLocations(1);
    return true;
  }
}
