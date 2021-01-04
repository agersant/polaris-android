import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:polaris/shared/api_error.dart';
import 'package:polaris/shared/dto.dart';
import 'package:polaris/transient/guest_api.dart';
import 'package:polaris/shared/host.dart' as host;
import 'package:polaris/shared/token.dart' as token;

final apiVersionEndpoint = '/api/version/';
final loginEndpoint = '/api/auth/';
final browseEndpoint = '/api/browse/';

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
