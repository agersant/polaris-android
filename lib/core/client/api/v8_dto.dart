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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'path': path,
        'is_directory': isDirectory,
      };
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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'songs': songs.map((s) => s.toJson()).toList(),
        'not_found': notFound,
      };
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

class Album extends AlbumHeader {
  List<Song> songs = [];

  Album({required name, required mainArtists}) : super(name: name, mainArtists: mainArtists);

  factory Album.fromJson(Map<String, dynamic> json) {
    final header = AlbumHeader.fromJson(json);
    return Album(name: header.name, mainArtists: header.mainArtists)
      ..artwork = header.artwork
      ..year = header.year
      ..songs = (json['songs'] as List<dynamic>).map((s) => Song.fromJson(s)).toList();
  }
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

enum ThumbnailSize {
  tiny,
  small,
  large,
  native,
}
