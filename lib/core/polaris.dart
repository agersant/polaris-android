import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:polaris/core/authentication.dart' as authentication;
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/cache/media.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/dto.dart' as dto;
import 'package:polaris/core/download.dart' as download;
import 'package:polaris/core/media_item.dart';

const apiVersionEndpoint = '/api/version/';
const browseEndpoint = '/api/browse/';
const flattenEndpoint = '/api/flatten/';
const randomEndpoint = '/api/random/';
const recentEndpoint = '/api/recent/';
const loginEndpoint = '/api/auth/';
const thumbnailEndpoint = '/api/thumbnail/';
const audioEndpoint = '/api/audio/';

enum _Method {
  get,
  post,
}

extension MethodToString on _Method {
  String toHTTPMethod() {
    switch (this) {
      case _Method.get:
        return 'GET';
      case _Method.post:
        return 'POST';
    }
  }
}

enum APIError {
  unspecifiedHost,
  networkError,
  unauthorized,
  responseParseError,
  requestFailed,
  unexpectedCacheMiss,
}

abstract class _BaseHttpClient {
  final http.Client httpClient;
  final connection.Manager connectionManager;

  _BaseHttpClient({
    required this.httpClient,
    required this.connectionManager,
  });

  String makeURL(String endpoint) {
    return (connectionManager.url ?? "") + endpoint;
  }

  Future<http.StreamedResponse> makeRequest(_Method method, String url,
      {dynamic body, String? authenticationToken}) async {
    http.Request request = http.Request(method.toHTTPMethod(), Uri.parse(url));

    if (authenticationToken != null) {
      request.headers[HttpHeaders.authorizationHeader] = 'Bearer ' + authenticationToken;
    }

    if (method == _Method.post) {
      request.headers[HttpHeaders.contentTypeHeader] = 'application/json';
      request.body = jsonEncode(body);
    }

    Future<http.StreamedResponse> response;
    try {
      response = httpClient.send(request);
    } catch (e) {
      return Future.error(APIError.networkError);
    }

    return response.then((r) {
      if (r.statusCode == 401) {
        return Future.error(APIError.unauthorized);
      }
      if (r.statusCode >= 300) {
        return Future.error(APIError.requestFailed);
      }
      return r;
    });
  }

  Future<Uint8List> completeRequest(_Method method, String url, {dynamic body, String? authenticationToken}) async {
    final streamedResponse = makeRequest(method, url, body: body, authenticationToken: authenticationToken);
    return streamedResponse.then((r) => r.stream.toBytes());
  }
}

class HttpGuestClient extends _BaseHttpClient {
  HttpGuestClient({
    required http.Client httpClient,
    required connection.Manager connectionManager,
  }) : super(httpClient: httpClient, connectionManager: connectionManager);

