import 'package:dartz/dartz.dart';
import 'package:polaris/utils.dart';

class APIVersion {
  int major, minor;
  APIVersion({required this.major, required this.minor});
  factory APIVersion.fromJson(Map<String, dynamic> json) {
    return APIVersion(
      major: json['major'],
      minor: json['minor'],
    );
  }
}

class Authorization {
  String username, token;
  bool isAdmin;
  Authorization({required this.username, required this.token, required this.isAdmin});
  factory Authorization.fromJson(Map<String, dynamic> json) {
    return Authorization(
      username: json['username'],
      token: json['token'],
      isAdmin: json['is_admin'],
    );
  }
}

class Credentials {
  String username, password;
  Credentials({required this.username, required this.password});
  Map<String, dynamic> toJson() => <String, String>{
        'username': username,
        'password': password,
      };
}

class BrowserEntry {
  String path;
  bool isDirectory;

  BrowserEntry({required this.path, required this.isDirectory});

  factory BrowserEntry.fromJson(Map<String, dynamic> json) {
    return BrowserEntry(path: json['path'], isDirectory: json['is_directory']);
  }
}

class SongList {
  List<String> paths;
  List<Song> firstSongs;

  SongList({required this.paths, required this.firstSongs});

  factory SongList.fromJson(Map<String, dynamic> json) {
    return SongList(
      paths: (json['paths'] as List<dynamic>).cast<String>(),
      firstSongs: (json['first_songs'] as List<dynamic>).map((s) => Song.fromJson(s)).toList(),
    );
  }
}

class SongBatchRequest {
  List<String> paths;
  SongBatchRequest({required this.paths});
  Map<String, dynamic> toJson() => <String, dynamic>{
        'paths': paths,
      };
}

class SongBatch {
  List<Song> songs;
  List<String> notFound;

  SongBatch({required this.songs, required this.notFound});

  factory SongBatch.fromJson(Map<String, dynamic> json) {
    return SongBatch(
      songs: (json['songs'] as List<dynamic>).map((s) => Song.fromJson(s)).toList(),
      notFound: (json['not_found'] as List<dynamic>).cast<String>(),
    );
  }
}

class AlbumHeader {
  String name;
  List<String> mainArtists;
  String? artwork;
  int? year;

  AlbumHeader({required this.name, required this.mainArtists});

  factory AlbumHeader.fromJson(Map<String, dynamic> json) {
    return AlbumHeader(name: json['name'], mainArtists: (json['main_artists'] as List<dynamic>).cast<String>())
      ..artwork = json['artwork']
      ..year = json['year'];
  }
}

// TODO v8 move me to legacy
class Directory {
  String path;
  String? artist;
  int? year;
  String? album;
  String? artwork;
  int? dateAdded;

  Directory({required this.path});

  factory Directory.fromJson(Map<String, dynamic> json) {
    return Directory(path: json['path'])
      ..artist = json['artist']
      ..year = json['year']
      ..album = json['album']
      ..artwork = json['artwork']
      ..dateAdded = json['date_added'];
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'path': path,
        'artist': artist,
        'year': year,
        'album': album,
        'artwork': artwork,
        'dateAdded': dateAdded,
      };
}

class Song {
  String path;
  int? trackNumber;
  int? discNumber;
  String? title;
  List<String> artists = [];
  List<String> albumArtists = [];
  List<String> lyricists = [];
  List<String> composers = [];
  List<String> genres = [];
  List<String> labels = [];
  int? year;
  String? album;
  String? artwork;
  int? duration;

  Song({required this.path});

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(path: json['path'])
      ..trackNumber = json['track_number']
      ..discNumber = json['disc_number']
      ..title = json['title']
      ..artists = (json['artists'] as List<dynamic>? ?? []).cast<String>()
      ..albumArtists = (json['album_artists'] as List<dynamic>? ?? []).cast<String>()
      ..lyricists = (json['lyricists'] as List<dynamic>? ?? []).cast<String>()
      ..composers = (json['composers'] as List<dynamic>? ?? []).cast<String>()
      ..genres = (json['genres'] as List<dynamic>? ?? []).cast<String>()
      ..labels = (json['labels'] as List<dynamic>? ?? []).cast<String>()
      ..year = json['year']
      ..album = json['album']
      ..artwork = json['artwork']
      ..duration = json['duration'];
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'path': path,
        'track_number': trackNumber,
        'disc_number': discNumber,
        'title': title,
        'artists': artists,
        'album_artists': albumArtists,
        'lyricists': lyricists,
        'composers': composers,
        'genres': genres,
        'labels': labels,
        'year': year,
        'album': album,
        'artwork': artwork,
        'duration': duration,
      };
}

// TODO v8 move me to legacy
class CollectionFile {
  Either<Song, Directory> content;

  CollectionFile(this.content);

  String get path {
    if (isSong()) {
      return asSong().path;
    } else {
      return asDirectory().path;
    }
  }

  String? get artwork {
    if (isSong()) {
      return asSong().artwork;
    } else {
      return asDirectory().artwork;
    }
  }

  bool isSong() {
    return content.isLeft();
  }

  bool isDirectory() {
    return content.isRight();
  }

  Song asSong() {
    return content.fold((song) => song, (directory) => throw "CollectionFile is not a song");
  }

  Directory asDirectory() {
    return content.fold((song) => throw "CollectionFile is not a directory", (directory) => directory);
  }

  factory CollectionFile.fromJson(Map<String, dynamic> json) {
    if (json['Song'] != null) {
      return CollectionFile(Left(Song.fromJson(json['Song'])));
    }
    if (json['Directory'] != null) {
      return CollectionFile(Right(Directory.fromJson(json['Directory'])));
    }
    throw ArgumentError("Malformed CollectionFile Json");
  }

  Map<String, dynamic> toJson() => content.fold(
        (song) => <String, dynamic>{'Song': song.toJson()},
        (directory) => <String, dynamic>{'Directory': directory.toJson()},
      );
}
