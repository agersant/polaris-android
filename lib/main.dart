import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:polaris/shared/loopback_host.dart';
import 'package:polaris/shared/token.dart' as token;
import 'package:polaris/shared/host.dart' as host;
import 'package:polaris/shared/polaris.dart' as polaris;
import 'package:polaris/shared/shared_preferences_host.dart';
import 'package:polaris/foreground/authentication.dart' as authentication;
import 'package:polaris/foreground/connection.dart' as connection;
import 'package:polaris/foreground/service.dart' as service;
import 'package:polaris/foreground/ui/collection/browser_model.dart';
import 'package:polaris/foreground/ui/collection/page.dart';
import 'package:polaris/foreground/ui/playback/player.dart';
import 'package:polaris/foreground/ui/playback/queue.dart';
import 'package:polaris/foreground/ui/playback/queue_model.dart';
import 'package:polaris/foreground/ui/startup/page.dart';
import 'package:polaris/foreground/ui/utils/back_button_handler.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

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
);

Future _registerSingletons() async {
  final hostManager = await SharedPreferencesHost.create();
  final tokenManager = await token.Manager.create();
  final client = Client();
  final guestAPI = polaris.HttpGuestAPI(
    tokenManager: tokenManager,
    hostManager: hostManager,
    client: client,
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
    launcher: service.AudioServiceLauncher(),
  );
  final loopbackHost = LoopbackHost(serviceManager: serviceManager);
  final polarisAPI = polaris.HttpAPI(
    client: client,
    hostManager: loopbackHost,
    tokenManager: null,
  );

  getIt.registerSingleton<host.Manager>(hostManager);
  getIt.registerSingleton<connection.Manager>(connectionManager);
  getIt.registerSingleton<authentication.Manager>(authenticationManager);
  getIt.registerSingleton<service.Manager>(serviceManager);
  getIt.registerSingleton<polaris.API>(polarisAPI);
  getIt.registerSingleton<BrowserModel>(BrowserModel());
  getIt.registerSingleton<QueueModel>(QueueModel());
  getIt.registerSingleton<Uuid>(Uuid());
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
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: getIt<connection.Manager>()),
        ChangeNotifierProvider.value(value: getIt<authentication.Manager>()),
        ChangeNotifierProvider.value(value: getIt<polaris.API>()),
        ChangeNotifierProvider.value(value: getIt<QueueModel>()),
      ],
      child: Consumer2<polaris.API, QueueModel>(
        builder: (context, polarisAPI, queueModel, child) {
          final isStartupComplete = polarisAPI.state == polaris.State.available;
          final showQueue = isStartupComplete && queueModel.isQueueOpen;

          return BackButtonHandler(
            AudioServiceWidget(
              child: Column(
                children: [
                  Expanded(
                    child: Navigator(
                      key: navigatorKey,
                      pages: [
                        if (!isStartupComplete) MaterialPage(child: StartupPage()),
                        if (isStartupComplete) MaterialPage(child: CollectionPage()),
                        // TODO Ideally album details would be here
                        // However, OpenContainer() can't be used with the pages API.
                        if (showQueue) MaterialPage(child: QueuePage()),
                      ],
                      onPopPage: (route, result) {
                        if (!route.didPop(result)) {
                          return false;
                        }
                        if (queueModel.isQueueOpen) {
                          queueModel.closeQueue();
                        }
                        return true;
                      },
                    ),
                  ),
                  if (isStartupComplete) Player(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Future<void> setNewRoutePath(PolarisPath configuration) async => null;
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
