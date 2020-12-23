import 'dart:convert';
import 'package:polaris/api/dto.dart';
import 'package:http/http.dart' as http;

enum APIError {
  unspecifiedHost,
  networkError,
  requestFailed,
}

class API {
  String _host;
  // String _authToken;

  set host(String host) {
    // TODO trim, remove trailing slash, prepend http:// if needed
    _host = host;
  }

  // set authToken(String authToken) {
  //   _authToken = authToken;
  // }

  String _makeURL(String endpoint) {
    if (_host == null) {
      throw APIError.unspecifiedHost;
    }
    return _host + endpoint;
  }

  Future<APIVersion> getAPIVersion() async {
    var url = _makeURL('/api/version');
    var response;
    try {
      response = await http.get(url);
    } catch (e) {
      throw APIError.networkError;
    }
    if (response.statusCode == 200) {
      return APIVersion.fromJson(jsonDecode(response.body));
    }
    throw APIError.requestFailed;
  }
}
