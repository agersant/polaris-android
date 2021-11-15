import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:polaris/core/authentication.dart' as authentication;
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/cache/media.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/download.dart' as download;
import 'package:polaris/core/pin.dart' as pin;
import 'package:polaris/core/playlist.dart';
import 'package:polaris/core/polaris.dart' as polaris;
import 'package:polaris/core/prefetch.dart' as prefetch;
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
  indicatorColor: Colors.blue, // TabBar current tab highlight
  toggleableActiveColor: Colors.blue, // SwitchListTile color
);

Future _registerSingletons() async {
  const uuid = Uuid();
  final httpClient = http.Client();
  final connectionManager = connection.Manager(httpClient: httpClient);
  final authenticationManager = authentication.Manager(
    httpClient: httpClient,
    connectionManager: connectionManager,
  );
  final polarisHttpClient = polaris.HttpClient(
    httpClient: httpClient,
    connectionManager: connectionManager,
    authenticationManager: authenticationManager,
  );
  final mediaCache = await MediaCache.create();
  final collectionCache = await CollectionCache.create();
  final downloadManager = download.Manager(
    mediaCache: mediaCache,
    httpClient: polarisHttpClient,
  );
  final polarisClient = polaris.Client(
    offlineClient: polaris.OfflineClient(
      mediaCache: mediaCache,
      collectionCache: collectionCache,
    ),
    httpClient: polarisHttpClient,
    downloadManager: downloadManager,
    connectionManager: connectionManager,
    collectionCache: collectionCache,
    mediaCache: mediaCache,
  );
  final audioPlayer = AudioPlayer();
  final playlist = Playlist(
    uuid: uuid,
    connectionManager: connectionManager,
    polarisClient: polarisClient,
    audioPlayer: audioPlayer,
  );
  final pinManager = await pin.Manager.create();
  final prefetchManager = prefetch.Manager(
    connectionManager: connectionManager,
    downloadManager: downloadManager,
    mediaCache: mediaCache,
    playlist: playlist,
  );

  getIt.registerSingleton<AudioPlayer>(audioPlayer);
  getIt.registerSingleton<Playlist>(playlist);
  getIt.registerSingleton<CollectionCache>(collectionCache);
  getIt.registerSingleton<connection.Manager>(connectionManager);
  getIt.registerSingleton<authentication.Manager>(authenticationManager);
  getIt.registerSingleton<polaris.Client>(polarisClient);
  getIt.registerSingleton<prefetch.Manager>(prefetchManager);
  getIt.registerSingleton<pin.Manager>(pinManager);
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
  await session.configure(const AudioSessionConfiguration.music());
  await getIt<AudioPlayer>().setAudioSource(getIt<Playlist>().audioSource);

  runApp(const PolarisApp());
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
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: getIt<connection.Manager>()),
        ChangeNotifierProvider.value(value: getIt<authentication.Manager>()),
        ChangeNotifierProvider.value(value: getIt<QueueModel>()),
      ],
      child: Consumer3<connection.Manager, authentication.Manager, QueueModel>(
        builder: (context, connectionManager, authenticationManager, queueModel, child) {
          final isOfflineMode = connectionManager.state == connection.State.offlineMode;
          final connectionComplete = connectionManager.state == connection.State.connected;
          final authenticationComplete = authenticationManager.state == authentication.State.authenticated;
          final isStartupComplete = isOfflineMode || (connectionComplete && authenticationComplete);
          final showQueue = isStartupComplete && queueModel.isQueueOpen;

          return BackButtonHandler(
            Column(
              children: [
                Expanded(
                  child: Navigator(
                    key: navigatorKey,
                    pages: [
                      if (!isStartupComplete) MaterialPage<dynamic>(child: StartupPage()),
                      if (isStartupComplete) const MaterialPage<dynamic>(child: CollectionPage()),
                      // TODO Ideally album details would be here but OpenContainer() can't be used with the pages API.
                      if (showQueue) const MaterialPage<dynamic>(child: QueuePage()),
                    ],
                    onPopPage: (route, dynamic result) {
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
                if (isStartupComplete) const Player(),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Future<void> setNewRoutePath(PolarisPath configuration) async {}
}

class PolarisApp extends StatefulWidget {
  const PolarisApp({Key? key}) : super(key: key);

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
    getIt<prefetch.Manager>().dispose();
    super.dispose();
  }
}
