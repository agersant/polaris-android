import 'dart:convert';
import 'dart:io';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:polaris/platform/api.dart';
import 'package:polaris/platform/dto.dart';
import 'package:polaris/platform/host.dart' as host;
import 'package:polaris/platform/token.dart' as token;

final getIt = GetIt.instance;

final apiVersionEndpoint = '/api/version';
final browseEndpoint = '/api/browse';
final loginEndpoint = '/api/auth';

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

  Future<Response> _makeRequest(_Method method, String url, {dynamic body}) async {
    var response;

    Map<String, String> headers = Map();
    if (_tokenManager.token != null && _tokenManager.token.isNotEmpty) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer ' + _tokenManager.token;
    }

    try {
      switch (method) {
        case _Method.get:
          response = await _client.get(url, headers: headers);
          break;
        case _Method.post:
          headers[HttpHeaders.contentTypeHeader] = 'application/json';
          response = await _client.post(url, headers: headers, body: body);
          break;
      }
    } catch (e) {
      throw APIError.networkError;
    }

    if (response.statusCode == 401) {
      throw APIError.unauthorized;
    }

    if (response.statusCode == 200) {
      return response;
    }

    throw APIError.requestFailed;
  }

  @override
  Future<APIVersion> getAPIVersion() async {
    final url = _makeURL(apiVersionEndpoint);
    final response = await _makeRequest(_Method.get, url);
    return APIVersion.fromJson(jsonDecode(response.body));
  }

  @override
  Future<Authorization> login(String username, String password) async {
    final url = _makeURL(loginEndpoint);
    final credentials = Credentials(username: username, password: password).toJson();
    final response = await _makeRequest(_Method.post, url, body: credentials);
    return Authorization.fromJson(jsonDecode(response.body));
  }

  @override
  Future browse(String path) async {
    final url = _makeURL(browseEndpoint);
    await _makeRequest(_Method.get, url);
  }
}
