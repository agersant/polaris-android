import 'package:flutter/foundation.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;

enum Zone { collection, playback }

class PagesModel extends ChangeNotifier {
  final List<Zone> _zones = [];
  List<Zone> get zones => _zones;

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

  dto.AlbumHeader? _album;
  dto.AlbumHeader? get album => _album;

  void _enterZone(Zone zone) {
    _zones.remove(zone);
    _zones.add(zone);
  }

  void closeAll() {
    _isOfflineMusicOpen = false;
    _isSettingsOpen = false;
    _genre = null;
    _artist = null;
    _album = null;
    _isPlayerOpen = false;
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
    _enterZone(Zone.collection);
    _genre = name;
    _artist = null;
    _album = null;
    notifyListeners();
  }

  void closeGenrePage() {
    _genre = null;
    notifyListeners();
  }

  void openArtistPage(String name) {
    _enterZone(Zone.collection);
    _artist = name;
    _album = null;
    notifyListeners();
  }

  void closeArtistPage() {
    _artist = null;
    notifyListeners();
  }

  void openAlbumPage(dto.AlbumHeader album) {
    _enterZone(Zone.collection);
    _album = album;
    notifyListeners();
  }

  void closeAlbumPage() {
    _album = null;
    notifyListeners();
  }

  void openPlayer() {
    _enterZone(Zone.playback);
    _isPlayerOpen = true;
    notifyListeners();
  }

  void closePlayer() {
    _isPlayerOpen = false;
    notifyListeners();
  }

  void openQueue() {
    _enterZone(Zone.playback);
    _isQueueOpen = true;
    notifyListeners();
  }

  void closeQueue() {
    _isQueueOpen = false;
    notifyListeners();
  }
}
