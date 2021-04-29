import 'package:dartz/dartz.dart';

class APIVersion {
  int major, minor;
  APIVersion({this.major, this.minor});
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
  Authorization({this.username, this.token, this.isAdmin});
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
  Credentials({this.username, this.password});
  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };
}

class Directory {
  String path;
  String artist;
  int year;
  String album;
  String artwork;
  int dateAdded;

  Directory();

  factory Directory.fromJson(Map<String, dynamic> json) {
    return Directory()
      ..path = json['path']
      ..artist = json['artist']
      ..year = json['year']
      ..album = json['album']
      ..artwork = json['artwork']
      ..dateAdded = json['date_added'];
  }

  Map<String, dynamic> toJson() => {
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
  int trackNumber;
  int discNumber;
  String title;
  String artist;
  String albumArtist;
  int year;
  String album;
  String artwork;
  int duration;

  Song();

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song()
      ..path = json['path']
      ..trackNumber = json['track_number']
      ..discNumber = json['disc_number']
      ..title = json['title']
      ..artist = json['artist']
      ..albumArtist = json['album_artist']
      ..year = json['year']
      ..album = json['album']
      ..artwork = json['artwork']
      ..duration = json['duration'];
  }

  Map<String, dynamic> toJson() => {
        'path': path,
        'track_number': trackNumber,
        'disc_number': discNumber,
        'title': title,
        'artist': artist,
        'album_artist': albumArtist,
        'year': year,
        'album': album,
        'artwork': artwork,
        'duration': duration,
      };
}

class CollectionFile {
  Either<Song, Directory> content;

  CollectionFile(this.content);

  bool isSong() {
    return content.isLeft();
  }

  bool isDirectory() {
    return content.isRight();
  }

  Song asSong() {
    return content.fold((song) => song, (directory) => null);
  }

  Directory asDirectory() {
    return content.fold((song) => null, (directory) => directory);
  }

  factory CollectionFile.fromJson(Map<String, dynamic> json) {
    if (json['Song'] != null) {
      return CollectionFile(Left(Song.fromJson(json['Song'])));
    }
    if (json['Directory'] != null) {
      return CollectionFile(Right(Directory.fromJson(json['Directory'])));
    }
    return null;
  }

  Map<String, dynamic> toJson() => content.fold(
        (song) => {'Song': song},
        (directory) => {'Directory': directory},
      );
}
