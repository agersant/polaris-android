import 'dart:convert';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:polaris/service/api.dart';
import 'package:polaris/service/dto.dart';
import 'package:polaris/service/host.dart';

final getIt = GetIt.instance;

final apiVersionEndpoint = '/api/version';

class HttpAPI implements API {
  final _host = getIt<Host>();
  final _client = getIt<Client>();

  String _makeURL(String endpoint) {
    if (_host.url == null) {
      throw APIError.unspecifiedHost;
    }
    return _host.url + endpoint;
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
    if (response.statusCode == 200) {
      return APIVersion.fromJson(jsonDecode(response.body));
    }
    throw APIError.requestFailed;
  }
}
