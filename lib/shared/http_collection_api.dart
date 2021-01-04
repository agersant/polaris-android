import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:polaris/shared/collection_api.dart';
import 'package:polaris/shared/dto.dart';
import 'package:polaris/shared/host.dart' as host;
import 'package:polaris/shared/token.dart' as token;

import 'api_error.dart';

final apiVersionEndpoint = '/api/version/';
final browseEndpoint = '/api/browse/';
final randomEndpoint = '/api/random/';
final recentEndpoint = '/api/recent/';
final loginEndpoint = '/api/auth/';
final thumbnailEndpoint = '/api/thumbnail/';
final audioEndpoint = '/api/audio/';

// TODO this is copy pasta
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

class HttpCollectionAPI implements CollectionAPI {
  final host.Manager hostManager;
  final token.Manager tokenManager;
  final Client client;

  HttpCollectionAPI({@required this.client, @required this.tokenManager, @required this.hostManager})
      : assert(client != null),
        assert(hostManager != null);

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
  Future<Uint8List> downloadImage(String path) async {
    final url = _makeURL(thumbnailEndpoint + Uri.encodeComponent(path) + '?pad=false');
    return _completeRequest(_Method.get, url, authenticate: true);
  }

  @override
  Uri getImageURI(String path) {
    assert(path != null);
    Uri uri = Uri.parse(thumbnailEndpoint + Uri.encodeComponent(path) + '?pad=false');
    if (tokenManager != null) {
      uri.queryParameters['auth_token'] = tokenManager.token;
    }
    return uri;
  }

  @override
  Future<StreamedResponse> downloadAudio(String path) async {
    final url = _makeURL(audioEndpoint + Uri.encodeComponent(path));
    return _makeRequest(_Method.get, url, authenticate: true);
  }
}
