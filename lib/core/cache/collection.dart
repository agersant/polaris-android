import 'package:dartz/dartz.dart';
import 'package:path/path.dart' as p;
import 'package:polaris/core/dto.dart' as dto;

class CollectionCache {
  final _collection = Collection(); // TODO read collection from disk

  List<dto.CollectionFile>? getDirectory(String host, String path) {
    return _collection
        .readDirectory(host, path)
        ?.map((name, file) {
          if (file.isSong()) {
            return MapEntry(name, dto.CollectionFile(Left(file.asSong().data)));
          } else {
            final directory = file.asDirectory().data ?? dto.Directory(path: name);
            return MapEntry(name, dto.CollectionFile(Right(directory)));
          }
        })
        .values
        .toList(); // TODO sort
  }

  putDirectory(String host, String path, List<dto.CollectionFile> content) {
    _collection.populateDirectory(host, path, content);
  }
}

class Collection {
  Map<String, Directory> servers = {};

  populateDirectory(String host, String path, List<dto.CollectionFile> content) {
    final parent = _findOrCreateDirectory(host, path);
    for (dto.CollectionFile file in content) {
      if (file.isSong()) {
        final name = p.basename(file.asSong().path);
        parent._children[name] = File(Left(Song(file.asSong())));
      } else {
        final name = p.basename(file.asDirectory().path);
        if (parent._children[name]?.isDirectory() != true) {
          parent._children[name] = File(Right(Directory(data: file.asDirectory())));
        }
      }
    }
    parent.populated = true;
  }

  Map<String, File>? readDirectory(String host, String path) {
    if (!_directoryExists(host, path)) {
      return null;
    }
    Directory directory = _findOrCreateDirectory(host, path);
    if (!directory.populated) {
      return null;
    }
    return directory.children;
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
      if (file == null) {
        file = parent._children[component] = File(Right(Directory()));
      } else if (file.isSong()) {
        throw "Found unexpected song";
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
