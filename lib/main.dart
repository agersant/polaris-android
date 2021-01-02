import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:polaris/collection/cache.dart' as cache;
import 'package:polaris/collection/interface.dart' as collection;
import 'package:polaris/platform/api.dart';
import 'package:polaris/platform/authentication.dart' as authentication;
import 'package:polaris/platform/connection.dart' as connection;
import 'package:polaris/platform/http_api.dart';
import 'package:polaris/platform/host.dart' as host;
import 'package:polaris/platform/token.dart' as token;
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
  getIt.registerSingleton<host.Manager>(await host.Manager.create());
  getIt.registerSingleton<token.Manager>(await token.Manager.create());
  getIt.registerSingleton<Client>(Client());
  getIt.registerSingleton<API>(HttpAPI());
  getIt.registerSingleton<connection.Manager>(connection.Manager());
  getIt.registerSingleton<authentication.Manager>(authentication.Manager());
  getIt.registerSingleton<cache.Interface>(await cache.Manager.create());
  getIt.registerSingleton<collection.Interface>(collection.Interface());
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

          return Column(
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
