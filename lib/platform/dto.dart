import 'dart:convert';

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
  String toJson() => json.encode({
        'username': username,
        'password': password,
      });
}

class Directory {
  String path;
  String artist;
  int year;
  String album;
  String artwork;
  int dateAdded;

  Directory({this.path, this.artist, this.year, this.album, this.artwork, this.dateAdded});
  factory Directory.fromJson(Map<String, dynamic> json) {
    return Directory(
      path: json['path'],
      artist: json['artist'],
      year: json['year'],
      album: json['album'],
      artwork: json['artwork'],
      dateAdded: json['date_added'],
    );
  }
}
