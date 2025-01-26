import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:polaris/core/client/api/api_client.dart';
import 'package:polaris/core/connection.dart' as connection;

enum Method {
  get,
  post,
  put,
  delete,
}

extension MethodToString on Method {
  String toHTTPMethod() {
    return switch (this) {
      Method.get => 'GET',
      Method.post => 'POST',
      Method.put => 'PUT',
      Method.delete => 'DELETE',
    };
  }
}

abstract class BaseHttpClient {
  final http.Client httpClient;
  final connection.Manager connectionManager;

  BaseHttpClient({
    required this.httpClient,
    required this.connectionManager,
  });

  String makeURL(String endpoint) {
    return (connectionManager.url ?? "") + endpoint;
  }

  Future<http.StreamedResponse> makeRequest(Method method, String url,
      {dynamic body, String? authenticationToken, Duration? timeout}) async {
    http.Request request = http.Request(method.toHTTPMethod(), Uri.parse(url));

    if (authenticationToken != null) {
      request.headers[HttpHeaders.authorizationHeader] = 'Bearer $authenticationToken';
    }

    request.headers["Accept-Version"] = '8';

    if (method == Method.post) {
      request.headers[HttpHeaders.contentTypeHeader] = 'application/json';
      request.body = jsonEncode(body);
    }

    Future<http.StreamedResponse> response;
    try {
      developer.log('Making API Request: ${request.url}');
      response = httpClient.send(request);
    } catch (e) {
      return Future.error(APIError.networkError);
    }

    if (timeout != null) {
      response = response.timeout(timeout, onTimeout: () => throw APIError.timeout);
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

  Future<Uint8List> completeRequest(Method method, String url,
      {dynamic body, String? authenticationToken, Duration? timeout}) async {
    final streamedResponse =
        makeRequest(method, url, body: body, authenticationToken: authenticationToken, timeout: timeout);
    return streamedResponse.then((r) => r.stream.toBytes());
  }
}
