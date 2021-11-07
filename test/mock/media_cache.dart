import 'dart:io';
import 'dart:typed_data';
import 'package:polaris/core/cache/media.dart';

class MediaCache implements MediaCacheInterface {
  static Future<MediaCache> create() async {
    return MediaCache();
  }

  @override
  Future<File?> getImage(String host, String path) async => null;

  @override
  putImage(String host, String path, Uint8List bytes) async {}

  @override
  Future<File?> getAudio(String host, String path) async {}

  @override
  File getAudioLocation(String host, String path) {
    return File("");
  }
}
