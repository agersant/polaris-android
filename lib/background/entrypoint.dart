import 'package:audio_service/audio_service.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:polaris/background/audio_player.dart';
import 'package:polaris/background/cache.dart' as cache;
import 'package:polaris/background/collection.dart';
import 'package:polaris/background/proxy_server.dart';
import 'package:polaris/shared/polaris.dart' as polaris;
import 'package:polaris/shared/token.dart' as token;
import 'package:polaris/shared/shared_preferences_host.dart';

final getIt = GetIt.instance;

final String customActionGetPort = 'getPort';
final String customActionMoveQueueItem = 'moveQueueItem';
final String customActionAddNextQueueItem = 'addNextQueueItem';

ProxyServer _proxyServer;

void entrypoint() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hostManager = await SharedPreferencesHost.create();
  final tokenManager = await token.Manager.create();
  final cacheManager = await cache.Manager.create();
  final collectionAPI = polaris.HttpAPI(client: Client(), tokenManager: tokenManager, hostManager: hostManager);
  final Collection collection = new Collection(
    hostManager: hostManager,
    cacheManager: cacheManager,
    collectionAPI: collectionAPI,
  );
  _proxyServer = await ProxyServer.create(collection);
  await AudioServiceBackground.run(() {
    return AudioPlayerTask(proxyServerPort: _proxyServer.port);
  });
}
