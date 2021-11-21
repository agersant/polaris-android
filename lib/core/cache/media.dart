import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _firstVersion = 1;
const _currentVersion = 4;

abstract class MediaCacheInterface {
  Future<bool> hasImage(String host, String path);
  Future<io.File?> getImage(String host, String path);
  io.File getImageLocation(String host, String path);
  Future putImage(String host, String path, Uint8List bytes);
  Future<bool> hasAudio(String host, String path);
  bool hasAudioSync(String host, String path);
  Future<io.File?> getAudio(String host, String path);
  io.File getAudioLocation(String host, String path);
  Future<void> purge(Map<String, Set<String>> songsToPreserve, Map<String, Set<String>> imagesToPreserve);
}

class MediaCache implements MediaCacheInterface {
  final io.Directory _root;

  MediaCache(this._root);

  static Future<MediaCache> create() async {
    final temporaryDirectory = await getTemporaryDirectory();
    makeRoot(int version) => io.Directory(p.join(temporaryDirectory.path, 'media', 'v$version'));

    for (int version = _firstVersion; version < _currentVersion; version++) {
      final oldRoot = makeRoot(version);
      oldRoot.exists().then((exists) {
        if (exists) {
          oldRoot.delete(recursive: true);
        }
      });
    }

    final root = makeRoot(_currentVersion);
    await root.create(recursive: true);

    return MediaCache(root);
  }

  @override
  Future<bool> hasImage(String host, String path) async {
    final file = getImageLocation(host, path);
    return file.exists();
  }

  @override
  Future<io.File?> getImage(String host, String path) async {
    final fullPath = _buildImagePath(host, path);
    final file = io.File(fullPath);
    try {
      if (await file.exists()) {
        developer.log('Found image in cache: $path');
        return file;
      }
    } catch (e) {
      developer.log('Error while accessing image from cache: $path', error: e);
    }
    return null;
  }

  @override
  io.File getImageLocation(String host, String path) {
    final fullPath = _buildImagePath(host, path);
    return io.File(fullPath);
  }

  @override
  io.File getAudioLocation(String host, String path) {
    final fullPath = _buildAudioPath(host, path);
    return io.File(fullPath);
  }

  @override
  Future<bool> hasAudio(String host, String path) async {
    final file = getAudioLocation(host, path);
    return file.exists();
  }

  @override
  bool hasAudioSync(String host, String path) {
    final file = getAudioLocation(host, path);
    return file.existsSync();
  }

  @override
  Future<io.File?> getAudio(String host, String path) async {
    final file = getAudioLocation(host, path);
    try {
      if (await file.exists()) {
        developer.log('Found audio in cache: $path');
        return file;
      }
    } catch (e) {
      developer.log('Error while accessing audio from cache: $path', error: e);
    }
    return null;
  }

  @override
  putImage(String host, String path, Uint8List bytes) async {
    developer.log('Adding image to disk cache: $path');
    final fullPath = _buildImagePath(host, path);
    final file = io.File(fullPath);
    try {
      await file.writeAsBytes(bytes, mode: io.FileMode.writeOnly, flush: true);
    } catch (e) {
      developer.log('Error while saving image: $path', error: e);
    }
  }

  @override
  Future<void> purge(Map<String, Set<String>> songsToPreserve, Map<String, Set<String>> imagesToPreserve) async {
    developer.log('Purging unused files from disk cache');

    final Set<String> filesToPreserve = {};
    songsToPreserve.forEach((host, songs) {
      filesToPreserve.addAll(songs.map((path) => _buildAudioPath(host, path)));
    });
    imagesToPreserve.forEach((host, images) {
      filesToPreserve.addAll(images.map((path) => _buildImagePath(host, path)));
    });

    // TODO use LRU policy to preserve some amount of cached content

    try {
      int numDeleted = 0;
      final cacheContent = _root.list();
      await for (final file in cacheContent) {
        if (!filesToPreserve.contains(file.path)) {
          final fileToDelete = io.File(file.path);
          developer.log('Deleting $file from disk cache');
          await fileToDelete.delete();
          numDeleted += 1;
        }
      }
      developer.log('Purged $numDeleted files from disk cache');
    } catch (e) {
      developer.log('Error while purging unused files from disk cache', error: e);
    }
  }

  String _sanitize(String input) {
    return sha1.convert(utf8.encode(input)).toString();
  }

  String _buildImagePath(String host, String path) {
    return p.join(_root.path, 'image_' + _sanitize(host + '::' + path));
  }

  String _buildAudioPath(String host, String path) {
    return p.join(_root.path, 'audio_' + _sanitize(host + '::' + path));
  }
}
