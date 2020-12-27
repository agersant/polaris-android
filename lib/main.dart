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
);

Future _registerSingletons() async {
  getIt.registerSingleton<host.Manager>(await host.Manager.create());
  getIt.registerSingleton<token.Manager>(await token.Manager.create());
  getIt.registerSingleton<Client>(Client());
  getIt.registerSingleton<API>(HttpAPI());
  getIt.registerSingleton<connection.Manager>(connection.Manager());
  getIt.registerSingleton<authentication.Manager>(authentication.Manager());
  getIt.registerSingleton<cache.Manager>(await cache.Manager.create());
  getIt.registerSingleton<collection.Interface>(collection.Interface());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _registerSingletons();
  runApp(PolarisApp());
}

class PolarisApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polaris',
      theme: lightTheme,
      darkTheme: darkTheme,
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: getIt<connection.Manager>()),
          ChangeNotifierProvider.value(value: getIt<authentication.Manager>()),
        ],
        child: Consumer2<connection.Manager, authentication.Manager>(
          builder: (context, connectionManager, authenticationManager, child) {
            final isStartupComplete = connectionManager.state == connection.State.connected &&
                authenticationManager.state == authentication.State.authenticated;

            List<Page<dynamic>> pages;
            if (!isStartupComplete) {
              pages = [MaterialPage(child: StartupPage())];
            } else {
              pages = [
                MaterialPage(child: CollectionPage()),
              ];
            }

            return Navigator(
              pages: pages,
              onPopPage: (route, result) {
                if (!route.didPop(result)) {
                  return false;
                }
                return true;
              },
            );
          },
        ),
      ),
    );
  }
}
