import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:polaris/shared/dto.dart';
import 'package:polaris/shared/host.dart' as host;
import 'package:polaris/shared/token.dart' as token;

final apiVersionEndpoint = '/api/version/';
final browseEndpoint = '/api/browse/';
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
      default:
        return null;
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
  Future<List<Directory>> random();
  Future<List<Directory>> recent();
  Uri getImageURI(String path);
  Future<StreamedResponse> downloadImage(String path);
  Future<StreamedResponse> downloadAudio(String path);
}

abstract class GuestAPI {
  Future<APIVersion> getAPIVersion();
  Future<Authorization> login(String username, String password);
  Future<void> testConnection();
}

class HttpGuestAPI implements GuestAPI {
  final host.Manager hostManager;
  final token.Manager tokenManager;
  final Client client;

  HttpGuestAPI({
    @required this.client,
    @required this.hostManager,
    @required this.tokenManager,
  })  : assert(client != null),
        assert(hostManager != null),
        assert(tokenManager != null);

  String _makeURL(String endpoint) {
    if (hostManager.url == null) {
      throw APIError.unspecifiedHost;
    }
    return hostManager.url + endpoint;
  }

  Future<Response> _makeRequest(_Method method, String url, {dynamic body, bool authenticate = false}) async {
    Map<String, String> headers = Map();
    if (authenticate) {
      if (tokenManager.token != null && tokenManager.token.isNotEmpty) {
        headers[HttpHeaders.authorizationHeader] = 'Bearer ' + tokenManager.token;
      }
    }

    Future<Response> response;
    try {
      switch (method) {
        case _Method.get:
          response = client.get(url, headers: headers);
          break;
        case _Method.post:
          headers[HttpHeaders.contentTypeHeader] = 'application/json';
          response = client.post(url, headers: headers, body: jsonEncode(body));
          break;
      }
    } catch (e) {
      throw APIError.networkError;
    }

    return response.catchError((e) => throw APIError.networkError).then((r) {
      if (r.statusCode == 401) {
        throw APIError.unauthorized;
      }
      if (r.statusCode != 200) {
        throw APIError.requestFailed;
      }
      return r;
    });
  }

  @override
  Future<APIVersion> getAPIVersion() async {
    final url = _makeURL(apiVersionEndpoint);
    final response = await _makeRequest(_Method.get, url);
    try {
      return APIVersion.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  @override
  Future<Authorization> login(String username, String password) async {
    final url = _makeURL(loginEndpoint);
    final credentials = Credentials(username: username, password: password).toJson();
    final response = await _makeRequest(_Method.post, url, body: credentials);
    try {
      return Authorization.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  @override
  Future<void> testConnection() async {
    final url = _makeURL(browseEndpoint);
    return await _makeRequest(_Method.get, url, authenticate: true);
  }
}

class HttpAPI extends ChangeNotifier implements API {
  final host.Manager hostManager;
  final token.Manager tokenManager;
  final Client client;
  State _state = State.unavailable;
  get state => _state;

  HttpAPI({@required this.client, @required this.tokenManager, @required this.hostManager})
      : assert(client != null),
        assert(hostManager != null) {
    hostManager.addListener(_updateState);
    _updateState();
  }

  void _updateState() {
    _state = hostManager.state == host.State.available ? State.available : State.unavailable;
    notifyListeners();
  }

  String _makeURL(String endpoint) {
    if (hostManager.url == null) {
      throw APIError.unspecifiedHost;
    }
    return hostManager.url + endpoint;
  }

  Future<StreamedResponse> _makeRequest(_Method method, String url, {dynamic body, bool authenticate = false}) async {
    Request request = Request(method.toHTTPMethod(), Uri.parse(url));

    if (authenticate && tokenManager != null) {
      if (tokenManager.token != null && tokenManager.token.isNotEmpty) {
        request.headers[HttpHeaders.authorizationHeader] = 'Bearer ' + tokenManager.token;
      }
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
      if (r.statusCode != 200) {
        throw APIError.requestFailed;
      }
      return r;
    });
  }

  Future<Uint8List> _completeRequest(_Method method, String url, {dynamic body, bool authenticate = false}) async {
    final streamedResponse = _makeRequest(method, url, body: body, authenticate: authenticate);
    return streamedResponse.then((r) => r.stream.toBytes().catchError((e) => throw APIError.networkError));
  }

  @override
  Future<List<CollectionFile>> browse(String path) async {
    final url = _makeURL(browseEndpoint + Uri.encodeComponent(path));
    final responseBody = await _completeRequest(_Method.get, url, authenticate: true);
    try {
      return (json.decode(utf8.decode(responseBody)) as List).map((c) => CollectionFile.fromJson(c)).toList();
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  @override
  Future<List<Directory>> random() async {
    final url = _makeURL(randomEndpoint);
    final responseBody = await _completeRequest(_Method.get, url, authenticate: true);
    try {
      return (json.decode(utf8.decode(responseBody)) as List).map((d) => Directory.fromJson(d)).toList();
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  @override
  Future<List<Directory>> recent() async {
    final url = _makeURL(recentEndpoint);
    final responseBody = await _completeRequest(_Method.get, url, authenticate: true);
    try {
      return (json.decode(utf8.decode(responseBody)) as List).map((d) => Directory.fromJson(d)).toList();
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  @override
  Future<StreamedResponse> downloadImage(String path) {
    final uri = getImageURI(path);
    return _makeRequest(_Method.get, uri.toString());
  }

  @override
  Uri getImageURI(String path) {
    assert(path != null);
    String url = _makeURL(thumbnailEndpoint + Uri.encodeComponent(path) + '?pad=false');
    if (tokenManager != null) {
      url += '&auth_token=' + tokenManager.token;
    }
    return Uri.parse(url);
  }

  @override
  Future<StreamedResponse> downloadAudio(String path) {
    final url = _makeURL(audioEndpoint + Uri.encodeComponent(path));
    return _makeRequest(_Method.get, url, authenticate: true);
  }
}
