import 'package:polaris/core/dto.dart' as dto;
import 'package:polaris/core/pin.dart';

class Manager implements ManagerInterface {
  static Future<Manager> create() async {
    return Manager();
  }

  @override
  Set<dto.Song>? getSongs(String host) => {};
}
