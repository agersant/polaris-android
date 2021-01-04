import 'dart:io';
import 'package:get_it/get_it.dart';
import 'package:polaris/service/collection.dart';

// TODO no getIt
final getIt = GetIt.instance;

class ProxyServer {
  static final String portParam = 'port';
  static final String audioEndpoint = '/audio';
  static final String pathQueryParameter = 'path';
  final Collection collection;

  ProxyServer({this.collection}) : assert(collection != null);

  HttpServer _server;

  static Future<ProxyServer> create() async {
    final mediaProxy = new ProxyServer();
    await mediaProxy.start();
    return mediaProxy;
  }

  // TODO this must implement full Polaris API :(

  Future start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

    _server.listen((request) async {
      final bool isAudioRequest = request.uri.path == audioEndpoint;
      assert(isAudioRequest);
      final String path = request.uri.queryParameters[pathQueryParameter];
      final data = await collection.getAudio(path); // TODO error handling

      request.response.contentLength = -1;
      request.response.statusCode = 200;
      // TODO content-type header?

      data.pipe(request.response);
    });
  }

  int get port => _server?.port;

  Future stop() => _server.close();
}
