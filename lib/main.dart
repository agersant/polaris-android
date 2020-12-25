import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:polaris/platform/api.dart';
import 'package:polaris/platform/authentication.dart' as authentication;
import 'package:polaris/platform/connection.dart' as connection;
import 'package:polaris/platform/http_api.dart';
import 'package:polaris/platform/host.dart' as host;
import 'package:polaris/platform/token.dart' as token;
import 'package:polaris/ui/startup/page.dart';

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
      home: StartupPage(),
    );
  }
}
