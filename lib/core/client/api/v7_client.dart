import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:polaris/core/authentication.dart' as authentication;
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/client/api/api_client.dart';
import 'package:polaris/core/client/base_http.dart';
import 'package:polaris/core/client/constants.dart';
import 'package:polaris/core/client/api/v7_dto.dart' as dto7;
import 'package:polaris/core/client/api/v8_dto.dart' as dto8;
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/ui/strings.dart';

class V7Client extends BaseHttpClient implements APIClientInterface {
  final authentication.Manager authenticationManager;
  final CollectionCache collectionCache;

  V7Client({
    required http.Client httpClient,
    required connection.Manager connectionManager,
    required this.collectionCache,
    required this.authenticationManager,
  }) : super(httpClient: httpClient, connectionManager: connectionManager);

  Future<List<dto8.BrowserEntry>> browse(String path) async {
    final url = makeURL(browseEndpoint + Uri.encodeComponent(path));
    final responseBody = await completeRequest(Method.get, url, authenticationToken: authenticationManager.token);
    try {
      final collectionFiles =
          (json.decode(utf8.decode(responseBody)) as List).map((dynamic c) => dto7.CollectionFile.fromJson(c)).toList();
      // TODO v8 this needs to call collectionCache.putSongs since APIClient doesnt do it
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
  Future<dto8.Album> getAlbum(String name, List<String> mainArtists) {
    throw APIError.notImplemented;
  }

  @override
  Future<List<dto8.AlbumHeader>> random() async {
    final url = makeURL(randomEndpoint(7));
    final responseBody = await completeRequest(Method.get, url, authenticationToken: authenticationManager.token);
    try {
      final directories =
          (json.decode(utf8.decode(responseBody)) as List).map((dynamic d) => dto7.Directory.fromJson(d)).toList();
      return directories.map((d) => d.toAlbumHeader()).toList();
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  @override
  Future<List<dto8.AlbumHeader>> recent() async {
    final url = makeURL(recentEndpoint(7));
    final responseBody = await completeRequest(Method.get, url, authenticationToken: authenticationManager.token);
    try {
      final directories =
          (json.decode(utf8.decode(responseBody)) as List).map((dynamic d) => dto7.Directory.fromJson(d)).toList();
      return directories.map((d) => d.toAlbumHeader()).toList();
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  Future<http.StreamedResponse> getImage(String path) {
    final uri = getImageURI(path);
    return makeRequest(Method.get, uri.toString());
  }

  Uri getImageURI(String path) {
    String url = makeURL('$thumbnailEndpoint${Uri.encodeComponent(path)}?pad=false');
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