  Future<dto.APIVersion> getAPIVersion() async {
    final url = makeURL(apiVersionEndpoint);
    final responseBody = await completeRequest(_Method.get, url);
    try {
      String body = utf8.decode(responseBody);
      return dto.APIVersion.fromJson(jsonDecode(body));
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  Future<dto.Authorization> login(String username, String password) async {
    final url = makeURL(loginEndpoint);
    final credentials = dto.Credentials(username: username, password: password).toJson();
    final responseBody = await completeRequest(_Method.post, url, body: credentials);
    try {
      return dto.Authorization.fromJson(jsonDecode(utf8.decode(responseBody)));
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  Future<void> testConnection(String? authenticationToken) async {
    final url = makeURL(browseEndpoint);
    await makeRequest(_Method.get, url, authenticationToken: authenticationToken);
  }
}

class HttpClient extends _BaseHttpClient {
  final authentication.Manager authenticationManager;

  HttpClient({
    required http.Client httpClient,
    required connection.Manager connectionManager,
    required this.authenticationManager,
  }) : super(httpClient: httpClient, connectionManager: connectionManager);

  Future<List<dto.CollectionFile>> browse(String path) async {
    final url = makeURL(browseEndpoint + Uri.encodeComponent(path));
    final responseBody = await completeRequest(_Method.get, url, authenticationToken: authenticationManager.token);
    try {
      return (json.decode(utf8.decode(responseBody)) as List)
          .map((dynamic c) => dto.CollectionFile.fromJson(c))
          .toList();
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  Future<List<dto.Song>> flatten(String path) async {
    final url = makeURL(flattenEndpoint + Uri.encodeComponent(path));
    final responseBody = await completeRequest(_Method.get, url, authenticationToken: authenticationManager.token);
    try {
      return (json.decode(utf8.decode(responseBody)) as List).map((dynamic c) => dto.Song.fromJson(c)).toList();
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  Future<List<dto.Directory>> random() async {
    final url = makeURL(randomEndpoint);
    final responseBody = await completeRequest(_Method.get, url, authenticationToken: authenticationManager.token);
    try {
      return (json.decode(utf8.decode(responseBody)) as List).map((dynamic d) => dto.Directory.fromJson(d)).toList();
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  Future<List<dto.Directory>> recent() async {
    final url = makeURL(recentEndpoint);
    final responseBody = await completeRequest(_Method.get, url, authenticationToken: authenticationManager.token);
    try {
      return (json.decode(utf8.decode(responseBody)) as List).map((dynamic d) => dto.Directory.fromJson(d)).toList();
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  Future<http.StreamedResponse> getImage(String path) {
    final uri = getImageURI(path);
    return makeRequest(_Method.get, uri.toString());
  }

  Uri getImageURI(String path) {
    String url = makeURL(thumbnailEndpoint + Uri.encodeComponent(path) + '?pad=false');
    String? token = authenticationManager.token;
    if (token != null && token.isNotEmpty) {
      url += '&auth_token=' + token;
    }
    return Uri.parse(url);
  }

  Uri getAudioURI(String path) {
    String url = makeURL(audioEndpoint + Uri.encodeComponent(path));
    String? token = authenticationManager.token;
    if (token != null && token.isNotEmpty) {
      url += '?auth_token=' + token;
    }
    return Uri.parse(url);
  }
}

class OfflineClient {
  final MediaCacheInterface mediaCache;
  final CollectionCache collectionCache;

  OfflineClient({required this.mediaCache, required this.collectionCache});

  Future<List<dto.CollectionFile>> browse(String host, String path) async {
    final cachedContent = collectionCache.getDirectory(host, path);
    if (cachedContent == null) {
      throw APIError.unexpectedCacheMiss;
    }

    return cachedContent.where((file) {
      if (file.isSong()) {
        return mediaCache.hasAudioSync(host, file.asSong().path);
      } else {
        final flattened = collectionCache.flattenDirectory(host, file.asDirectory().path);
        return flattened?.any((song) => mediaCache.hasAudioSync(host, song.path)) ?? false;
      }
    }).toList();
  }

  Future<List<dto.Song>> flatten(String host, String path) async {
    final cachedContent = collectionCache.flattenDirectory(host, path);
    if (cachedContent == null) {
      throw APIError.unexpectedCacheMiss;
    }
    return cachedContent.where((s) => mediaCache.hasAudioSync(host, s.path)).toList();
  }

  Future<Uint8List?> getImage(String host, String path) async {
    final cacheFile = await mediaCache.getImage(host, path);
    return cacheFile?.readAsBytes();
  }

  Future<AudioSource?> getAudio(String host, String path, MediaItem mediaItem) async {
    final cacheFile = await mediaCache.getAudio(host, path);
    if (cacheFile == null) {
      return null;
    }
    return AudioSource.uri(cacheFile.uri, tag: mediaItem);
  }
}

class Client {
  final HttpClient _httpClient;
  final OfflineClient offlineClient;
  final download.Manager downloadManager;
  final connection.Manager connectionManager;
  final CollectionCache collectionCache;
  final MediaCacheInterface mediaCache;

  Client({
    required HttpClient httpClient,
    required this.offlineClient,
    required this.connectionManager,
    required this.downloadManager,
    required this.collectionCache,
    required this.mediaCache,
  }) : _httpClient = httpClient;

  HttpClient? get httpClient {
    if (connectionManager.isConnected()) {
      return _httpClient;
    }
    return null;
  }

  Future<List<dto.CollectionFile>> browse(String path, {bool useCache = true}) async {
    final String host = _getHost();

    if (!connectionManager.isConnected()) {
      return offlineClient.browse(host, path);
    }

    if (useCache && collectionCache.hasPopulatedDirectory(host, path)) {
      final cachedContent = collectionCache.getDirectory(host, path);
      if (cachedContent != null) {
        return cachedContent;
      }
    }

    return _httpClient.browse(path).then((content) {
      collectionCache.putDirectory(host, path, content);
      return content;
    });
  }

  Future<List<dto.Song>> flatten(String path) async {
    final String host = _getHost();
    if (connectionManager.isConnected()) {
      return _httpClient.flatten(path).then((songs) {
        collectionCache.putSongs(host, songs);
        return songs;
      });
    }
    return offlineClient.flatten(host, path);
  }

  Future<Uri?> _getImageURI(String path) async {
    try {
      final String host = _getHost();
      if (await mediaCache.hasImage(host, path)) {
        return mediaCache.getImageLocation(host, path).uri;
      }
      if (connectionManager.isConnected()) {
        return _httpClient.getImageURI(path);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<AudioSource?> getAudio(dto.Song song, String id) async {
    final String? artwork = song.artwork;
    Uri? artworkUri;
    if (artwork != null) {
      artworkUri = await _getImageURI(artwork);
    }
    final mediaItem = song.toMediaItem(id, artworkUri);

    try {
      final String host = _getHost();
      if (connectionManager.isConnected()) {
        return await downloadManager.getAudio(host, song.path, mediaItem);
      } else {
        return await offlineClient.getAudio(host, song.path, mediaItem);
      }
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List?> getImage(String path) async {
    try {
      final String host = _getHost();
      if (connectionManager.isConnected()) {
        return await downloadManager.getImage(host, path);
      } else {
        return await offlineClient.getImage(host, path);
      }
    } catch (e) {
      return null;
    }
  }

  String _getHost() {
    final String? host = connectionManager.url;
    if (host == null) {
      throw APIError.unspecifiedHost;
    }
    return host;
  }
}
