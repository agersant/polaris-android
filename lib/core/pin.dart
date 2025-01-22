import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/polaris.dart' as polaris;

const _firstVersion = 1;
const _currentVersion = 2;

abstract class ManagerInterface extends ChangeNotifier {
  List<String> get hosts;
  Set<String>? getSongsInHost(String host);
  List<Pin>? getPinsForHost(String host);
  int countSongs();
}

sealed class Pin {
  Pin();

  factory Pin.fromJson(Map<String, dynamic> json) {
    final String type = json['type'];
    return switch (type) {
      'song' => SongPin.fromJson(json),
      'directory' => DirectoryPin.fromJson(json),
      'album' => AlbumPin.fromJson(json),
      _ => throw 'Unexpected pin type: `$type`',
    };
  }

  String get key;
  List<String> get songs;
  Map<String, dynamic> toJson();
}

class SongPin extends Pin {
  final String path;
  SongPin(this.path);

  @override
  String get key => path;

  @override
  List<String> get songs => [path];

  factory SongPin.fromJson(Map<String, dynamic> json) => SongPin(json['path']);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': 'song',
        'path': path,
      };
}

class DirectoryPin extends Pin {
  final String path;
  final List<String> _songs;

  DirectoryPin(this.path, this._songs);

  @override
  String get key => path;

  @override
  List<String> get songs => _songs;

  factory DirectoryPin.fromJson(Map<String, dynamic> json) => DirectoryPin(
        json['path'],
        (json['songs'] as List<dynamic>).cast<String>().toList(),
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': 'directory',
        'path': path,
        'songs': songs,
      };
}

class AlbumPin extends Pin {
  final String name;
  final String? artwork;
  final List<String> mainArtists;
  final List<String> _songs;

  AlbumPin(this.name, this.mainArtists, this._songs, this.artwork);

  @override
  String get key => name + mainArtists.join('');

  @override
  List<String> get songs => _songs;

  factory AlbumPin.fromJson(Map<String, dynamic> json) => AlbumPin(
        json['name'],
        (json['mainArtists'] as List<dynamic>).cast<String>().toList(),
        (json['songs'] as List<dynamic>).cast<String>().toList(),
        json['artwork'],
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': 'album',
        'name': name,
        'mainArtists': mainArtists,
        'songs': songs,
        'artwork': artwork,
      };
}

class Pins {
  final Map<String, Set<Pin>> byHost = {};

  Pins();

  factory Pins.fromBytes(List<int> bytes) {
    return Pins.fromJson(jsonDecode(utf8.decode(io.gzip.decode(bytes))));
  }

  List<int> toBytes() {
    return io.gzip.encode(utf8.encode(jsonEncode(this)));
  }

  Pins.fromJson(Map<String, dynamic> json) {
    json['byHost'].forEach((String host, dynamic pins) {
      byHost[host] = (pins as List<dynamic>).map((p) => Pin.fromJson(p)).toSet();
    });
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'byHost': byHost.map(
          (host, pins) => MapEntry(
            host,
            pins.map((p) => p.toJson()).toList(),
          ),
        )
      };
}

class Manager extends ChangeNotifier implements ManagerInterface {
  final connection.Manager connectionManager;
  final polaris.Client polarisClient;
  final Pins _pins;

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

