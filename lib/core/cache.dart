import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final _slashRegExp = RegExp(r'[:/\.\\]');
const _firstVersion = 1;
const _currentVersion = 4;

abstract class Interface {
  Future<File?> getImage(String host, String path);
  putImage(String host, String path, Uint8List bytes);
  Future<File?> getAudio(String host, String path);
  File getAudioLocation(String host, String path);
}

class Manager implements Interface {
  final Directory _root;

  Manager(this._root);

  static Future<Manager> create() async {
    final temporaryDirectory = await getTemporaryDirectory();
    makeRoot(int version) => Directory(p.join(temporaryDirectory.path, 'collection', 'v$version'));

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
    return Manager(root);
  }

  @override
  Future<File?> getImage(String host, String path) async {
    final fullPath = _buildImagePath(host, path);
    final file = File(fullPath);
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
  File getAudioLocation(String host, String path) {
    final fullPath = _buildAudioPath(host, path);
    return File(fullPath);
  }

  @override
  Future<File?> getAudio(String host, String path) async {
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
    final file = File(fullPath);
    try {
      await file.writeAsBytes(bytes, mode: FileMode.writeOnly, flush: true);
    } catch (e) {
      developer.log('Error while saving image: $path', error: e);
    }
  }

  String _sanitize(String input) {
    return input.replaceAll(_slashRegExp, '-');
  }

  String _buildImagePath(String host, String path) {
    return p.join(_root.path, _sanitize(host + '__polaris__image__' + path));
  }

  String _buildAudioPath(String host, String path) {
    return p.join(_root.path, _sanitize(host + '__polaris__audio__' + path));
  }
}
