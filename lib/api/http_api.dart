import 'dart:convert';
import 'package:get_it/get_it.dart';
import 'package:polaris/api/api.dart';
import 'package:polaris/api/dto.dart';
import 'package:polaris/api/host.dart';
import 'package:http/http.dart' as http;

final getIt = GetIt.instance;

class HttpAPI implements API {
  final _host = getIt<Host>();

  String _makeURL(String endpoint) {
    if (_host.url == null) {
      throw APIError.unspecifiedHost;
    }
    return _host.url + endpoint;
  }

  @override
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
