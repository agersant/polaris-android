import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:flutter/painting.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:polaris/service/cache.dart' as cache;
import 'package:polaris/shared/collection_api.dart';
import 'package:polaris/shared/host.dart' as host;

// TODO no getIt
final getIt = GetIt.instance;

class _Job {
  String path;
  Future<Uint8List> result;

  _Job(this.path, this.result);
}

class Collection {
  final _host = getIt<host.Manager>();
  final _api = getIt<CollectionAPI>();
  final _cache = getIt<cache.Interface>();
  final _imageJobs = Map<String, _Job>();

  Future<ByteStream> getAudio(String path) async {
    // TODO
    return null;
  }

  Future<ImageProvider> getImage(String path) async {
    if (path == null || path.isEmpty) {
      return null;
    }
    final host = _host.url;
    final cacheFile = await _cache.getImage(host, path);
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

  downloadImage(String path) {
    final host = _host.url;
    _downloadImage(host, path);
  }

  _Job _downloadImage(String host, String path) {
    assert(!_imageJobs.containsKey(path));
    developer.log('Beginning image download: $path');
    final job = _Job(path, _api.downloadImage(path));
    _imageJobs[path] = job;
    job.result.then((bytes) async {
      await _cache.putImage(host, path, bytes);
    }).catchError((e) => developer.log('Error downloading image: $path', error: e));
    return job;
  }
}
