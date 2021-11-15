import 'mock/client.dart' as http_client;
import 'mock/media_cache.dart';
import 'mock/pin.dart' as pin;
import 'package:just_audio/just_audio.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/authentication.dart' as authentication;
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/download.dart' as download;
import 'package:polaris/core/playlist.dart';
import 'package:polaris/core/polaris.dart' as polaris;
import 'package:polaris/core/prefetch.dart' as prefetch;
import 'package:polaris/ui/collection/browser_model.dart';
import 'package:polaris/ui/playback/queue_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final getIt = GetIt.instance;

class Harness {
  final http_client.Mock mockHTTPClient;
  final CollectionCache collectionCache;

  Harness(this.mockHTTPClient, this.collectionCache);

  static final Map<String, Object> reconnectPreferences = {
    connection.hostPreferenceKey: http_client.goodHostURI,
    authentication.tokenPreferenceKey: 'auth-token',
    authentication.usernamePreferenceKey: 'good-username'
  };

  static Future<Harness> reconnect() async {
    return create(preferences: reconnectPreferences);
  }

  static Future<Harness> create({Map<String, Object>? preferences}) async {
    SharedPreferences.setMockInitialValues(preferences ?? {});

    getIt.allowReassignment = true;

    const uuid = Uuid();
    final mockHttpClient = http_client.Mock();
    final connectionManager = connection.Manager(httpClient: mockHttpClient);
    final authenticationManager = authentication.Manager(
      httpClient: mockHttpClient,
      connectionManager: connectionManager,
    );
    final polarisHttpClient = polaris.HttpClient(
      httpClient: mockHttpClient,
      connectionManager: connectionManager,
      authenticationManager: authenticationManager,
    );
    final mediaCache = await MediaCache.create();
    final collectionCache = CollectionCache(Collection());
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
    audioPlayer.setAudioSource(playlist.audioSource);
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

    return Harness(mockHttpClient, collectionCache);
  }
}
