import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' as io;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/utils.dart';
import 'package:rxdart/rxdart.dart';

const _firstVersion = 1;
const _currentVersion = 2;

class CollectionCache {
  final Collection _collection;
  final BehaviorSubject<()> _songIngestion = BehaviorSubject();
  final BehaviorSubject<()> _songRequest = BehaviorSubject();
  final BehaviorSubject<()> _playlists = BehaviorSubject();
  Stream<()> get onSongsIngested => _songIngestion.stream;
  Stream<()> get onSongsRequested => _songRequest.stream;
  Stream<()> get onPlaylistsUpdated => _playlists.stream;

  CollectionCache(this._collection);

  static Future<io.File> _getCollectionFile(int version) async {
    final temporaryDirectory = await getTemporaryDirectory();
    return io.File(p.join(temporaryDirectory.path, 'collection-v$version.cache'));
  }

  static Future<CollectionCache> create() async {
    for (int version = _firstVersion; version < _currentVersion; version++) {
      final oldCacheFile = await _getCollectionFile(version);
      oldCacheFile.exists().then((exists) {
        if (exists) {
          oldCacheFile.delete(recursive: true);
        }
      });
    }

    Collection collection = Collection();
    final currentCacheFile = await _getCollectionFile(_currentVersion);
    try {
      if (await currentCacheFile.exists()) {
        final cacheData = await currentCacheFile.readAsBytes();
        collection = Collection.fromBytes(cacheData);
        developer.log('Read collection cache from: $currentCacheFile');
      }
    } catch (e) {
      developer.log('Error while reading collection from disk: ', error: e);
    }

    return CollectionCache(collection);
  }

  Future saveToDisk() async {
    try {
      final cacheFile = await _getCollectionFile(_currentVersion);
      await cacheFile.create(recursive: true);
      final serializedData = _collection.toBytes();
      await cacheFile.writeAsBytes(serializedData, flush: true);
      developer.log('Wrote collection cache to: $cacheFile');
    } catch (e) {
      developer.log('Error while writing collection to disk: ', error: e);
    }
  }

  Future putDirectory(String host, String path, List<dto.BrowserEntry> entries) async {
    final server = _collection.servers.putIfAbsent(host, () => Server());
    server.directoryChildren[path] = {};
    server.directorySongs[path] = {};
    bool hasNewSongs = false;

    for (dto.BrowserEntry entry in entries) {
      if (entry.isDirectory) {
        server.directoryChildren[path]!.add(entry.path);
      } else {
        server.directorySongs[path]!.add(entry.path);
        hasNewSongs |= !server.songs.containsKey(entry.path);
      }
    }

    server.populatedDirectories.add(path);
    if (hasNewSongs) {
      _songRequest.value = ();
    }
    await saveToDisk();
  }

  Future putFiles(String host, List<String> files) async {
    final server = _collection.servers.putIfAbsent(host, () => Server());
    bool hasNewSongs = false;

    for (String path in files) {
      final components = splitPath(path);
      server.directorySongs.putIfAbsent(components.length > 1 ? dirname(path) : "", () => {}).add(path);
      hasNewSongs |= !server.songs.containsKey(path);
      String parent = components[0];
      for (int i = 1; i < components.length - 1; i++) {
        final child = '$parent/${components[i]}';
        server.directoryChildren.putIfAbsent(parent, () => {}).add(child);
        parent = child;
      }
    }

    if (hasNewSongs) {
      _songRequest.value = ();
    }
    await saveToDisk();
  }

  Future putSongs(String host, List<dto.Song> songs) async {
    final server = _collection.servers.putIfAbsent(host, () => Server());
    for (dto.Song song in songs) {
      server.songs[song.path] = song;
      final components = splitPath(song.path);
      server.directorySongs.putIfAbsent(components.length > 1 ? dirname(song.path) : "", () => {}).add(song.path);
      String parent = components[0];
      for (int i = 1; i < components.length - 1; i++) {
        final child = '$parent/${components[i]}';
        server.directoryChildren.putIfAbsent(parent, () => {}).add(child);
        parent = child;
      }
    }
    _songIngestion.value = ();
    await saveToDisk();
  }

  void putPlaylists(String host, List<dto.PlaylistHeader> playlists) {
    final server = _collection.servers.putIfAbsent(host, () => Server());
    server.playlists = playlists;
    _playlists.value = ();
  }

