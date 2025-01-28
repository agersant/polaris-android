import 'package:flutter/foundation.dart';

class PagesModel extends ChangeNotifier {
  bool _isPlayerOpen = false;
  bool get isPlayerOpen => _isPlayerOpen;

  bool _isQueueOpen = false;
  bool get isQueueOpen => _isQueueOpen;

  bool _isOfflineMusicOpen = false;
  bool get isOfflineMusicOpen => _isOfflineMusicOpen;

  bool _isSettingsOpen = false;
  bool get isSettingsOpen => _isSettingsOpen;

  String? _artist;
  String? get artist => _artist;

  String? _genre;
  String? get genre => _genre;

  void openPlayer() {
    _isPlayerOpen = true;
    notifyListeners();
  }

  void closePlayer() {
    _isPlayerOpen = false;
    notifyListeners();
  }

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

  void openGenrePage(String name) {
    _genre = name;
    notifyListeners();
  }

  void closeGenrePage() {
    _genre = null;
    notifyListeners();
  }

  void openArtistPage(String name) {
    _artist = name;
    notifyListeners();
  }

  void closeArtistPage() {
    _artist = null;
    notifyListeners();
  }
}
