import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:polaris/core/cache.dart' as cache;
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/polaris.dart' as polaris;

class _ImageJob {
  String path;
  Future<Uint8List> imageData;
  _ImageJob(this.path, this.imageData);
}

class Manager {
  final cache.Manager _cacheManager;
  final connection.Manager _connectionManager;
  final polaris.HttpClient _httpClient;

  final _imageJobs = Map<String, _ImageJob>();

  Manager({required cacheManager, required connectionManager, required httpClient})
      : _cacheManager = cacheManager,
        _connectionManager = connectionManager,
        _httpClient = httpClient;

  Future<Uint8List?> downloadImage(String path) {
    final _ImageJob? existingJob = _imageJobs[path];
    if (existingJob != null) {
      return existingJob.imageData;
    }

    final host = _connectionManager.url;
    if (host == null) {
      return Future.value(null);
    }

    developer.log('Downloading image: $path');
    final imageData = _httpClient.getImage(path).then((r) => http.Response.fromStream(r)).then((r) {
      if (r.statusCode >= 300) {
        throw r.statusCode;
      }
      _cacheManager.putImage(host, path, r.bodyBytes);
      return r.bodyBytes;
    }).catchError((e) {
      developer.log('Error while downloading image: $path', error: e);
      throw e;
    });

    final job = _ImageJob(path, imageData);
    _imageJobs[path] = job;
    job.imageData.whenComplete(() async {
      _imageJobs.remove(job);
    });

    return job.imageData;
  }
}
