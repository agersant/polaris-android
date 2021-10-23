import 'package:flutter/foundation.dart';
import 'package:polaris/core/dto.dart';

class BrowserModel extends ChangeNotifier {
  List<String> _browserStack = const [''];
  List<String> get browserStack => _browserStack;
  bool isBrowserActive = false;

  void pushBrowserLocation(Directory directory) {
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
