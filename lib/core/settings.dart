import 'package:flutter/material.dart';

const keyNumSongsToPreload = 'key-playlist-num-songs-to-preload';
const defaultNumSongsToPreload = 5;

const keyCacheCapacityMB = 'key-cache-capacity-mb';
const defaultCacheSizeMB = 1024;

const keyThemeMode = 'key-theme-mode';
final defaultThemeMode = ThemeMode.system.index;

class Manager extends ChangeNotifier {
  void handleSettingChanged(String settingKey) {
    notifyListeners();
  }
}
