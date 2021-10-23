import 'dart:io';
import 'dart:typed_data';
import 'package:polaris/core/cache.dart' as cache;

class Manager implements cache.Interface {
  static Future<Manager> create() async {
    return Manager();
  }

  Future<File?> getImage(String host, String path) async {
    return null;
  }

  putImage(String host, String path, Uint8List bytes) async {}
}