  Set<String> getMissingSongs(String host) {
    final server = _collection.servers[host];
    if (server == null) {
      return {};
    }

    final Set<String> missing = {};
    server.directorySongs.forEach((_, paths) {
      for (final path in paths) {
        if (!server.songs.containsKey(path)) {
          missing.add(path);
        }
      }
    });

    return missing;
  }

  bool hasSong(String host, String path) {
    final server = _collection.servers[host];
    if (server == null) {
      return false;
    }
    return server.songs.containsKey(path);
  }

  dto.Song? getSong(String host, String path) {
    final server = _collection.servers[host];
    if (server == null) {
      return null;
    }
    return server.songs[path];
  }

  (Stream<dto.Song?>, dto.Song?) getSongStream(String host, String path) {
    final song = getSong(host, path);
    final stream =
        song != null ? Stream.value(song) : onSongsIngested.map((_) => getSong(host, path)).whereNotNull().take(1);
    return (stream, song);
  }

  List<dto.BrowserEntry>? getDirectory(String host, String path) {
    final server = _collection.servers[host];
    if (server == null) {
      return null;
    }

    final subdirectories = (server.directoryChildren[path] ?? {}).toList(growable: false)..sort(compareStrings);
    final songs = (server.directorySongs[path] ?? {}).toList(growable: false)..sort(compareStrings);

    return subdirectories
        .map((path) => dto.BrowserEntry(path: path, isDirectory: true))
        .followedBy(songs.map((path) => dto.BrowserEntry(path: path, isDirectory: false)))
        .toList(growable: false);
  }

  List<dto.PlaylistHeader>? getPlaylists(String host) {
    return _collection.servers[host]?.playlists;
  }

  bool hasPopulatedDirectory(String host, String path) {
    return _collection.servers[host]?.populatedDirectories.contains(path) ?? false;
  }

  List<String>? flattenDirectory(String host, String path) {
    final server = _collection.servers[host];
    if (server == null) {
      return null;
    }

    final List<String> exploreList = [path];
    final List<String> songs = [];
    while (exploreList.isNotEmpty) {
      final location = exploreList.removeLast();
      for (String song in server.directorySongs[location] ?? []) {
        songs.add(song);
      }
      for (String directory in server.directoryChildren[location] ?? []) {
        exploreList.add(directory);
      }
    }

    songs.sort(compareStrings);
    return songs;
  }
}

class Collection {
  final Map<String, Server> servers = {};

  Collection();

  factory Collection.fromBytes(List<int> bytes) {
    return Collection.fromJson(jsonDecode(utf8.decode(io.gzip.decode(bytes))));
  }

  List<int> toBytes() {
    return io.gzip.encode(utf8.encode(jsonEncode(this)));
  }

  Collection.fromJson(Map<String, dynamic> json) {
    json['servers'].forEach((String k, dynamic v) {
      servers[k] = Server.fromJson(v);
    });
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'servers': servers.map((k, v) => MapEntry(k, v.toJson())),
      };
}

class Server {
  Set<String> populatedDirectories = {};
  Map<String, Set<String>> directoryChildren = {};
  Map<String, Set<String>> directorySongs = {};
  Map<String, dto.Song> songs = {};
  List<dto.PlaylistHeader>? playlists; // not serialized

  Server();

  Server.fromJson(Map<String, dynamic> json)
      : populatedDirectories = (json['populatedDirectories'] as List<dynamic>).cast<String>().toSet() {
    json['directoryChildren'].forEach((String k, dynamic v) {
      directoryChildren[k] = (v as List<dynamic>).cast<String>().toSet();
    });

    json['directorySongs'].forEach((String k, dynamic v) {
      directorySongs[k] = (v as List<dynamic>).cast<String>().toSet();
    });

    json['songs'].forEach((String k, dynamic v) {
      songs[k] = dto.Song.fromJson(v);
    });
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'populatedDirectories': populatedDirectories.toList(),
        'directoryChildren': directoryChildren.map((key, value) => MapEntry(key, value.toList())),
        'directorySongs': directorySongs.map((key, value) => MapEntry(key, value.toList())),
        'songs': songs.map((key, value) => MapEntry(key, value.toJson())),
      };
}
