import 'package:flutter/foundation.dart';
import 'package:polaris/core/pin.dart';

class Manager extends ChangeNotifier implements ManagerInterface {
  static Future<Manager> create() async {
    return Manager();
  }

  @override
  List<String> get hosts => [];

  @override
  Set<String>? getSongsInHost(String host) => {};

  @override
  List<Pin>? getPinsForHost(String host) => [];

  @override
  int countSongs() => 0;
}
