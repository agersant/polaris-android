import 'mock/client.dart' as client;
import 'package:just_audio/just_audio.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/playlist.dart';
import 'package:polaris/core/polaris.dart' as polaris;
import 'package:polaris/shared/host.dart' as host;
import 'package:polaris/shared/shared_preferences_host.dart' as host;
import 'package:polaris/core/authentication.dart' as authentication;
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/ui/collection/browser_model.dart';
import 'package:polaris/ui/playback/queue_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final getIt = GetIt.instance;

class Harness {
  final client.Mock mockClient;
  Harness(this.mockClient);

  static final Map<String, Object> reconnectPreferences = {
    host.preferenceKey: client.goodHostURI,
    authentication.tokenPreferenceKey: 'auth-token',
  };

  static Future<Harness> reconnect() async {
    return create(preferences: reconnectPreferences);
  }

  static Future<Harness> create({Map<String, Object>? preferences}) async {
    SharedPreferences.setMockInitialValues(preferences ?? new Map());

    getIt.allowReassignment = true;

    final hostManager = await host.SharedPreferencesHost.create();
    final mockClient = client.Mock();
    final guestAPI = polaris.HttpGuestClient(
      hostManager: hostManager,
      httpClient: mockClient,
    );

    final connectionManager = connection.Manager(
      hostManager: hostManager,
      guestAPI: guestAPI,
    );
    final authenticationManager = authentication.Manager(
      connectionManager: connectionManager,
      guestAPI: guestAPI,
    );
    final polarisClient = polaris.HttpClient(
      httpClient: mockClient,
      hostManager: hostManager,
      authenticationManager: authenticationManager,
    );

    final uuid = Uuid();
    final audioPlayer = AudioPlayer();
    final playlist = Playlist(uuid: uuid, polarisClient: polarisClient, audioPlayer: audioPlayer);
    audioPlayer.setAudioSource(playlist.audioSource);

    getIt.registerSingleton<AudioPlayer>(audioPlayer);
    getIt.registerSingleton<Playlist>(playlist);
    getIt.registerSingleton<host.Manager>(hostManager);
    getIt.registerSingleton<connection.Manager>(connectionManager);
    getIt.registerSingleton<authentication.Manager>(authenticationManager);
    getIt.registerSingleton<polaris.Client>(polarisClient);
    getIt.registerSingleton<BrowserModel>(BrowserModel());
    getIt.registerSingleton<QueueModel>(QueueModel());
    getIt.registerSingleton<Uuid>(uuid);

    return Harness(mockClient);
  }
}
