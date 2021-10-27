import 'dart:io';
import 'dart:typed_data';
import 'package:polaris/core/cache.dart' as cache;

class Manager implements cache.Interface {
  static Future<Manager> create() async {
    return Manager();
  }

  @override
  Future<File?> getImage(String host, String path) async {
    return null;
  }

  @override
  putImage(String host, String path, Uint8List bytes) async {}

  @override
  Future<File?> getAudio(String host, String path) async {}

  @override
  File getAudioLocation(String host, String path) {
    return File("");
  }
}
