import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:polaris/core/authentication.dart' as authentication;
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/cache.dart' as cache;
import 'package:polaris/core/playlist.dart';
import 'package:polaris/core/polaris.dart' as polaris;
import 'package:polaris/ui/collection/browser_model.dart';
import 'package:polaris/ui/collection/page.dart';
import 'package:polaris/ui/playback/player.dart';
import 'package:polaris/ui/playback/queue.dart';
import 'package:polaris/ui/playback/queue_model.dart';
import 'package:polaris/ui/startup/page.dart';
import 'package:polaris/ui/utils/back_button_handler.dart';
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
  final httpClient = http.Client();
  final connectionManager = connection.Manager(httpClient: httpClient);
  final authenticationManager = authentication.Manager(
    httpClient: httpClient,
    connectionManager: connectionManager,
  );
  final cacheManager = await cache.Manager.create();
  final polarisClient = polaris.Client(
    cacheManager: cacheManager,
    offlineClient: polaris.OfflineClient(
      connectionManager: connectionManager,
      cacheManager: cacheManager,
    ),
    httpClient: polaris.HttpClient(
      httpClient: httpClient,
      connectionManager: connectionManager,
      authenticationManager: authenticationManager,
    ),
    connectionManager: connectionManager,
  );
  final uuid = Uuid();
  final audioPlayer = AudioPlayer();
  final playlist = Playlist(uuid: uuid, polarisClient: polarisClient, audioPlayer: audioPlayer);

  getIt.registerSingleton<AudioPlayer>(audioPlayer);
  getIt.registerSingleton<Playlist>(playlist);
  getIt.registerSingleton<connection.Manager>(connectionManager);
  getIt.registerSingleton<authentication.Manager>(authenticationManager);
  getIt.registerSingleton<polaris.Client>(polarisClient);
  getIt.registerSingleton<BrowserModel>(BrowserModel());
  getIt.registerSingleton<QueueModel>(QueueModel());
  getIt.registerSingleton<Uuid>(uuid);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _registerSingletons();

  await JustAudioBackground.init(
    androidNotificationChannelName: 'Polaris Audio Playback',
    androidNotificationOngoing: true,
  );
  final session = await AudioSession.instance;
  await session.configure(AudioSessionConfiguration.music());
  await getIt<AudioPlayer>().setAudioSource(getIt<Playlist>().audioSource);

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
        ChangeNotifierProvider.value(value: getIt<QueueModel>()),
      ],
      child: Consumer2<authentication.Manager, QueueModel>(
        builder: (context, authenticationManager, queueModel, child) {
          final isStartupComplete = authenticationManager.state == authentication.State.authenticated;
          final showQueue = isStartupComplete && queueModel.isQueueOpen;

          return BackButtonHandler(
            Column(
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
          );
        },
      ),
    );
  }

  @override
  Future<void> setNewRoutePath(PolarisPath configuration) async => null;
}

class PolarisApp extends StatefulWidget {
  @override
  _PolarisAppState createState() => _PolarisAppState();
}

class _PolarisAppState extends State<PolarisApp> {
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

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {}

  @override
  void dispose() {
    getIt<AudioPlayer>().dispose();
    super.dispose();
  }
}
