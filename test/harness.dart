import 'package:polaris/shared/loopback_host.dart';
import 'package:polaris/transient/service_launcher.dart';
import 'package:polaris/transient/ui_model.dart';

import 'mock/client.dart' as client;
import 'package:get_it/get_it.dart';
import 'package:polaris/shared/collection_api.dart';
import 'package:polaris/shared/http_collection_api.dart';
import 'package:polaris/shared/token.dart' as token;
import 'package:polaris/shared/host.dart' as host;
import 'package:polaris/transient/authentication.dart' as authentication;
import 'package:polaris/transient/connection.dart' as connection;
import 'package:polaris/transient/http_guest_api.dart';
import 'package:polaris/shared/shared_preferences_host.dart' as host;
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

    final hostManager = await host.SharedPreferencesHost.create();
    final tokenManager = await token.Manager.create();
    final mockClient = client.Mock();
    final guestAPI = HttpGuestAPI(
      tokenManager: tokenManager,
      hostManager: hostManager,
      client: mockClient,
    );
    final loopbackHost = LoopbackHost();
    final collectionAPI = HttpCollectionAPI(
      client: mockClient,
      hostManager: loopbackHost,
      tokenManager: null,
    );
    final connectionManager = connection.Manager(
      hostManager: hostManager,
      guestAPI: guestAPI,
    );
    final authenticationManager = authentication.Manager(
      connectionManager: connectionManager,
      tokenManager: tokenManager,
      guestAPI: guestAPI,
    );
    final serviceLauncher = ServiceLauncher(
      hostManager: hostManager,
      tokenManager: tokenManager,
      connectionManager: connectionManager,
      authenticationManager: authenticationManager,
      loopbackHost: loopbackHost,
    );

    getIt.registerSingleton<host.Manager>(hostManager);
    getIt.registerSingleton<connection.Manager>(connectionManager);
    getIt.registerSingleton<authentication.Manager>(authenticationManager);
    getIt.registerSingleton<ServiceLauncher>(serviceLauncher);
    getIt.registerSingleton<CollectionAPI>(collectionAPI);
    getIt.registerSingleton<UIModel>(UIModel());

    return Harness(mockClient);
  }
}
