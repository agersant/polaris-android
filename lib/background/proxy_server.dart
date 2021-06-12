import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:polaris/background/collection.dart';
import 'package:polaris/shared/dto.dart';
import 'package:polaris/shared/polaris.dart';

class ProxyServer {
  static final String portParam = 'port';
  static final String audioEndpoint = '/audio';
  static final String pathQueryParameter = 'path';
  final Collection collection;

  ProxyServer({required this.collection});

  late final HttpServer _server;

  static Future<ProxyServer> create(Collection collection) async {
    final mediaProxy = new ProxyServer(collection: collection);
    await mediaProxy.start();
    return mediaProxy;
  }

  Future start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((HttpRequest request) {
      _handleRequest(request);
    });
  }

  void _handleRequest(HttpRequest request) async {
    // TODO handle errors from collection calls
    try {
      if (request.uri.path.startsWith(browseEndpoint)) {
        _handleBrowseRequest(request);
      } else if (request.uri.path.startsWith(randomEndpoint)) {
        _handleRandomRequest(request);
      } else if (request.uri.path.startsWith(recentEndpoint)) {
        _handleRecentRequest(request);
      } else if (request.uri.path.startsWith(thumbnailEndpoint)) {
        _handleThumbnailRequest(request);
      } else if (request.uri.path.startsWith(audioEndpoint)) {
        _handleAudioRequest(request);
      } else {
        request.response
          ..contentLength = 0
          ..statusCode = HttpStatus.notFound
          ..close();
      }
    } catch (e) {
      developer.log('Unhandled server error: $e');
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..close();
    }
  }

  void _handleBrowseRequest(HttpRequest request) async {
    final String path = Uri.decodeComponent(request.uri.path.substring(browseEndpoint.length));
    final List<CollectionFile> results = await collection.browse(path);
    final encoded = utf8.encode(jsonEncode(results));
    request.response
      ..contentLength = encoded.length
      ..statusCode = HttpStatus.ok
      ..add(encoded)
      ..close();
  }

  void _handleRandomRequest(HttpRequest request) async {
    final List<Directory> results = await collection.random();
    final encoded = utf8.encode(jsonEncode(results));
    request.response
      ..contentLength = encoded.length
      ..statusCode = HttpStatus.ok
      ..add(encoded)
      ..close();
  }

  void _handleRecentRequest(HttpRequest request) async {
    final List<Directory> results = await collection.recent();
    final encoded = utf8.encode(jsonEncode(results));
    request.response
      ..contentLength = encoded.length
      ..statusCode = HttpStatus.ok
      ..add(encoded)
      ..close();
  }

  void _handleThumbnailRequest(HttpRequest request) async {
    final String path = Uri.decodeComponent(request.uri.path.substring(thumbnailEndpoint.length));
    final data = await collection.getImage(path);
    if (data == null) {
      request.response
        ..contentLength = 0
        ..statusCode = HttpStatus.internalServerError
        ..close();
    } else {
      request.response
        ..contentLength = -1
        ..statusCode = HttpStatus.ok;
      data.pipe(request.response);
    }
  }

  void _handleAudioRequest(HttpRequest request) async {
    final String path = request.uri.queryParameters[pathQueryParameter] ?? "";
    final data = await collection.getAudio(path);
    if (data == null) {
      request.response
        ..contentLength = 0
        ..statusCode = HttpStatus.internalServerError
        ..close();
    } else {
      request.response
        ..contentLength = -1
        ..statusCode = HttpStatus.ok;
      data.pipe(request.response);
    }
  }

  int get port => _server.port;

  Future stop() => _server.close();
}
