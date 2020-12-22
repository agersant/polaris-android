import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:polaris/api/api.dart';
import 'package:polaris/store/connection.dart';
import 'package:polaris/ui/startup.dart';

final getIt = GetIt.instance;

void setup() {
  getIt.registerSingleton<API>(API());
  getIt.registerSingleton<ConnectionStore>(ConnectionStore());
}

void main() {
  setup();
  runApp(PolarisApp());
}

class PolarisApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => getIt<ConnectionStore>())
      ],
      child: MaterialApp(
        title: 'Polaris',
        theme: ThemeData(
          brightness: Brightness.light,
          primarySwatch: Colors.blue,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.blue,
        ),
        home: StartupPage(),
      ),
    );
  }
}
