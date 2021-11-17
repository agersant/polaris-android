import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' as io;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:polaris/core/dto.dart' as dto;

const _firstVersion = 1;
const _currentVersion = 1;

abstract class ManagerInterface {
  Set<dto.Song>? getSongs(String host);
}

class Manager implements ManagerInterface {
  final Pins _pins;

  Manager(this._pins);

  Set<String> get hosts => _pins._servers.keys.toSet();

  static Future<io.File> _getPinsFile(int version) async {
    final temporaryDirectory = await getTemporaryDirectory();
    return io.File(p.join(temporaryDirectory.path, 'pins', 'v$version.cache'));
  }

  static Future<Manager> create() async {
    for (int version = _firstVersion; version < _currentVersion; version++) {
      final oldCacheFile = await _getPinsFile(version);
      oldCacheFile.exists().then((exists) {
        if (exists) {
          oldCacheFile.delete(recursive: true);
        }
      });
    }

    Pins pins = Pins();
    final cachedFile = await _getPinsFile(_currentVersion);
    try {
      if (await cachedFile.exists()) {
        final cacheData = await cachedFile.readAsBytes();
        pins = Pins.fromBytes(cacheData);
        developer.log('Read pins list from: $cachedFile');
      }
    } catch (e) {
      developer.log('Error while reading pins list from disk: ', error: e);
    }

    return Manager(pins);
  }

  Set<dto.Directory>? getDirectories(String host) {
    return _pins._servers[host]?.values
        .where((file) => file.isDirectory())
        .map<dto.Directory>((file) => file.asDirectory())
        .toSet();
  }

  @override
  Set<dto.Song>? getSongs(String host) {
    return _pins._servers[host]?.values.where((file) => file.isSong()).map<dto.Song>((file) => file.asSong()).toSet();
  }

  void pin(String host, dto.CollectionFile file) async {
    _pins.add(host, file);
    await saveToDisk();
  }

  void unpin(String host, dto.CollectionFile file) async {
    _pins.remove(host, file);
    await saveToDisk();
  }

  bool isPinned(String host, dto.CollectionFile file) {
    return _pins.contains(host, file);
  }

  Future saveToDisk() async {
    try {
      final cacheFile = await _getPinsFile(_currentVersion);
      await cacheFile.create(recursive: true);
      final serializedData = _pins.toBytes();
      await cacheFile.writeAsBytes(serializedData, flush: true);
      developer.log('Wrote pins list to: $cacheFile');
    } catch (e) {
      developer.log('Error while writing pins list to disk: ', error: e);
    }
  }
}

class Pins {
  final Map<String, Map<String, dto.CollectionFile>> _servers = {};

  Pins();

  factory Pins.fromBytes(List<int> bytes) {
    return Pins.fromJson(jsonDecode(utf8.decode(io.gzip.decode(bytes))));
  }

  List<int> toBytes() {
    return io.gzip.encode(utf8.encode(jsonEncode(this)));
  }

  Pins.fromJson(Map<String, dynamic> json) {
    json['servers'].forEach((String host, dynamic files) {
      _servers[host] = <String, dto.CollectionFile>{};
      files.forEach((String path, dynamic file) {
        _servers[host]![path] = dto.CollectionFile.fromJson(file);
      });
    });
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'servers': _servers.map(
          (host, files) => MapEntry(
            host,
            files.map((path, file) => MapEntry(path, file.toJson())),
          ),
        )
      };

  void add(String host, dto.CollectionFile file) {
    final hostContent = _servers.putIfAbsent(host, () => <String, dto.CollectionFile>{});
    if (file.isSong()) {
      hostContent[file.asSong().path] = file;
    } else {
      hostContent[file.asDirectory().path] = file;
    }
  }

  bool contains(String host, dto.CollectionFile file) {
    final hostContent = _servers[host];
    if (hostContent == null) {
      return false;
    }
    if (file.isSong()) {
      return hostContent[file.asSong().path] != null;
    } else {
      return hostContent[file.asDirectory().path] != null;
    }
  }

  void remove(String host, dto.CollectionFile file) {
    if (file.isSong()) {
      _servers[host]?.remove(file.asSong().path);
    } else {
      _servers[host]?.remove(file.asDirectory().path);
    }
  }
}
