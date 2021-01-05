import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:polaris/service/cache.dart' as cache;
import 'package:polaris/shared/collection_api.dart';
import 'package:polaris/shared/dto.dart';
import 'package:polaris/shared/host.dart' as host;

class _ImageJob {
  String path;
  Future<Uint8List> imageData;
  _ImageJob(this.path, this.imageData);
}

class Collection {
  final host.Manager hostManager; // TODO remove dependency on hostmanager (go through collection API instead)
  final CollectionAPI collectionAPI;
  final cache.Interface cacheManager;

  final _imageJobs = Map<String, _ImageJob>();

  Collection({@required this.hostManager, @required this.collectionAPI, @required this.cacheManager})
      : assert(hostManager != null),
        assert(collectionAPI != null),
        assert(cacheManager != null);

  Future<List<CollectionFile>> browse(String path) async {
    return collectionAPI.browse(path);
  }

  Future<List<Directory>> random() async {
    return collectionAPI.random();
  }

  Future<List<Directory>> recent() async {
    return collectionAPI.recent();
  }

  Future<Stream<List<int>>> getAudio(String path) async {
    // TODO
    return null;
  }

  Future<Stream<List<int>>> getImage(String path) async {
    if (path == null || path.isEmpty) {
      return null;
    }
    final host = hostManager.url;
    final cacheFile = await cacheManager.getImage(host, path);
    if (cacheFile != null) {
      return cacheFile.openRead();
    }
    final job = _imageJobs[path] ?? _downloadImage(host, path);
    try {
      return Stream.value(await job.imageData);
    } catch (e) {
      return null;
    }
  }

  _ImageJob _downloadImage(String host, String path) {
    assert(!_imageJobs.containsKey(path));
    developer.log('Beginning image download: $path');
    final streamedResponse = collectionAPI.downloadImage(path);
    final job = _ImageJob(
        path,
        streamedResponse
            .then((r) => http.Response.fromStream(r))
            .then((r) => r.bodyBytes)
            .catchError((e) => developer.log('Error downloading image: $path', error: e)));
    _imageJobs[path] = job;
    job.imageData.then((bytes) async {
      await cacheManager.putImage(host, path, bytes);
    });
    return job;
  }
}
