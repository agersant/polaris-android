import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final _slashRegExp = RegExp(r'[:/\.\\]');
final _version = 4;

class Manager {
  Directory _root;

  Manager(this._root);

  static Future<Manager> create() async {
    // TODO delete previous directories for previous versions
    final temporaryDirectory = await getTemporaryDirectory();
    final root = new Directory(p.join(temporaryDirectory.path, 'collection', 'v$_version'));
    await root.create(recursive: true);
    return Manager(root);
  }

  Future<File> getImage(String host, String path) async {
    final fullPath = _generateImagePath(host, path);
    final file = new File(fullPath);
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  putImage(String host, String path, Uint8List bytes) async {
    developer.log('Adding image to disk cache: $path');
    final fullPath = _generateImagePath(host, path);
    final file = new File(fullPath);
    try {
      await file.writeAsBytes(bytes, mode: FileMode.writeOnly, flush: true);
    } catch (e) {
      developer.log('Error saving image $path', error: e);
    }
  }

  String _generateImageKey(String host, String path) {
    host = host.replaceAll(_slashRegExp, '-');
    path = path.replaceAll(_slashRegExp, '-');
    return host + '__polaris__image__' + path;
  }

  String _generateImagePath(String host, String path) {
    return p.join(_root.path, _generateImageKey(host, path));
  }
}
