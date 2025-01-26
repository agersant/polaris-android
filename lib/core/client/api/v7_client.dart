import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:polaris/core/authentication.dart' as authentication;
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/cache/media.dart';
import 'package:polaris/core/client/api/api_client.dart';
import 'package:polaris/core/client/base_http.dart';
import 'package:polaris/core/client/api/v7_dto.dart' as dto7;
import 'package:polaris/core/client/api/v8_dto.dart' as dto8;
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/ui/strings.dart';

const apiVersionEndpoint = '/api/version/';
const audioEndpoint = '/api/audio/';
const browseEndpoint = '/api/browse/';
const flattenEndpoint = '/api/flatten/';
const loginEndpoint = '/api/auth/';
const randomEndpoint = '/api/random';
const recentEndpoint = '/api/recent';
const songsEndpoint = '/api/songs/';

String searchEndpoint(String query) => '/api/search/${Uri.encodeComponent(query)}';
String thumbnailEndpoint(String path, dto7.ThumbnailSize size) =>
    '/api/thumbnail/${Uri.encodeComponent(path)}?size=${size.name}&pad=false';

class V7Client extends BaseHttpClient implements APIClientInterface {
  final authentication.Manager authenticationManager;
  final CollectionCache collectionCache;
  final Map<(String, String), String> albumsSeen = {}; // (name, artist) -> path

  V7Client({
    required http.Client httpClient,
    required connection.Manager connectionManager,
    required this.collectionCache,
    required this.authenticationManager,
  }) : super(httpClient: httpClient, connectionManager: connectionManager);

