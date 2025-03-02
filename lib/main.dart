import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:polaris/core/audio_handler.dart';
import 'package:polaris/core/authentication.dart' as authentication;
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/cache/media.dart';
import 'package:polaris/core/cleanup.dart' as cleanup;
import 'package:polaris/core/client/api/api_client.dart';
import 'package:polaris/core/client/app_client.dart';
import 'package:polaris/core/client/offline_client.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/download.dart' as download;
import 'package:polaris/core/pin.dart' as pin;
import 'package:polaris/core/playlist.dart';
import 'package:polaris/core/prefetch.dart' as prefetch;
import 'package:polaris/core/savestate.dart' as savestate;
import 'package:polaris/core/settings.dart' as settings;
import 'package:polaris/core/songs.dart' as songs;
import 'package:polaris/ui/collection/album_details.dart';
import 'package:polaris/ui/collection/artist.dart';
import 'package:polaris/ui/collection/browser_model.dart';
import 'package:polaris/ui/collection/genre.dart';
import 'package:polaris/ui/collection/page.dart';
import 'package:polaris/ui/offline_music/page.dart';
import 'package:polaris/ui/pages_model.dart';
import 'package:polaris/ui/playback/mini_player.dart';
import 'package:polaris/ui/playback/player.dart';
import 'package:polaris/ui/playback/queue.dart';
import 'package:polaris/ui/settings/page.dart';
import 'package:polaris/ui/startup/page.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

final getIt = GetIt.instance;

final lightTheme = ThemeData(
  useMaterial3: false,
  brightness: Brightness.light,
  primarySwatch: Colors.blue,
);

final darkTheme = ThemeData(
  useMaterial3: false,
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  indicatorColor: Colors.blue, // TabBar current tab highlight
);

