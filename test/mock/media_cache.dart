import 'dart:io';
import 'dart:typed_data';
import 'package:polaris/core/cache/media.dart';

class MediaCache implements MediaCacheInterface {
  static Future<MediaCache> create() async {
    return MediaCache();
  }

  @override
  void dispose() {}

  @override
  Future<bool> hasImage(String host, String path) async => false;

  @override
  Future<File?> getImage(String host, String path) async => null;

  @override
  File getImageLocation(String host, String path) => File("");

  @override
  putImage(String host, String path, Uint8List bytes) async {}

  @override
  Future<bool> hasAudio(String host, String path) async => false;

  @override
  Future<void> putAudio(String host, String path, File source) async {}

  @override
  bool hasAudioSync(String host, String path) => false;

  @override
  Future<File?> getAudio(String host, String path) async {
    return null;
  }

  @override
  File getAudioLocation(String host, String path) => File("");

  @override
  Future<void> purge(Map<String, Set<String>> songsToPreserve, Map<String, Set<String>> imagesToPreserve) async {}
}
