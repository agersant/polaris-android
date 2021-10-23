import 'mock/client.dart' as httpClient;
import 'package:just_audio/just_audio.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/playlist.dart';
import 'package:polaris/core/polaris.dart' as polaris;
import 'package:polaris/core/authentication.dart' as authentication;
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/ui/collection/browser_model.dart';
import 'package:polaris/ui/playback/queue_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final getIt = GetIt.instance;

class Harness {
  final httpClient.Mock mockHTTPClient;
  Harness(this.mockHTTPClient);

  static final Map<String, Object> reconnectPreferences = {
    connection.hostPreferenceKey: httpClient.goodHostURI,
    authentication.tokenPreferenceKey: 'auth-token',
  };

  static Future<Harness> reconnect() async {
    return create(preferences: reconnectPreferences);
  }

  static Future<Harness> create({Map<String, Object>? preferences}) async {
    SharedPreferences.setMockInitialValues(preferences ?? new Map());

    getIt.allowReassignment = true;

    final mockHttpClient = httpClient.Mock();
    final connectionManager = connection.Manager(httpClient: mockHttpClient);
    final authenticationManager = authentication.Manager(
      httpClient: mockHttpClient,
      connectionManager: connectionManager,
    );
    final polarisClient = polaris.HttpClient(
      httpClient: mockHttpClient,
      connectionManager: connectionManager,
      authenticationManager: authenticationManager,
    );

    final uuid = Uuid();
    final audioPlayer = AudioPlayer();
    final playlist = Playlist(uuid: uuid, polarisClient: polarisClient, audioPlayer: audioPlayer);
    audioPlayer.setAudioSource(playlist.audioSource);

    getIt.registerSingleton<AudioPlayer>(audioPlayer);
    getIt.registerSingleton<Playlist>(playlist);
    getIt.registerSingleton<connection.Manager>(connectionManager);
    getIt.registerSingleton<authentication.Manager>(authenticationManager);
    getIt.registerSingleton<polaris.Client>(polarisClient);
    getIt.registerSingleton<BrowserModel>(BrowserModel());
    getIt.registerSingleton<QueueModel>(QueueModel());
    getIt.registerSingleton<Uuid>(uuid);

    return Harness(mockHttpClient);
  }
}
