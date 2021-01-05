import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:http/http.dart';
import 'package:polaris/service/cache.dart' as cache;
import 'package:polaris/shared/collection_api.dart';
import 'package:polaris/shared/dto.dart';
import 'package:polaris/shared/host.dart' as host;

class _Job {
  String path;
  Future<Uint8List> result;

  _Job(this.path, this.result);
}

class Collection {
  final host.Manager hostManager; // TODO remove dependency on hostmanager (go through collection API instead)
  final CollectionAPI collectionAPI;
  final cache.Interface cacheManager;

  final _imageJobs = Map<String, _Job>();

  Collection({@required this.hostManager, @required this.collectionAPI, @required this.cacheManager})
      : assert(hostManager != null),
        assert(collectionAPI != null),
        assert(cacheManager != null);

  Future<List<CollectionFile>> browse(String path) async {
    return collectionAPI.browse(path);
  }

  Future<ByteStream> getAudio(String path) async {
    // TODO
    return null;
  }

  Future<ImageProvider> getImage(String path) async {
    if (path == null || path.isEmpty) {
      return null;
    }
    final host = hostManager.url;
    final cacheFile = await cacheManager.getImage(host, path);
    if (cacheFile != null) {
      return FileImage(cacheFile);
    }
    final job = _imageJobs[path] ?? _downloadImage(host, path);
    try {
      return MemoryImage(await job.result);
    } catch (e) {
      return null;
    }
  }

  _Job _downloadImage(String host, String path) {
    assert(!_imageJobs.containsKey(path));
    developer.log('Beginning image download: $path');
    final job = _Job(path, collectionAPI.downloadImage(path));
    _imageJobs[path] = job;
    job.result.then((bytes) async {
      await cacheManager.putImage(host, path, bytes);
    }).catchError((e) => developer.log('Error downloading image: $path', error: e));
    return job;
  }
}
