import 'dart:convert';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:polaris/platform/api.dart';
import 'package:polaris/platform/dto.dart';
import 'package:polaris/platform/host.dart' as host;

final getIt = GetIt.instance;

final apiVersionEndpoint = '/api/version';

class HttpAPI implements API {
  final _hostManager = getIt<host.Manager>();
  final _client = getIt<Client>();

  String _makeURL(String endpoint) {
    if (_hostManager.url == null) {
      throw APIError.unspecifiedHost;
    }
    return _hostManager.url + endpoint;
  }

  @override
  Future<APIVersion> getAPIVersion() async {
    var url = _makeURL(apiVersionEndpoint);
    var response;
    try {
      response = await _client.get(url);
    } catch (e) {
      throw APIError.networkError;
    }
    if (response.statusCode == 401) {
      throw APIError.unauthorized;
    }
    if (response.statusCode == 200) {
      return APIVersion.fromJson(jsonDecode(response.body));
    }
    throw APIError.requestFailed;
  }
}
