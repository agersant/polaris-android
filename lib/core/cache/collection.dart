import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' as io;
import 'package:dartz/dartz.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:polaris/core/dto.dart' as dto;
import 'package:polaris/utils.dart';

const _firstVersion = 1;
const _currentVersion = 1;

class CollectionCache {
  final Collection _collection;

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

  List<dto.CollectionFile>? getDirectory(String host, String path) {
    return _collection
        .readDirectory(host, path)
        ?.children
        .map((name, file) {
          if (file.isSong()) {
            return MapEntry(name, dto.CollectionFile(Left(file.asSong().data)));
          } else {
            final directory = file.asDirectory().data ?? dto.Directory(path: p.join(path, name));
            return MapEntry(name, dto.CollectionFile(Right(directory)));
          }
        })
        .values
        .toList()
      ?..sort();
  }

  bool hasPopulatedDirectory(String host, String path) {
    final directory = _collection.readDirectory(host, path);
    return directory?.populated == true;
  }

  Future putDirectory(String host, String path, List<dto.CollectionFile> content) async {
    _collection.populateDirectory(host, path, content);
    await saveToDisk();
  }

  Future putSongs(String host, List<dto.Song> songs) async {
    _collection.addSongs(host, songs);
    await saveToDisk();
  }

  List<dto.Song>? flattenDirectory(String host, String path) {
    return _collection.flattenDirectory(host, path)?.map((song) => song.data).toList()
      ?..sort((a, b) => a.path.compareTo(b.path));
  }
}

class Collection {
  final Map<String, Directory> servers = {};

  Collection();

  factory Collection.fromBytes(List<int> bytes) {
    return Collection.fromJson(jsonDecode(utf8.decode(io.gzip.decode(bytes))));
  }

  List<int> toBytes() {
    return io.gzip.encode(utf8.encode(jsonEncode(this)));
  }

  Collection.fromJson(Map<String, dynamic> json) {
    json['servers'].forEach((String k, dynamic v) {
      servers[k] = Directory.fromJson(v);
    });
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'servers': servers.map((k, v) => MapEntry(k, v.toJson())),
      };

  void populateDirectory(String host, String path, List<dto.CollectionFile> content) {
    final parent = _findOrCreateDirectory(host, path);
    final Set<String> childrenToKeep = {};
    for (dto.CollectionFile file in content) {
      final name = basename(file.path);
      if (file.isSong()) {
        parent._children[name] = File(Left(Song(file.asSong())));
        childrenToKeep.add(name);
      } else {
        if (parent._children[name]?.isDirectory() != true) {
          parent._children[name] = File(Right(Directory()));
        }
        parent._children[name]!.asDirectory().data = file.asDirectory();
        childrenToKeep.add(name);
      }
    }
    parent._children.removeWhere((key, value) => !childrenToKeep.contains(key));
    parent.populated = true;
  }

  void addSongs(String host, List<dto.Song> songs) {
    for (dto.Song song in songs) {
      final directoryPath = dirname(song.path);
      final name = basename(song.path);
      final parent = _findOrCreateDirectory(host, directoryPath);
      parent._children[name] = File(Left(Song(song)));
    }
  }

  Directory? readDirectory(String host, String path) {
    if (!_directoryExists(host, path)) {
      return null;
    }
    return _findOrCreateDirectory(host, path);
  }

  List<Song>? flattenDirectory(String host, String path) {
    if (!_directoryExists(host, path)) {
      return null;
    }
    final Directory directory = _findOrCreateDirectory(host, path);
    final List<File> exploreList = [];
    final List<Song> songs = [];
    exploreList.addAll(directory._children.values);
    while (exploreList.isNotEmpty) {
      final candidate = exploreList.removeLast();
      if (candidate.isSong()) {
        songs.add(candidate.asSong());
      } else {
        exploreList.addAll(candidate.asDirectory()._children.values);
      }
    }
    return songs;
  }

  bool _directoryExists(String host, String path) {
    final Directory? topLevelDirectory = servers[host];
    if (topLevelDirectory == null) {
      return false;
    }
    final components = splitPath(path);
    File? file = File(Right(topLevelDirectory));
    while (components.isNotEmpty) {
      final component = components.removeAt(0);
      final parent = file!.asDirectory();
      file = parent._children[component];
      if (file == null || file.isSong()) {
        return false;
      }
    }
    return true;
  }

  Directory _findOrCreateDirectory(String host, String path) {
    Directory? topLevelDirectory = servers[host];
    if (topLevelDirectory == null) {
      Directory newDirectory = Directory();
      servers[host] = newDirectory;
      topLevelDirectory = newDirectory;
    }

    final components = splitPath(path);
    File? file = File(Right(topLevelDirectory));
    while (components.isNotEmpty) {
      final component = components.removeAt(0);
      final parent = file!.asDirectory();
      file = parent._children[component];
      if (file == null || !file.isDirectory()) {
        file = parent._children[component] = File(Right(Directory()));
      }
    }
    return file!.asDirectory();
  }
}

class File {
  final Either<Song, Directory> content;
  File(this.content);

  bool isSong() {
    return content.isLeft();
  }

  bool isDirectory() {
    return content.isRight();
  }

  Song asSong() {
    return content.fold((song) => song, (directory) => throw "cache.File is not a song");
  }

  Directory asDirectory() {
    return content.fold((song) => throw "cache.File is not a directory", (directory) => directory);
  }

  factory File.fromJson(Map<String, dynamic> json) {
    if (json['song'] != null) {
      return File(Left(Song.fromJson(json['song'])));
    }
    if (json['directory'] != null) {
      return File(Right(Directory.fromJson(json['directory'])));
    }
    throw ArgumentError("Malformed cache file Json");
  }

  Map<String, dynamic> toJson() => content.fold(
        (song) => <String, dynamic>{'song': song.toJson()},
        (directory) => <String, dynamic>{'directory': directory.toJson()},
      );
}

class Directory {
  dto.Directory? data;
  final Map<String, File> _children;
  bool populated = false;

  Map<String, File> get children => {..._children};

  Directory({this.data, Map<String, File>? children}) : _children = children ?? {};

  Directory.fromJson(Map<String, dynamic> json) : _children = {} {
    populated = json['populated'] as bool;
    if (json['data'] != null) {
      data = dto.Directory.fromJson(json['data']);
    }
    json['children'].forEach((String k, dynamic v) {
      _children[k] = File.fromJson(v);
    });
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'data': data?.toJson(),
        'children': _children.map((key, value) => MapEntry(key, value.toJson())),
        'populated': populated,
      };
}

class Song {
  final dto.Song data;
  Song(this.data);

  Song.fromJson(Map<String, dynamic> json) : data = dto.Song.fromJson(json['data']);
  Map<String, dynamic> toJson() => <String, dynamic>{'data': data.toJson()};
}
