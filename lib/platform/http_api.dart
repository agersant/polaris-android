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

enum _Method {
  get,
  post,
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

  Future<Response> _makeRequest(_Method method, String url, {dynamic body, bool authenticate = false}) async {
    Map<String, String> headers = Map();
    if (authenticate) {
      if (_tokenManager.token != null && _tokenManager.token.isNotEmpty) {
        headers[HttpHeaders.authorizationHeader] = 'Bearer ' + _tokenManager.token;
      }
    }

    Future<Response> response;
    try {
      switch (method) {
        case _Method.get:
          response = _client.get(url, headers: headers);
          break;
        case _Method.post:
          headers[HttpHeaders.contentTypeHeader] = 'application/json';
          response = _client.post(url, headers: headers, body: body);
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
  Future browse(String path) async {
    final url = _makeURL(browseEndpoint);
    await _makeRequest(_Method.get, url, authenticate: true);
  }

  @override
  Future<List<Directory>> random() async {
    final url = _makeURL(randomEndpoint);
    final response = await _makeRequest(_Method.get, url, authenticate: true);
    try {
      return (json.decode(utf8.decode(response.bodyBytes)) as List).map((d) => Directory.fromJson(d)).toList();
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  @override
  Future<List<Directory>> recent() async {
    final url = _makeURL(recentEndpoint);
    final response = await _makeRequest(_Method.get, url, authenticate: true);
    try {
      return (json.decode(utf8.decode(response.bodyBytes)) as List).map((d) => Directory.fromJson(d)).toList();
    } catch (e) {
      throw APIError.responseParseError;
    }
  }

  @override
  Future<Uint8List> downloadImage(String path) async {
    final url = _makeURL(thumbnailEndpoint + Uri.encodeComponent(path) + '?pad=false');
    return _makeRequest(_Method.get, url, authenticate: true).then((r) => r.bodyBytes);
  }
}
