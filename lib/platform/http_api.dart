import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:polaris/platform/api.dart';
import 'package:polaris/platform/dto.dart';
import 'package:polaris/platform/host.dart' as host;
import 'package:polaris/platform/token.dart' as token;

final getIt = GetIt.instance;

final apiVersionEndpoint = '/api/version/';
final browseEndpoint = '/api/browse/';
final randomEndpoint = '/api/random/';
final recentEndpoint = '/api/recent/';
final loginEndpoint = '/api/auth/';
final thumbnailEndpoint = '/api/thumbnail/';
final audioEndpoint = '/api/audio/';

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

class HttpAPI implements API {
  final _hostManager = getIt<host.Manager>();
  final _tokenManager = getIt<token.Manager>();
  final _client = getIt<Client>();

  String _makeURL(String endpoint) {
    if (_hostManager.url == null) {
      throw APIError.unspecifiedHost;
    }
    return _hostManager.url + endpoint;
  }

  Future<StreamedResponse> _makeRequest(_Method method, String url, {dynamic body, bool authenticate = false}) async {
    Request request = Request(method.toHTTPMethod(), Uri.parse(url));

    if (authenticate) {
      if (_tokenManager.token != null && _tokenManager.token.isNotEmpty) {
        request.headers[HttpHeaders.authorizationHeader] = 'Bearer ' + _tokenManager.token;
      }
    }

    if (method == _Method.post) {
      request.headers[HttpHeaders.contentTypeHeader] = 'application/json';
      request.body = jsonEncode(body);
    }

    Future<StreamedResponse> response;
    try {
      response = _client.send(request);
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

  Future<APIVersion> getAPIVersion() async {
    final url = _makeURL(apiVersionEndpoint);
    final responseBody = await _completeRequest(_Method.get, url);
    try {
      return APIVersion.fromJson(jsonDecode(utf8.decode(responseBody)));
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  @override
  Future<Authorization> login(String username, String password) async {
    final url = _makeURL(loginEndpoint);
    final credentials = Credentials(username: username, password: password).toJson();
    final responseBody = await _completeRequest(_Method.post, url, body: credentials);
    try {
      return Authorization.fromJson(jsonDecode(utf8.decode(responseBody)));
    } catch (e) {
      throw APIError.responseParseError;
    }
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
  Future<Uint8List> downloadImage(String path) async {
    final url = _makeURL(thumbnailEndpoint + Uri.encodeComponent(path) + '?pad=false');
    return _completeRequest(_Method.get, url, authenticate: true);
  }

  @override
  Future<StreamedResponse> downloadAudio(String path) async {
    final url = _makeURL(audioEndpoint + Uri.encodeComponent(path));
    return _makeRequest(_Method.get, url, authenticate: true);
  }
}