    return Manager(
      pins,
      connectionManager: connectionManager,
      polarisClient: polarisClient,
    );
  }

  Manager(
    this._pins, {
    required this.connectionManager,
    required this.polarisClient,
  });

  static Future<io.File> _getPinsFile(int version) async {
    final temporaryDirectory = await getTemporaryDirectory();
    return io.File(p.join(temporaryDirectory.path, 'pins-v$version.pins'));
  }

  @override
  List<String> get hosts {
    final hosts = _pins.byHost.entries.where((e) => e.value.isNotEmpty).map((e) => e.key).toList();
    hosts.sort();
    return hosts;
  }

  @override
  Set<String>? getSongsInHost(String host) {
    return _pins.byHost[host]
        ?.map((p) => switch (p) {
              final SongPin p => [p.path],
              final DirectoryPin p => p.songs,
              final AlbumPin p => p.songs,
            })
        .expand<String>((p) => p)
        .toSet();
  }

  @override
  List<Pin>? getPinsForHost(String host) {
    final list = _pins.byHost[host]?.toList() ?? [];
    list.sort(
      (a, b) => switch ((a, b)) {
        (final DirectoryPin _, final AlbumPin _) => -1,
        (final DirectoryPin a, final DirectoryPin b) => a.path.compareTo(b.path),
        (final DirectoryPin _, final SongPin _) => -1,
        (final AlbumPin a, final AlbumPin b) => a.name.compareTo(b.name),
        (final AlbumPin _, final DirectoryPin _) => 1,
        (final AlbumPin _, final SongPin _) => -1,
        (final SongPin _, final AlbumPin _) => 1,
        (final SongPin _, final DirectoryPin _) => 1,
        (final SongPin a, final SongPin b) => a.path.compareTo(b.path),
      },
    );
    return list;
  }

  @override
  int countSongs() {
    return _pins.byHost.values.fold(0, (a, b) => a + b.length);
  }

  void pinSong(String song) async {
    final host = connectionManager.url;
    if (host == null) {
      return;
    }
    _pins.byHost.putIfAbsent(host, () => {}).add(SongPin(song));
    notifyListeners();
    await saveToDisk();
  }

  void unpinSong(String song) async {
    final host = connectionManager.url;
    if (host == null) {
      return;
    }
    _pins.byHost[host]?.removeWhere((p) => switch (p) {
          final SongPin p => p.path == song,
          _ => false,
        });
    notifyListeners();
    await saveToDisk();
  }

  bool isSongPinned(String song) {
    final host = connectionManager.url;
    if (host == null) {
      return false;
    }
    return _pins.byHost[host]?.any((p) => switch (p) {
              final SongPin p => p.path == song,
              _ => false,
            }) ??
        false;
  }

  void pinDirectory(String path) async {
    final host = connectionManager.url;
    if (host == null) {
      return;
    }
    final songList = await polarisClient.httpClient?.flatten(path);
    if (songList == null) {
      return;
    }
    _pins.byHost.putIfAbsent(host, () => {}).add(DirectoryPin(path, songList.paths));
    notifyListeners();
    await saveToDisk();
  }

  void unpinDirectory(String path) async {
    final host = connectionManager.url;
    if (host == null) {
      return;
    }
    _pins.byHost[host]?.removeWhere((p) => switch (p) {
          final DirectoryPin p => p.path == path,
          _ => false,
        });
    notifyListeners();
    await saveToDisk();
  }

  bool isDirectoryPinned(String path) {
    final host = connectionManager.url;
    if (host == null) {
      return false;
    }
    return _pins.byHost[host]?.any((p) => switch (p) {
              final DirectoryPin p => p.path == path,
              _ => false,
            }) ??
        false;
  }

  void pinAlbum(String name, List<String> mainArtists, String? artwork) async {
    final host = connectionManager.url;
    if (host == null) {
      return;
    }
    final album = await polarisClient.httpClient?.getAlbum(name, mainArtists);
    if (album == null) {
      return;
    }
    final songs = album.songs.map((s) => s.path).toList();
    _pins.byHost.putIfAbsent(host, () => {}).add(AlbumPin(name, mainArtists, songs, artwork));
    notifyListeners();
    await saveToDisk();
  }

  void unpinAlbum(String name, List<String> mainArtists) async {
    final host = connectionManager.url;
    if (host == null) {
      return;
    }
    _pins.byHost[host]?.removeWhere((p) => switch (p) {
          final AlbumPin p => p.name == name && listEquals(p.mainArtists, mainArtists),
          _ => false,
        });
    notifyListeners();
    await saveToDisk();
  }

  bool isAlbumPinned(String name, List<String> mainArtists) {
    final host = connectionManager.url;
    if (host == null) {
      return false;
    }
    return _pins.byHost[host]?.any((p) => switch (p) {
              final AlbumPin p => p.name == name && listEquals(p.mainArtists, mainArtists),
              _ => false,
            }) ??
        false;
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
