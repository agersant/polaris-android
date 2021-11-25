import 'package:flutter/cupertino.dart';

const keyNumSongsToPreload = 'key-playlist-num-songs-to-preload';
const defaultNumSongsToPreload = 5;

const keyCacheCapacityMB = 'key-cache-capacity-mb';
const defaultCacheSizeMB = 1024;

class Manager extends ChangeNotifier {
  void handleSettingChanged(String settingKey) {
    notifyListeners();
  }
}
