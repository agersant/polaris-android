import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:polaris/core/authentication.dart' as authentication;
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/cache/media.dart';
import 'package:polaris/core/cleanup.dart' as cleanup;
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/download.dart' as download;
import 'package:polaris/core/pin.dart' as pin;
import 'package:polaris/core/playlist.dart';
import 'package:polaris/core/polaris.dart' as polaris;
import 'package:polaris/core/prefetch.dart' as prefetch;
import 'package:polaris/core/savestate.dart' as savestate;
import 'package:polaris/core/settings.dart' as settings;
import 'package:polaris/ui/collection/browser_model.dart';
import 'package:polaris/ui/collection/page.dart';
import 'package:polaris/ui/offline_music/page.dart';
import 'package:polaris/ui/pages_model.dart';
import 'package:polaris/ui/playback/mini_player.dart';
import 'package:polaris/ui/playback/player.dart';
import 'package:polaris/ui/playback/queue.dart';
import 'package:polaris/ui/settings/page.dart';
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
  final settingsManager = settings.Manager();
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
  final polarisOfflineClient = polaris.OfflineClient(
    mediaCache: mediaCache,
    collectionCache: collectionCache,
  );
  final polarisClient = polaris.Client(
    offlineClient: polarisOfflineClient,
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
  final savestateManager =
      savestate.Manager(connectionManager: connectionManager, audioPlayer: audioPlayer, playlist: playlist);
  final pinManager = await pin.Manager.create(
    connectionManager: connectionManager,
    polarisClient: polarisClient,
  );
  final prefetchManager = prefetch.Manager(
    uuid: uuid,
    connectionManager: connectionManager,
    authenticationManager: authenticationManager,
    downloadManager: downloadManager,
    mediaCache: mediaCache,
    pinManager: pinManager,
    audioPlayer: audioPlayer,
    settingsManager: settingsManager,
  );
  final cleanupManager = cleanup.Manager(
    connectionManager: connectionManager,
    mediaCache: mediaCache,
    pinManager: pinManager,
    audioPlayer: audioPlayer,
    settingsManager: settingsManager,
  );
  final browserModel = BrowserModel(connectionManager: connectionManager);

  // TODO Needs some logic to recover from app restart while audio service is still running (?)

  getIt.registerSingleton<AudioPlayer>(audioPlayer);
  getIt.registerSingleton<Playlist>(playlist);
  getIt.registerSingleton<CollectionCache>(collectionCache);
  getIt.registerSingleton<MediaCacheInterface>(mediaCache);
  getIt.registerSingleton<connection.Manager>(connectionManager);
  getIt.registerSingleton<authentication.Manager>(authenticationManager);
  getIt.registerSingleton<polaris.Client>(polarisClient);
  getIt.registerSingleton<savestate.Manager>(savestateManager);
  getIt.registerSingleton<pin.Manager>(pinManager);
  getIt.registerSingleton<prefetch.Manager>(prefetchManager);
  getIt.registerSingleton<cleanup.Manager>(cleanupManager);
  getIt.registerSingleton<BrowserModel>(browserModel);
  getIt.registerSingleton<PagesModel>(PagesModel());
  getIt.registerSingleton<settings.Manager>(settingsManager);
  getIt.registerSingleton<Uuid>(uuid);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.init();
  await _registerSingletons();
  await JustAudioBackground.init(
    androidNotificationIcon: "drawable/notification_icon",
    androidNotificationChannelName: 'Polaris Audio Playback',
    androidNotificationOngoing: true,
  );
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
  await getIt<AudioPlayer>().setAudioSource(getIt<Playlist>().audioSource);
  getIt<savestate.Manager>().init();

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
        ChangeNotifierProvider.value(value: getIt<PagesModel>()),
      ],
      child: Consumer3<connection.Manager, authentication.Manager, PagesModel>(
        builder: (context, connectionManager, authenticationManager, pagesModel, child) {
          final isOfflineMode = connectionManager.state == connection.State.offlineMode;
          final connectionComplete = connectionManager.isConnected();
          final authenticationComplete = authenticationManager.isAuthenticated();
          final isStartupComplete = isOfflineMode || (connectionComplete && authenticationComplete);
          final showPlayer = isStartupComplete && pagesModel.isPlayerOpen;
          final collapseMiniPlayer = !isStartupComplete || (pagesModel.isPlayerOpen && !pagesModel.isQueueOpen);
          final showQueue = isStartupComplete && pagesModel.isQueueOpen;
          final showSettings = isStartupComplete && pagesModel.isSettingsOpen;
          final showOfflineMusic = isStartupComplete && pagesModel.isOfflineMusicOpen;

          return BackButtonHandler(
            Column(
              children: [
                Expanded(
                  child: Navigator(
                    key: navigatorKey,
                    pages: [
                      if (!isStartupComplete) MaterialPage<dynamic>(child: StartupPage()),
                      if (isStartupComplete) const MaterialPage<dynamic>(child: CollectionPage()),
                      if (showSettings) const MaterialPage<dynamic>(child: SettingsPage()),
                      if (showOfflineMusic) const MaterialPage<dynamic>(child: OfflineMusicPage()),
                      // Ideally album details would be here but OpenContainer() can't be used with the pages API.
                      // TODO Consider transitions that aren't the default for player and queue pages
                      if (showPlayer) const MaterialPage<dynamic>(child: PlayerPage()),
                      if (showQueue) const MaterialPage<dynamic>(child: QueuePage()),
                    ],
                    onPopPage: (route, dynamic result) {
                      if (!route.didPop(result)) {
                        return false;
                      }
                      if (pagesModel.isQueueOpen) {
                        pagesModel.closeQueue();
                      } else if (pagesModel.isPlayerOpen) {
                        pagesModel.closePlayer();
                      } else if (pagesModel.isOfflineMusicOpen) {
                        pagesModel.closeOfflineMusic();
                      } else if (pagesModel.isSettingsOpen) {
                        pagesModel.closeSettings();
                      }
                      return true;
                    },
                  ),
                ),
                MiniPlayer(collapse: collapseMiniPlayer),
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
  State<PolarisApp> createState() => _PolarisAppState();
}

class _PolarisAppState extends State<PolarisApp> {
  @override
  Widget build(BuildContext context) {
    return ValueChangeObserver<int>(
      cacheKey: settings.keyThemeMode,
      defaultValue: settings.defaultThemeMode,
      builder: (context, int themeMode, _) {
        return MaterialApp.router(
          title: 'Polaris',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.values[themeMode],
          routeInformationParser: PolarisRouteInformationParser(),
          routerDelegate: PolarisRouterDelegate(),
          debugShowCheckedModeBanner: false,
        );
      },
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
    getIt<cleanup.Manager>().dispose();
    getIt<MediaCacheInterface>().dispose();
    super.dispose();
  }
}
