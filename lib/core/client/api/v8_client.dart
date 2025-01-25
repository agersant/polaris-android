import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:polaris/core/authentication.dart' as authentication;
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/client/api/api_client.dart';
import 'package:polaris/core/client/base_http.dart';
import 'package:polaris/core/client/constants.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/core/connection.dart' as connection;

class V8Client extends BaseHttpClient implements APIClientInterface {
  final authentication.Manager authenticationManager;
  final CollectionCache collectionCache;

  V8Client({
    required http.Client httpClient,
    required connection.Manager connectionManager,
    required this.collectionCache,
    required this.authenticationManager,
  }) : super(httpClient: httpClient, connectionManager: connectionManager);

  Future<List<dto.BrowserEntry>> browse(String path) async {
    final url = makeURL(browseEndpoint + Uri.encodeComponent(path));
    final responseBody = await completeRequest(Method.get, url, authenticationToken: authenticationManager.token);
    try {
      return (json.decode(utf8.decode(responseBody)) as List).map((dynamic c) => dto.BrowserEntry.fromJson(c)).toList();
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  @override
  Future<dto.SongList> flatten(String path) async {
    final url = makeURL(flattenEndpoint + Uri.encodeComponent(path));
    final responseBody = await completeRequest(Method.get, url, authenticationToken: authenticationManager.token);
    try {
      return dto.SongList.fromJson(json.decode(utf8.decode(responseBody)));
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  Future<dto.SongBatch> getSongs(List<String> paths) async {
    final url = makeURL(songsEndpoint);
    final payload = dto.SongBatchRequest(paths: paths).toJson();
    final responseBody =
        await completeRequest(Method.post, url, authenticationToken: authenticationManager.token, body: payload);
    try {
      return dto.SongBatch.fromJson(json.decode(utf8.decode(responseBody)));
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  @override
  Future<dto.Album> getAlbum(String name, List<String> mainArtists) async {
    final host = _getHost();
    final url = makeURL(albumEndpoint(name, mainArtists));
    final responseBody = await completeRequest(Method.get, url, authenticationToken: authenticationManager.token);
    try {
      final album = dto.Album.fromJson(json.decode(utf8.decode(responseBody)));
      collectionCache.putSongs(host, album.songs);
      return album;
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  @override
  Future<List<dto.AlbumHeader>> random() async {
    final url = makeURL(randomEndpoint(8));
    final responseBody = await completeRequest(Method.get, url, authenticationToken: authenticationManager.token);
    try {
      return (json.decode(utf8.decode(responseBody)) as List).map((dynamic d) => dto.AlbumHeader.fromJson(d)).toList();
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  @override
  Future<List<dto.AlbumHeader>> recent() async {
    final url = makeURL(recentEndpoint(8));
    final responseBody = await completeRequest(Method.get, url, authenticationToken: authenticationManager.token);
    try {
      return (json.decode(utf8.decode(responseBody)) as List).map((dynamic d) => dto.AlbumHeader.fromJson(d)).toList();
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  @override
  Future<dto.SongList> search(String query) async {
    final host = _getHost();
    if (query.isEmpty) {
      return dto.SongList(paths: [], firstSongs: []);
    }

    final url = makeURL(searchEndpoint(query));
    final responseBody = await completeRequest(Method.get, url, authenticationToken: authenticationManager.token);

    try {
      final songList = dto.SongList.fromJson(json.decode(utf8.decode(responseBody)));
      collectionCache.putSongs(host, songList.firstSongs);
      collectionCache.putFiles(host, songList.paths);
      return songList;
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

  String _getHost() {
    final String? host = connectionManager.url;
    if (host == null) {
      throw APIError.unspecifiedHost;
    }
    return host;
  }
}