Future _registerSingletons() async {
  const uuid = Uuid();
  final settingsManager = settings.Manager();
  final mediaCache = await MediaCache.create();
  final collectionCache = await CollectionCache.create();
  final httpClient = http.Client();
  final connectionManager = connection.Manager(httpClient: httpClient);
  final authenticationManager = authentication.Manager(
    httpClient: httpClient,
    connectionManager: connectionManager,
  );
  final apiClient = APIClient(
    httpClient: httpClient,
    connectionManager: connectionManager,
    authenticationManager: authenticationManager,
    collectionCache: collectionCache,
  );
  final downloadManager = download.Manager(
    mediaCache: mediaCache,
    apiClient: apiClient,
  );
  final offlineClient = OfflineClient(
    mediaCache: mediaCache,
    collectionCache: collectionCache,
  );
  final songsManager = songs.Manager(
    connectionManager: connectionManager,
    authenticationManager: authenticationManager,
    collectionCache: collectionCache,
    apiClient: apiClient,
  );
  final appClient = AppClient(
    offlineClient: offlineClient,
    apiClient: apiClient,
    downloadManager: downloadManager,
    connectionManager: connectionManager,
    collectionCache: collectionCache,
    mediaCache: mediaCache,
  );
  final audioHandler = await initAudioService(
    connectionManager: connectionManager,
    collectionCache: collectionCache,
    appClient: appClient,
  );
  final audioPlayer = audioHandler.audioPlayer;
  final playlist = Playlist(
    uuid: uuid,
    connectionManager: connectionManager,
    appClient: appClient,
    audioPlayer: audioPlayer,
  );
  final savestateManager = savestate.Manager(
    connectionManager: connectionManager,
    collectionCache: collectionCache,
    audioPlayer: audioPlayer,
    playlist: playlist,
  );
  final pinManager = await pin.Manager.create(
    connectionManager: connectionManager,
    appClient: appClient,
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
    collectionCache: collectionCache,
    mediaCache: mediaCache,
    pinManager: pinManager,
    audioPlayer: audioPlayer,
    settingsManager: settingsManager,
  );
  final browserModel = BrowserModel(connectionManager: connectionManager);

  // TODO Needs some logic to recover from app restart while audio service is still running (?)

  getIt.registerSingleton<PolarisAudioHandler>(audioHandler);
  getIt.registerSingleton<AudioPlayer>(audioPlayer);
  getIt.registerSingleton<Playlist>(playlist);
  getIt.registerSingleton<CollectionCache>(collectionCache);
  getIt.registerSingleton<MediaCacheInterface>(mediaCache);
  getIt.registerSingleton<connection.Manager>(connectionManager);
  getIt.registerSingleton<authentication.Manager>(authenticationManager);
  getIt.registerSingleton<AppClient>(appClient);
  getIt.registerSingleton<savestate.Manager>(savestateManager);
  getIt.registerSingleton<pin.Manager>(pinManager);
  getIt.registerSingleton<prefetch.Manager>(prefetchManager);
  getIt.registerSingleton<cleanup.Manager>(cleanupManager);
  getIt.registerSingleton<BrowserModel>(browserModel);
  getIt.registerSingleton<PagesModel>(PagesModel());
  getIt.registerSingleton<settings.Manager>(settingsManager);
  getIt.registerSingleton<songs.Manager>(songsManager);
  getIt.registerSingleton<Uuid>(uuid);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.init();
  await _registerSingletons();
  FlutterDisplayMode.setHighRefreshRate();
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
          final showQueue = isStartupComplete && pagesModel.isQueueOpen;
          final showSettings = isStartupComplete && pagesModel.isSettingsOpen;
          final showOfflineMusic = isStartupComplete && pagesModel.isOfflineMusicOpen;
          final showArtist = isStartupComplete && pagesModel.artist != null;
          final showAlbum = isStartupComplete && pagesModel.album != null;
          final showGenre = isStartupComplete && pagesModel.genre != null;

          final collectionPages = [
            if (showGenre)
              MaterialPage<dynamic>(
                  child: Genre(pagesModel.genre!),
                  onPopInvoked: (didPop, dynamic result) {
                    if (didPop) {
                      pagesModel.handleGenrePageClosed();
                    }
                  }),
            if (showArtist)
              MaterialPage<dynamic>(
                  child: Artist(pagesModel.artist!),
                  onPopInvoked: (didPop, dynamic result) {
                    if (didPop) {
                      pagesModel.handleArtistPageClosed();
                    }
                  }),
            if (showAlbum)
              MaterialPage<dynamic>(
                  child: AlbumDetails(pagesModel.album!),
                  onPopInvoked: (didPop, dynamic result) {
                    if (didPop) {
                      pagesModel.handleAlbumPageClosed();
                    }
                  }),
          ];

          final playbackPages = [
            if (showPlayer)
              MaterialPage<dynamic>(
                  child: const PlayerPage(),
                  onPopInvoked: (didPop, dynamic result) {
                    if (didPop) {
                      pagesModel.handlePlayerClosed();
                    }
                  }),
            if (showQueue)
              MaterialPage<dynamic>(
                  child: const QueuePage(),
                  onPopInvoked: (didPop, dynamic result) {
                    if (didPop) {
                      pagesModel.handleQueueClosed();
                    }
                  }),
          ];

          final sortedPages = pagesModel.zones
              .expand((z) => switch (z) {
                    Zone.collection => collectionPages,
                    Zone.playback => playbackPages,
                  })
              .toList();

          final topPage = sortedPages.lastOrNull?.child;
          final collapseMiniPlayer = !isStartupComplete || topPage is PlayerPage || topPage is QueuePage;

          return Column(
            children: [
              Expanded(
                child: Navigator(
                  key: navigatorKey,
                  onDidRemovePage: (page) {},
                  pages: [
                    if (!isStartupComplete) MaterialPage<dynamic>(child: StartupPage()),
                    if (isStartupComplete) const MaterialPage<dynamic>(child: CollectionPage()),
                    if (showSettings)
                      MaterialPage<dynamic>(
                          child: const SettingsPage(),
                          onPopInvoked: (didPop, dynamic result) {
                            if (didPop) {
                              pagesModel.handleSettingsClosed();
                            }
                          }),
                    if (showOfflineMusic)
                      MaterialPage<dynamic>(
                          child: const OfflineMusicPage(),
                          onPopInvoked: (didPop, dynamic result) {
                            if (didPop) {
                              pagesModel.handleOfflineMusicClosed();
                            }
                          }),
                    ...sortedPages,
                  ],
                ),
              ),
              MiniPlayer(collapse: collapseMiniPlayer),
            ],
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
