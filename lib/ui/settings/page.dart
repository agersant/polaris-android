import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/settings.dart' as settings;
import 'package:polaris/ui/strings.dart';

final getIt = GetIt.instance;

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SettingsScreen(
      title: settingsTitle,
      children: [
        RadioModalSettingsTile<int>(
          title: numberOfSongsToPreload,
          settingKey: settings.keyNumSongsToPreload,
          values: const <int, String>{
            0: '0',
            1: '1',
            2: '2',
            5: '5',
            10: '10',
          },
          selected: settings.defaultNumSongsToPreload,
          onChange: (value) {
            getIt<settings.Manager>().handleSettingChanged(settings.keyNumSongsToPreload);
          },
        ),
        RadioModalSettingsTile<int>(
          title: cacheSize,
          settingKey: settings.keyCacheCapacityMB,
          values: const <int, String>{
            100: '100 MB',
            500: '500 MB',
            1024: '1 GB',
            (5 * 1024): '5 GB',
            (10 * 1024): '10 GB',
            (100 * 1024): '100 GB',
          },
          selected: settings.defaultCacheSizeMB,
          onChange: (value) {
            getIt<settings.Manager>().handleSettingChanged(settings.keyCacheCapacityMB);
          },
        ),
      ],
    );
  }
}
