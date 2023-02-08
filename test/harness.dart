import 'package:flutter_settings_screens/flutter_settings_screens.dart';

import 'mock/client.dart' as mock;
import 'mock/media_cache.dart' as mock;
import 'mock/pin.dart' as pin;
import 'package:just_audio/just_audio.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/cache/media.dart';
import 'package:polaris/core/authentication.dart' as authentication;
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/cleanup.dart' as cleanup;
import 'package:polaris/core/download.dart' as download;
import 'package:polaris/core/playlist.dart';
import 'package:polaris/core/polaris.dart' as polaris;
import 'package:polaris/core/prefetch.dart' as prefetch;
import 'package:polaris/core/savestate.dart' as savestate;
import 'package:polaris/core/settings.dart' as settings;
import 'package:polaris/ui/collection/browser_model.dart';
import 'package:polaris/ui/pages_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final getIt = GetIt.instance;

class Harness {
  final mock.HttpClient mockHTTPClient;
  final CollectionCache collectionCache;

  Harness(this.mockHTTPClient, this.collectionCache);

  static final Map<String, Object> reconnectPreferences = {
    connection.hostPreferenceKey: mock.goodHostURI,
    authentication.authHostPreferenceKey: mock.goodHostURI,
    authentication.tokenPreferenceKey: 'auth-token',
    authentication.usernamePreferenceKey: 'good-username'
  };

  static Future<Harness> reconnect() async {
    return create(preferences: reconnectPreferences);
  }

  static Future<Harness> create({Map<String, Object>? preferences}) async {
    SharedPreferences.setMockInitialValues(preferences ?? {});
    await Settings.init();

    getIt.allowReassignment = true;

    const uuid = Uuid();
    final settingsManager = settings.Manager();
    final mockHttpClient = mock.HttpClient();
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
    final MediaCacheInterface mediaCache = await mock.MediaCache.create();
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
    final savestateManager =
        savestate.Manager(connectionManager: connectionManager, audioPlayer: audioPlayer, playlist: playlist);
    final pinManager = await pin.Manager.create();
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

    audioPlayer.setAudioSource(playlist.audioSource);
    savestateManager.init();

    return Harness(mockHttpClient, collectionCache);
  }
}
