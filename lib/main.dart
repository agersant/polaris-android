import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:polaris/api/api.dart';
import 'package:polaris/api/http_api.dart';
import 'package:polaris/api/host.dart';
import 'package:polaris/ui/startup/page.dart';
import 'package:polaris/store/connection.dart';

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
  var host = await Host.create();
  getIt.registerSingleton<Host>(host);
  getIt.registerSingleton<Client>(Client());
  getIt.registerSingleton<API>(HttpAPI());
  getIt.registerSingleton<ConnectionStore>(ConnectionStore());
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
