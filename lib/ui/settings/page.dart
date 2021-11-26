import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/settings.dart' as settings;
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/format.dart';
import 'package:polaris/utils.dart';

final getIt = GetIt.instance;

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SettingsScreen(
      title: settingsTitle,
      children: [
        SettingsGroup(
          title: appearanceHeader,
          children: const [
            ThemeModeSetting(),
          ],
        ),
        SettingsGroup(
          title: performanceHeader,
          children: const [
            CacheSizeSetting(),
            NumSongsToPreloadSetting(),
          ],
        ),
      ],
    );
  }
}

class CacheSizeSetting extends StatelessWidget {
  const CacheSizeSetting({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueChangeObserver(
      cacheKey: settings.keyCacheCapacityMB,
      defaultValue: settings.defaultCacheSizeMB,
      builder: (context, int cacheSizeBytes, _) {
        return SimpleSettingsTile(
          title: cacheSize,
          leading: const SettingTileIcon(Icons.sd_card, Colors.green),
          subtitle: formatBytes(oneMB * cacheSizeBytes, 0),
          child: SettingsScreen(
            title: settingsTitle,
            children: [
              Builder(builder: (context) {
                return RadioSettingsTile<int>(
                  title: cacheSize,
                  subtitle: cacheSizeDescription,
                  settingKey: settings.keyCacheCapacityMB,
                  values: const <int, String>{
                    100: '100 MB',
                    500: '500 MB',
                    1024: '1 GB',
                    (5 * 1024): '5 GB',
                    (10 * 1024): '10 GB',
                    (100 * 1024): '100 GB',
                  },
                  selected: cacheSizeBytes,
                  onChange: (value) {
                    getIt<settings.Manager>().handleSettingChanged(settings.keyCacheCapacityMB);
                    Navigator.of(context).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class NumSongsToPreloadSetting extends StatelessWidget {
  const NumSongsToPreloadSetting({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueChangeObserver(
      cacheKey: settings.keyNumSongsToPreload,
      defaultValue: settings.defaultNumSongsToPreload,
      builder: (context, int numSongs, _) {
        return SimpleSettingsTile(
          title: numberOfSongsToPreload,
          leading: const SettingTileIcon(Icons.queue_music, Colors.blueGrey),
          subtitle: nSongs(numSongs),
          child: SettingsScreen(
            title: settingsTitle,
            children: [
              Builder(builder: (context) {
                return RadioSettingsTile<int>(
                  title: numberOfSongsToPreload,
                  subtitle: numberOfSongsToPreloadDescription,
                  settingKey: settings.keyNumSongsToPreload,
                  values: const <int, String>{
                    0: '0',
                    1: '1',
                    2: '2',
                    5: '5',
                    10: '10',
                  },
                  selected: numSongs,
                  onChange: (value) {
                    getIt<settings.Manager>().handleSettingChanged(settings.keyNumSongsToPreload);
                    Navigator.of(context).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class ThemeModeSetting extends StatelessWidget {
  const ThemeModeSetting({Key? key}) : super(key: key);

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return themeLight;
      case ThemeMode.dark:
        return themeDark;
      case ThemeMode.system:
      default:
        return themeSystem;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueChangeObserver<int>(
      cacheKey: settings.keyThemeMode,
      defaultValue: settings.defaultThemeMode,
      builder: (context, int themeMode, _) {
        return SimpleSettingsTile(
          title: theme,
          leading: const SettingTileIcon(Icons.dark_mode, Colors.purple),
          subtitle: _themeModeToString(ThemeMode.values[themeMode]),
          child: SettingsScreen(
            title: settingsTitle,
            children: [
              Builder(builder: (context) {
                return RadioSettingsTile<int>(
                  title: theme,
                  subtitle: themeDescription,
                  settingKey: settings.keyThemeMode,
                  values: <int, String>{
                    ThemeMode.light.index: themeLight,
                    ThemeMode.dark.index: themeDark,
                    ThemeMode.system.index: themeSystem,
                  },
                  selected: themeMode,
                  onChange: (value) {
                    getIt<settings.Manager>().handleSettingChanged(settings.keyThemeMode);
                    Navigator.of(context).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class SettingTileIcon extends StatelessWidget {
  final Color color;
  final IconData icon;
  const SettingTileIcon(this.icon, this.color, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}
