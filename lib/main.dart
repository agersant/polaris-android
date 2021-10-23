import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:polaris/core/authentication.dart' as authentication;
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/playlist.dart';
import 'package:polaris/shared/token.dart' as token;
import 'package:polaris/shared/host.dart' as host;
import 'package:polaris/shared/polaris.dart' as polaris;
import 'package:polaris/shared/shared_preferences_host.dart';
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
  final polarisAPI = polaris.HttpAPI(
    client: client,
    hostManager: hostManager,
    tokenManager: tokenManager,
  );
  final uuid = Uuid();
  final audioPlayer = AudioPlayer();
  final playlist = Playlist(uuid: uuid, polarisAPI: polarisAPI, audioPlayer: audioPlayer);

  getIt.registerSingleton<AudioPlayer>(audioPlayer);
  getIt.registerSingleton<Playlist>(playlist);
  getIt.registerSingleton<host.Manager>(hostManager);
  getIt.registerSingleton<connection.Manager>(connectionManager);
  getIt.registerSingleton<authentication.Manager>(authenticationManager);
  getIt.registerSingleton<polaris.API>(polarisAPI);
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
        ChangeNotifierProvider.value(value: getIt<polaris.API>()),
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
