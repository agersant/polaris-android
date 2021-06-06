import 'mock/client.dart' as client;
import 'mock/service.dart' as service show MockServiceLauncher;
import 'package:get_it/get_it.dart';
import 'package:polaris/shared/loopback_host.dart';
import 'package:polaris/shared/polaris.dart' as polaris;
import 'package:polaris/shared/token.dart' as token;
import 'package:polaris/shared/host.dart' as host;
import 'package:polaris/shared/shared_preferences_host.dart' as host;
import 'package:polaris/foreground/authentication.dart' as authentication;
import 'package:polaris/foreground/connection.dart' as connection;
import 'package:polaris/foreground/service.dart' as service;
import 'package:polaris/foreground/ui/collection/browser_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final getIt = GetIt.instance;

class Harness {
  final client.Mock mockClient;
  Harness(this.mockClient);

  static final Map<String, Object> reconnectPreferences = {
    host.preferenceKey: client.goodHostURI,
    token.preferenceKey: 'auth-token',
  };

  static Future<Harness> reconnect() async {
    return create(preferences: reconnectPreferences);
  }

  static Future<Harness> create({Map<String, Object>? preferences}) async {
    SharedPreferences.setMockInitialValues(preferences ?? new Map());

    getIt.allowReassignment = true;

    final hostManager = await host.SharedPreferencesHost.create();
    final tokenManager = await token.Manager.create();
    final mockClient = client.Mock();
    final guestAPI = polaris.HttpGuestAPI(
      tokenManager: tokenManager,
      hostManager: hostManager,
      client: mockClient,
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
    final serviceManager = service.Manager(
      hostManager: hostManager,
      tokenManager: tokenManager,
      connectionManager: connectionManager,
      authenticationManager: authenticationManager,
      launcher: service.MockServiceLauncher(),
    );
    final loopbackHost = LoopbackHost(serviceManager: serviceManager);
    final collectionAPI = polaris.HttpAPI(
      client: mockClient,
      hostManager: loopbackHost,
      tokenManager: null,
    );

    getIt.registerSingleton<host.Manager>(hostManager);
    getIt.registerSingleton<connection.Manager>(connectionManager);
    getIt.registerSingleton<authentication.Manager>(authenticationManager);
    getIt.registerSingleton<service.Manager>(serviceManager);
    getIt.registerSingleton<polaris.API>(collectionAPI);
    getIt.registerSingleton<BrowserModel>(BrowserModel());
    getIt.registerSingleton<Uuid>(Uuid());

    return Harness(mockClient);
  }
}
