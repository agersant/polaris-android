import 'package:dartz/dartz.dart';
import 'package:path/path.dart' as p;
import 'package:polaris/core/dto.dart' as dto;

class CollectionCache {
  final _collection = Collection(); // TODO read collection from disk

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
        .toList(); // TODO sort
  }

  bool hasPopulatedDirectory(String host, String path) {
    final directory = _collection.readDirectory(host, path);
    return directory?.populated == true;
  }

  putDirectory(String host, String path, List<dto.CollectionFile> content) {
    _collection.populateDirectory(host, path, content);
  }

  List<dto.Song>? flattenDirectory(String host, String path) {
    return _collection.flattenDirectory(host, path)?.map((song) => song.data).toList(); // TODO sort
  }
}

class Collection {
  Map<String, Directory> servers = {};

  populateDirectory(String host, String path, List<dto.CollectionFile> content) {
    final parent = _findOrCreateDirectory(host, path);
    final Set<String> childrenToKeep = {};
    for (dto.CollectionFile file in content) {
      if (file.isSong()) {
        final name = p.basename(file.asSong().path);
        parent._children[name] = File(Left(Song(file.asSong())));
        childrenToKeep.add(name);
      } else {
        final name = p.basename(file.asDirectory().path);
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
    final components = _splitPath(path);
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

    final components = _splitPath(path);
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

  static List<String> _splitPath(String path) {
    // TODO this probably won't split path correctly when they use \ as separator (ie. server running on Windows)
    return p.split(path);
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
}

class Directory {
  dto.Directory? data;
  final Map<String, File> _children = {};
  bool populated = false;
  Map<String, File> get children => {..._children};

  Directory({this.data});
}

class Song {
  final dto.Song data;
  int lastUsed = 0;

  Song(this.data);
}
