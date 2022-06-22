import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/dto.dart' as dto;
import 'package:polaris/core/polaris.dart' as polaris;
import 'package:rxdart/rxdart.dart';

const _firstVersion = 1;
const _currentVersion = 1;

abstract class ManagerInterface extends ChangeNotifier {
  Set<Host> get hosts;
  Stream<Set<Host>> get hostsStream;
  Set<dto.Song> getSongs(String host);
  Set<dto.Directory> getDirectories(String host);
  Future<Set<dto.Song>?> getAllSongs(String host);
  Future<Set<dto.Song>?> getSongsInDirectory(String host, String path);
}

class Manager extends ChangeNotifier implements ManagerInterface {
  final connection.Manager connectionManager;
  final polaris.Client polarisClient;
  final Map<String, Map<String, Set<dto.Song>>> _flattenCache = {};
  final Storage _storage;

  final _hostsSubject = BehaviorSubject<Set<Host>>.seeded({});

  @override
  Stream<Set<Host>> get hostsStream => _hostsSubject.stream;

  @override
  Set<Host> get hosts => _hostsSubject.value;

  Manager(
    this._storage, {
    required this.connectionManager,
    required this.polarisClient,
  }) {
    _updateHosts();
  }

  static Future<io.File> _getPinsFile(int version) async {
    final temporaryDirectory = await getTemporaryDirectory();
    return io.File(p.join(temporaryDirectory.path, 'pins-v$version.pins'));
  }

  static Future<Manager> create({
    required connection.Manager connectionManager,
    required polaris.Client polarisClient,
  }) async {
    for (int version = _firstVersion; version < _currentVersion; version++) {
      final oldCacheFile = await _getPinsFile(version);
      oldCacheFile.exists().then((exists) {
        if (exists) {
          oldCacheFile.delete(recursive: true);
        }
      });
    }

    Storage pins = Storage();
    final cachedFile = await _getPinsFile(_currentVersion);
    try {
      if (await cachedFile.exists()) {
        final cacheData = await cachedFile.readAsBytes();
        pins = Storage.fromBytes(cacheData);
        developer.log('Read pins list from: $cachedFile');
      }
    } catch (e) {
      developer.log('Error while reading pins list from disk: ', error: e);
    }

    return Manager(
      pins,
      connectionManager: connectionManager,
      polarisClient: polarisClient,
    );
  }

  @override
  Set<dto.Directory> getDirectories(String host) {
    final server = _storage._servers[host];
    if (server == null) {
      return {};
    }
    return server.values.where((file) => file.isDirectory()).map<dto.Directory>((file) => file.asDirectory()).toSet();
  }

  @override
  Set<dto.Song> getSongs(String host) {
    final server = _storage._servers[host];
    if (server == null) {
      return {};
    }
    return server.values.where((file) => file.isSong()).map<dto.Song>((file) => file.asSong()).toSet();
  }

  @override
  Future<Set<dto.Song>?> getAllSongs(String host) async {
    final allSongs = getSongs(host);
    final directories = getDirectories(host);
    for (dto.Directory directory in directories) {
      Set<dto.Song>? songs = await _flatten(host, directory.path);
      if (songs == null) {
        return null;
      }
      allSongs.addAll(songs);
    }
    return allSongs;
  }

  @override
  Future<Set<dto.Song>?> getSongsInDirectory(String host, String path) async {
    return await _flatten(host, path);
  }

  Future<Set<dto.Song>?> _flatten(String host, String path) async {
    Set<dto.Song>? cachedSongs = _flattenCache[host]?[path];
    if (cachedSongs != null) {
      return cachedSongs;
    }

    if (host != connectionManager.url || !connectionManager.isConnected()) {
      try {
        return (await polarisClient.offlineClient.flatten(host, path)).toSet();
      } catch (e) {
        return {};
      }
    }

    try {
      final songs = (await polarisClient.flatten(path)).toSet();
      _flattenCache.putIfAbsent(host, () => {})[path] = songs;
      return songs;
    } catch (e) {
      return null;
    }
  }

  void pin(String host, dto.CollectionFile file) async {
    _storage.add(host, file);
    _updateHosts();
    notifyListeners();
    await saveToDisk();
  }

  void unpin(String host, dto.CollectionFile file) async {
    _storage.remove(host, file);
    _updateHosts();
    notifyListeners();
    await saveToDisk();
  }

  bool isPinned(String host, dto.CollectionFile file) {
    return _storage.contains(host, file);
  }

  Future saveToDisk() async {
    try {
      final cacheFile = await _getPinsFile(_currentVersion);
      await cacheFile.create(recursive: true);
      final serializedData = _storage.toBytes();
      await cacheFile.writeAsBytes(serializedData, flush: true);
      developer.log('Wrote pins list to: $cacheFile');
    } catch (e) {
      developer.log('Error while writing pins list to disk: ', error: e);
    }
  }

  void _updateHosts() {
    _hostsSubject.add(_storage._servers.keys
        .where((host) => _storage._servers[host]?.isNotEmpty ?? false)
        .map((host) => Host(_storage, url: host))
        .toSet());
  }
}

class Host {
  final String url;
  late Set<dto.CollectionFile> content;

  Host(Storage storage, {required this.url}) {
    content = storage._servers[url]?.values.toSet() ?? {};
  }
}

class Storage {
  final Map<String, Map<String, dto.CollectionFile>> _servers = {};

  Storage();

  factory Storage.fromBytes(List<int> bytes) {
    return Storage.fromJson(jsonDecode(utf8.decode(io.gzip.decode(bytes))));
  }

  List<int> toBytes() {
    return io.gzip.encode(utf8.encode(jsonEncode(this)));
  }

  Storage.fromJson(Map<String, dynamic> json) {
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
    hostContent[file.path] = file;
  }

  bool contains(String host, dto.CollectionFile file) {
    final hostContent = _servers[host];
    if (hostContent == null) {
      return false;
    }
    return hostContent[file.path] != null;
  }

  void remove(String host, dto.CollectionFile file) {
    _servers[host]?.remove(file.path);
  }
}
