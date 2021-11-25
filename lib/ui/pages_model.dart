import 'package:flutter/foundation.dart';

class PagesModel extends ChangeNotifier {
  bool _isQueueOpen = false;
  bool get isQueueOpen => _isQueueOpen;

  bool _isOfflineMusicOpen = false;
  bool get isOfflineMusicOpen => _isOfflineMusicOpen;

  bool _isSettingsOpen = false;
  bool get isSettingsOpen => _isSettingsOpen;

  void openQueue() {
    _isQueueOpen = true;
    notifyListeners();
  }

  void closeQueue() {
    _isQueueOpen = false;
    notifyListeners();
  }

  void openOfflineMusic() {
    _isOfflineMusicOpen = true;
    notifyListeners();
  }

  void closeOfflineMusic() {
    _isOfflineMusicOpen = false;
    notifyListeners();
  }

  void openSettings() {
    _isSettingsOpen = true;
    notifyListeners();
  }

  void closeSettings() {
    _isSettingsOpen = false;
    notifyListeners();
  }
}