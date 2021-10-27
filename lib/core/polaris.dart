import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:polaris/core/authentication.dart' as authentication;
import 'package:polaris/core/cache.dart' as cache;
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/dto.dart';
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
      throw APIError.networkError;
    }

    return response.catchError((e) => throw APIError.networkError).then((r) {
      if (r.statusCode == 401) {
        throw APIError.unauthorized;
      }
      if (r.statusCode >= 300) {
        throw APIError.requestFailed;
      }
      return r;
    });
  }

  Future<Uint8List> completeRequest(_Method method, String url, {dynamic body, String? authenticationToken}) async {
    final streamedResponse = makeRequest(method, url, body: body, authenticationToken: authenticationToken);
    return streamedResponse.then((r) => r.stream.toBytes().catchError((e) => throw APIError.networkError));
  }
}

class HttpGuestClient extends _BaseHttpClient {
  HttpGuestClient({
    required http.Client httpClient,
    required connection.Manager connectionManager,
  }) : super(httpClient: httpClient, connectionManager: connectionManager);

  Future<APIVersion> getAPIVersion() async {
    final url = makeURL(apiVersionEndpoint);
    final responseBody = await completeRequest(_Method.get, url);
    try {
      String body = utf8.decode(responseBody);
      return APIVersion.fromJson(jsonDecode(body));
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  Future<Authorization> login(String username, String password) async {
    final url = makeURL(loginEndpoint);
    final credentials = Credentials(username: username, password: password).toJson();
    final responseBody = await completeRequest(_Method.post, url, body: credentials);
    try {
      return Authorization.fromJson(jsonDecode(utf8.decode(responseBody)));
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

  HttpClient(
      {required http.Client httpClient,
      required connection.Manager connectionManager,
      required this.authenticationManager})
      : super(httpClient: httpClient, connectionManager: connectionManager);

  Future<List<CollectionFile>> browse(String path) async {
    final url = makeURL(browseEndpoint + Uri.encodeComponent(path));
    final responseBody = await completeRequest(_Method.get, url, authenticationToken: authenticationManager.token);
    try {
      return (json.decode(utf8.decode(responseBody)) as List).map((c) => CollectionFile.fromJson(c)).toList();
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  Future<List<Song>> flatten(String path) async {
    final url = makeURL(flattenEndpoint + Uri.encodeComponent(path));
    final responseBody = await completeRequest(_Method.get, url, authenticationToken: authenticationManager.token);
    try {
      return (json.decode(utf8.decode(responseBody)) as List).map((c) => Song.fromJson(c)).toList();
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  Future<List<Directory>> random() async {
    final url = makeURL(randomEndpoint);
    final responseBody = await completeRequest(_Method.get, url, authenticationToken: authenticationManager.token);
    try {
      return (json.decode(utf8.decode(responseBody)) as List).map((d) => Directory.fromJson(d)).toList();
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  Future<List<Directory>> recent() async {
    final url = makeURL(recentEndpoint);
    final responseBody = await completeRequest(_Method.get, url, authenticationToken: authenticationManager.token);
    try {
      return (json.decode(utf8.decode(responseBody)) as List).map((d) => Directory.fromJson(d)).toList();
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
  final connection.Manager connectionManager;
  final cache.Interface cacheManager;

  OfflineClient({required this.connectionManager, required this.cacheManager});

  Future<Uint8List?> getImage(String path) async {
    final String? host = connectionManager.url;
    if (host == null) {
      throw "Unspecified host";
    }
    final cacheFile = await cacheManager.getImage(host, path);
    if (cacheFile != null) {
      return cacheFile.readAsBytes();
    }
    return null;
  }
}

class Client {
  final HttpClient _httpClient;
  final OfflineClient _offlineClient;
  final download.Manager _downloadManager;
  final connection.Manager _connectionManager;

  Client(
      {required httpClient,
      required offlineClient,
      required cacheManager,
      required connectionManager,
      required downloadManager})
      : _httpClient = httpClient,
        _offlineClient = offlineClient,
        _downloadManager = downloadManager,
        _connectionManager = connectionManager;

  HttpClient? get httpClient {
    if (_connectionManager.state == connection.State.connected) {
      return _httpClient;
    }
    return null;
  }

  Future<List<CollectionFile>> browse(String path) async {
    if (_connectionManager.state == connection.State.connected) {
      return _httpClient.browse(path);
    }
    // TODO implement offline browse
    return [];
  }

  Future<List<Song>> flatten(String path) async {
    if (_connectionManager.state == connection.State.connected) {
      return _httpClient.flatten(path);
    }
    // TODO implement offline flatten
    return [];
  }

  Uri _getImageURI(String path) {
    if (_connectionManager.state == connection.State.connected) {
      return _httpClient.getImageURI(path);
    }
    // TODO implement offline getImageURI
    return Uri.parse("");
  }

  Future<AudioSource?> getAudio(Song song, String id) async {
    String? artwork;
    Uri? artworkUri;
    if (artwork != null) {
      artworkUri = _getImageURI(artwork);
    }
    final mediaItem = song.toMediaItem(id, artworkUri);

    if (_connectionManager.state == connection.State.connected) {
      return await _downloadManager.getAudio(song.path, mediaItem);
    } else {
      // TODO implement offline getAudio
      return null;
    }
  }

  Future<Uint8List?> getImage(String path) async {
    try {
      if (_connectionManager.state == connection.State.connected) {
        return await _downloadManager.getImage(path);
      } else {
        return await _offlineClient.getImage(path);
      }
    } catch (e) {
      return null;
    }
  }
}