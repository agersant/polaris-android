import 'dart:io';
import 'package:get_it/get_it.dart';
import 'package:polaris/platform/api.dart';

final getIt = GetIt.instance;

class MediaProxy {
  static final String portParam = 'port';
  static final String audioEndpoint = '/audio';
  static final String pathQueryParameter = 'path';

  final _api = getIt<API>();
  HttpServer _server;

  static Future<MediaProxy> create() async {
    final mediaProxy = new MediaProxy();
    await mediaProxy.start();
    return mediaProxy;
  }

  Future start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

    _server.listen((request) async {
      final bool isAudioRequest = request.uri.path == audioEndpoint;
      assert(isAudioRequest);
      final String path = request.uri.queryParameters[pathQueryParameter];
      final streamedResponse = await _api.downloadAudio(path);

      request.response.contentLength = streamedResponse.contentLength ?? -1;
      request.response.statusCode = streamedResponse.statusCode;
      for (var header in streamedResponse.headers.entries) {
        // TODO explodes when path contains non-ASCII characters w/ content-disposition header
        request.response.headers.add(header.key, header.value);
      }
      request.response.headers
          .removeAll(HttpHeaders.contentEncodingHeader); // Compression already handled, we have the raw response

      streamedResponse.stream.pipe(request.response);
    });
  }

  int get port => _server?.port;

  Future stop() => _server.close();
}
