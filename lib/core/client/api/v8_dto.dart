import 'package:polaris/ui/utils/format.dart';

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

class ArtistHeader {
  String name;
  int numAlbumsAsPerformer;
  int numAlbumsAsAdditionalPerformer;
  int numAlbumsAsComposer;
  int numAlbumsAsLyricist;
  Map<String, int> numSongsByGenre;
  int numSongs;

  ArtistHeader({
    required this.name,
    required this.numAlbumsAsPerformer,
    required this.numAlbumsAsAdditionalPerformer,
    required this.numAlbumsAsComposer,
    required this.numAlbumsAsLyricist,
    required this.numSongsByGenre,
    required this.numSongs,
  });

  factory ArtistHeader.fromJson(Map<String, dynamic> json) {
    return ArtistHeader(
      name: json['name'],
      numAlbumsAsPerformer: json['num_albums_as_performer'],
      numAlbumsAsAdditionalPerformer: json['num_albums_as_performer'],
      numAlbumsAsComposer: json['num_albums_as_composer'],
      numAlbumsAsLyricist: json['num_albums_as_lyricist'],
      numSongsByGenre: Map.from(json['num_songs_by_genre']),
      numSongs: json['num_songs'],
    );
  }
}

class Artist extends ArtistHeader {
  List<ArtistAlbum> albums;

  Artist({
    required name,
    required numAlbumsAsPerformer,
    required numAlbumsAsAdditionalPerformer,
    required numAlbumsAsComposer,
    required numAlbumsAsLyricist,
    required numSongsByGenre,
    required numSongs,
    required this.albums,
  }) : super(
          name: name,
          numAlbumsAsPerformer: numAlbumsAsPerformer,
          numAlbumsAsAdditionalPerformer: numAlbumsAsAdditionalPerformer,
          numAlbumsAsComposer: numAlbumsAsComposer,
          numAlbumsAsLyricist: numAlbumsAsLyricist,
          numSongsByGenre: numSongsByGenre,
          numSongs: numSongs,
        );

  factory Artist.fromJson(Map<String, dynamic> json) {
    final header = ArtistHeader.fromJson(json);
    return Artist(
      name: header.name,
      numAlbumsAsPerformer: header.numAlbumsAsPerformer,
      numAlbumsAsAdditionalPerformer: header.numAlbumsAsAdditionalPerformer,
      numAlbumsAsComposer: header.numAlbumsAsComposer,
      numAlbumsAsLyricist: header.numAlbumsAsLyricist,
      numSongsByGenre: header.numSongsByGenre,
      numSongs: header.numSongs,
      albums: (json['albums'] as List<dynamic>).map((a) => ArtistAlbum.fromJson(a)).toList(),
    );
  }
}

class ArtistAlbum extends AlbumHeader {
  List<Contribution> contributions;

  ArtistAlbum({
    required name,
    required mainArtists,
    required this.contributions,
  }) : super(name: name, mainArtists: mainArtists);

  factory ArtistAlbum.fromJson(Map<String, dynamic> json) {
    final header = AlbumHeader.fromJson(json);
    return ArtistAlbum(
      name: header.name,
      mainArtists: header.mainArtists,
      contributions: (json['contributions'] as List<dynamic>).map((c) => Contribution.fromJson(c)).toList(),
    )
      ..artwork = header.artwork
      ..year = header.year;
  }
}

class Contribution {
  bool performer;
  bool composer;
  bool lyricist;

  Contribution({required this.performer, required this.composer, required this.lyricist});

  factory Contribution.fromJson(Map<String, dynamic> json) {
    return Contribution(
      performer: json['performer'],
      composer: json['composer'],
      lyricist: json['lyricist'],
    );
  }
}

class GenreHeader {
  String name;

  GenreHeader({required this.name});

  factory GenreHeader.fromJson(Map<String, dynamic> json) {
    return GenreHeader(
      name: json['name'],
    );
  }
}

class Genre extends GenreHeader {
  Map<String, int> relatedGenres;
  List<ArtistHeader> mainArtists;
  List<AlbumHeader> recentlyAdded;

  Genre({
    required name,
    required this.relatedGenres,
    required this.mainArtists,
    required this.recentlyAdded,
  }) : super(name: name);

  factory Genre.fromJson(Map<String, dynamic> json) {
    final header = GenreHeader.fromJson(json);
    return Genre(
      name: header.name,
      relatedGenres: Map.from(json['related_genres']),
      mainArtists: (json['main_artists'] as List<dynamic>).map((c) => ArtistHeader.fromJson(c)).toList(),
      recentlyAdded: (json['recently_added'] as List<dynamic>).map((c) => AlbumHeader.fromJson(c)).toList(),
    );
  }
}

class PlaylistHeader {
  String name;
  int duration; // in seconds
  Map<String, int> numSongsByGenre;

  PlaylistHeader({required this.name, required this.numSongsByGenre, required this.duration});

  factory PlaylistHeader.fromJson(Map<String, dynamic> json) {
    return PlaylistHeader(
      name: json['name'],
      duration: json['duration'],
      numSongsByGenre: Map.from(json['num_songs_by_genre']),
    );
  }
}

class Playlist extends PlaylistHeader {
  SongList songs;

  Playlist({required name, required duration, required numSongsByGenre, required this.songs})
      : super(name: name, duration: duration, numSongsByGenre: numSongsByGenre);

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final header = PlaylistHeader.fromJson(json);
    final songs = SongList.fromJson(json['songs']);
    return Playlist(
      name: header.name,
      duration: header.duration,
      numSongsByGenre: header.numSongsByGenre,
      songs: songs,
    );
  }
}

class SavePlaylistInput {
  List<String> tracks;

  SavePlaylistInput({required this.tracks});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'tracks': tracks,
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

  AlbumHeader? toAlbumHeader() {
    if (album == null) {
      return null;
    }
    if (artists.isEmpty && albumArtists.isEmpty) {
      return null;
    }
    final mainArtists = albumArtists.isNotEmpty ? albumArtists : artists;
    if (mainArtists.isEmpty) {
      return null;
    }
    return AlbumHeader(name: album!, mainArtists: mainArtists)
      ..artwork = artwork
      ..year = year;
  }
}

enum ThumbnailSize {
  tiny,
  small,
  large,
  native,
}
