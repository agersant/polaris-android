import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:polaris/core/authentication.dart' as authentication;
import 'package:polaris/core/dto.dart';
import 'package:polaris/shared/host.dart' as host;

final apiVersionEndpoint = '/api/version/';
final browseEndpoint = '/api/browse/';
final flattenEndpoint = '/api/flatten/';
final randomEndpoint = '/api/random/';
final recentEndpoint = '/api/recent/';
final loginEndpoint = '/api/auth/';
final thumbnailEndpoint = '/api/thumbnail/';
final audioEndpoint = '/api/audio/';

enum State {
  available,
  unavailable,
}

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

abstract class API extends ChangeNotifier {
  State get state;
  Future<List<CollectionFile>> browse(String path);
  Future<List<Song>> flatten(String path);
  Future<List<Directory>> random();
  Future<List<Directory>> recent();
  Uri getImageURI(String path);
  Uri getAudioURI(String path);
  Future<StreamedResponse> downloadImage(String path);
  Future<StreamedResponse> downloadAudio(String path);
}

abstract class GuestAPI {
  Future<APIVersion> getAPIVersion();
  Future<Authorization> login(String username, String password);
  Future<void> testConnection(String? authenticationToken);
}

abstract class _BaseHttpAPI extends ChangeNotifier {
  final host.Manager hostManager;
  final Client client;

  _BaseHttpAPI({
    required this.client,
    required this.hostManager,
  });

  String makeURL(String endpoint) {
    // TODO Ideally we would never have a _BaseHTTPAPI constructed without a valid host
    return (hostManager.url ?? "") + endpoint;
  }

  Future<StreamedResponse> makeRequest(_Method method, String url, {dynamic body, String? authenticationToken}) async {
    Request request = Request(method.toHTTPMethod(), Uri.parse(url));

    if (authenticationToken != null) {
      request.headers[HttpHeaders.authorizationHeader] = 'Bearer ' + authenticationToken;
    }

    if (method == _Method.post) {
      request.headers[HttpHeaders.contentTypeHeader] = 'application/json';
      request.body = jsonEncode(body);
    }

    Future<StreamedResponse> response;
    try {
      response = client.send(request);
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

class HttpGuestAPI extends _BaseHttpAPI implements GuestAPI {
  HttpGuestAPI({
    required Client client,
    required host.Manager hostManager,
  }) : super(client: client, hostManager: hostManager);

  @override
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

  @override
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

  @override
  Future<void> testConnection(String? authenticationToken) async {
    final url = makeURL(browseEndpoint);
    await makeRequest(_Method.get, url, authenticationToken: authenticationToken);
  }
}

class HttpAPI extends _BaseHttpAPI implements API {
  State _state = State.unavailable;
  get state => _state;
  final authentication.Manager authenticationManager;

  HttpAPI({required Client client, required host.Manager hostManager, required this.authenticationManager})
      : super(client: client, hostManager: hostManager) {
    hostManager.addListener(_updateState);
    _updateState();
  }

  void _updateState() {
    _state = hostManager.state == host.State.available ? State.available : State.unavailable;
    notifyListeners();
  }

  @override
  Future<List<CollectionFile>> browse(String path) async {
    final url = makeURL(browseEndpoint + Uri.encodeComponent(path));
    final responseBody = await completeRequest(_Method.get, url, authenticationToken: authenticationManager.token);
    try {
      return (json.decode(utf8.decode(responseBody)) as List).map((c) => CollectionFile.fromJson(c)).toList();
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  @override
  Future<List<Song>> flatten(String path) async {
    final url = makeURL(flattenEndpoint + Uri.encodeComponent(path));
    final responseBody = await completeRequest(_Method.get, url, authenticationToken: authenticationManager.token);
    try {
      return (json.decode(utf8.decode(responseBody)) as List).map((c) => Song.fromJson(c)).toList();
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  @override
  Future<List<Directory>> random() async {
    final url = makeURL(randomEndpoint);
    final responseBody = await completeRequest(_Method.get, url, authenticationToken: authenticationManager.token);
    try {
      return (json.decode(utf8.decode(responseBody)) as List).map((d) => Directory.fromJson(d)).toList();
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  @override
  Future<List<Directory>> recent() async {
    final url = makeURL(recentEndpoint);
    final responseBody = await completeRequest(_Method.get, url, authenticationToken: authenticationManager.token);
    try {
      return (json.decode(utf8.decode(responseBody)) as List).map((d) => Directory.fromJson(d)).toList();
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  @override
  Future<StreamedResponse> downloadImage(String path) {
    final uri = getImageURI(path);
    return makeRequest(_Method.get, uri.toString());
  }

  @override
  Uri getImageURI(String path) {
    String url = makeURL(thumbnailEndpoint + Uri.encodeComponent(path) + '?pad=false');
    String? token = authenticationManager.token;
    if (token != null && token.isNotEmpty) {
      url += '&auth_token=' + token;
    }
    return Uri.parse(url);
  }

  @override
  Future<StreamedResponse> downloadAudio(String path) {
    final uri = getAudioURI(path);
    return makeRequest(_Method.get, uri.toString());
  }

  @override
  Uri getAudioURI(String path) {
    String url = makeURL(audioEndpoint + Uri.encodeComponent(path));
    String? token = authenticationManager.token;
    if (token != null && token.isNotEmpty) {
      url += '?auth_token=' + token;
    }
    return Uri.parse(url);
  }
}