  Future<List<dto8.BrowserEntry>> browse(String path) async {
    final host = _getHost();
    final url = makeURL(browseEndpoint + Uri.encodeComponent(path));
    final responseBody = await completeRequest(Method.get, url, authenticationToken: authenticationManager.token);
    try {
      final collectionFiles =
          (json.decode(utf8.decode(responseBody)) as List).map((dynamic c) => dto7.CollectionFile.fromJson(c)).toList();
      final songs = collectionFiles.where((f) => f.isSong()).map((f) => f.asSong().toV8()).toList();
      collectionCache.putSongs(host, songs);
      return collectionFiles.map((f) => f.toBrowserEntry()).toList();
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  @override
  Future<dto8.SongList> flatten(String path) async {
    final url = makeURL(flattenEndpoint + Uri.encodeComponent(path));
    final responseBody = await completeRequest(Method.get, url, authenticationToken: authenticationManager.token);
    try {
      final songs = (json.decode(utf8.decode(responseBody)) as List).map((dynamic c) => dto7.Song.fromJson(c)).toList();
      final paths = songs.map((s) => s.path).toList();
      final firstSongs = songs.map((s) => s.toV8()).toList();
      return dto8.SongList(paths: paths, firstSongs: firstSongs);
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  @override
  Future<dto8.Album> getAlbum(String name, List<String> mainArtists) async {
    final host = _getHost();
    final path = albumsSeen[(name, mainArtists.join(''))];
    if (path == null) {
      throw APIError.unexpectedCacheMiss;
    }
    final url = makeURL(browseEndpoint + Uri.encodeComponent(path));
    final responseBody = await completeRequest(Method.get, url, authenticationToken: authenticationManager.token);
    try {
      final collectionFiles =
          (json.decode(utf8.decode(responseBody)) as List).map((dynamic c) => dto7.CollectionFile.fromJson(c)).toList();
      final songs = collectionFiles.where((f) => f.isSong()).map((f) => f.asSong().toV8()).toList();
      collectionCache.putSongs(host, songs);
      return dto8.Album(name: name, mainArtists: mainArtists)
        ..songs = songs
        ..artwork = songs.firstOrNull?.artwork
        ..year = songs.firstOrNull?.year;
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  @override
  Future<List<dto8.AlbumHeader>> random() async {
    final url = makeURL(randomEndpoint);
    final responseBody = await completeRequest(Method.get, url, authenticationToken: authenticationManager.token);
    try {
      final directories =
          (json.decode(utf8.decode(responseBody)) as List).map((dynamic d) => dto7.Directory.fromJson(d)).toList();
      for (dto7.Directory directory in directories) {
        final album = directory.album;
        final artist = directory.artist;
        if (album != null && artist != null) {
          albumsSeen[(album, artist)] = directory.path;
        }
      }
      return directories.map((d) => d.toAlbumHeader()).toList();
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  @override
  Future<List<dto8.AlbumHeader>> recent() async {
    final url = makeURL(recentEndpoint);
    final responseBody = await completeRequest(Method.get, url, authenticationToken: authenticationManager.token);
    try {
      final directories =
          (json.decode(utf8.decode(responseBody)) as List).map((dynamic d) => dto7.Directory.fromJson(d)).toList();
      for (dto7.Directory directory in directories) {
        final album = directory.album;
        final artist = directory.artist;
        if (album != null && artist != null) {
          albumsSeen[(album, artist)] = directory.path;
        }
      }
      return directories.map((d) => d.toAlbumHeader()).toList();
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  @override
  Future<dto8.SongList> search(String query) async {
    if (query.isEmpty) {
      return dto8.SongList(paths: [], firstSongs: []);
    }

    final host = _getHost();
    final url = makeURL(searchEndpoint(query));
    final responseBody = await completeRequest(Method.get, url, authenticationToken: authenticationManager.token);

    try {
      final collectionFiles =
          (json.decode(utf8.decode(responseBody)) as List).map((dynamic c) => dto7.CollectionFile.fromJson(c)).toList();
      final songs = collectionFiles.where((f) => f.isSong()).map((f) => f.asSong().toV8()).toList();
      final paths = songs.map((s) => s.path).toList();
      collectionCache.putSongs(host, songs);
      collectionCache.putFiles(host, paths);
      return dto8.SongList(paths: paths, firstSongs: songs);
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  @override
  Future<()> deletePlaylist(String name) {
    throw APIError.notImplemented;
  }

  @override
  Future<dto8.Playlist> getPlaylist(String name) {
    throw APIError.notImplemented;
  }

  @override
  Future<List<dto8.PlaylistHeader>> listPlaylists() {
    throw APIError.notImplemented;
  }

  @override
  Future<()> savePlaylist(String name, List<String> tracks) {
    throw APIError.notImplemented;
  }

  Future<http.StreamedResponse> getImage(String path, ArtworkSize size) {
    final uri = getImageURI(path, size);
    return makeRequest(Method.get, uri.toString());
  }

  Uri getImageURI(String path, ArtworkSize size) {
    final dtoSize = switch (size) {
      ArtworkSize.tiny => dto7.ThumbnailSize.small,
      ArtworkSize.small => dto7.ThumbnailSize.small,
    };
    String url = makeURL(thumbnailEndpoint(path, dtoSize));
    String? token = authenticationManager.token;
    if (token != null && token.isNotEmpty) {
      url += '&auth_token=$token';
    }
    return Uri.parse(url);
  }

  Uri getAudioURI(String path) {
    String url = makeURL(audioEndpoint + Uri.encodeComponent(path));
    String? token = authenticationManager.token;
    if (token != null && token.isNotEmpty) {
      url += '?auth_token=$token';
    }
    return Uri.parse(url);
  }

  String _getHost() {
    final String? host = connectionManager.url;
    if (host == null) {
      throw APIError.unspecifiedHost;
    }
    return host;
  }
}

extension SongMigration on dto7.Song {
  dto8.Song toV8() {
    return dto8.Song(path: path)
      ..trackNumber = trackNumber
      ..discNumber = discNumber
      ..album = album
      ..title = title
      ..artists = artist == null ? [] : [artist!]
      ..albumArtists = albumArtist == null ? [] : [albumArtist!]
      ..lyricists = lyricist == null ? [] : [lyricist!]
      ..composers = composer == null ? [] : [composer!]
      ..genres = genre == null ? [] : [genre!]
      ..labels = label == null ? [] : [label!]
      ..year = year
      ..artwork = artwork
      ..duration = duration;
  }
}

extension DirectoryMigration on dto7.Directory {
  dto8.AlbumHeader toAlbumHeader() {
    return dto8.AlbumHeader(name: album ?? unknownAlbum, mainArtists: [artist ?? unknownArtist])
      ..artwork = artwork
      ..year = year;
  }
}

extension CollectionFileMigration on dto7.CollectionFile {
  dto8.BrowserEntry toBrowserEntry() {
    return dto8.BrowserEntry(path: path, isDirectory: isDirectory());
  }
}
