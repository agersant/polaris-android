import 'mock/client.dart' as client;
import 'mock/cache.dart' as cache;
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:polaris/collection/cache.dart' as cache show Interface;
import 'package:polaris/collection/interface.dart' as collection;
import 'package:polaris/platform/api.dart';
import 'package:polaris/platform/authentication.dart' as authentication;
import 'package:polaris/platform/connection.dart' as connection;
import 'package:polaris/platform/http_api.dart';
import 'package:polaris/platform/host.dart' as host;
import 'package:polaris/platform/token.dart' as token;
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

class Harness {
  final client.Mock mockClient;
  Harness(this.mockClient);

  static final Map<String, dynamic> reconnectPreferences = {
    host.preferenceKey: client.goodHostURL,
    token.preferenceKey: 'auth-token',
  };

  static Future<Harness> reconnect() async {
    return create(preferences: reconnectPreferences);
  }

  static Future<Harness> create({Map<String, dynamic> preferences}) async {
    SharedPreferences.setMockInitialValues(preferences ?? Map());

    getIt.allowReassignment = true;

    getIt.registerSingleton<host.Manager>(await host.Manager.create());
    getIt.registerSingleton<token.Manager>(await token.Manager.create());

    final mockClient = client.Mock();
    getIt.registerSingleton<Client>(mockClient);
    getIt.registerSingleton<API>(HttpAPI());

    getIt.registerSingleton<connection.Manager>(connection.Manager());
    getIt.registerSingleton<authentication.Manager>(authentication.Manager());

    getIt.registerSingleton<cache.Interface>(await cache.Manager.create());
    getIt.registerSingleton<collection.Interface>(collection.Interface());

    return Harness(mockClient);
  }
}
