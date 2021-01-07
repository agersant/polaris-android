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

abstract class _BaseHttpAPI extends ChangeNotifier {
  final host.Manager hostManager;
  final token.Manager tokenManager;
  final Client client;

  _BaseHttpAPI({
    @required this.client,
    @required this.hostManager,
    @required this.tokenManager,
  })  : assert(client != null),
        assert(hostManager != null);

  String makeURL(String endpoint) {
    if (hostManager.url == null) {
      throw APIError.unspecifiedHost;
    }
    return hostManager.url + endpoint;
  }

  Future<StreamedResponse> makeRequest(_Method method, String url, {dynamic body, bool authenticate = false}) async {
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
      if (r.statusCode >= 300) {
        throw APIError.requestFailed;
      }
      return r;
    });
  }

  Future<Uint8List> completeRequest(_Method method, String url, {dynamic body, bool authenticate = false}) async {
    final streamedResponse = makeRequest(method, url, body: body, authenticate: authenticate);
    return streamedResponse.then((r) => r.stream.toBytes().catchError((e) => throw APIError.networkError));
  }
}

class HttpGuestAPI extends _BaseHttpAPI implements GuestAPI {
  HttpGuestAPI({
    @required Client client,
    @required host.Manager hostManager,
    @required token.Manager tokenManager,
  })  : assert(client != null),
        assert(hostManager != null),
        assert(tokenManager != null),
        super(client: client, hostManager: hostManager, tokenManager: tokenManager);

  @override
  Future<APIVersion> getAPIVersion() async {
    final url = makeURL(apiVersionEndpoint);
    final responseBody = await completeRequest(_Method.get, url);
    try {
      return APIVersion.fromJson(jsonDecode(utf8.decode(responseBody)));
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
  Future<void> testConnection() async {
    final url = makeURL(browseEndpoint);
    return await makeRequest(_Method.get, url, authenticate: true);
  }
}

class HttpAPI extends _BaseHttpAPI implements API {
  State _state = State.unavailable;
  get state => _state;

  HttpAPI({@required Client client, @required token.Manager tokenManager, @required host.Manager hostManager})
      : assert(client != null),
        assert(hostManager != null),
        super(client: client, hostManager: hostManager, tokenManager: tokenManager) {
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
    final responseBody = await completeRequest(_Method.get, url, authenticate: true);
    try {
      return (json.decode(utf8.decode(responseBody)) as List).map((c) => CollectionFile.fromJson(c)).toList();
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  @override
  Future<List<Directory>> random() async {
    final url = makeURL(randomEndpoint);
    final responseBody = await completeRequest(_Method.get, url, authenticate: true);
    try {
      return (json.decode(utf8.decode(responseBody)) as List).map((d) => Directory.fromJson(d)).toList();
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  @override
  Future<List<Directory>> recent() async {
    final url = makeURL(recentEndpoint);
    final responseBody = await completeRequest(_Method.get, url, authenticate: true);
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
    assert(path != null);
    String url = makeURL(thumbnailEndpoint + Uri.encodeComponent(path) + '?pad=false');
    if (tokenManager != null) {
      url += '&auth_token=' + tokenManager.token;
    }
    return Uri.parse(url);
  }

  @override
  Future<StreamedResponse> downloadAudio(String path) {
    final url = makeURL(audioEndpoint + Uri.encodeComponent(path));
    return makeRequest(_Method.get, url, authenticate: true);
  }
}
