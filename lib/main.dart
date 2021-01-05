import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:polaris/shared/collection_api.dart';
import 'package:polaris/shared/http_collection_api.dart';
import 'package:polaris/shared/loopback_host.dart';
import 'package:polaris/shared/token.dart' as token;
import 'package:polaris/shared/host.dart' as host;
import 'package:polaris/transient/authentication.dart' as authentication;
import 'package:polaris/transient/connection.dart' as connection;
import 'package:polaris/transient/http_guest_api.dart';
import 'package:polaris/transient/service_launcher.dart';
import 'package:polaris/shared/shared_preferences_host.dart';
import 'package:polaris/ui/collection/page.dart';
import 'package:polaris/ui/playback/player.dart';
import 'package:polaris/ui/startup/page.dart';
import 'package:provider/provider.dart';

final getIt = GetIt.instance;

final lightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.blue,
);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  // Colors below are a workaround for https://github.com/flutter/flutter/issues/19089
  toggleableActiveColor: Colors.blue[200],
  accentColor: Colors.blue[200],
  textSelectionHandleColor: Colors.blue[400],
);

Future _registerSingletons() async {
  final hostManager = await SharedPreferencesHost.create();
  final tokenManager = await token.Manager.create();
  final client = Client();
  final guestAPI = HttpGuestAPI(
    tokenManager: tokenManager,
    hostManager: hostManager,
    client: client,
  );
  final loopbackHost = LoopbackHost();
  final collectionAPI = HttpCollectionAPI(
    client: client,
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
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _registerSingletons();
  runApp(PolarisApp());
}

class PolarisPath {}

class PolarisRouteInformationParser extends RouteInformationParser<PolarisPath> {
  @override
  Future<PolarisPath> parseRouteInformation(RouteInformation routeInformation) async {
    return PolarisPath();
  }
}

class PolarisRouterDelegate extends RouterDelegate<PolarisPath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<PolarisPath> {
  final GlobalKey<NavigatorState> navigatorKey;

  PolarisRouterDelegate() : navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: getIt<connection.Manager>()),
        ChangeNotifierProvider.value(value: getIt<authentication.Manager>()),
      ],
      child: Consumer2<connection.Manager, authentication.Manager>(
        builder: (context, connectionManager, authenticationManager, child) {
          final isStartupComplete = connectionManager.state == connection.State.connected &&
              authenticationManager.state == authentication.State.authenticated;
          // TODO wait for service to be started

          return AudioServiceWidget(
            child: Column(
              children: [
                Expanded(
                  child: Navigator(
                    key: navigatorKey,
                    pages: [
                      if (!isStartupComplete) MaterialPage(child: StartupPage()),
                      if (isStartupComplete) MaterialPage(child: CollectionPage()),
                    ],
                    onPopPage: (route, result) {
                      if (!route.didPop(result)) {
                        return false;
                      }
                      return true;
                    },
                  ),
                ),
                if (isStartupComplete) Player(),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Future<void> setNewRoutePath(PolarisPath configuration) => null;
}

class PolarisApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Polaris',
      theme: lightTheme,
      darkTheme: darkTheme,
      routeInformationParser: PolarisRouteInformationParser(),
      routerDelegate: PolarisRouterDelegate(),
    );
  }
}
