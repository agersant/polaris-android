import 'package:flutter/foundation.dart';
import 'package:polaris/core/dto.dart' as dto;
import 'package:polaris/core/pin.dart';

class Manager extends ChangeNotifier implements ManagerInterface {
  static Future<Manager> create() async {
    return Manager();
  }

  @override
  Set<dto.Song>? getSongs(String host) => {};

  @override
  Set<dto.Directory>? getDirectories(String host) => {};

  @override
  Future<Set<dto.Song>> getAllSongs(String host) async => {};
}
